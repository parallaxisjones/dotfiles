{ pkgs }:

with pkgs;
let shared-packages = import ../shared/packages.nix { inherit pkgs; }; in
shared-packages ++ [
  awscli2
  awscurl
  fswatch
  dockutil
  devenv
  pnpm
  docker-compose
  syncthing
]
