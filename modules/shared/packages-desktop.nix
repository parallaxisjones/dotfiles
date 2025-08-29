{ pkgs, ... }:

with pkgs; [
  # Desktop/dev-only additions layered on top of base shared packages
  alacritty
  gleam
  elixir
  erlang
  zig
  docker-compose
  _1password-cli
  flyctl
  google-cloud-sdk
  go
  gopls
  ngrok
  ssm-session-manager-plugin
  terraform
  terraform-ls
  tflint
  emacs-all-the-icons-fonts
  imagemagick
  dejavu_fonts
  ffmpeg
  nodePackages.live-server
  nodePackages.nodemon
  nodePackages.prettier
  nodejs
  jetbrains.phpstorm
  slack
]


