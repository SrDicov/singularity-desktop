# Singularity Desktop on Void Linux (musl)

The tree builds and runs on **Void musl x86_64** only with gestures disabled.
The gesture runtime (`libmediapipe.so`, `libonnxruntime.so`, the `.task`/`.onnx`
models) is shipped as prebuilt **glibc** x86_64 binaries, so meson refuses to
enable gestures on a musl host. The musl package is published in
`z-repo-musl` with gestures disabled. To install it:

```sh
fp=02:16:21:e8:80:43:b6:16:d4:63:13:e5:5d:e1:32:b7
dots=$(printf '%s' "$fp" | tr ':' '.')
mkdir -p /var/db/xbps/keys /etc/xbps.d
curl -fsSL -o "/var/db/xbps/keys/$fp.plist" \
  "https://github.com/SrDicov/z-repo-musl/releases/download/stable/$dots.plist"
echo "repository=https://github.com/SrDicov/z-repo-musl/releases/download/stable" \
  > /etc/xbps.d/11-zrepo-musl.conf
xbps-install -S
xbps-install -y singularity-desktop
```

## Dependencies

```sh
xbps-install -S bash
make prepare-deps
```

`prepare-deps.sh` skips `libxcrypt-devel` and `libexecinfo-devel` if the musl
repo does not carry them; install `libexecinfo-devel` manually because the crash
handler uses `backtrace()` and meson adds `-lexecinfo` on non-glibc libcs.

## Build

```sh
meson setup build -Dapps=all -Dgestures=disabled
meson compile -C build
```

`-Dgestures=disabled` is the canonical spelling (meson `feature` option). The
old `-Dgestures=false` form is not valid and is not supported anywhere.

Verified on `ghcr.io/void-linux/void-musl` (2026-10-30): `prepare-deps` OK,
`meson setup` OK and a full `meson compile` finishes; the resulting binaries are
linked against `/lib/ld-musl-x86_64.so.1`. `xbps-src pkg` builds
`singularity-desktop-0.1.0_23.x86_64-musl` and
`labwc-singularity-0.20.2_4.x86_64-musl`, both published with `.sig2`.

A clean musl container installed them from `z-repo-musl` (`inst_rc=0`; repodata
SHA256 equals the downloaded asset SHA256:
`1a6722bc6a3f76bd9c7a232718db5ea2973bae812e6ebbd0c46013b450f84469` for the
desktop and
`5bd985a236a2429ab7a206e14725222a849ba3be0a28767163d54efad3bcc909` for labwc).
Every declared dependency was present (54 checks, no misses), and installing
over stock `labwc-0.20.2_1` removes it and installs `labwc-singularity-0.20.2_4`
(`/usr/bin/labwc` owned by the fork). A headless
`singularity-labwc-session` started `labwc`, the desktop shell, the polkit
agent, `pipewire`, `wireplumber`, `pipewire-pulse`,
`xdg-desktop-portal-singularity` and `xdg-desktop-portal-gtk`, with the audio
sockets `pipewire-0`/`pulse/native` and the keyring bus name; the session
exported `LANG`/`LC_TIME` from `~/.config/locale.conf`. The gesture runtime
directory is absent, as intended.

## Runtime

The musl runtime path is the same as glibc minus gestures:

- runit services: `dbus`, `elogind`, `greetd` (plus `seatd` only if you do not
  use elogind for seat management).
- date/time and hostname use the `pkexec` fallback (`polkit` + admin auth).
- portal/keyring/polkit activate over D-Bus; there are no systemd units.
- the package depends on `NetworkManager`, `upower`, `pipewire`, `bluez`,
  `polkit`, `fprintd`, `cups`, `shadow`, `rtkit`, `nftables`,
  `libheif-tools`, `sane`, `udisks2` and the filesystem tools (`e2fsprogs`,
  `btrfs-progs`, `xfsprogs`, `exfatprogs`, `dosfstools`, `ntfs-3g`,
  `cryptsetup`, `gvfs` with its smb/mtp/afc/gphoto2 backends, `flatpak`),
  `gst-plugins-bad1`/`ugly1`/`gst-libav`, `elfutils`, `libnotify`,
  `power-profiles-daemon`, `colord`, `fwupd`, `geoclue2`, `avahi`, `samba`,
  `noto-fonts-ttf`, `noto-fonts-emoji`, `xdg-utils`,
  `xdg-desktop-portal-gtk` and `appmenu-gtk3-module`, so networking, battery,
  audio, Bluetooth, printing, fingerprint enrolment, greeter setup, file
  opening and third-party GTK global menus work without extra packages.
  `fprintd` is D-Bus activated; link the runit services for the other daemons
  (`NetworkManager`, `bluetoothd`, `cupsd`, `rtkit`).

## Known limits

- Gestures: cannot be enabled because the prebuilt blobs are glibc-only.
- Locales: musl has no locale data (only `C.UTF-8`), so the Region page has
  nothing to offer; the session runs in `C.UTF-8`.
  Rebuilding the MediaPipe/ONNX runtime for musl is out of scope. Tracked in
  `TODO.md` as an internal follow-up.
- scenefx headers use `__always_inline`, which musl's headers do not export.
  `labwc-singularity` applies `files/scenefx-musl-always-inline.patch` after
  extracting its bundled scenefx. The desktop package does not build labwc, so
  it carries no scenefx copy.
- The session scripts are bash and labwc refuses to start with no fonts, so the
  package depends on `bash`, `dejavu-fonts-ttf` and `xkeyboard-config`.
- No prebuilt musl package is needed on the build host: `z-repo-musl`
  publishes one. Build from source only if you are changing the tree.
- `fprintd` integration with libfprint-TOD is a source build (`make
  install-fprint`); the standard Void `fprintd` package still enumerates
  supported sensors without it.
