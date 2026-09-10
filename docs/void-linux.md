# Singularity Desktop on Void Linux (glibc)

Void uses runit (no systemd), `xbps`, and `sudo` or `doas` (package
`opendoas`) instead of `run0`. This guide covers a full install from source.
`elogind` provides the `org.freedesktop.login1` API, so session tracking,
suspend and brightness work unchanged. There is no `timedate1`/`hostnamed` on
Void: date/timezone/hostname settings fall back to `pkexec` helpers (the
session polkit agent prompts, same UX).

## 1. Dependencies

```sh
sudo xbps-install -Su \
  meson ninja vala pkg-config gettext git curl unzip python3 \
  glib-devel gobject-introspection sassc scdoc wayland-protocols \
  gtk4-devel gtk4-layer-shell-devel vte3-gtk4-devel gtksourceview5-devel \
  libpeas2-devel libgee-devel NetworkManager-devel upower-devel \
  pulseaudio-devel gnome-online-accounts-devel polkit-devel libsoup3-devel \
  json-glib-devel libdbusmenu-glib-devel at-spi2-core-devel tinysparql-devel \
  eudev-libudev-devel pam-devel elogind-devel wayland-devel \
  libxkbcommon-devel cairo-devel pango-devel gdk-pixbuf-devel libxcb-devel \
  libpng-devel librsvg-devel libsfdo-devel libxml2-devel libsecret-devel \
  poppler-glib-devel gst-plugins-base1-devel gst-plugins-good1-devel \
  pipewire-devel libdisplay-info-devel libliftoff-devel libdrm-devel \
  MesaLib-devel libinput-devel libseat-devel xorg-server-xwayland \
  dbus elogind greetd seatd xdg-desktop-portal xdg-user-dirs accountsservice \
  desktop-file-utils hicolor-icon-theme openntpd
```

`sudo` or `opendoas` (both work), plus `qt6-base` if you want Qt apps to
follow the theme. `appmenu-gtk-module` is not packaged: first-party apps are
unaffected, third-party GTK global menus just won't appear.

## 2. Build

```sh
git clone --recurse-submodules https://github.com/singularityos-lab/singularity-desktop
cd singularity-desktop
make compile
```

This bootstraps the gesture runtime (downloads MediaPipe/ONNX blobs,
glibc x86_64), builds the labwc fork, then the desktop.

## 3. Deploy (sudo or doas, both fully supported)

```sh
make install            # sudo preferred, doas fallback, run0 only on systemd hosts
```

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

## 5. Notes

- Date/time, timezone, NTP toggle and hostname work via `pkexec` fallback
  (needs `polkit` + admin auth: root password or a wheel user).
- NTP toggle manages the runit service (`/etc/sv/ntpd` from `openntpd`, or
  `chronyd`).
- Restart the session (logout/login) after every deploy so the new binary
  is picked up.
- Binary packages: see `packaging/xbps/` (draft templates for void-packages).
