{ pkgs }:

with pkgs; [
  # Desktop packages specific to NixOS desktop role
  _1password-gui
  yubikey-agent
  keepassxc
  appimage-run
  gnumake
  cmake
  home-manager
  steam
  gimp
  vlc
  wineWowPackages.stable
  fontconfig
  font-manager
  brlaser
  bc
  galculator
  pavucontrol
  cider
  discord
  hexchat
  fractal
  direnv
  rofi
  rofi-calc
  qmk
  postgresql
  libusb1
  libtool
  flameshot
  simplescreenrecorder
  emote
  feh
  screenkey
  xclip
  xorg.xwininfo
  xorg.xrandr
  inotify-tools
  i3lock-fancy-rapid
  libnotify
  ledger-live-desktop
  playerctl
  pcmanfm
  xdg-utils
  yad
  xdotool
  zathura
  spotify
  immersed
]


