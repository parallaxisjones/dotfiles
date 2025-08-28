{ config, pkgs, lib, ... }:
{
  # Minimal, headless-friendly profile for stability during transition.
  services.xserver.enable = false;
  services.printing.enable = false;
  programs.steam.enable = lib.mkDefault false;
  hardware.pulseaudio.enable = false;
  services.pipewire.enable = false;
  services.gvfs.enable = false;
  services.tumbler.enable = false;

  # Basic server utilities (append without self-reference)
  environment.systemPackages = lib.mkAfter [
    pkgs.htop
    pkgs.iotop
    pkgs.nmon
  ];
}


