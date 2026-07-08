# Change: Add Neogit + Diffview to Neovim with leader bindings

- Date: 2026-07-08
- PR / commit: (pending)
- Related ADRs: none

## What changed

- Added two Lazy.nvim plugin specs to `modules/shared/config/nvim/lua/custom/plugins.lua`:
  - `sindrets/diffview.nvim` — diff and file-history viewer, lazy-loaded on its
    `Diffview*` commands, with `nvim-lua/plenary.nvim` as a dependency.
  - `NeogitOrg/neogit` — git staging/commit UI, lazy-loaded on the `Neogit`
    command, wired to `plenary`, `diffview.nvim` (richer diffs), and
    `nvim-telescope/telescope.nvim` (telescope-backed pickers).
- Added three normal-mode leader bindings to
  `modules/shared/config/nvim/lua/custom/mappings.lua` (`M.general.n`):
  - `<leader>gd` → `:DiffviewOpen`
  - `<leader>gh` → `:DiffviewFileHistory %` (history for the current file)
  - `<leader>gs` → `:Neogit`

## What caused it (trigger / root cause)

User request: wanted a dedicated git-review workflow inside Neovim (Neogit for
staging/committing, Diffview for browsing diffs and file history) with the
plugin authors' recommended leader bindings, provided they didn't clash with
existing mappings.

## How it was done

- The nvim config is an NvChad (Lazy.nvim) setup vendored as lua files under
  `modules/shared/config/nvim/`. `~/.config/nvim` is a recursive Nix symlink
  (`modules/shared/files.nix`) into the read-only store, so the plugins are
  managed by Lazy.nvim (not Nix) and install on next nvim startup after a
  rebuild.
- Both plugins are declared with `cmd = { ... }` so they cost nothing at
  startup; the leader mappings invoke those commands, which triggers the
  lazy-load on first use.
- Bindings were placed in `custom/mappings.lua` (NvChad table format) rather
  than plugin-local `keys`, so they surface in the NvChad cheatsheet /
  which-key alongside the other leader mappings.

### Conflict check

Requested bindings were verified against all existing `<leader>g*` mappings.
Only `<leader>gt` (Telescope git_status) and `<leader>gb` (gitsigns blame line)
were in use; `<leader>gd`, `<leader>gh`, and `<leader>gs` were all free.

## Verification

- `nvim --headless -c "lua assert(loadfile('lua/custom/plugins.lua'))" -c q`
  and the same for `lua/custom/mappings.lua` — both parse without error.
- Full activation is pending a `darwin-rebuild switch` (to update the symlinked
  store copy) followed by an nvim restart, which lets Lazy.nvim install the two
  plugins. After that, `<leader>gd/gh/gs` should open Diffview / file history /
  Neogit respectively.

## Links

- CHANGELOG entry: `CHANGELOG.md` → `[Unreleased]`
- Source files: `modules/shared/config/nvim/lua/custom/plugins.lua`,
  `modules/shared/config/nvim/lua/custom/mappings.lua`
- Upstream: https://github.com/NeogitOrg/neogit,
  https://github.com/sindrets/diffview.nvim
