#!/bin/bash
pacman -S --noconfirm --needed python-jeepney >/dev/null 2>&1
export XDG_RUNTIME_DIR=/tmp/xdg; mkdir -p -m 700 $XDG_RUNTIME_DIR; export WAYLAND_DISPLAY=wl0
cat > /tmp/call.py <<'PY'
import os, sys, threading
from jeepney import DBusAddress, new_method_call
from jeepney.io.blocking import open_dbus_connection
a = DBusAddress("/org/kde/KWin/ScreenShot2", bus_name="org.kde.KWin.ScreenShot2", interface="org.kde.KWin.ScreenShot2")
r, w = os.pipe(); buf = bytearray()
t = threading.Thread(target=lambda: [buf.extend(b) for b in iter(lambda: os.read(r, 1 << 20), b"")]); t.start()
m = sys.argv[1]
args = {"ws": ("CaptureWorkspace", "a{sv}h", ({}, w)), "area": ("CaptureArea", "iiuua{sv}h", (0, 0, 640, 360, {}, w)),
        "screen": ("CaptureScreen", "sa{sv}h", ("Virtual-0", {}, w))}[m]
with open_dbus_connection(bus="SESSION", enable_fds=True) as c:
    rep = c.send_and_get_reply(new_method_call(a, *args), timeout=10)
os.close(w); t.join(); print(m, rep.header.message_type.name, str(rep.body)[:200], len(buf))
PY
for compose in "" O2 Q; do for m in ws area screen; do
  rm -f $XDG_RUNTIME_DIR/wl0*
  KWIN_COMPOSE=$compose KWIN_WAYLAND_NO_PERMISSION_CHECKS=1 KWIN_SCREENSHOT_NO_PERMISSION_CHECKS=1 kwin_wayland --virtual --width 640 --height 360 --socket wl0 --no-lockscreen >/tmp/k.log 2>&1 &
  K=$!; sleep 3
  echo "== compose=${compose:-default} method=$m: $(timeout 15 python /tmp/call.py $m 2>&1 | tail -1)"
  kill -0 $K 2>/dev/null && echo "   kwin alive" || { echo "   kwin died"; grep -iE "segv|fatal|error|warn|backend|compos|opengl|qpainter" /tmp/k.log | head -8 | sed 's/^/   | /'; }
  kill $K 2>/dev/null; wait $K 2>/dev/null
done; done
kwin_wayland --version
