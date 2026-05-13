{ secrets, ... }:

let
  user = "pjones";
in
{
  age = {
    identityPaths = [ "/Users/${user}/.ssh/parallaxis" ];
    secrets = {
      "openai-key" = {
        symlink = true;
        path = "/Users/${user}/.config/nvim/openai_key.txt";
        file = "${secrets}/openai-key.age";
        mode = "600";
      };
      "anthropic-api-key" = {
        symlink = true;
        path = "/Users/${user}/.config/anthropic/api-key";
        file = "${secrets}/anthropic-api-key.age";
        mode = "600";
      };
    };
  };
}
