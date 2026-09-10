# XBPS packaging (Void Linux) — DRAFT

Templates for `void-packages`, not yet build-tested. To try on a Void host:

```sh
git clone https://github.com/void-linux/void-packages.git
cd void-packages
ln -s /path/to/singularity-desktop/packaging/xbps/singularity-desktop srcpkgs/singularity-desktop
ln -s /path/to/singularity-desktop/packaging/xbps/labwc-singularity srcpkgs/labwc-singularity
./xbps-src pkg labwc-singularity
./xbps-src pkg singularity-desktop
```

Notes:

- `singularity-desktop` builds with `--prefix=/usr`; host integration
  (D-Bus activation files, schemas, icons, per-user config) is applied by
  running `SINGULARITY_PREFIX=/usr bash scripts/deploy-to-host.sh` after
  install (also shipped in `/usr/share/doc/singularity-desktop/`).
- `labwc-singularity` replaces stock `labwc` (`conflicts` + `provides`).
  The desktop needs the fork; do not install both.
- `singularity-desktop` is `archs="x86_64*"` because the gesture runtime
  blobs are glibc x86_64. A musl/no-gestures flavour needs a
  `-Dgestures=false` meson option first (not yet implemented upstream).
- Before submitting to void-packages: set a real `maintainer`, unpin
  `_commit` to a tag, and verify the full `makedepends` list in a clean
  chroot (a few names may need adjusting).
