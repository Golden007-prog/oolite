#!/bin/bash
pacman -S --noconfirm --needed python-jeepney gdb >/dev/null 2>&1
export XDG_RUNTIME_DIR=/tmp/xdg; mkdir -p -m 700 $XDG_RUNTIME_DIR; export WAYLAND_DISPLAY=wl0
export DEBUGINFOD_URLS=https://debuginfod.archlinux.org
KWIN_WAYLAND_NO_PERMISSION_CHECKS=1 KWIN_SCREENSHOT_NO_PERMISSION_CHECKS=1 \
 gdb -q -batch -ex "set debuginfod enabled on" -ex run -ex "bt 25" --args kwin_wayland --virtual --width 640 --height 360 --socket wl0 --no-lockscreen >/tmp/gdb.log 2>&1 &
for i in $(seq 300); do dbus-send --session --print-reply --dest=org.freedesktop.DBus / org.freedesktop.DBus.ListNames 2>/dev/null | grep -q ScreenShot2 && break; sleep 1; done; sleep 3
timeout 60 python /spike/capture.py ws 2>/dev/null; sleep 120
grep -A30 "SIGSEGV" /tmp/gdb.log | grep -E "^#|SIGSEGV" | cut -c1-220
