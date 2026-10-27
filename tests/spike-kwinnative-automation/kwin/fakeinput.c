/* fakeinput: drive a headless KWin through org_kde_kwin_fake_input. KWin must run with KWIN_WAYLAND_NO_PERMISSION_CHECKS=1.
   Usage: fakeinput CMD...  where CMD is  move X Y | click [BTN] | down BTN | up BTN | key EVDEV_CODE | sleep MS
   e.g.  fakeinput move 640 360 click   /   fakeinput key 2 key 28   (BTN default 0x110 = BTN_LEFT) */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <wayland-client.h>
#include "fake-input-client-protocol.h"

static struct org_kde_kwin_fake_input *fi;
static uint32_t fiver;

static void reg(void *d, struct wl_registry *r, uint32_t name, const char *iface, uint32_t ver) {
    if (!strcmp(iface, "org_kde_kwin_fake_input"))
        fi = wl_registry_bind(r, name, &org_kde_kwin_fake_input_interface, fiver = ver < 4 ? ver : 4);
}
static void rem(void *d, struct wl_registry *r, uint32_t n) {}
static const struct wl_registry_listener rl = { reg, rem };

int main(int argc, char **argv) {
    struct wl_display *d = wl_display_connect(NULL);
    if (!d) { fprintf(stderr, "no wayland display\n"); return 2; }
    struct wl_registry *r = wl_display_get_registry(d);
    wl_registry_add_listener(r, &rl, NULL);
    wl_display_roundtrip(d);
    if (!fi) { fprintf(stderr, "no org_kde_kwin_fake_input global\n"); return 3; }
    org_kde_kwin_fake_input_authenticate(fi, "spike", "test automation");
    for (int i = 1; i < argc; i++) {
        const char *c = argv[i];
        if (!strcmp(c, "move") && i + 2 < argc) {
            if (fiver < 2) { fprintf(stderr, "fake_input v%u has no absolute motion\n", fiver); return 3; }
            org_kde_kwin_fake_input_pointer_motion_absolute(fi, wl_fixed_from_double(atof(argv[i+1])), wl_fixed_from_double(atof(argv[i+2])));
            i += 2;
        } else if (!strcmp(c, "click")) {
            uint32_t b = (i + 1 < argc && strtoul(argv[i+1], NULL, 0)) ? strtoul(argv[++i], NULL, 0) : 0x110;
            org_kde_kwin_fake_input_button(fi, b, WL_POINTER_BUTTON_STATE_PRESSED); wl_display_roundtrip(d); usleep(50000);
            org_kde_kwin_fake_input_button(fi, b, WL_POINTER_BUTTON_STATE_RELEASED);
        } else if ((!strcmp(c, "down") || !strcmp(c, "up")) && i + 1 < argc) {
            org_kde_kwin_fake_input_button(fi, strtoul(argv[++i], NULL, 0), c[0] == 'd' ? WL_POINTER_BUTTON_STATE_PRESSED : WL_POINTER_BUTTON_STATE_RELEASED);
        } else if (!strcmp(c, "key") && i + 1 < argc) {
            if (fiver < 4) { fprintf(stderr, "fake_input v%u has no keyboard\n", fiver); return 3; }
            uint32_t k = strtoul(argv[++i], NULL, 0);
            org_kde_kwin_fake_input_keyboard_key(fi, k, WL_KEYBOARD_KEY_STATE_PRESSED); wl_display_roundtrip(d); usleep(30000);
            org_kde_kwin_fake_input_keyboard_key(fi, k, WL_KEYBOARD_KEY_STATE_RELEASED);
        } else if (!strcmp(c, "sleep") && i + 1 < argc) {
            usleep(atoi(argv[++i]) * 1000);
        } else { fprintf(stderr, "bad command: %s\n", c); return 2; }
        wl_display_roundtrip(d); usleep(20000);
    }
    return 0;
}
