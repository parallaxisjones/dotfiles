## Bootstrap and Key Management

This guide covers bootstrapping a new machine and managing keys for secrets, Git operations, and first-install flows.

### Goals

- **Single source of truth**: secrets tracked in a dedicated `secrets` flake input.
- **Safe first install**: use installer apps that stage this repo and optionally fetch secrets.
- **Key hygiene**: clear generation, rotation, and recovery procedures.

### Key types used here

- **SSH keys (host/user)**: for GitHub access, remote builders, and general SSH.
- **age identity**: used by [agenix](https://github.com/ryantm/agenix) to encrypt/decrypt secrets.
- (Optional) **GPG/signing**: for Git commit signing if desired.

### Directory conventions

- Repo-checked public keys (recommended):
  - `modules/shared/secrets/keys/<user-or-host>.pub`
  - Reference via `builtins.readFile` in Nix modules.
- Secrets repo (flake input `secrets`):
  - Store `.age` files, e.g. `github-ssh-key.age`, `openai-key.age`.
  - Keep private; provision read-only deploy keys.

## Generate keys

### SSH (user)

```bash
ssh-keygen -t ed25519 -C "<you>@example" -f ~/.ssh/id_github
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_github
pbcopy < ~/.ssh/id_github.pub  # macOS copy; Linux: xclip -sel clip
```

- Add the public key to GitHub (User settings → SSH and GPG keys).
- Optionally add a separate deploy key (read-only) on the `nix-secrets` repo.

### age identity (for agenix)

Option A — age native key (recommended):

```bash
mkdir -p ~/.config/age
age-keygen -o ~/.config/age/keys.txt
```

Set `age.identityPaths` (NixOS/Darwin) to include this file.

Option B — reuse SSH ed25519 via age-plugin-ssh:

```bash
nix shell nixpkgs#age-plugin-ssh -c true   # ensure plugin available
```

Ensure `age-plugin-ssh` is present on machines that decrypt.

## Wire keys into Nix modules

### Reference recipient public keys

Example `modules/shared/secrets.nix` using agenix.lib.secrets:

```nix
{ agenix, ... }:
let
  pjonesPublicKey     = builtins.readFile ./secrets/keys/pjones.pub;
  parallaxisPublicKey = builtins.readFile ./secrets/keys/parallaxis.pub;
  systems = [ "x86_64-linux" "aarch64-darwin" ];
in
{
  age.secrets = agenix.lib.secrets rec {
    inherit systems;
    users = {
      pjones     = { publicKeys = [ pjonesPublicKey ]; };
      parallaxis = { publicKeys = [ parallaxisPublicKey ]; };
    };
    ageFiles = {
      "openai-key.age" = { publicKeys = [ users.pjones users.parallaxis ]; };
    };
  };
}
```

### Use a `secrets` flake input for encrypted files

`flake.nix` already includes a `secrets` input. Prefer SSH:

```
git+ssh://git@github.com/parallaxisjones/nix-secrets.git
```

In a module consuming secrets (example NixOS):

```nix
{ secrets, user, ... }:
{
  age = {
    identityPaths = [ "/home/${user}/.ssh/id_ed25519" ];
    secrets = {
      "github-ssh-key" = {
        path = "/home/${user}/.ssh/id_github";
        file = "${secrets}/github-ssh-key.age";
        owner = user; group = "wheel"; mode = "600";
      };
    };
  };
}
```

Darwin is analogous via nix-darwin/Home Manager.

## Managing secrets with agenix

Create or edit an encrypted secret (it will derive recipients from your agenix config):

```bash
agenix -e path/to/secret.age
```

Decrypt to verify (test only):

```bash
agenix -d path/to/secret.age | head -n 5
```

Common files in `nix-secrets`:

- `github-ssh-key.age` (private key material for GitHub operations)
- `github-signing-key.age` (PGP or SSH signing as desired)
- Application/API keys (e.g., `openai-key.age`)

## First install and secrets access

The installer apps (`nix run .#install-with-secrets`) stage this repo to `/mnt/etc/nixos` and run `disko` + `nixos-install`.

Private `secrets` access options during install:

- **SSH agent forwarding (preferred)**:
  - Ensure your SSH agent has the deploy/user key: `ssh-add -l`.
  - Use commands that propagate `SSH_AUTH_SOCK` to root, for example:
    ```bash
    sudo SSH_AUTH_SOCK=$SSH_AUTH_SOCK nixos-install --flake /mnt/etc/nixos#<system>
    ```
- **HTTPS fallback**:
  - Temporarily point the `secrets` input at an HTTPS URL with a token or use a public read-only artifact.
- **Local override** (air-gapped or lab testing):
  - `nix build --override-input secrets path:/path/to/local/secrets` or vendor a snapshot.

Tip: the installer scripts add GitHub to root’s known_hosts; you still need credentials for private fetches.

## Rotation and recovery

- **Rotate SSH keys**:
  - Generate new key, update GitHub and deploy keys.
  - Update `identityPaths` if paths change.
- **Rotate age recipients**:
  - Update public keys in `modules/shared/secrets/keys/` and agenix config.
  - Re-encrypt secrets: `agenix -e` on each file.
- **Lost key scenario**:
  - If a private key is lost, remove it from recipients, add a new key, and re-encrypt all affected `.age` files.

## Validation checklist

- `nix flake show` — inputs resolve.
- `nix build .#nixosConfigurations.<host>.config.system.build.toplevel` — builds locally.
- From macOS, observe remote builder activity when building Linux targets.
- `agenix -d <file.age>` works on intended machines only.

## Quick bootstrap summary

- Generate SSH and age keys; add recipients and deploy keys.
- Ensure `secrets` flake input is reachable (SSH recommended).
- For first install: run installer app, forward SSH agent to root if using private inputs.
- Keep secrets small, rotated, and documented; prefer per-host/user scoping.


