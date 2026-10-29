# Singularity Desktop on Void Linux (musl)

The tree builds and runs on **Void musl x86_64** only with gestures disabled.
The gesture runtime (`libmediapipe.so`, `libonnxruntime.so`, the `.task`/`.onnx`
models) is shipped as prebuilt **glibc** x86_64 binaries, so meson refuses to
enable gestures on a musl host. There is no musl xbps package in `z-repo`; the
published package is glibc-only.

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

Verified on `ghcr.io/void-linux/void-musl` (2026-10-29): `prepare-deps` OK,
`meson setup` OK and a full `meson compile` finishes; the resulting binaries are
linked against `/lib/ld-musl-x86_64.so.1`.

## Runtime

The musl runtime path is the same as glibc minus gestures:

- runit services: `dbus`, `elogind`, `seatd`, `greetd`.
- date/time and hostname use the `pkexec` fallback (`polkit` + admin auth).
- portal/keyring/polkit activate over D-Bus; there are no systemd units.
- `appmenu-gtk-module` is not packaged in Void, so third-party GTK global menus
  are not available.

## Known limits

- Gestures: cannot be enabled because the prebuilt blobs are glibc-only.
  Rebuilding the MediaPipe/ONNX runtime for musl is out of scope. Tracked in
  `TODO.md` as an internal follow-up.
- The vendored `scenefx` headers use `__always_inline`, which musl's headers do
  not export. The xbps templates apply `scenefx-musl-always-inline.patch` to
  both the standalone labwc build and the desktop's vendored copy.
- The session scripts are bash and labwc refuses to start with no fonts, so the
  package depends on `bash`, `dejavu-fonts-ttf` and `xkeyboard-config`.
- No prebuilt musl package. Build from source as above.
- `fprintd` integration with libfprint-TOD is a source build (`make
  install-fprint`); the standard Void `fprintd` package still enumerates
  supported sensors without it.
