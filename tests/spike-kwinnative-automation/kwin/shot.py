"""shot.py OUT.png [window-uuid]: screenshot a headless KWin through its org.kde.KWin.ScreenShot2 D-Bus interface.
KWin must run with KWIN_SCREENSHOT_NO_PERMISSION_CHECKS=1. KWin writes raw pixels into a pipe we pass it; the reply gives the layout."""
import os, sys, threading
from jeepney import DBusAddress, new_method_call
from jeepney.io.blocking import open_dbus_connection
from PIL import Image

out, uuid = sys.argv[1], (sys.argv[2] if len(sys.argv) > 2 else None)
kwin = DBusAddress("/org/kde/KWin/ScreenShot2", bus_name="org.kde.KWin.ScreenShot2", interface="org.kde.KWin.ScreenShot2")
rfd, wfd = os.pipe()
data = bytearray()
reader = threading.Thread(target=lambda: [data.extend(b) for b in iter(lambda: os.read(rfd, 1 << 20), b"")])
reader.start()
opts = {"include-cursor": ("b", False), "native-resolution": ("b", True)}
msg = (new_method_call(kwin, "CaptureWindow", "sa{sv}h", (uuid, opts, wfd)) if uuid
       else new_method_call(kwin, "CaptureWorkspace", "a{sv}h", (opts, wfd)))
with open_dbus_connection(bus="SESSION", enable_fds=True) as conn:
    reply = conn.send_and_get_reply(msg, timeout=10)
os.close(wfd); reader.join(); os.close(rfd)
if reply.header.message_type.name == "error":
    sys.exit("ScreenShot2 error: %s" % (reply.body,))
meta = {k: v[1] for k, v in reply.body[0].items()}
w, h, stride, fmt = meta["width"], meta["height"], meta["stride"], meta["format"]
# QImage formats: 4/5/6 = (A)RGB32 (BGRA bytes on little-endian); 16/17/18 = RGBX/RGBA8888 (RGBA bytes, what the GL path returns)
order = {4: "BGRA", 5: "BGRA", 6: "BGRA", 16: "RGBA", 17: "RGBA", 18: "RGBA"}.get(fmt)
if not order: sys.exit("unhandled QImage format %d" % fmt)
Image.frombuffer("RGBA", (w, h), bytes(data), "raw", order, stride, 1).convert("RGB").save(out)
print("saved %s %dx%d" % (out, w, h))
