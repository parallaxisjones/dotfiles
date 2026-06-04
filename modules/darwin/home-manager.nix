{ config, pkgs, lib, agenix, fenix ? null, inputs, ... }:

let
  user = "pjones";
  inherit (inputs) secrets;
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
    brews = [ "rtk" "bastionzero/tap/zli" "nvm" ];
    casks = pkgs.callPackage ./casks.nix { };
  };

  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = { inherit inputs secrets; };
    sharedModules = [ inputs.agent-skills-nix.homeManagerModules.default ];
    users.${user} = { pkgs, config, lib, ... }:
      let
        # Get system from pkgs
        inherit (pkgs) system;
        # Get Rust toolchain from fenix if available
        rustToolchain =
          if fenix != null then
          # `stable` = latest stable release as of the locked fenix input.
          # Run `nix flake update fenix` then build-switch to move to a newer stable.
            fenix.packages.${system}.stable.withComponents [
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
            # Configure Rust/Cargo for macOS: use the system Apple clang for C deps
            # (aws-lc-sys etc.) so plain-terminal builds work, plus the dsco registry.
            # Note: This will overwrite any existing .cargo/config.toml
            {
              ".cargo/config.toml" = {
                text = ''
                  # Cargo registries
                  [registries.dsco-cargo]
                  index = "https://dl.cloudsmith.io/HrWnzYbvPYsqmoOd/dsco/cargo/cargo/index.git"

                  # macOS: compile C dependencies (e.g. aws-lc-sys) and link with the
                  # system Apple clang rather than the nix clang-wrapper.
                  #
                  # The nix clang-wrapper lacks `dsymutil` and mishandles the
                  # `arm64-apple-macosx` target triple that aws-lc-sys passes, so its
                  # compiler-feature probes abort with "tool 'dsymutil' not found".
                  # /usr/bin/clang (Command Line Tools) has dsymutil and the right SDK,
                  # so plain-terminal `cargo build`/`cargo test` succeed cleanly.
                  #
                  # Scoped here (not as global $CC) so only cargo builds are affected.
                  [env]
                  CC_aarch64_apple_darwin = "/usr/bin/clang"
                  CXX_aarch64_apple_darwin = "/usr/bin/clang++"
                  CC_x86_64_apple_darwin = "/usr/bin/clang"
                  CXX_x86_64_apple_darwin = "/usr/bin/clang++"

                  # Use the system linker too, so the final link uses the macOS SDK's
                  # libiconv/libc++ instead of nix dylibs (avoids "built for newer macOS
                  # version" linker warnings). No -liconv/-lc++ rustflags needed.
                  [target.aarch64-apple-darwin]
                  linker = "/usr/bin/clang"

                  [target.x86_64-apple-darwin]
                  linker = "/usr/bin/clang"

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
          ./secrets.nix
        ];

        # ─────────────────────────────────────────────────────────────────────────
        programs = lib.mkMerge [
          (import ../shared/home-manager.nix { inherit config pkgs lib; })
          {
            nvm = {
              enable = true;
              enableZshIntegration = true;
            };
            agent-skills = {
              enable = true;
              sources.mine = {
                input = "my-skills";
                subdir = "skills";
                filter.nameRegex = "^(engineering|misc|personal|productivity)/.*";
              };
              skills.enableAll = true;
              targets.claude.enable = true;
            };
          }
        ];
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
