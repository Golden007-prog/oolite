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
