#!/bin/bash

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="${BUILD_DIR:-$PROJECT_DIR/build}"

if [ $# -eq 0 ]; then
    echo "usage: make install-app <app> [<app>...]   e.g. make install-app messages" >&2
    exit 2
fi

resolve() {
    local name="$1"
    for candidate in "$name" "singularity-$name" "${name#singularity-}"; do
        if [ -f "$PROJECT_DIR/subprojects/$candidate/meson.build" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

apps=()
for name in "$@"; do
    if ! dir="$(resolve "$name")"; then
        echo "ERROR: no app called '$name' in subprojects/" >&2
        exit 1
    fi
    apps+=("$dir")
done

if [ ! -f "$BUILD/build.ninja" ]; then
    echo "ERROR: $BUILD is not configured; run make once first" >&2
    exit 1
fi

mapfile -t targets < <(meson introspect "$BUILD" --targets | python3 -c '
import json, os, sys
build, apps = sys.argv[1], sys.argv[2:]
for t in json.load(sys.stdin):
    if not t.get("installed"):
        continue
    if not any("/subprojects/%s/" % app in t.get("defined_in", "") for app in apps):
        continue
    for f in t.get("filename", []):
        print(os.path.relpath(f, build))
' "$BUILD" "${apps[@]}")

for app in "${apps[@]}"; do
    found=0
    for t in "${targets[@]}"; do
        case "$t" in subprojects/"$app"/*) found=1 ;; esac
    done
    if [ "$found" -eq 0 ]; then
        echo "ERROR: $app has no installed targets in this build (is it enabled by APPS?)" >&2
        exit 1
    fi
done

echo "Building ${apps[*]} (${#targets[@]} targets)"
ninja -C "$BUILD" "${targets[@]}"

ONLY_APPS="libsingularity ${apps[*]}" bash "$PROJECT_DIR/scripts/deploy-to-host.sh"

on_host() {
    if [ -n "$container" ] && command -v host-spawn >/dev/null; then
        host-spawn sh -c "$1"
    else
        sh -c "$1"
    fi
}

restart_shell=0
for app in "${apps[@]}"; do
    case "$app" in
        singularity-shell|libsingularity) restart_shell=1 ;;
        singularity-nearby)
            on_host 'pkill -f "/libexec/singularity-nearby$"' && echo "Restarted the Nearby service" ;;
        *)
            if on_host "pgrep -f '/bin/$app( |\$)' >/dev/null"; then
                echo "$app is open: close and reopen it to use the new version"
            fi ;;
    esac
done
if [ "$restart_shell" -eq 1 ]; then
    on_host 'pkill -USR1 -f "/bin/singularity-desktop$"' && echo "Restarted the shell"
fi
