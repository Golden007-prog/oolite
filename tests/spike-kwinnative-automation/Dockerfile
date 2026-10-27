# dockerfile for setting up a headless KWin Wayland environment with automation tools and a Calculator AppImage
# automation setup for KWin Wayland with a Calculator AppImage

FROM ubuntu:24.04

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install KWin, Wayland backend, D-Bus, and Python dependencies
RUN apt-get update && apt-get install -y \
    kwin-wayland \
    kwin-wayland-backend-virtual \
    dbus-x11 \
    python3 \
    python3-pip \
    python3-venv \
    wget \
    libgl1-mesa-dri \
    libgl1 \
    libglx0 \
    fuse3 \
    libfuse2 \
    && rm -rf /var/lib/apt/lists/*
    
# 2. Set up a dedicated Python Virtual Environment to keep dependencies clean
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Install automation tools (PyAutoGUI requires Xlib fallbacks, Pillow captures screens)
RUN pip install --no-cache-dir pyautogui pillow dbus-python

# 3. Download an AppImage Calculator (e.g., KCalc AppImage package or standard build)
# Note: AppImages usually require FUSE which can fail inside basic Docker configurations. 
# We work around this by automatically extracting the AppImage into an execution directory.
WORKDIR /app
RUN wget -O kcalc.AppImage "https://kde.org" || \
    wget -O kcalc.AppImage "https://github.com"
RUN chmod +x kcalc.AppImage && ./kcalc.AppImage --appimage-extract && mv squashfs-root calculator-app

# 4. Global KWin Permission Override Variables
ENV KWIN_WAYLAND_NO_PERMISSION_CHECKS=1
ENV KWIN_SCREENSHOT_NO_PERMISSION_CHECKS=1
ENV XDG_RUNTIME_DIR=/tmp/runtime-dir
ENV WAYLAND_DISPLAY=wayland-0

# Create the runtime directory required by Wayland
RUN mkdir -p $XDG_RUNTIME_DIR && chmod 700 $XDG_RUNTIME_DIR

# Copy our automation controller script
COPY automate.py /app/automate.py

# Launch a D-Bus instance, spin up a virtual/headless KWin compositor, and run the script
CMD dbus-run-session -- kwin_wayland --headless --virtual --width 1280 --height 720 python3 /app/automate.py
