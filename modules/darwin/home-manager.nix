{ config, pkgs, lib, agenix, fenix ? null, ... }:

let
  user = "pjones";
  # myEmacsLauncher was unused; removed to satisfy deadnix
  sharedFiles = import ../shared/files.nix { inherit config pkgs lib; };
  additionalFiles = import ./files.nix { inherit user config pkgs; };
in
{
  imports = [
    # agenix.homeManagerModules.default
    ./dock
  ];

  users.users.${user} = {
    name = "${user}";
    home = "/Users/${user}";
    isHidden = false;
    # shell    = pkgs.zsh;
  };

  homebrew = {
    enable = true;
    casks = pkgs.callPackage ./casks.nix { };
  };

  home-manager = {
    useGlobalPkgs = true;
    users.${user} = { pkgs, config, lib, ... }:
      let
        # Get system from pkgs
        inherit (pkgs) system;
        # Get Rust toolchain from fenix if available
        rustToolchain =
          if fenix != null then
            fenix.packages.${system}.complete.withComponents [
              "cargo"
              "clippy"
              "rustc"
              "rustfmt"
              "rust-analyzer"
              "rust-src"
            ]
          else null;
        basePackages = pkgs.callPackage ./packages.nix { };
        rustPackages = if rustToolchain != null then [ rustToolchain ] else [ ];
      in
      {
        home = {
          enableNixpkgsReleaseCheck = false;
          packages = basePackages ++ rustPackages;
          file = lib.mkMerge [
            sharedFiles
            additionalFiles
            # Ensure ~/.ssh exists and provide a keep file so the directory is created
            {
              ".ssh/.keep".text = "";
            }
            # Configure Rust/Cargo to find libiconv on macOS and fix aws-lc-sys issues
            # This fixes "library not found for -liconv" errors and aws-lc-sys compilation
            # Includes known registry config and adds libiconv linking
            # Note: This will overwrite any existing .cargo/config.toml
            {
              ".cargo/config.toml" = {
                text = ''
                  # Cargo registries
                  [registries.dsco-cargo]
                  index = "https://dl.cloudsmith.io/HrWnzYbvPYsqmoOd/dsco/cargo/cargo/index.git"

                  # macOS libiconv linking configuration
                  # This fixes "library not found for -liconv" errors when building on macOS
                  [target.aarch64-apple-darwin]
                  rustflags = [
                    "-C", "link-arg=-L${pkgs.libiconv}/lib",
                    "-C", "link-arg=-liconv",
                    "-C", "target-cpu=native"
                  ]

                  [target.x86_64-apple-darwin]
                  rustflags = [
                    "-C", "link-arg=-L${pkgs.libiconv}/lib",
                    "-C", "link-arg=-liconv"
                  ]

                  # Linux targets (if needed)
                  [target.x86_64-unknown-linux-gnu]
                  rustflags = []

                  [target.aarch64-unknown-linux-gnu]
                  rustflags = []
                '';
                # Force overwrite to ensure rustflags are always present
                force = true;
              };
            }
            # ──────────────────────────────────────────────────────────────────────
            # 1) Ensure ~/.cache/nvim/avante/clipboard exists
            {
              ".cache/nvim/avante/clipboard/.placeholder".text = "";
            }

            # 2) Ensure ~/.local/share/nvim/avante/clipboard exists
            {
              ".local/share/nvim/avante/clipboard/.placeholder".text = "";
            }

            # 3) Ensure ~/.local/state/nvim/avante exists (if Avante ever writes there)
            {
              ".local/state/nvim/avante/.placeholder".text = "";
            }

            # 4) You already want ~/.local/share/nvim/lazy for Lazy.nvim
            {
              ".local/share/nvim/lazy/.placeholder".text = "";
            }

            # 5) And ~/.local/state/nvim (for Lazy’s lockfile)
            {
              ".local/state/nvim/.placeholder".text = "";
            }
          ];
          stateVersion = "23.11";
        };
        imports = [
          agenix.homeManagerModules.default
          # ./secrets.nix 
        ];
        # ─────────────────────────────────────────────────────────────────────────
        programs = { } // import ../shared/home-manager.nix { inherit config pkgs lib; };
        manual.manpages.enable = false;

        # Ensure a writable known_hosts exists for the user (not a symlink)
        home.activation.ensureKnownHosts = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          mkdir -p "$HOME/.ssh"
          if [ ! -e "$HOME/.ssh/known_hosts" ]; then
            touch "$HOME/.ssh/known_hosts"
            chmod 600 "$HOME/.ssh/known_hosts"
          fi
        '';
      };
  };

  local.dock = {
    enable = true;
    username = user;
    entries = [ ];
  };
}
