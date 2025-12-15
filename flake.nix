{
  description = "A NixOS flake for the demo.peer.observer infrastructure definition.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.11";
    b10c-nix = {
      url = "github:0xb10c/nix?ref=2025-12-peer-observer-protobuf-refactor";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    peer-observer-infra-library = {
      url = "github:0xB10C/peer-observer-infra-library";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.b10c-nix.follows = "b10c-nix";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      peer-observer-infra-library,
      b10c-nix,
      disko,
    }:
    let
      infra = import ./infra.nix { inherit nixpkgs peer-observer-infra-library disko; };

      # Systems we have a devShell for
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forSystem =
        system: f:
        f rec {
          inherit system;
          pkgs = import nixpkgs { inherit system; };
        };

      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: (forSystem system f));

    in
    {
      formatter = forAllSystems ({ system, ... }: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      nixosConfigurations = (peer-observer-infra-library.lib "x86_64-linux").mkConfigurations infra;

      # a shell with all needed tools
      # enter with `nix develop`
      devShells = forAllSystems (
        { pkgs, system, ... }:
        {
          default = pkgs.mkShell {
            buildInputs = [
              pkgs.nixos-anywhere
              pkgs.nixos-rebuild
              peer-observer-infra-library.packages.${system}.agenix
            ];

            shellHook = ''
              deploy() {
                local host=$1
                echo "deploying $host..."
                nixos-rebuild switch \
                --flake .#$host \
                --target-host $host \
                --build-host $host \
                --sudo \
                --show-trace
              }

              build-vm() {
                local host=$1
                echo "building $host..."
                nixos-rebuild build-vm \
                --flake .#$host \
                --show-trace
              }
              export -f build-vm

              echo "use 'deploy <host> to deploy a host'"
              echo "use 'build-vm <host> to build a vm of a host (useful when testing)'"
            '';
          };
        }
      );
    };
}
