{ pkgs, config, lib, ... }:

let
  # Path to local system cheat sheets (committed in dotfiles)
  cheatsheetPath = ./config/cheat/cheatsheets/system;
  cheatsheetFiles = builtins.readDir cheatsheetPath;

  # Map individual system cheatsheets into home.file entries
  mkCheatsheet = name: type:
    lib.nameValuePair ".config/cheat/cheatsheets/system/${name}" {
      source = cheatsheetPath + "/${name}";
    };

  systemCheatsheets = lib.mapAttrs' mkCheatsheet
    (lib.filterAttrs (n: v: v == "regular") cheatsheetFiles);

  # Pull in community cheat sheets as a full directory
  communityCheatsheets = {
    ".config/cheat/cheatsheets/community" = {
      source = builtins.fetchGit {
        url = "https://github.com/cheat/cheatsheets.git";
        ref = "master";
        # Optionally pin to a commit:
        rev = "36bdb99dcfadde210503d8c2dcf94b34ee950e1d";
      };
      recursive = true;
      force = true;
    };
  };

in
{
  ".ssh/known_hosts" = {
    force = true;
    text = ''
nixos.attlocal.net ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIUWX7kVXQnsjU2a2sHv7JvEaqP6FxF0OIgAe2PbFR5B
'';
  };

  ".ssh/id_github.pub" = {
    source = ./config/id_github.pub;
  };

  ".ssh/pgp_github.pub" = {
    source = ./config/pgp_github.pub;
  };

  ".config/nvim" = {
    source = ./config/nvim;
    recursive = true;
  };

  ".config/op-setup.sh" = {
    source = ./config/op-setup.sh;
  };

  ".config/cheat/conf.yml" = {
    source = ./config/cheat_conf.yml;
  };
}
//
systemCheatsheets
//
communityCheatsheets
