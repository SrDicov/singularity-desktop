#!/bin/bash
# Set up the Singularity greeter on top of greetd. Run via: make install-greeter

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$EUID" -ne 0 ]; then
    if [ -n "$container" ]; then
        exec host-spawn run0 bash "$0" "$@"
    elif [ -d /run/systemd/system ] && command -v run0 >/dev/null; then
        exec run0 bash "$0" "$@"
    elif command -v sudo >/dev/null; then
        exec sudo bash "$0" "$@"
    elif command -v doas >/dev/null; then
        exec doas bash "$0" "$@"
    else
        echo "ERROR: need root (run as root, or install sudo/doas)." >&2
        exit 1
    fi
fi

has_systemd() {
    [ -d /run/systemd/system ] && command -v systemctl >/dev/null
}

has_runit() {
    [ -d /etc/sv ] && [ -d /var/service ]
}

# Match the prefix that actually has the greeter (a stale /opt/local with only
# labwc must not shadow a /usr package install). SINGULARITY_PREFIX wins.
if [ -n "${SINGULARITY_PREFIX:-}" ]; then
    PREFIX="$SINGULARITY_PREFIX"
elif [ -x /opt/local/bin/singularity-greeter ]; then
    PREFIX="/opt/local"
elif [ -x /usr/local/bin/singularity-greeter ]; then
    PREFIX="/usr/local"
else
    PREFIX="/usr"
fi
BIN="$PREFIX/bin"

if [ ! -x "$BIN/singularity-greeter" ]; then
    echo "ERROR: $BIN/singularity-greeter not found. Run 'make install' first." >&2
    exit 1
fi

GREETD_DIR="/etc/greetd"
mkdir -p "$GREETD_DIR"

cat > "$GREETD_DIR/greeter-session" <<EOF
#!/bin/bash
export PATH="$BIN:\$PATH"
export LD_LIBRARY_PATH="$PREFIX/lib\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}"
export GSETTINGS_SCHEMA_DIR="$PREFIX/share/glib-2.0/schemas"
export XDG_DATA_DIRS="$PREFIX/share:/usr/local/share:/usr/share"
export GI_TYPELIB_PATH="$PREFIX/lib/girepository-1.0\${GI_TYPELIB_PATH:+:\$GI_TYPELIB_PATH}"
export GDK_BACKEND=wayland
export GSK_RENDERER=gl
export GTK_A11Y=none
for ls in /usr/lib/x86_64-linux-gnu/libgtk4-layer-shell.so.0 \\
          /usr/lib64/libgtk4-layer-shell.so.0 \\
          /usr/lib/libgtk4-layer-shell.so.0; do
    if [ -e "\$ls" ]; then
        export LD_PRELOAD="\$ls\${LD_PRELOAD:+:\$LD_PRELOAD}"
        break
    fi
done
exec "$BIN/singularity-greeter"
EOF
chmod +x "$GREETD_DIR/greeter-session"

cat > "$GREETD_DIR/start-greeter" <<EOF
#!/bin/bash
# labwc and its libsfdo deps live under \$PREFIX/lib; greetd starts this with a
# clean environment, so put them on the search path (the user session does the
# same via singularity-labwc-session).
export LD_LIBRARY_PATH="$PREFIX/lib\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}"
export PATH="$BIN:\$PATH"
for drv in /sys/class/drm/card[0-9]*/device/driver; do
    [ -e "\$drv" ] || continue
    case "\$(basename "\$(readlink -f "\$drv")")" in
        virtio*|qxl|vmwgfx|bochs-drm|cirrus|vboxvideo|simpledrm)
            export WLR_NO_HARDWARE_CURSORS="\${WLR_NO_HARDWARE_CURSORS:-1}"
            break ;;
    esac
done
_LLOG="\${HOME:-/var/lib/greetd}/labwc.log"
[ -f "\$_LLOG" ] && mv -f "\$_LLOG" "\$_LLOG.1" 2>/dev/null || true
exec "$BIN/labwc" -s "$GREETD_DIR/greeter-session" >> "\$_LLOG" 2>&1
EOF
chmod +x "$GREETD_DIR/start-greeter"

cat > "$GREETD_DIR/config.toml" <<EOF
[terminal]
vt = 1

[default_session]
command = "$GREETD_DIR/start-greeter"
user = "greetd"
EOF

# greetd runs the greeter as a dedicated unprivileged user. Some distros'
# packages create it, but immutable/atomic ones (e.g. Vanilla OS) may not,
# leaving greetd failing with "configured default session user 'greetd' not
# found". Create it if missing so the install is self-sufficient.
# nologin lives in different places per distro (/usr/sbin vs /usr/bin).
NOLOGIN="$(command -v nologin || echo /usr/sbin/nologin)"
if ! id greetd >/dev/null 2>&1; then
    useradd --system --create-home --home-dir /var/lib/greetd \
        --shell "$NOLOGIN" greetd 2>/dev/null \
        || useradd --system --shell "$NOLOGIN" greetd 2>/dev/null \
        || true
fi
if id greetd >/dev/null 2>&1; then
    # video + input always exist; render only on some systems.
    usermod -aG video,input greetd 2>/dev/null || true
    usermod -aG render greetd 2>/dev/null || true
fi

if command -v getenforce >/dev/null 2>&1 && [ "$(getenforce)" != "Disabled" ]; then
    chcon -t bin_t "$GREETD_DIR/start-greeter" "$GREETD_DIR/greeter-session" 2>/dev/null || true
fi

# greetd must own tty1; a getty left running on the same VT fights it and labwc
# cannot hold the DRM master (atomic commit: Permission denied). Stop the getty
# whenever greetd runs, the standard display-manager-owns-VT pattern.
if has_systemd; then
    mkdir -p /etc/systemd/system/greetd.service.d
    cat > /etc/systemd/system/greetd.service.d/10-vt.conf <<EOF
[Unit]
Conflicts=getty@tty1.service
After=getty@tty1.service
EOF
    systemctl daemon-reload 2>/dev/null || true
elif has_runit; then
    # runit (Void): enable greetd, drop the getty on tty1 so greetd owns the VT.
    [ -e /var/service/greetd ] || ln -s /etc/sv/greetd /var/service/ 2>/dev/null || true
    rm -f /var/service/agetty-tty1 2>/dev/null || true
fi

echo "Singularity greeter configured for greetd in $GREETD_DIR."
echo
if has_runit && ! has_systemd; then
    echo "runit detected:"
    echo "  - greetd enabled (make sure packages 'greetd' and 'elogind' are installed)."
    echo "  - required services: ln -s /etc/sv/dbus /var/service/ ; ln -s /etc/sv/elogind /var/service/"
    echo "  - disable any other display manager, then reboot."
else
    echo "To enable it as your login manager:"
    echo "  1. Install greetd if it is not already (package 'greetd')."
    echo "  2. Disable your current display manager, e.g. 'systemctl disable gdm'."
    echo "  3. Enable greetd: 'systemctl enable greetd'."
    echo "  4. Reboot."
fi
