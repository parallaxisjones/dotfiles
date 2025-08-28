{ config, pkgs, lib, ... }:
{
  # Minimal, headless-friendly profile for stability during transition.
  services = {
    xserver.enable = false;
    printing.enable = false;
    pipewire.enable = false;
    gvfs.enable = false;
    tumbler.enable = false;
  };
  programs.steam.enable = lib.mkDefault false;
  hardware.pulseaudio.enable = false;

  # Basic server utilities (append without self-reference)
  environment.systemPackages = lib.mkAfter [
    pkgs.htop
    pkgs.iotop
    pkgs.nmon
  ];
}


