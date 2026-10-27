#!/bin/bash
# Runs inside spike-kwin: headless native KWin, a native Wayland app, mouse + keys via fake_input, screenshots via ScreenShot2.
set -e; unset LIBGL_ALWAYS_SOFTWARE   # run in the spike-kwin image (Dockerfile here) with --device /dev/dri
export XDG_RUNTIME_DIR=/tmp/xdg; mkdir -p -m 700 $XDG_RUNTIME_DIR
export WAYLAND_DISPLAY=wl0 QT_QPA_PLATFORM=wayland
KWIN_WAYLAND_NO_PERMISSION_CHECKS=1 KWIN_SCREENSHOT_NO_PERMISSION_CHECKS=1 \
  kwin_wayland --virtual --width 1280 --height 720 --socket wl0 --no-lockscreen >/tmp/kwin.log 2>&1 &
for i in $(seq 50); do [ -S $XDG_RUNTIME_DIR/wl0 ] && break; sleep 0.2; done
sleep 2
weston-terminal >/tmp/app.log 2>&1 &
sleep 3
python /usr/local/bin/shot.py /out/1-launched.png || true
fakeinput move 400 300 click           # focus the terminal by clicking in it
# type "echo hi" Enter: evdev codes e=18 c=46 h=35 o=24 space=57 i=23 enter=28
fakeinput key 18 key 46 key 35 key 24 key 57 key 35 key 23 key 28
sleep 1
python /usr/local/bin/shot.py /out/2-typed.png || true
# drag the window by its title bar 200 px left and 100 px up
fakeinput move 500 159 down 0x110 move 450 140 move 400 100 move 300 59 up 0x110
sleep 1
python /usr/local/bin/shot.py /out/3-dragged.png || true
fakeinput move 755 60 sleep 300 move 761 60 sleep 300 click   # the maximise button (client-drawn: hover first)
sleep 1
python /usr/local/bin/shot.py /out/4-maximised.png || true
echo "--- kwin log"; grep -v "^$" /tmp/kwin.log | tail -40; cat /tmp/app.log | tail -5
