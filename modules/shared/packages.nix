{ pkgs, ... }:

let
  myPython = pkgs.python3.withPackages (ps: with ps; [
    slpp
    pip
    rich
    virtualenv
    black
  ]);
in

with pkgs; [
  # General packages for development and system management
  act
  # alacritty                   # desktop-dev profile only
  aspell
  aspellDicts.en
  bash-completion
  bat
  btop
  coreutils
  difftastic
  dust
  gcc
  git-filter-repo
  killall
  openssh
  pandoc
  sqlite
  wget
  zip
  uv
  # rust-analyzer, rustfmt - removed, now provided by fenix Rust toolchain in darwin home-manager
  libiconv
  htmlq
  # BEAM
  # gleam                       # desktop-dev
  # elixir                      # desktop-dev
  # erlang                      # desktop-dev
  # zig                         # desktop-dev
  # docker-compose              # desktop-dev
  # Encryption and security tools
  # _1password-cli              # desktop-dev
  age
  age-plugin-yubikey
  gnupg
  libfido2
  pkg-config
  # Cloud-related tools and SDKs
  # flyctl                      # desktop-dev
  # google-cloud-sdk            # desktop-dev
  # go                          # desktop-dev
  # gopls                       # desktop-dev
  # ngrok                       # desktop-dev
  # ssm-session-manager-plugin  # desktop-dev
  # terraform                   # desktop-dev
  # terraform-ls                # desktop-dev
  # tflint                      # desktop-dev
  neovim
  zellij
  zsh
  # Media-related packages
  # emacs-all-the-icons-fonts   # desktop-dev
  # imagemagick                 # desktop-dev
  # dejavu_fonts                # desktop-dev
  # ffmpeg                      # desktop-dev
  fd
  font-awesome
  glow
  hack-font
  jpegoptim
  meslo-lgs-nf
  noto-fonts
  noto-fonts-color-emoji
  pngquant
  cheat
  # cargo - removed, now provided by fenix Rust toolchain in darwin home-manager
  # Node.js development tools
  fzf
  # nodePackages.live-server    # desktop-dev
  # nodePackages.nodemon       # desktop-dev
  # nodePackages.prettier      # desktop-dev
  # nodejs                     # desktop-dev

  # Source code management, Git, GitHub tools
  gh

  tig
  # Text and terminal utilities
  htop
  hunspell
  iftop
  jetbrains-mono
  # jetbrains.phpstorm          # desktop-dev
  jq
  ripgrep
  # slack                       # desktop-dev
  tree
  tmux
  unrar
  unzip
  zsh-powerlevel10k
  eza
  myPython
  lua-language-server
  # aider removed due to heavy dependency closure and test flakiness
] ++ pkgs.lib.optionals (!pkgs.stdenv.isDarwin) [
  neofetch
]
