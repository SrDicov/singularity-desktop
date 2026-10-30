# Singularity Desktop on Void Linux (glibc)

Void uses runit (no systemd), `xbps`, and `sudo` or `doas` (package
`opendoas`) instead of `run0`. `elogind` provides the
`org.freedesktop.login1` API, so session tracking, suspend and brightness work
unchanged. There is no `timedate1`/`hostnamed` on Void: date/timezone/hostname
settings fall back to `pkexec` helpers (the session polkit agent prompts, same
UX).

Supported: **Void glibc and musl, x86_64**. Both have published xbps packages;
the musl one is built with `-Dgestures=disabled` because the gesture runtime
blobs are glibc-only (see "musl" below).

## 1. Dependencies

```sh
sudo make prepare-deps
```

`prepare-deps.sh` now has a Void case; its package list was checked against a
Void glibc x86_64 repo index. The xbps package pulls the full runtime set:
`dbus elogind greetd xdg-desktop-portal xdg-desktop-portal-gtk xdg-user-dirs
xdg-utils desktop-file-utils hicolor-icon-theme pipewire wireplumber
NetworkManager upower bluez polkit fprintd cups shadow rtkit nftables
libheif-tools sane udisks2 e2fsprogs btrfs-progs xfsprogs exfatprogs
dosfstools ntfs-3g cryptsetup gvfs gvfs-smb gvfs-mtp gvfs-afc gvfs-gphoto2
flatpak appmenu-gtk3-module`. `NetworkManager` is capitalised in xbps.
`shadow` is required because `install-greeter.sh` creates the `greetd` user with
`useradd`. `fprintd` is D-Bus activated; the other daemons need their runit
service linked (`NetworkManager`, `bluetoothd`, `cupsd`, `rtkit`) unless you
already use an alternative (`dhcpcd`/`connman` for networking). For a source
install, add those packages yourself, plus one NTP daemon (`openntpd`, `ntp`
or `chrony`) and `qt6-base` if you want Qt apps to follow the theme. Void's
`appmenu-gtk3-module` installs `libappmenu-gtk-module.so`, the module the shell
looks for, so third-party GTK global menus work.

## 2. Build

```sh
git clone --recurse-submodules https://github.com/SrDicov/singularity-desktop
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

From the `singularity-desktop` xbps package there is nothing to deploy: the
package already ships the session entry, the portal/keyring D-Bus activation
files, the polkit agent and every asset under `/usr`. Do **not** run
`deploy-to-host.sh` after `xbps-install`; enable the runit services below, run
`install-greeter.sh` (section 4) and reboot. The script exists only for source
installs under `/opt/local`.

For a source install, the deploy script detects non-systemd hosts
automatically: it skips systemd units (the portal/keyring activate over D-Bus;
the polkit agent is started by the session itself) and tells you which runit
services to enable:

```sh
sudo ln -s /etc/sv/dbus /var/service/
sudo ln -s /etc/sv/elogind /var/service/
sudo ln -s /etc/sv/NetworkManager /var/service/   # or keep dhcpcd/connman
sudo ln -s /etc/sv/bluetoothd /var/service/
sudo ln -s /etc/sv/cupsd /var/service/
sudo ln -s /etc/sv/rtkit /var/service/
# fprintd is D-Bus activated; no service to enable.
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
`void-musl`), 2026-10-30:

- **Real package install (glibc)**: a clean `void-glibc` container with the
  z-repo key and repository configured upgraded from `0.1.0_4` to
  `singularity-desktop-0.1.0_14` / `labwc-singularity-0.20.2_3` with `EXIT 0`.
  The repodata SHA256 equals the downloaded asset SHA256 for both packages
  (`954cc6deaa9fd6165b61f596fda5edded96c00299931397726f0c3eae65e6e5d` and
  `a04b14e1cc1c97d10c3ccb376bc67c09c4ae756485ed2b262b7d5c91dcdbb879`).
- **CI is green**: the glibc autobuild for rev 14 finished `success`. The
  build log warns `only the autodeps teardown failed` because the seeded
  masterdir breaks xbps-src's cleanup after the package is created; the
  workflow accepts that only when the `.xbps` is new and it is the sole error.
- **Post-install message**: the package's `INSTALL` (now in the template root;
  `files/*.INSTALL` is ignored by xbps-src) tells users to enable
  `dbus`/`elogind`, run `install-greeter.sh` and not to run
  `deploy-to-host.sh`.
- **Session**: with `WLR_BACKENDS=headless WLR_RENDERER=gles2` and a DRM
  render node passed to the container, `singularity-labwc-session` starts
  `labwc`, `singularity-desktop-session`, `singularity-polkit-agent` and
  `singularity-desktop`; `xdg-desktop-portal` activates the
  `org.freedesktop.impl.portal.desktop.singularity` backend over D-Bus and
  `org.freedesktop.secrets` (keyring) activates on demand. The container has
  no `/dev/fuse`, PipeWire daemon or seat, so the portal logs those warnings.
- The package installs `wayland-sessions/singularity.desktop`, the three
  session-bus activation files, and the artist-pack helpers under `/usr/bin`
  (no `/usr/local` payload).
