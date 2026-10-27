#!/bin/bash
# oolite.sh xwayland|native [fakeinput args...]: Oolite (stock AppImage) on headless KWin; screenshot, run the fakeinput args, screenshot.
# Run with --device /dev/dri (KWin's screenshot crashes without a render node).
mode=$1; shift
unset LIBGL_ALWAYS_SOFTWARE
export XDG_RUNTIME_DIR=/tmp/xdg; mkdir -p -m 700 $XDG_RUNTIME_DIR; export WAYLAND_DISPLAY=wl0
xw=; [ $mode = xwayland ] && xw=--xwayland
KWIN_WAYLAND_NO_PERMISSION_CHECKS=1 KWIN_SCREENSHOT_NO_PERMISSION_CHECKS=1 \
  kwin_wayland --virtual --width 1280 --height 720 --socket wl0 $xw --no-lockscreen >/tmp/kwin.log 2>&1 &
for i in $(seq 50); do [ -S $XDG_RUNTIME_DIR/wl0 ] && break; sleep 0.2; done; sleep 2
if [ $mode = xwayland ]; then export DISPLAY=:$(ls /tmp/.X11-unix | sed -n 's/^X//p' | head -1) SDL_VIDEODRIVER=x11
else export SDL_VIDEODRIVER=wayland; fi
mkdir /tmp/run && cp -r /app/GameData /app/stock.AppImage /tmp/run/ && cd /tmp/run
APPIMAGE_EXTRACT_AND_RUN=1 ./stock.AppImage >/tmp/game.log 2>&1 &
sleep 35
python /usr/local/bin/shot.py /out/$mode-1-title.png
if [ $# -gt 0 ]; then fakeinput "$@"; sleep 1; python /usr/local/bin/shot.py /out/$mode-2-after.png; fi
echo "--- game log"; grep -iE "video|sdl|wayland|x11|error|driver" /tmp/game.log | head -8
