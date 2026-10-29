# XBPS packaging (Void Linux) — DRAFT

Templates for `void-packages`, not yet tested as a full `xbps-src` build.

```sh
git clone https://github.com/void-linux/void-packages.git
cd void-packages
ln -s /path/to/singularity-desktop/packaging/xbps/singularity-desktop srcpkgs/singularity-desktop
ln -s /path/to/singularity-desktop/packaging/xbps/labwc-singularity srcpkgs/labwc-singularity
./xbps-src pkg labwc-singularity
./xbps-src pkg singularity-desktop
```

Status:

- `makedepends` were checked against a Void glibc x86_64 repo index
  (`xbps-query -R`); a full clean-chroot build is still pending.
- `singularity-desktop` pins `_commit` to a master SHA because upstream has no
  release tags yet. Bump it only after re-verifying the build.
- `archs="x86_64"` (glibc only): the gesture runtime blobs are glibc x86_64.
  musl needs `-Dgestures=disabled` (already supported by the root meson
  options) plus a build test; it is not enabled in the template.
- `labwc-singularity` replaces stock `labwc` (`conflicts` + `provides`). The
  desktop needs the fork; do not install both.
- `singularity-desktop` builds with `--prefix=/usr`; host integration (D-Bus
  activation files, schemas, icons, per-user config) is applied by running
  `SINGULARITY_PREFIX=/usr bash scripts/deploy-to-host.sh` after install (also
  shipped in `/usr/share/doc/singularity-desktop/`).
- Before submitting to void-packages: set a real maintainer for the PR and
  verify the full `makedepends` list in a clean chroot (a few names may still
  need adjusting).
