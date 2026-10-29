#!/bin/sh
# Escalate once: run0 on systemd hosts, otherwise sudo or doas (Void).
if command -v run0 >/dev/null 2>&1; then
    if command -v pkttyagent >/dev/null 2>&1 && [ -t 0 ]; then
        timeout --foreground 900 pkttyagent --process $$ &
        sleep 0.3
    fi
    exec run0 "$@"
elif command -v sudo >/dev/null 2>&1; then
    exec sudo "$@"
elif command -v doas >/dev/null 2>&1; then
    exec doas "$@"
fi
echo "ERROR: need root (run as root, or install run0/sudo/doas)." >&2
exit 1
