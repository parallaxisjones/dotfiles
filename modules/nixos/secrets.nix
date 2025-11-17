{ secrets, user, ... }:
{
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
    };
  };

}
