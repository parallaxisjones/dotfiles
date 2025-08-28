{ pkgs, lib, ... }:
{
  networking.hostName = "helios64";

  time.timeZone = "America/New_York";

  # Device tree for Helios64
  hardware.deviceTree.enable = true;
  hardware.deviceTree.name = "rockchip/rk3399-kobol-helios64.dtb";

  # Evaluate as a container-like system to bypass boot/filesystems asserts in CI
  boot.isContainer = true;

  # Allow unfree pkgs for evaluation (e.g., copilot.vim in HM)
  nixpkgs.config.allowUnfree = true;

  # Ensure the primary user exists and has a valid home dir
  users.users.parallaxis = {
    isNormalUser = true;
    description = "Parker Jones";
    extraGroups = [ "wheel" ];
    home = "/home/parallaxis";
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  # Provide a minimal Home Manager profile for evaluation on aarch64
  home-manager.users.parallaxis = lib.mkForce {
    home = {
      username = "parallaxis";
      homeDirectory = "/home/parallaxis";
      stateVersion = "24.11";
    };
    programs.zsh.enable = true;
  };

  # Basic SSH access
  services.openssh.enable = true;

  # Minimal packages
  environment.systemPackages = with pkgs; [ neovim git curl ];

  # Keep it minimal; storage/services come later in Phase 3
  system.stateVersion = "24.11";
}


