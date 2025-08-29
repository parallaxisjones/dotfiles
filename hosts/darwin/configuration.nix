{ config, pkgs, home-manager, lib, ... }:

let
  # Pull in nix-darwin’s Home Manager engine (provided by the home-manager flake input)
  darwinHM = home-manager.darwinModules.home-manager;
in
{
  # 1) Import the Home Manager engine into nix-darwin
  # 2) Your per-user Home Manager config from the flake
  # 3) Any shared HM definitions
  imports = [
    darwinHM
    ../../modules/darwin/home-manager.nix
    ../../modules/shared
  ];
  nix = {
    package = pkgs.nix;
    settings = {
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://parallaxisjones.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "parallaxisjones.cachix.org-1:A85H34pyLFZq2A3A0hB32/8CXuFNS3e4Js+KlKlP43Q="
      ];

      trusted-users = [
        "root"
        "pjones"
      ];

      # Remote builder configuration (controller side)
      # - Use a conservative single-job builder entry to avoid OOM on the server
      # - Force local max-jobs to 0 to offload builds
      builders-use-substitutes = true;
      max-jobs = 0;
      builders = lib.mkForce "@/etc/nix/machines";
    };
    gc = {
      automatic = true;
      interval = { Weekday = 0; Hour = 2; Minute = 0; };
      options = "--delete-older-than 30d";
    };
    # Turn this on to make command line easier
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
  services.dnsmasq = {
    enable = true;
    bind = "127.0.0.1";
    addresses = {
      "dev.dsco.io" = "127.0.0.1";
      "dev-core.dsco.io" = "127.0.0.1";
      "dev-core-ftp.dsco.io" = "127.0.0.1";
      "dev-core-static.dsco.io" = "127.0.0.1";
      "dev-core-images.dsco.io" = "127.0.0.1";
    };
    # settings = {
    #   "bind-interfaces" = true;
    #   # add more dnsmasq configs here if needed
    # };
  };
  # Enable Home Manager
  # programs.home-manager.enable = true;

  # System-wide packages to install in /usr/local
  environment.systemPackages = with pkgs; [
    vim
    rage
    # mcp-hub removed
  ];

  # Ensure ~/.ssh/known_hosts is a writable regular file, not a symlink, to avoid SSH known_hosts update issues
  system.activationScripts.fixKnownHosts = {
    deps = [ ];
    text = ''
      USER_HOME="/Users/pjones"
      KNOWN_HOSTS="$USER_HOME/.ssh/known_hosts"
      mkdir -p "$USER_HOME/.ssh"
      if [ -L "$KNOWN_HOSTS" ]; then
        echo "Replacing symlinked known_hosts with a regular file"
        rm -f "$KNOWN_HOSTS"
        touch "$KNOWN_HOSTS"
        chown pjones:staff "$KNOWN_HOSTS"
        chmod 600 "$KNOWN_HOSTS"
      elif [ ! -e "$KNOWN_HOSTS" ]; then
        touch "$KNOWN_HOSTS"
        chown pjones:staff "$KNOWN_HOSTS"
        chmod 600 "$KNOWN_HOSTS"
      fi
    '';
  };

  # nix-darwin manages nix-daemon automatically when nix is enabled

  # Provide the remote builders file referenced above
  environment.etc."nix/machines".text = ''
    # host                         systems                               ssh-key  max-jobs speed  features
    ssh-ng://parallaxis@nixos      x86_64-linux,i686-linux,aarch64-linux  -        4        1
  '';
  # services.karabiner-elements.enable = true;

  # Enable experimental flakes support
  nix.settings.experimental-features = "nix-command flakes";

  # Use Zsh as the default shell
  programs.zsh.enable = true;

  # Darwin-specific settings
  system = {
    stateVersion = 4;
    primaryUser = "pjones";
    defaults = {
      dock = {
        autohide = true;
        orientation = "bottom";
        show-process-indicators = false;
        show-recents = false;
        static-only = true;
      };
      finder = {
        AppleShowAllExtensions = true;
        ShowPathbar = true;
        FXEnableExtensionChangeWarning = false;
      };
      NSGlobalDomain = {
        AppleKeyboardUIMode = 3;
        "com.apple.keyboard.fnState" = true;
      };
    };
  };
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  # Define the macOS user
  users.users.pjones = {
    # isNormalUser = true;
    home = "/Users/pjones";
    shell = pkgs.zsh;
  };

  # macOS defaults are defined above in system.defaults
}
