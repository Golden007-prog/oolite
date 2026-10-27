Act as a Linux systems engineer. Regenerate a functional Docker stack to automate a GUI AppImage inside a headless KWin Wayland container without any permission/security blockades. 

Provide two separate, complete files with no conversational fluff:

1. A "Dockerfile" based on ubuntu:24.04 that:
- Installs kwin-wayland, kwin-wayland-backend-virtual, dbus-x11, python3-venv, and modern graphics packages (libgl1, libglx0, libgl1-mesa-dri, fuse3, libfuse2).
- Sets up a clean python venv and pip installs pyautogui, pillow, and dbus-python.
- Downloads a calculator AppImage (such as KCalc) and extracts it into an execution folder (/app/calculator-app) to bypass FUSE container restrictions.
- Globally exports KWIN_WAYLAND_NO_PERMISSION_CHECKS=1 and KWIN_SCREENSHOT_NO_PERMISSION_CHECKS=1 alongside required Wayland/X11 environment variables.
- Uses CMD with dbus-run-session to spin up `kwin_wayland --headless --virtual --width 1280 --height 720` and immediately fires off a controller script.

2. A Python script named "automate.py" that:
- Executes right alongside KWin inside the container.
- Launches the extracted AppImage binary using Xwayland fallback compatibility (DISPLAY=:0).
- Delays to allow the UI to load, then leverages PyAutoGUI to simulate mouse movements, inputs numeric key sequences (e.g., '123+456='), and presses enter.
- Takes a full virtual framebuffer screenshot via PyAutoGUI and saves it flawlessly to `/app/output_screenshot.png`.
