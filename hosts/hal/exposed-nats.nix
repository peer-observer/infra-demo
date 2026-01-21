{ config, pkgs, ... }:


{

  # On host "hal", we want to expose the NATS server to external users.
  # This sets up authentification for publishing to NATS, but subscribing is
  # allowed without authentification (through no_auth_user).
  services.nats = {
    settings = {
      authorization = {
        users = [
          # can publish
          { user = "peerobserver-extractor"; password = "$2a$11$VIr5naSP6BqinPhD/1j54.cB3q7ozz5samciq/e5SJjOihHVO1h4i"; permissions = { publish = { allow = ">"; }; subscribe = { deny = ">"; }; }; }
          # can subscribe
          { user = "peerobserver-tool"; permissions = { publish = { deny = ">"; }; subscribe = { allow = ">"; }; }; }
        ];
      };
      no_auth_user = "peerobserver-tool";
    };
  };
  age.secrets.extractor-nats-password = {
    file = "${config.infra.agenixSecretsDir}/extractor-nats-password-hal.age";
    mode = "0440";
    owner = "peerobserver";
    group = "peerobserver";
  };
  services.peer-observer = {
    extractors = {
      ebpf.nats = {
        username = "peerobserver-extractor";
        passwordFile = config.age.secrets.extractor-nats-password.path;
      };
      rpc.nats = {
        username = "peerobserver-extractor";
        passwordFile = config.age.secrets.extractor-nats-password.path;
      };
      p2p.nats = {
        username = "peerobserver-extractor";
        passwordFile = config.age.secrets.extractor-nats-password.path;
      };
    };
  };

}
