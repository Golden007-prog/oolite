# The framework's wayland image plus this spike's tools: fakeinput (mouse + keys via KWin fake-input) and jeepney for shot.py.
FROM oolite-uitest-wayland:latest
COPY fakeinput.c /tmp/fakeinput.c
RUN pacman -S --noconfirm --needed gcc pkgconf plasma-wayland-protocols python-jeepney >/dev/null && cd /tmp \
 && wayland-scanner client-header /usr/share/plasma-wayland-protocols/fake-input.xml fake-input-client-protocol.h \
 && wayland-scanner private-code /usr/share/plasma-wayland-protocols/fake-input.xml fake-input-protocol.c \
 && gcc -O2 -o /usr/local/bin/fakeinput fakeinput.c fake-input-protocol.c -I. $(pkg-config --cflags --libs wayland-client) \
 && rm -f /tmp/fake*
COPY shot.py /usr/local/bin/shot.py
