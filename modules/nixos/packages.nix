{ pkgs }:

with pkgs;
let
  shared-packages = import ../shared/packages.nix { inherit pkgs; };
  desktop-packages = import ./packages-desktop.nix { inherit pkgs; };
in
shared-packages ++ desktop-packages
