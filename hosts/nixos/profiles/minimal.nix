{ config, pkgs, ... }:
{
  # Minimal, headless-friendly profile for stability during transition.
  services.xserver.enable = false;
  services.printing.enable = false;
  programs.steam.enable = false;
  sound.enable = false;
  hardware.pulseaudio.enable = false;
  services.pipewire.enable = false;
  services.gvfs.enable = false;
  services.tumbler.enable = false;

  # Basic server utilities
  environment.systemPackages = (config.environment.systemPackages or []) ++ [
    pkgs.htop
    pkgs.iotop
    pkgs.nmon
  ];
}


