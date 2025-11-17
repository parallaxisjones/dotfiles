{ config, user, ... }:

{
  # Mount Synology NAS shares via SMB/CIFS
  # Using fileSystems (not systemd.mounts) so it runs after activation scripts
  # which is when agenix decrypts secrets
  # Note: SMB share names are just the share name, not "volume1/ShareName" (volume1 is internal)

  fileSystems."/mnt/nas/documents" =
    let
      userUid = toString config.users.users.${user}.uid;
      primaryGroup = config.users.users.${user}.group or user;
      userGid = toString config.users.groups.${primaryGroup}.gid;
    in
    {
      device = "//nasology.tail9fed5f.ts.net/Documents";
      fsType = "cifs";
      options = [
        "nofail"
        "_netdev"
        "credentials=${config.age.secrets.smb-credentials.path}"
        "uid=${userUid}"
        "gid=${userGid}"
        "file_mode=0664"
        "dir_mode=0775"
      ];
    };

  fileSystems."/mnt/nas/downloads" =
    let
      userUid = toString config.users.users.${user}.uid;
      primaryGroup = config.users.users.${user}.group or user;
      userGid = toString config.users.groups.${primaryGroup}.gid;
    in
    {
      device = "//nasology.tail9fed5f.ts.net/Downloads";
      fsType = "cifs";
      options = [
        "nofail"
        "_netdev"
        "credentials=${config.age.secrets.smb-credentials.path}"
        "uid=${userUid}"
        "gid=${userGid}"
        "file_mode=0664"
        "dir_mode=0775"
      ];
    };

  fileSystems."/mnt/nas/media" =
    let
      userUid = toString config.users.users.${user}.uid;
      primaryGroup = config.users.users.${user}.group or user;
      userGid = toString config.users.groups.${primaryGroup}.gid;
    in
    {
      device = "//nasology.tail9fed5f.ts.net/Media";
      fsType = "cifs";
      options = [
        "nofail"
        "_netdev"
        "credentials=${config.age.secrets.smb-credentials.path}"
        "uid=${userUid}"
        "gid=${userGid}"
        "file_mode=0664"
        "dir_mode=0775"
      ];
    };
}

