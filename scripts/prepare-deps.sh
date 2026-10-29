#!/usr/bin/env bash
set -euo pipefail

PKGCONFIG=(
    atspi-2 cairo cairo-ft cairo-gobject colord cups dbusmenu-glib-0.4 egl enchant-2 epoxy
    fontconfig freerdp3 freerdp-client3 winpr3 freetype2 fribidi fuse3 gbm gdk-pixbuf-2.0 gee-0.8
    gio-2.0 gio-unix-2.0 gl glesv2 glib-2.0 glu gmodule-2.0 gnutls gobject-2.0
    gobject-introspection-1.0 graphene-gobject-1.0 gst-editing-services-1.0 gstreamer-1.0
    gstreamer-allocators-1.0 gstreamer-app-1.0 gstreamer-audio-1.0 gstreamer-base-1.0
    gstreamer-gl-1.0 gstreamer-pbutils-1.0 gstreamer-play-1.0 gstreamer-tag-1.0 gstreamer-video-1.0
    gtk4 gtk4-layer-shell-0 gtksourceview-5 gudev-1.0 harfbuzz harfbuzz-subset hwdata iso-codes
    json-glib-1.0 lcms2 libarchive libdisplay-info libdrm libevdev libfido2 libgcrypt libinput
    libjpeg libliftoff liblzma libnm libpeas-2 libpng libpulse libpulse-mainloop-glib librsvg-2.0
    libseat libsecret-1 libsodium libsoup-3.0 libsystemd libtiff-4 libudev libusb-1.0 libwacom
    libxml-2.0 libzstd mtdev nettle pango pangocairo pangoft2 pixman-1 polkit-agent-1
    polkit-gobject-1 poppler-glib sane-backends sdl2 sqlite3 tracker-sparql-3.0 upower-glib
    vte-2.91-gtk4 vulkan wayland-client wayland-cursor wayland-egl wayland-protocols wayland-scanner
    wayland-server webkitgtk-6.0 x11 xcb xcb-composite xcb-dri3 xcb-errors xcb-ewmh xcb-icccm
    xcb-present xcb-render xcb-renderutil xcb-res xcb-shm xcb-xfixes xcb-xinput xcursor xdamage
    xext xfixes xi xinerama xkbcommon xrandr xrender xwayland zbar zlib
)

DEBIAN=(
    build-essential cmake gettext git glslc golang-go cargo meson ninja-build pkg-config python3
    sassc scdoc valac libvala-dev gobject-introspection libgirepository1.0-dev libglib2.0-dev
    libglib2.0-dev-bin hwdata iso-codes wayland-protocols libwayland-bin xwayland
    freerdp3-dev libarchive-dev libatspi2.0-dev libcairo2-dev libcmocka-dev libcolord-dev
    libcups2-dev libdbusmenu-glib-dev libdisplay-info-dev libdrm-dev libegl-dev libenchant-2-dev
    libepoxy-dev libevdev-dev libfido2-dev libfontconfig-dev libfreetype-dev libfribidi-dev
    libfuse3-dev libgbm-dev libgcrypt20-dev libgdk-pixbuf-2.0-dev libgee-0.8-dev libges-1.0-dev
    libgl-dev libgles-dev libglu1-mesa-dev libgnutls28-dev libgraphene-1.0-dev
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgstreamer-plugins-bad1.0-dev
    libgtk-4-dev libgtk4-layer-shell-dev libgtksourceview-5-dev libgudev-1.0-dev libharfbuzz-dev
    libinput-dev libjpeg-dev libjson-glib-dev liblcms2-dev libliftoff-dev liblzma-dev
    libmtdev-dev libnm-dev libpam0g-dev libpango1.0-dev libpeas-2-dev libpixman-1-dev libpng-dev
    libpolkit-agent-1-dev libpolkit-gobject-1-dev libpoppler-glib-dev libpulse-dev librsvg2-dev
    libsane-dev libsdl2-dev libseat-dev libsecret-1-dev libsodium-dev libsoup-3.0-dev
    libsqlite3-dev libsystemd-dev libtiff-dev libtracker-sparql-3.0-dev libudev-dev
    libupower-glib-dev libusb-1.0-0-dev libvte-2.91-gtk4-dev libvulkan-dev libwacom-dev
    libwayland-dev libwebkitgtk-6.0-dev libx11-dev libxcb1-dev libxcb-composite0-dev
    libxcb-dri3-dev libxcb-errors-dev libxcb-ewmh-dev libxcb-icccm4-dev libxcb-present-dev
    libxcb-render0-dev libxcb-render-util0-dev libxcb-res0-dev libxcb-shm0-dev libxcb-xfixes0-dev
    libxcb-xinput-dev libxcursor-dev libxdamage-dev libxext-dev libxfixes-dev libxi-dev
    libxinerama-dev libxkbcommon-dev libxml2-dev libxrandr-dev libxrender-dev libzbar-dev
    libzstd-dev nettle-dev zlib1g-dev libcrypt-dev libdecor-0-0 qt6-xdgdesktopportal-platformtheme
)

