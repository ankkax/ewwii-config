/* ws_wheel.c -- wheel over the workspace numbers switches workspaces.
 *
 * Selects button presses only (XInput 2, root window), so it never receives
 * keyboard events. Only wheel presses on the bar's workspace strip count: the
 * bar is 36 px high and the strip sits between x=40 and x=300.
 *
 * Build:  gcc -O2 -o ~/.local/bin/ws-wheel ws_wheel.c -lX11 -lXi
 * Run:    ws-wheel /path/to/ws_scroll.sh
 */
#include <signal.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <X11/Xlib.h>
#include <X11/extensions/XInput2.h>

int main(int argc, char **argv)
{
    if (argc < 2) {
        fprintf(stderr, "usage: %s ws_scroll.sh\n", argv[0]);
        return 1;
    }
    const char *step = argv[1];

    Display *dpy = XOpenDisplay(NULL);
    if (!dpy) return 1;

    int xi_opcode, event, error;
    if (!XQueryExtension(dpy, "XInputExtension", &xi_opcode, &event, &error))
        return 1;
    int major = 2, minor = 0;
    if (XIQueryVersion(dpy, &major, &minor) != Success)
        return 1;

    Window root = DefaultRootWindow(dpy);
    unsigned char mask_bits[XIMaskLen(XI_RawButtonPress)];
    memset(mask_bits, 0, sizeof(mask_bits));
    XISetMask(mask_bits, XI_RawButtonPress);
    XIEventMask evmask = { XIAllMasterDevices, sizeof(mask_bits), mask_bits };
    XISelectEvents(dpy, root, &evmask, 1);
    XFlush(dpy);

    signal(SIGCHLD, SIG_IGN);

    XEvent ev;
    for (;;) {
        XNextEvent(dpy, &ev);
        if (ev.xcookie.type != GenericEvent || ev.xcookie.extension != xi_opcode)
            continue;
        if (!XGetEventData(dpy, &ev.xcookie))
            continue;
        if (ev.xcookie.evtype == XI_RawButtonPress) {
            XIRawEvent *re = ev.xcookie.data;
            if (re->detail == 4 || re->detail == 5) {
                Window r, c;
                int rx, ry, wx, wy;
                unsigned int mask;
                if (XQueryPointer(dpy, root, &r, &c, &rx, &ry, &wx, &wy, &mask)
                    && ry < 36 && rx >= 40 && rx <= 300) {
                    pid_t pid = fork();
                    if (pid == 0) {
                        execl(step, step, re->detail == 4 ? "up" : "down", (char *)NULL);
                        _exit(127);
                    }
                }
            }
        }
        XFreeEventData(dpy, &ev.xcookie);
    }
}
