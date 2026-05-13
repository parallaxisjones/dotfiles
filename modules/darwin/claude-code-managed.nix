{ pkgs, ... }:

let
  fragment = pkgs.writeText "10-anthropic-api-key.json" (
    builtins.toJSON {
      apiKeyHelper = "cat /Users/pjones/.config/anthropic/api-key";
    }
  );
in
{
  system.activationScripts.claudeCodeManagedSettings = {
    deps = [ ];
    text = ''
      MANAGED_DIR="/Library/Application Support/ClaudeCode/managed-settings.d"
      mkdir -p "$MANAGED_DIR"
      install -m 0644 ${fragment} "$MANAGED_DIR/10-anthropic-api-key.json"
    '';
  };
}
