{
  peer-observer-infra-library,
  disko,
  nixpkgs,
  ...
}:

let
  mkPkgs = system: import nixpkgs { inherit system; };
  customBitcoind =
    { system, overrides }: (peer-observer-infra-library.lib system).mkCustomBitcoind overrides;
in
{

  global = {
    admin = {
      username = "b10c";
      sshPubKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCtQmhXAp3F/KcaK3NzA30b2jE26zdYg6msXTXMBVJvZ8p8adHVYrl1QVFieeIjZvy1sj0gMXPOjYpgOm7OdwiZL4h0B9/FU49h+TLly6+YBwO/XYDR84WCvtv1/HVrVSIcYdMZo2+5fnGV3zxrtC/ndBheu17PbW7pvB+O7ODjxJa2tu66Q0If1cYH85PNkF3/jzsjQRwzo88eMxPEqVfp3MfYxJR53oWlXN2SUe1F/6FkeUulx9FpHgmWtPVLsGLd285GeQwsBUIRl+VnJQwCSB69YWgATR0zlRloFcfu1DhOCo5rGXnOvGmOWZ9LYpybwvuotQ8AGbsdNpZWYhQUNGF/YealVkyKABKhIHRQcGkqqqSGHpx6ui1tLkBHJWFgdCTU6eaK9OhgnjyHDJDtPGDl/Ek84JGYHp8+seHvE0/4GvQ2hQXUEUSQpxNwlwT1TKJ8uEMQuSn5zOK9TBSrYktW9h7HRe0ZQd23C6J38Lhxt9bJ3FcyfxFqogJZz3szAo0iR/bsjyeErfjKqeDHDZu4x9OISntrL42tCtNnb9ucWHo2nd+y+2X/hGQlGDdCo+RFi4cZeIHusibmr6J8FHnYgtNldamU2MYKk9R26MmPwVD/eM1Eq/sKL1jhAH3vfnxSifsQ6DvMicRiXWy/AOb3ZdZWVCLSd0mmrjkncQ== b10c"
      ];
    };
    extraConfig = {
      system.stateVersion = "25.11";

      # HACK: When starting the wireguard interface, might try to lookup the webserver domains
      # before we can resolve DNS queries. So add an /etc/host entry here.
      networking.hosts = {
        "40.160.235.42" = [ "demo.peer.observer" ];
      };
    };
  };

  agenixSecretsDir = ./secrets;

  nodes = {
    hal = {
      id = 1;
      setup = false;
      arch = "x86_64-linux";
      description = ''A Bitcoin Core node named after Hal Finney. Sponsored by <a href=https://lclhost.org/>Localhost Research</a>.'';

      wireguard = {
        ip = "10.20.0.1";
        pubkey = "hal/kH7xbDdOTrAL+6lqBnowJqronZMh+QzYDnV6nCU=";
      };

      bitcoind = {
        package = customBitcoind {
          system = "x86_64-linux";
          overrides = {
            sanitizersAddressUndefined = true;
          };
        };

        detailedLogging = {
          # we are a bit limited in disk space, so don't keep old debug logs for too long.
          logsToKeep = 2;
        };

        net = {
          useTor = true;
          useI2P = true;
          useASMap = true;
        };
      };

      extraConfig = {


      };
      extraModules = [
        disko.nixosModules.disko
        ./hosts/hal/disko.nix
        ./hosts/hal/hardware-configuration.nix
        ./hosts/hal/exposed-nats.nix
      ];
    };

    len = {
      id = 2;
      setup = false;
      arch = "x86_64-linux";
      description = ''A Bitcoin Core node named after Len Sassaman. Sponsored by <a href=https://lclhost.org/>Localhost Research</a>.'';

      wireguard = {
        ip = "10.20.0.2";
        pubkey = "len/Vm7OftPLWOqO4mIMJ+JlJIGB3EHqGZ8lBJ5opkU=";
      };

      bitcoind = {
        net = {
          useTor = true;
          useI2P = true;
          useASMap = true;
        };
        banlistScript = ''
          bitcoin-cli setban 162.218.65.0/24    add 31536000  # LinkingLion
          bitcoin-cli setban 209.222.252.0/24   add 31536000  # LinkingLion
          bitcoin-cli setban 91.198.115.0/24    add 31536000  # LinkingLion
          bitcoin-cli setban 2604:d500:4:1::/64 add 31536000  # LinkingLion
        '';
        detailedLogging = {
          # we are a bit limited in disk space, so don't keep old debug logs for too long.
          logsToKeep = 2;
        };
      };

      extraConfig = { };
      extraModules = [
        disko.nixosModules.disko
        ./hosts/len/disko.nix
        ./hosts/len/hardware-configuration.nix
      ];
    };
  };

  webservers = {
    jude =
      let
        domain = "demo.peer.observer";
      in
      {
        id = 1;
        setup = false;
        arch = "x86_64-linux";
        description = "The demo.peer.observer webserver - named after Judith Milhon.";
        domain = domain;

        wireguard = {
          ip = "10.20.1.2";
          pubkey = "jude3aDNN8hJTT8CvHXlJuJ7roMVYEr6LtpysP/EaWA=";
        };

        grafana.admin_user = "b10c";

        # On this demo instance, we give visitors full access to data.
        # This means, the IP address of the honeypot nodes can leak.
        # Don't do this in a "production" setup.
        access_DANGER = "FULL_ACCESS";

        index.fullAccessNotice = ''
          <div class="alert alert-info" role="alert">
            <h2>peer-observer demo instance</h2>
            This is a peer-observer demo instance operated by <a href="https://b10c.me">b10c</a> and sponsored by <a href=https://lclhost.org/>Localhost Research</a>: a Bitcoin-Focused Research Center in the Bay Area.
            <br><br>
            Normally, access to the peer-observer frontend is restricted to avoid leaking the honeypot node IP addresses to attackers.
            For this demo instance, full access is granted to all visitors. Feel free to explore!
            Note that data presented here could be manipulated by someone who found the node IP addresses.
            <br>
            <br>
            More information on peer-observer can be found in <a href="https://b10c.me/projects/024-peer-observer/">peer-observer: A tool and infrastructure for monitoring the Bitcoin P2P network for attacks and anomalies<a/>.
            <br>
            <br>
            The NixOS configuration for the demo infrastructure can be found in the <a href="https://github.com/0xB10C/peer-observer-infra-demo">peer-observer-infra-demo</a> repository.
          </div>
        '';

        extraConfig = {
          # For a Let's Encrypt ACME certificate, accept the terms.
          security.acme.acceptTerms = true;
          security.acme.defaults.email = "demo-peer-observer-acme@b10c.me";
        };

        extraModules = [
          disko.nixosModules.disko
          ./hosts/jude/disko.nix
          ./hosts/jude/hardware-configuration.nix
        ];

      };
  };

}
