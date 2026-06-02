{ lib, secrets ? null, user, ... }:

lib.mkIf (secrets != null) {
  age = {
    identityPaths = [
      "/home/${user}/.ssh/id_ed25519"
    ];

    secrets = {
      # GitHub keys removed - not needed on this server
      # If needed in the future, add the encrypted files to the secrets repo first

      "smb-credentials" = {
        symlink = false;
        path = "/etc/nixos/secrets/smb-credentials";
        file = "${secrets}/smb-credentials.age";
        mode = "600";
        owner = "root";
        group = "root";
      };

      # gluetun reads this as an env file (environmentFiles). The decrypted
      # contents are a single line: WIREGUARD_PRIVATE_KEY=<key from ProtonVPN>.
      # Add protonvpn-wireguard.age to the nix-secrets repo before rebuilding.
      "protonvpn-wireguard" = {
        symlink = false;
        path = "/etc/nixos/secrets/protonvpn-wireguard";
        file = "${secrets}/protonvpn-wireguard.age";
        mode = "600";
        owner = "root";
        group = "root";
      };
    };
  };
}