FEDORA=(
    gcc gcc-c++ make cmake gettext git glslc golang cargo meson ninja-build pkgconf-pkg-config
    python3 sassc scdoc vala vala-devel gobject-introspection-devel hwdata xorg-x11-server-Xwayland
    pam-devel libcmocka-devel libxcrypt-devel hwdata-devel libdecor qt6-qtbase-gui
)

SUSE=(
    gcc gcc-c++ make cmake gettext-tools git shaderc go cargo meson ninja pkgconf python3 sassc
    scdoc vala gobject-introspection-devel hwdata xwayland pam-devel libcmocka-devel libxcrypt-devel libdecor-0-0 qt6-gui
)

ARCH=(
    base-devel cmake gettext git shaderc go rust meson ninja pkgconf python sassc scdoc vala
    gobject-introspection hwdata xorg-xwayland iso-codes at-spi2-core cairo colord libcups
    libdbusmenu-glib mesa glu enchant libepoxy fontconfig freerdp freetype2 fribidi fuse3
    gdk-pixbuf2 libgee glib2 gnutls graphene gst-editing-services gstreamer gst-plugins-base-libs
    gst-plugins-bad-libs gtk4 gtk4-layer-shell gtksourceview5 libgudev harfbuzz json-glib lcms2
    libarchive libdisplay-info libdrm libevdev libfido2 libgcrypt libinput libjpeg-turbo libliftoff
    xz libnm libpeas-2 libpng libpulse librsvg seatd libsecret libsodium libsoup3 systemd-libs
    libtiff libusb libwacom libxml2 zstd mtdev nettle pango pixman polkit poppler-glib sane sdl2
    sqlite tinysparql upower vte4 vulkan-icd-loader vulkan-headers wayland wayland-protocols
    webkitgtk-6.0 libx11 libxcb xcb-util-errors xcb-util-wm xcb-util-renderutil libxcursor
    libxdamage libxext libxfixes libxi libxinerama libxkbcommon libxrandr libxrender zbar zlib pam
    cmocka libxcrypt libdecor qt6-base
)

