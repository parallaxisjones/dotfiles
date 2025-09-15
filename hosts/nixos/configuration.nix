# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # Role-based profiles (pick minimal for now)
      ./profiles/minimal.nix
      # ./profiles/desktop-gnome.nix
    ];

  # Bootloader.
  boot = {
    loader = {
      grub = {
        enable = true;
        device = "/dev/sda";
        useOSProber = true;
      };
    };
    # Disable cross-arch emulation to reduce build load while converting this
    # machine from desktop to server. Re-enable when needed.
    # binfmt.emulatedSystems = [ "aarch64-linux" ];
  };
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # Constrain parallelism to avoid OOM under load
    max-jobs = 2;
    cores = 2;
    # Keep features minimal for this host
    system-features = [ "kvm" ];
    extra-platforms = [ "aarch64-linux" "i686-linux" ];
  };
  networking = {
    hostName = "nixos"; # Define your hostname.
    networkmanager.enable = true;
    firewall.allowedTCPPorts = [ 24800 80 443 22 8081 ];
  };
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking moved into networking set

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system and GNOME Desktop Environment.
  # Keep GNOME desktop config commented while in minimal mode
  # services = {
  #   xserver = {
  #     enable = true;
  #     displayManager = {
  #       gdm.enable = true;
  #       autoLogin = {
  #         enable = true;
  #         user = "parallaxis";
  #       };
  #     };
  #     desktopManager.gnome.enable = true;
  #     xkb = {
  #       layout = "us";
  #       variant = "";
  #     };
  #   };
  #   printing.enable = true;
  # };

  # Configure keymap in X11 moved into services.xserver above

  # Sound stack (disabled in minimal profile)
  # hardware.pulseaudio.enable = false;
  # security.rtkit.enable = true;
  # services.pipewire = {
  #   enable = true;
  #   alsa.enable = true;
  #   alsa.support32Bit = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.parallaxis = {
    isNormalUser = true;
    description = "Parker Jones";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [
      #  thunderbird
    ];
  };
  # Steam (disabled in minimal profile)
  # programs.steam = {
  #   enable = true;
  #   remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
  #   dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  #   localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  # };
  # Enable automatic login moved into services set above

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Install firefox (desktop profile only)
  # programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    neovim
    git
    curl
    wget
    ripgrep
    fzf
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall moved into networking set above
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable Docker daemon and install docker
  virtualisation = {
    docker = {
      enable = true;
      logDriver = "json-file";
    };
  };

  # Add swap via zram and enable systemd-oomd for better stability under memory pressure
  zramSwap = {
    enable = true;
    memoryPercent = 50;
    priority = 100;
  };
  systemd.oomd.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
