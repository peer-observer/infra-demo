let
  # when changing any of these keys, use the following to re-key:
  # agenix -r -i b10c.agekey

  # An age key by b10c.
  # Generated with "age-keygen -o b10c.agekey"
  # The private key is encrypted with GPG with "gpg --encrypt -r 982A193E3CE0EED535E09023188CBB2648416AD5 b10c.agekey"
  b10c = "age1dcssyes2yufpv02d2x5gyev6nn3cmggkpluuzmgctmlaqpcps9pq2u6xge";

  # got these with "ssh-keyscan <ip>"
  hal = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIByjvlE7jneJCR6Cn4RksL6QXaxVj1/xHcG5hy8WqsyX";
  len = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJxBizzOxd7L7A4D5NrGrzWn7tI1AhMe2XLxGVq3aIql";
  jude = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILAe0id3NF/0Vr9eTRpWu9/GS+8Yl/FJcx6lLmAoAMNS";
in
{

  ## node secrets
  # hal
  "wireguard-private-key-hal.age".publicKeys = [
    hal
    b10c
  ];
  # only present for hal, as we only expose the NATS server on hal
  "extractor-nats-password-hal.age".publicKeys = [
    hal
    b10c
  ];

  # len
  "wireguard-private-key-len.age".publicKeys = [
    len
    b10c
  ];

  ## web secrets
  # jude
  "wireguard-private-key-jude.age".publicKeys = [
    jude
    b10c
  ];
  "grafana-admin-password-jude.age".publicKeys = [
    jude
    b10c
  ];
}