VOID=(
    cmake meson ninja vala pkg-config gettext git curl unzip python3 sassc scdoc
    gcc make bash
    gobject-introspection wayland-protocols hwids iso-codes
    glib-devel gtk4-devel gtk4-layer-shell-devel vte3-gtk4-devel gtksourceview5-devel
    libpeas2-devel libgee-devel NetworkManager-devel upower-devel pulseaudio-devel
    gnome-online-accounts-devel polkit-devel libsoup3-devel json-glib-devel
    libdbusmenu-glib-devel at-spi2-core-devel tinysparql-devel eudev-libudev-devel
    libgudev-devel pam-devel elogind-devel wayland-devel libxkbcommon-devel
    cairo-devel pango-devel gdk-pixbuf-devel libxcb-devel libpng-devel librsvg-devel
    libsfdo-devel libxml2-devel libsecret-devel poppler-glib-devel
    gst-plugins-base1-devel gst1-editing-services-devel pipewire-devel
    libdisplay-info-devel libliftoff-devel libdrm-devel MesaLib-devel libglvnd-devel
    libgbm-devel libinput-devel libseat-devel xorg-server-xwayland xorgproto xcb-proto
    libX11-devel libXcursor-devel libXdamage-devel libXext-devel libXfixes-devel
    libXi-devel libXinerama-devel libXrandr-devel libXrender-devel libXcomposite-devel
    libXres-devel libXxf86vm-devel libXtst-devel libXScrnSaver-devel
    xcb-util-devel xcb-util-wm-devel xcb-util-errors-devel xcb-util-image-devel
    xcb-util-keysyms-devel xcb-util-renderutil-devel xcb-util-cursor-devel
    libusb-devel cmocka-devel libxcrypt-devel cups-devel colord-devel libarchive-devel
    libjpeg-turbo-devel tiff-devel libwebp-devel vulkan-loader-devel Vulkan-Headers
    shaderc go cargo libevdev-devel libfido2-devel libwacom-devel libsodium-devel
    libzbar-devel libgcrypt-devel nettle-devel freerdp3-devel sane-devel SDL2-devel
    enchant2-devel libgphoto2-devel
    fuse3-devel liblzma-devel mtdev-devel sqlite-devel libzstd-devel zlib-devel
    gnutls-devel glu-devel libwebkitgtk60-devel
)

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

SUDO=()
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null; then SUDO=(sudo)
    elif command -v doas >/dev/null; then SUDO=(doas)
    else SUDO=(run0); fi
fi

run() {
    if [ "$DRY_RUN" = 1 ]; then
        printf '%q ' "$@"
        echo
    else
        "${SUDO[@]}" "$@"
    fi
}

pkgconfig_names() {
    local name
    for name in "${PKGCONFIG[@]}"; do printf 'pkgconfig(%s)\n' "$name"; done
}

install_apt() {
    run apt-get update
    local available=() missing=() name
    for name in "${DEBIAN[@]}"; do
        if apt-cache show "$name" >/dev/null 2>&1; then available+=("$name"); else missing+=("$name"); fi
    done
    [ "${#missing[@]}" -gt 0 ] && echo "Not available on this release, skipped: ${missing[*]}" >&2
    run env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${available[@]}"
}

install_dnf() {
    mapfile -t names < <(pkgconfig_names)
    if dnf --version 2>/dev/null | grep -q '^dnf5'; then
        run dnf install -y --skip-unavailable "${FEDORA[@]}" "${names[@]}"
    else
        run dnf install -y --setopt=strict=0 "${FEDORA[@]}" "${names[@]}"
    fi
}

install_zypper() {
    mapfile -t names < <(pkgconfig_names)
    run zypper --non-interactive install --no-recommends "${SUSE[@]}" "${names[@]}" || {
        local name
        for name in "${SUSE[@]}" "${names[@]}"; do
            run zypper --non-interactive install --no-recommends "$name" || echo "Skipped $name" >&2
        done
    }
}

install_pacman() {
    run pacman -Syu --needed --noconfirm "${ARCH[@]}"
}

install_xbps() {
    run xbps-install -Sy "${VOID[@]}"
}

[ -r /etc/os-release ] || { echo "Cannot detect the distribution: /etc/os-release is missing" >&2; exit 1; }
. /etc/os-release
family=" ${ID:-} ${ID_LIKE:-} "
echo "Detected ${PRETTY_NAME:-$ID}"

case "$family" in
    *" debian "*|*" ubuntu "*) install_apt ;;
    *" fedora "*|*" rhel "*|*" centos "*) install_dnf ;;
    *" suse "*|*" opensuse "*) install_zypper ;;
    *" arch "*) install_pacman ;;
    *" void "*) install_xbps ;;
    *)
        echo "Unsupported distribution ${ID:-unknown}. Install the packages providing these pkg-config modules:" >&2
        printf '  %s\n' "${PKGCONFIG[@]}" >&2
        exit 1
        ;;
esac