- **Clean install pulls the full stack**: a fresh container with only `curl`
  and `ca-certificates` added ran `xbps-install -y singularity-desktop`; it
  pulled `bash`, `dejavu-fonts-ttf`, `xkeyboard-config`, `accountsservice`,
  `wireplumber`, `mesa-dri`, `xorg-server-xwayland`, `labwc-singularity`,
  `greetd`, `xdg-desktop-portal`, `elogind` and `dbus`. Nothing else is
  required to start the session.
- **Non-root session**: a regular `tester` user (groups `wheel/video/input/
  audio`) started `singularity-labwc-session` headless and got `labwc`,
  `singularity-desktop-session`, `singularity-desktop`,
  `xdg-desktop-portal` and `xdg-desktop-portal-singularity` plus the
  keyring bus name.
- glibc x86_64: `meson setup -Dapps=all -Dgestures=disabled` and
  `meson compile` finish with all 4538 targets built.
- labwc: both the `make` path (forced wlroots/scenefx wraps) and the xbps
  path (system wlroots 0.20 + patched scenefx) compile.
- musl x86_64: `xbps-src pkg` builds
  `singularity-desktop-0.1.0_11.x86_64-musl` and
  `labwc-singularity-0.20.2_3.x86_64-musl`, and both are published with
  `.sig2` in `z-repo-musl`. The source tree also builds with
  `-Dgestures=disabled` (binary linked against `/lib/ld-musl-x86_64.so.1`).

## 6. Notes

- Updates: Void's `PackageKit` ships only the dummy/test backends, so the
  desktop uses its own xbps provider. `auto` picks it whenever
  `xbps-install` exists: checks run unprivileged (`xbps-install -un`),
  download and install run through `pkexec`. It can be forced with
  `Backend=xbps` in `singularity/updates.conf`.
- Files and the software store: `gvfs` (+ `smb`/`mtp`/`afc`/`gphoto2`
  backends) makes network shares and phones appear in Files, and `flatpak`
  backs the Store app. Samba server and Avahi are optional extras for
  sharing (`samba`, `avahi`).
- Disks/backups: `udisks2` plus the filesystem tools (`e2fsprogs`,
  `btrfs-progs`, `xfsprogs`, `exfatprogs`, `dosfstools`, `ntfs-3g`,
  `cryptsetup`) cover every format option the Disks app offers.
- Date/time, timezone, NTP toggle and hostname work via `pkexec` fallback
  (needs `polkit` + admin auth: root password or a wheel user).
- NTP toggle manages the runit service (`/etc/sv/openntpd` from `openntpd`,
  `/etc/sv/ntpd` from `ntp`, or `/etc/sv/chronyd` from `chrony`).
- Fingerprint: the standard Void `fprintd` package works with supported
  sensors. The libfprint-TOD vendor drivers are a **source-build** feature
  (`make install-fprint`); the xbps package does not ship them. On runit the
  script skips the systemd drop-in and prints the `LD_LIBRARY_PATH` to add to
  `/etc/sv/fprintd/run`. Automatic drop-in generation is not implemented.
- musl: the full tree builds with `-Dgestures=disabled` (tested on
  `void-musl`, both `meson setup` and `meson compile`). The base image may not
  ship `bash`: `xbps-install -S bash` before `make prepare-deps`.
  `libexecinfo-devel` is needed (the crash handler uses `backtrace`); the
  glibc repo does not ship it and `prepare-deps` skips it there. The gesture
  runtime blobs stay glibc-only, so the musl package is built without them.
- Portals on runit: there is no `systemd --user` to start the backend unit, so
  the package installs session-bus activation files for
  `org.freedesktop.impl.portal.desktop.singularity` and `dev.sinty.ush.Portal`.
  `xdg-desktop-portal` activates the backend on first use. A source deploy to
  `/opt/local` keeps using the `singularity-portal` wrapper from
  `deploy-to-host.sh` (it sets `LD_LIBRARY_PATH` and preloads
  `gtk4-layer-shell`).
- Restart the session (logout/login) after every deploy so the new binary
  is picked up.
- The package depends on `bash`, `dejavu-fonts-ttf` and `xkeyboard-config`:
  the session launchers are bash scripts, labwc aborts with "no fonts are
  available" on a font-less system, and the compositor needs the xkb data.
  `labwc-singularity` itself pulls the font and xkb packages.
- Headless smoke test (no seat, any container with a DRM render node):
  `WLR_BACKENDS=headless WLR_RENDERER=gles2 WLR_LIBINPUT_NO_DEVICES=1 labwc -S /bin/true`.
  Scenefx needs a DRM FD, so pass `/dev/dri/renderD128`. Without one it exits
  with "Cannot create GLES2 renderer: no DRM FD available".
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

- Publishing CI: `z-packages` dispatches an autobuild only when `z-repo` (or
  `z-repo-musl`) has no run in progress. During a 40-minute build, pushes to
  other packages wait for the next trigger instead of cancelling it. To force
  a build anyway:
  `gh workflow run autobuild.yml -R SrDicov/z-repo -f packages="singularity-desktop,labwc-singularity" -f force=true`.
- `appmenu-gtk3-module` is the Void name. It ships
  `/usr/lib/gtk-3.0/modules/libappmenu-gtk-module.so`, exactly what the shell
  probes, and `singularity-desktop` depends on it so third-party GTK global
  menus work out of the box.
