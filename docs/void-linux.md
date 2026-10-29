# Singularity Desktop on Void Linux (glibc)

Void uses runit (no systemd), `xbps`, and `sudo` or `doas` (package
`opendoas`) instead of `run0`. `elogind` provides the
`org.freedesktop.login1` API, so session tracking, suspend and brightness work
unchanged. There is no `timedate1`/`hostnamed` on Void: date/timezone/hostname
settings fall back to `pkexec` helpers (the session polkit agent prompts, same
UX).

Supported: **Void glibc, x86_64**. Void musl x86_64 builds from source with
`-Dgestures=disabled`; the gesture runtime blobs and the prebuilt xbps package
stay glibc-only (see "musl" below).

## 1. Dependencies

```sh
sudo make prepare-deps
```

`prepare-deps.sh` now has a Void case; its package list was checked against a
Void glibc x86_64 repo index. Runtime extras: `dbus elogind greetd seatd
xdg-desktop-portal xdg-user-dirs desktop-file-utils hicolor-icon-theme
openntpd`, plus `qt6-base` if you want Qt apps to follow the theme.
`appmenu-gtk-module` is not packaged in Void: first-party apps are unaffected,
third-party GTK global menus just won't appear.

## 2. Build

```sh
git clone --recurse-submodules https://github.com/singularityos-lab/singularity-desktop
cd singularity-desktop
make
```

`make` builds the labwc fork, libinput, libfprint and (when the submodule is
present) sit before the desktop. Gestures are enabled by default and bootstrap
the MediaPipe/ONNX blobs (glibc x86_64). To build without them:

```sh
make GESTURES=disabled          # or: meson setup build -Dgestures=disabled
```

## 3. Deploy (sudo or doas, both fully supported)

From a source checkout:

```sh
make install            # sudo preferred, doas fallback, run0 only on systemd hosts
```

From the `singularity-desktop` xbps package (scripts in doc dir, no build
tree — integration-only mode is automatic, no env vars needed):

```sh
sudo bash /usr/share/doc/singularity-desktop/deploy-to-host.sh
# doas-only systems:
doas bash /usr/share/doc/singularity-desktop/deploy-to-host.sh
```

NOTE: `doas VAR=x cmd` does not work (doas rejects the assignment, and
`sudo`'s `env_reset` strips it too). The scripts re-pass their own knobs
across re-escalation themselves — always invoke them plainly. Only if you
ever need an explicit prefix with doas, use `doas env VAR=x ...`.

The script detects non-systemd hosts automatically: it skips systemd units
(the portal/keyring activate over D-Bus; the polkit agent is started by the
session itself) and tells you which runit services to enable:

```sh
sudo ln -s /etc/sv/dbus /var/service/
sudo ln -s /etc/sv/elogind /var/service/
```

Prefix defaults to `/opt/local`; packagers can set `SINGULARITY_PREFIX=/usr`.

## 4. Greeter (greetd + runit)

```sh
sudo make install-greeter     # or: sudo bash scripts/install-greeter.sh
```

On runit this enables the `greetd` service and removes the `agetty-tty1`
service so greetd owns tty1. Reboot and log in.

## 5. Verification status

Checked in containers from `ghcr.io/void-linux/void-glibc` (and
`void-musl`), 2026-10-29:

- glibc x86_64: `meson setup -Dapps=all -Dgestures=disabled` and
  `meson compile` finish with all 4538 targets built.
- labwc: both the `make` path (forced wlroots/scenefx wraps) and the xbps
  path (system wlroots 0.20 + patched scenefx) compile.
- musl x86_64: dependencies installed, `meson setup -Dapps=all
  -Dgestures=disabled` succeeds, and a full `meson compile` finishes
  (binary linked against `/lib/ld-musl-x86_64.so.1`).

## 6. Notes

- Date/time, timezone, NTP toggle and hostname work via `pkexec` fallback
  (needs `polkit` + admin auth: root password or a wheel user).
- NTP toggle manages the runit service (`/etc/sv/openntpd` from `openntpd`,
  `/etc/sv/ntpd` from `ntp`, or `/etc/sv/chronyd` from `chrony`).
- Fingerprint: `scripts/install-fprint.sh` installs the libfprint-TOD
  libraries, but the fprintd wiring is a systemd drop-in. On Void it skips the
  drop-in and prints the `LD_LIBRARY_PATH` to add to `/etc/sv/fprintd/run`.
- musl: the full tree builds with `-Dgestures=disabled` (tested on
  `void-musl`, both `meson setup` and `meson compile`). The base image may not
  ship `bash`: `xbps-install -S bash` before `make prepare-deps`.
  `libexecinfo-devel` is needed (the crash handler uses `backtrace`); the
  glibc repo does not ship it and `prepare-deps` skips it there. The gesture
  runtime blobs and the published xbps package stay glibc-only.
- Restart the session (logout/login) after every deploy so the new binary
  is picked up.
- Binary packages: the templates live in
  [SrDicov/z-packages](https://github.com/SrDicov/z-packages) and publish to
  [SrDicov/z-repo](https://github.com/SrDicov/z-repo). Install with:

  ```sh
  fp=02:16:21:e8:80:43:b6:16:d4:63:13:e5:5d:e1:32:b7
  sudo mkdir -p /var/db/xbps/keys /etc/xbps.d
  sudo curl -fsSL -o "/var/db/xbps/keys/$fp.plist" \
    "https://github.com/SrDicov/z-repo/releases/download/stable/${fp//:/.}.plist"
  echo "repository=https://github.com/SrDicov/z-repo/releases/download/stable" \
    | sudo tee /etc/xbps.d/10-zrepo.conf
  sudo xbps-install -S
  sudo xbps-install singularity-desktop
  ```

  `singularity-desktop` pulls `labwc-singularity`; do not install stock
  `labwc` alongside it.
