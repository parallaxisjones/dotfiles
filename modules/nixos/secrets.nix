{ secrets, user, ... }:
{
  age = {
    identityPaths = [
      "/home/${user}/.ssh/id_ed25519"
    ];

    secrets = {
      "github-ssh-key" = {
        symlink = false;
        path = "/home/${user}/.ssh/id_github";
        file = "${secrets}/github-ssh-key.age";
        mode = "600";
        owner = user;
        group = "wheel";
      };

      "github-signing-key" = {
        symlink = false;
        path = "/home/${user}/.ssh/pgp_github.key";
        file = "${secrets}/github-signing-key.age";
        mode = "600";
        owner = user;
        group = "wheel";
      };

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
