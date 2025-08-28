{ user, config, ... }:

let
  xdg_configHome = "${config.users.users.${user}.home}/.config";

  inherit (config.users.users.${user}) home;
  mcpServers = import ../shared/mcp-servers.nix { inherit home; };
in
{
  # Other file definitions can go here...
  # mcp-hub removed
}
