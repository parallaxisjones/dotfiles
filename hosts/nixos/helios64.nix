{ pkgs, ... }:
{
  networking.hostName = "helios64";

  time.timeZone = "America/New_York";

  # Device tree for Helios64
  hardware.deviceTree.enable = true;
  hardware.deviceTree.name = "rockchip/rk3399-kobol-helios64.dtb";

  # Basic SSH access
  services.openssh.enable = true;

  # Minimal packages
  environment.systemPackages = with pkgs; [
    neovim
    git
    curl
  ];

  # Keep it minimal; storage/services come later in Phase 3
  system.stateVersion = "24.11";
}


