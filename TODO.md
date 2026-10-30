# Pending work

Everything below needs hardware, a real display/seat, or CI time that this
environment cannot provide. No internal code TODO is open.

## [pending-external] Publish the rev 11 packages

- What is missing: the `z-repo`/`z-repo-musl` autobuilds for
  `singularity-desktop-0.1.0_11` (and `labwc-singularity-0.20.2_3`). Rev 11
  fixes the `/usr/local` install abort and the missing portal D-Bus activation;
  rev 10 and earlier cannot be published by xbps-src.
- Unblocks it: the CI runners finishing the ~1.5h build.
- Exact check:

  ```sh
  gh workflow run autobuild.yml -R SrDicov/z-repo \
    -f packages="singularity-desktop,labwc-singularity" -f force=true
  gh workflow run autobuild.yml -R SrDicov/z-repo-musl \
    -f packages="singularity-desktop,labwc-singularity" -f force=true
  gh release view stable -R SrDicov/z-repo --json assets | grep -o 'singularity-desktop[^"]*'
  gh release view stable -R SrDicov/z-repo-musl --json assets | grep -o 'singularity-desktop[^"]*'
  ```

## [pending-external] Graphical session on a real Void host

- What is missing: a login through greetd into labwc + `singularity-desktop`
  with a real DRM seat. The container test proves the xbps install, the
  compositor start with a DRM render node, the shell process, and the portal /
  keyring D-Bus activation; it does not exercise greetd, PAM or real input.
- Unblocks it: any Void glibc x86_64 machine with a GPU/VM display.
- Exact check:

  ```sh
  sudo xbps-install -S singularity-desktop
  sudo bash /usr/share/doc/singularity-desktop/deploy-to-host.sh
  sudo bash /usr/share/doc/singularity-desktop/install-greeter.sh
  # reboot, log in, then:
  busctl --user list | grep -E 'portal.desktop.singularity|freedesktop.secrets'
  busctl --user introspect org.freedesktop.impl.portal.desktop.singularity /org/freedesktop/portal/desktop
  ```

## [pending-external] Fingerprint enrolment and authentication

- What is missing: a fingerprint reader to enrol/authenticate. `fprintd` and the
  client stack install and start on runit.
- Unblocks it: hardware with a supported sensor.
- Exact check: `sudo sv start fprintd`, then enrol a finger from Settings >
  Users. TODO: add `LD_LIBRARY_PATH` to `/etc/sv/fprintd/run` only when using
  the libfprint-TOD source build (`make install-fprint`).

## [pending-external] Gesture runtime on hardware

- What is missing: a camera and a physical input device to exercise gestures.
- Unblocks it: hardware. The glibc runtime blobs are installed and load.
- Exact check: `singularity-hand-control --help` and enable gestures in
  Settings > Mouse & Touchpad.

## [pending-external] musl binary package

- What is missing: a successful `xbps-src pkg` for `x86_64-musl` and a published
  `z-repo-musl` asset. The template now sets `archs="x86_64 x86_64-musl"`,
  forces `-Dgestures=disabled` on musl and swaps `libxcrypt-devel` for
  `libexecinfo-devel`.
- Unblocks it: the `z-repo-musl` autobuild.
- Exact check:

  ```sh
  gh workflow run autobuild.yml -R SrDicov/z-repo-musl \
    -f packages="singularity-desktop,labwc-singularity" -f force=true
  gh run watch -R SrDicov/z-repo-musl
  ```

- Ceiling: the gesture runtime blobs are glibc-only. A musl build without
  gestures is the supported path; rebuilding MediaPipe/ONNX for musl is out of
  scope.

## Decisions recorded

- `-Dgestures=disabled` is the only supported spelling; `false` is not a valid
  meson `feature` value and no script or doc uses it.
- `appmenu-gtk-module` is not packaged in Void. First-party apps are unaffected;
  third-party GTK global menus are not supported.
- The xbps template pins a specific meta-repo commit; bump both `_commit` and
  the first distfile checksum/submodule pointers together. A docs-only change
  does not justify a rebuild, but any change to `meson.build`, `data/` or
  `scripts/` does.
