# Pending work

Everything below needs hardware, a real display/seat, or CI time that this
environment cannot provide. No internal code TODO is open.

## [pending-external] Graphical session on a real Void host

- What is missing: a login through greetd into labwc + `singularity-desktop`
  with a real DRM seat. Containers prove: xbps install, compositor start with a
  DRM render node, shell process, portal and keyring D-Bus activation, on both
  glibc (`0.1.0_11` / `0.20.2_3`) and musl. They do not exercise greetd, PAM,
  real input or audio.
- Unblocks it: any Void glibc or musl x86_64 machine with a GPU/VM display.
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
  Users. Add `LD_LIBRARY_PATH` to `/etc/sv/fprintd/run` only when using the
  libfprint-TOD source build (`make install-fprint`); the xbps package uses the
  stock Void `fprintd`.

## [pending-external] Gesture runtime on hardware (glibc only)

- What is missing: a camera and a physical input device to exercise gestures.
- Unblocks it: hardware. The glibc runtime blobs are installed and load; the
  musl package is intentionally built with `-Dgestures=disabled`.
- Exact check: `singularity-hand-control --help` and enable gestures in
  Settings > Mouse & Touchpad.

## Decisions recorded

- `-Dgestures=disabled` is the only supported spelling; `false` is not a valid
  meson `feature` value and no script or doc uses it.
- `appmenu-gtk-module` is not packaged in Void. First-party apps are unaffected;
  third-party GTK global menus are not supported.
- The xbps template pins a specific meta-repo commit; bump `_commit`, the first
  distfile checksum and any changed submodule pins together. A docs-only change
  does not justify a rebuild; a change to `meson.build`, `data/` or `scripts/`
  does.
- musl ships without gestures because the prebuilt MediaPipe/ONNX blobs are
  glibc-only. Rebuilding them for musl is out of scope.
- `labwc-singularity` depends on `dejavu-fonts-ttf` and `xkeyboard-config`: the
  compositor aborts with "no fonts are available" otherwise.
- `singularity-desktop` depends on `bash`: the session launchers are bash
  scripts and Void does not install bash by default.
