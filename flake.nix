{
  description = "General Purpose Configuration for macOS and NixOS";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    agenix.url = "github:ryantm/agenix";
    home-manager.url = "github:nix-community/home-manager";
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # mcp-hub removed
    secrets = {
      url = "git+ssh://git@github.com/parallaxisjones/nix-secrets.git";
      flake = false;
    };
  };
  outputs = { self, darwin, nix-homebrew, homebrew-bundle, homebrew-core, homebrew-cask, home-manager, nixpkgs, disko, fenix, ... } @inputs:
    let
      user = "parallaxis";
      workUser = "pjones";
      linuxSystems = [ "x86_64-linux" "aarch64-linux" ];
      darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs (linuxSystems ++ darwinSystems) f;
      devShell = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          # Get fenix toolchain with all components including clippy
          rustToolchain = fenix.packages.${system}.complete.withComponents [
            "cargo"
            "clippy"
            "rustc"
            "rustfmt"
            "rust-analyzer"
            "rust-src"
          ];
          # Darwin-specific build inputs for Rust
          darwinBuildInputs = with pkgs; nixpkgs.lib.optionals (nixpkgs.lib.strings.hasSuffix "-darwin" system) [
            libiconv
          ];
        in
        {
          default = with pkgs; mkShell {
            nativeBuildInputs = with pkgs; [ bashInteractive git age age-plugin-yubikey ];
            shellHook = with pkgs; ''
              export EDITOR=nvim
            '';
          };
          rust = with pkgs; mkShell {
            name = "rust-shell";
            buildInputs = [
              rustToolchain
              pkg-config
              openssl
            ] ++ darwinBuildInputs;
            shellHook =
              let
                iconvLib = "${pkgs.libiconv}/lib";
                isDarwin = nixpkgs.lib.strings.hasSuffix "-darwin" system;
                isAarch64Darwin = system == "aarch64-darwin";
                # For aarch64-darwin, use -arch arm64 flag for proper compilation
                # For x86_64-darwin, use standard flags
                cflagsValue = if isAarch64Darwin then "-arch arm64" else "";
                darwinEnv =
                  if isDarwin then ''
                    # libiconv linking
                    export LIBRARY_PATH="${iconvLib}''${LIBRARY_PATH:+:$LIBRARY_PATH}"
                    export LDFLAGS="-L${iconvLib}''${LDFLAGS:+ $LDFLAGS}"
                
                    # Compiler flags
                    # Use clang (not gcc) for proper Apple Silicon support
                    export CC="${pkgs.clang}/bin/clang"
                    export CXX="${pkgs.clang}/bin/clang++"
                    ${if cflagsValue != "" then ''
                      # Enable ARM64 crypto extensions for aws-lc-sys
                      # -mcpu=apple-m1 enables NEON and crypto extensions on Apple Silicon
                      # This ensures aws-lc-sys detects the required CPU features
                      export CFLAGS="${cflagsValue} -mcpu=apple-m1''${CFLAGS:+ $CFLAGS}"
                      export CXXFLAGS="${cflagsValue} -mcpu=apple-m1''${CXXFLAGS:+ $CXXFLAGS}"
                    '' else ""}
                
                    # Fix for aws-lc-sys: ensure NEON and crypto extensions are available
                    export RUSTFLAGS="-C link-arg=-L${iconvLib} -C link-arg=-liconv''${RUSTFLAGS:+ $RUSTFLAGS}"
                  '' else "";
                linuxEnv =
                  if nixpkgs.lib.strings.hasSuffix "-linux" system then ''
                    export LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib''${LIBRARY_PATH:+:$LIBRARY_PATH}"
                  '' else "";
              in
              ''
                echo "Entering Rust development shell"
                # Set up Rust environment
                export CARGO_HOME="$HOME/.cargo"
                export RUSTUP_HOME="$HOME/.rustup"
              
                ${darwinEnv}
                ${linuxEnv}
              
                # Verify Rust toolchain
                rustc --version
                cargo --version
                cargo clippy --version || echo "Note: clippy should be available"
              '';
          };
          gleam = with pkgs; mkShell {
            name = "gleam-shell";
            buildInputs = [ erlang elixir gleam ];
            shellHook = ''
              echo "Entering Gleam shell"
            '';
          };
          elixir = with pkgs; mkShell {
            name = "elixir-shell";
            buildInputs = [ erlang elixir ];
            shellHook = ''
              echo "Entering Elixir shell"
            '';
          };
          zig = with pkgs; mkShell {
            name = "zig-shell";
            buildInputs = [ zig ];
            shellHook = ''
              echo "Entering Zig shell"
            '';
          };
        };
      mkApp = scriptName: system: {
        type = "app";
        program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin scriptName ''
          #!/usr/bin/env bash
          PATH=${nixpkgs.legacyPackages.${system}.git}/bin:$PATH
          echo \"Running ${scriptName} for ${system}\"
          exec bash ${self}/apps/${system}/${scriptName}
        '')}/bin/${scriptName}";
      };
      mkLinuxApps = system: {
        "apply" = mkApp "apply" system;
        "build-switch" = mkApp "build-switch" system;
        "build-dry" = mkApp "build-dry" system;
        "copy-keys" = mkApp "copy-keys" system;
        "create-keys" = mkApp "create-keys" system;
        "check-keys" = mkApp "check-keys" system;
        "install" = mkApp "install" system;
        "install-with-secrets" = mkApp "install-with-secrets" system;
      };
      mkDarwinApps = system: {
        "apply" = mkApp "apply" system;
        "build" = mkApp "build" system;
        "build-switch" = mkApp "build-switch" system;
        "build-dry" = mkApp "build-dry" system;
        "copy-keys" = mkApp "copy-keys" system;
        "create-keys" = mkApp "create-keys" system;
        "check-keys" = mkApp "check-keys" system;
        "rollback" = mkApp "rollback" system;
      };
      overlays =
        let
          overlayPath = ./overlays;
          overlayFiles = builtins.attrNames (builtins.readDir overlayPath);
          nixFiles = builtins.filter (f: builtins.match ".*\\.nix" f != null) overlayFiles;
          toPath = f: overlayPath + ("/" + f);
        in
        map import (map toPath nixFiles);
    in
    {
      devShells = forAllSystems devShell;
      apps = nixpkgs.lib.genAttrs linuxSystems mkLinuxApps // nixpkgs.lib.genAttrs darwinSystems mkDarwinApps;
      darwinConfigurations = nixpkgs.lib.genAttrs darwinSystems (system:
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = inputs // { user = workUser; inherit fenix; };
          modules = [
            { nixpkgs.overlays = [ fenix.overlays.default ] ++ overlays; }
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                user = workUser;
                enable = true;
                taps = {
                  "homebrew/homebrew-core" = homebrew-core;
                  "homebrew/homebrew-cask" = homebrew-cask;
                  "homebrew/homebrew-bundle" = homebrew-bundle;
                };
                mutableTaps = false;
                autoMigrate = true;
              };
            }
            # ./modules/shared/secrets.nix
            ./hosts/darwin/configuration.nix
          ];
        }
      );
      nixosConfigurations = (
        nixpkgs.lib.genAttrs linuxSystems (system:
          nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = inputs // { inherit user; secrets = inputs.secrets or null; };
            modules = [
              disko.nixosModules.disko
              home-manager.nixosModules.home-manager
              ({ config, ... }: {
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  backupFileExtension = "backup";
                  extraSpecialArgs = { isDesktop = config.services.xserver.enable or false; };
                  users.${user} = import ./modules/nixos/home-manager.nix;
                };
              })
              (_: {
                # Keep overlays available but avoid installing large Rust toolchains
                # by default on NixOS hosts to reduce build time and memory pressure.
                nixpkgs.overlays = [ fenix.overlays.default ] ++ overlays;
              })
              # ./modules/shared/secrets.nix
              ./hosts/nixos/configuration.nix
            ];
          }
        )
      ) // {
        helios64 = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = inputs // { inherit user; secrets = inputs.secrets or null; };
          modules = [
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            ({ config, ... }: {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = { isDesktop = config.services.xserver.enable or false; };
                users.${user} = import ./modules/nixos/home-manager.nix;
              };
            })
            (_: {
              nixpkgs.overlays = [ fenix.overlays.default ] ++ overlays;
            })
            ./hosts/nixos/helios64.nix
          ];
        };
      };
    };
}
