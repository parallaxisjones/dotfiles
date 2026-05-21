{ pkgs, lib, ... }:

let
  fragment = pkgs.writeText "10-anthropic-api-key.json" (
    builtins.toJSON {
      apiKeyHelper = "cat /Users/pjones/.config/anthropic/api-key";
    }
  );
in
{
  # Run before homebrew activation (see activation-scripts.nix order): when brew bundle fails,
  # postActivation never runs due to set -e.
  # system.activationScripts.extraActivation.text = lib.mkAfter ''
  #   MANAGED_DIR="/Library/Application Support/ClaudeCode/managed-settings.d"
  #   mkdir -p "$MANAGED_DIR"
  #   ${lib.getExe' pkgs.coreutils "install"} -m 0644 ${fragment} "$MANAGED_DIR/10-anthropic-api-key.json"
  # '';
}
