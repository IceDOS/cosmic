# AGENTS.md — IceDOS **cosmic**

> Utilizes the **IceDOS** framework. The full bible — module structure, config flow,
> the `icedos rebuild --build` test loop, `validate.*` helpers, dep loading — lives in
> **core**: <https://github.com/IceDOS/core/blob/main/AGENTS.md> — this file only
> covers what is specific to **cosmic**.

## Non-negotiable rules (full detail in core)
- Build/test only via the `icedos` CLI — **never `sudo nixos-rebuild`**.
- **Never** `git commit/stash/reset/pull` — the user manages git.
- Every option uses a `validate.*`/`mk*Option` helper; **no untyped options**.
- A module's `config.toml` defaults must mirror its `icedos.nix` defaults.
- Format with `icedos nixf .` after editing any `.nix`.
- If a repo or the config root you need isn't checked out locally, **ask the user** for
  its path or permission to `git clone` it — don't guess or clone unprompted.

## Purpose
The COSMIC desktop environment for IceDOS, under the `icedos.desktop.cosmic` namespace.

## Layout (DE repo)
- Modules live under `modules/<group>/…/icedos.nix` (nested groups):
  `desktop/{appearance,dock,panel,wallpaper,window-management,workspaces}`,
  `accessibility/{magnifier,mono-sound}`, `applications/{cosmic-files,x11}`,
  `brightness-control`, `input`, `sound`, `power`, `time`, `patches`.
- `lib.nix` is a repo-local helper. **No root `icedos.nix`.**
- `flake.nix` scans the whole repo: `icedosLib.scanModules { path = ./.; filename = "icedos.nix"; }`.

## Module shape here
Standard IceDOS module shape, grouped by area.

## Test a change to this repo
In the config root's `config.toml`, point this repo's `overrideUrl` at your local
checkout (`path:/abs/path/to/cosmic`), then `icedos rebuild --build` (no activation).

## Notable modules / gotchas
- **Per-user config nests under the shared desktop user submodule**, not a cosmic-owned
  `.users` tree: `modules/desktop/panel` contributes `cosmic` to `desktop.users`, so panel
  favorites live at `icedos.desktop.users.<name>.cosmic.panelFavorites` (materialised by
  `desktop/default`'s `genDefaults`). See core's *Per-user (`users`) options*.
- `patches/` carries local patches against upstream COSMIC (pop-os). On a COSMIC bump,
  check the upstream issue/PR trackers to see whether each local patch is still needed
  before keeping it (see core memory `reference_cosmic_patch_trackers`).
- DE/session changes need a `switch` + re-login to take effect — the **user's** call.
