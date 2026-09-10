# AGENTS.md

## Structure (meta-repo)

All code lives in `subprojects/` as git submodules — there is no root `src/`.
Shell: `subprojects/singularity-shell/src/`; toolkit: `subprojects/libsingularity`;
compositor: `subprojects/labwc` (fork, stay on its `singularity` branch);
apps/portals/session: `subprojects/singularity-*`.
After cloning or when a submodule looks empty/stale:
`git submodule update --init --recursive` (deploy fails without
`singularity-leafs` checked out).

## Build

```sh
meson setup build
meson compile -C build        # or: make compile
```

`make compile` does extra steps beyond bare meson: bootstraps the gesture runtime (downloads ML models), builds labwc separately, copies the GIR to `~/.local/share/gir-1.0/`, then compiles the main tree. Use `make compile` for a full working build.

Reconfigure after option changes: `make reconfigure` (handles both main build and labwc).

labwc has its own meson tree (`subprojects/labwc/build`): `make labwc`.
To build only libsingularity (has its own CI): `meson setup build && meson compile -C build` inside `subprojects/libsingularity/`.

## Deploy

```sh
make install          # or: bash scripts/deploy-to-host.sh
```

Requires root via `run0`. Installs to `/opt/local` by default. Inside a container it uses `host-spawn run0`. After deploying, restart the session (logout/login) for the new binary.

## Non-systemd hosts (Void/runit)

- Privilege escalation order in `scripts/`: `run0` (systemd only) -> `sudo` -> `doas`. `REAL_USER` comes from `ORIG_USER`/`SUDO_USER`/`DOAS_USER` — never pass it via env through sudo/doas (stripped).
- `deploy-to-host.sh` auto-detects via `has_systemd()` (`/run/systemd/system`): skips units/GDM drop-in on Void. Portal/keyring rely on D-Bus activation; polkit agent is started by the session script. Override prefix with `SINGULARITY_PREFIX=/usr` for packaging.
- No `timedate1`/`hostnamed` without systemd: `DateTimeManager` and hostname setting fall back to `pkexec` (`ln /etc/localtime`, `date -s` + `hwclock`, runit `ntpd`/`chronyd` toggle, `/etc/hostname` + `hostname`). Validate privileged inputs (zone list / hostname regex) before escalating.
- `elogind` provides `login1`, so session/brightness/suspend code needs no changes. User guide: `docs/void-linux.md`. Draft xbps templates: `packaging/xbps/`.

## Vala code style

- 4-space indent, no tabs. `PascalCase` classes, `snake_case` methods/fields.
- `_snake_case` for private fields.
- Never use `var` when the type isn't obvious from the RHS.
- Never use `Gtk.MessageDialog` — use inline `Gtk.InfoBar` or custom `SettingsPage`.
- Prefer `GLib.Subprocess.newv()` over `sh -c`.
- Timers: store `Timeout.add` / `Idle.add` ID, cancel in `dispose()`.
- One primary class per `.vala` file, named after the class (`ScreenshotPortal` -> `screenshot.vala`); no redundant suffixes (`_manager`, `_portal`).
- Settings UI: inline pages only (no modals); detail pages via `SettingsView.open_subpage()`, `PreferencesGroup` / `SwitchRow` / `ActionRow` pattern.

## Widget placement

- Reusable widgets: `subprojects/libsingularity/src/widgets/`
- Shell-only widgets (need GtkLayerShell): `subprojects/libsingularity/src/shell/`
- App-specific widgets: stay in the app's own directory.

## libsingularity-system

Headless system backends (D-Bus, sysfs, hardware) live in `subprojects/libsingularity/src/system/` (`libsingularity-system`). They must not `using Gtk`. Built with `-Dsystem=true` (default). Apps needing only the UI toolkit build with `-Dlibsingularity:system=false` (and `-Dlibsingularity:layer-shell=false` if no layer-shell widgets) to skip heavy deps.

## Testing

No automated test suite. Verify manually:
1. `ninja -C build` — zero errors and warnings.
2. `bash scripts/deploy-to-host.sh`, restart the shell.
3. Test your change manually.
4. Check for timer leaks (`dispose()` cleanup).

## Git conventions

- Branches: `master`, `feat/<name>`, `fix/<name>`, `refactor/<name>`.
- Commits: Conventional Commits — `feat:`, `fix:`, `chore:`, etc. Scope optional. No co-author trailers.
- PRs against `master`, one feature/fix per PR.
