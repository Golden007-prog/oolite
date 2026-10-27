# Spike: drive a headless KWin with mouse, keys and screenshots

**Result: it works, using KWin's own interfaces and no extra stack.** In a container we can take screenshots, move and click the mouse,
and type keys under headless `kwin_wayland --virtual`, for native Wayland clients and XWayland clients alike. Oolite's title menu
responds to mouse clicks both ways.

## What works

| Need | How | Requirement |
|---|---|---|
| Mouse (move, press, release, drag) | `org_kde_kwin_fake_input` (v2+): `pointer_motion_absolute`, `button`. See [kwin/fakeinput.c](kwin/fakeinput.c) | `KWIN_WAYLAND_NO_PERMISSION_CHECKS=1` on **kwin_wayland** |
| Keys | the same protocol (v4): `keyboard_key` | the same |
| Screenshots | D-Bus `org.kde.KWin.ScreenShot2` (`CaptureWorkspace`, `CaptureWindow`, `CaptureArea`, `CaptureScreen`). KWin writes raw pixels into a pipe we pass it. See [kwin/shot.py](kwin/shot.py) | `KWIN_SCREENSHOT_NO_PERMISSION_CHECKS=1` on **kwin_wayland**, and a GPU render node in the container (`--device /dev/dri`) |

The framework's `uitest-fakekey` (docker/fakekey.c) already uses this protocol, but only for keys. `fakeinput` is the same code taking
a list of commands: `fakeinput move X Y | click [BTN] | down BTN | up BTN | key EVDEV | sleep MS`.

## Evidence (kwin/out/)

- **weston-terminal**, a native Wayland app ([kwin/demo.sh](kwin/demo.sh)): typed `echo hi` and the command ran (`2-typed.png`).
  Dragging the title bar moved the window exactly 200 px left and 100 px up (`3-dragged.png`). Clicking its maximise button
  maximised it (`4-maximised.png`).
- **Oolite stock AppImage** ([kwin/oolite.sh](kwin/oolite.sh)): pressing on "Game Options" moved the menu highlight there from
  "Start New Commander":
  - under XWayland (`SDL_VIDEODRIVER=x11`, `xwayland-*.png`). XTEST clicks never reached the game here, which is why `needs_mouse`
    tests are skipped on headless kwin-xwayland today. The fake-input events go through KWin itself, so XWayland clients get them.
  - as a native Wayland client (`SDL_VIDEODRIVER=wayland`, `native-*.png`).

## Gotchas found on the way

1. **Without a render node, KWin crashes on any screenshot request** (KWin 6.8.1, every capture method, every `KWIN_COMPOSE` mode).
   The backtrace ([kwin/bt.sh](kwin/bt.sh)):
   ```
   #0 KWin::RenderDevice::eglContext (this=0x0)                      src/core/renderdevice.cpp:143
   #1 KWin::ScreenShotManager::takeScreenShot (...)                  src/plugins/screenshot/screenshot.cpp:125
   ```
   With software rendering and no `/dev/dri` there is no `RenderDevice`, and the screenshot plugin dereferences it anyway. This is
   a KWin bug, worth reporting upstream. Workaround: `docker run --device /dev/dri` without `LIBGL_ALWAYS_SOFTWARE`. GitHub's
   standard runners have no GPU, so **screenshots on native KWin are local-only until KWin is fixed**. Mouse and keys need no GPU.
   This is probably the same crash behind the "headless KWin crashes on screenshot requests" note on `kwin-xwayland-headed` in
   environments.toml.
2. **The permission variables belong on the compositor.** KWin checks them in its own process, so setting them for the client
   script does nothing.
3. **With the GPU path, ScreenShot2 returns QImage format 16 (RGBX8888, RGBA byte order)**, not ARGB32. `shot.py` handles 4/5/6
   and 16/17/18.
4. **Apps that draw their own decorations need the pointer to rest before a click.** A click 20 ms after the move was ignored by
   weston-terminal's maximise button; a 300 ms hover worked. KWin-drawn decorations (Oolite's title bar) are not affected.
5. In native mode, Oolite's window is taller than a 1280x720 output, so its bottom menu row is off screen.

## Dead ends (kept for the record)

`Dockerfile`, `Dockerfile.2`–`.7` and `automate.py` came from an AI chat (Google) and don't work. They contain placeholder URLs
(`wget https://kde.org`, `urlopen("http://127.0.0")`), a "Selkies screenshot API" that doesn't exist, and X11 tools (pyautogui,
xdotool) aimed at native Wayland, where they cannot work. linuxserver/webtop adds a whole desktop and streaming stack without
solving input or capture. krfb-virtualmonitor (VNC) would combine capture and input, but it captures through KWin as well (so
probably needs the same render node) and is much heavier.

## Running it

```sh
cd tests/spike-kwinnative-automation/kwin
docker build -t spike-kwin .            # FROM oolite-uitest-wayland, adds fakeinput + python-jeepney
docker run --rm --device /dev/dri -v "$PWD":/spike:ro -v "$PWD/out":/out spike-kwin dbus-run-session -- bash /spike/demo.sh
docker run --rm --device /dev/dri -v "$PWD":/spike:ro -v "$PWD/out":/out \
  -v .../oolite-ui-test-framework/appimages:/app:ro spike-kwin dbus-run-session -- \
  bash /spike/oolite.sh xwayland move 420 430 sleep 300 move 428 434 sleep 300 down 0x110 sleep 500 up 0x110
```

[kwin/variants.sh](kwin/variants.sh) tries every capture method and compositing mode, for checking whether a newer KWin still crashes.

## Next

- Framework: replace `uitest-fakekey` with `fakeinput`, add a fake-input click for `keys = "fakeinput"` environments, and drop the
  `mouse_na` skip on kwin-xwayland (and kwin-native).
- Framework: a ScreenShot2 grab for kwin-native when `/dev/dri` is available, so its screenshot tests stop being NOT MEASURABLE locally.
- Report the null `RenderDevice` crash to KDE.
