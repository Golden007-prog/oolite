# gdb helper used by the "Debug Oolite (gdb)" launch configuration (see launch.json).
#
# Adds an "ostep" command. Plain "step" / VS Code "Step Into" skips Objective-C message
# sends: the GNUstep runtime's objc_msgSend looks up the method and tail-jumps to it, and
# gdb does not follow that jump. "ostep" single-steps through the dispatch until it reaches
# the target method, then runs to the first source line after the prologue.
#
# Use from the VS Code Debug Console with:  -exec ostep
# Debugging aid only; it is not part of the game build.

import gdb


class OStep(gdb.Command):
    """Step into an Objective-C message send (GNUstep objc_msgSend tail-jumps, so plain 'step' skips it).

    Single-steps instructions until the PC is in a different function that has line info,
    or the call returns to the starting frame's caller."""

    def __init__(self):
        super(OStep, self).__init__("ostep", gdb.COMMAND_RUNNING)

    def invoke(self, arg, from_tty):
        limit = int(arg) if arg else 5000
        start = gdb.selected_frame()
        start_fn = start.function()
        start_depth = 0
        f = start
        while f.older() is not None:
            start_depth += 1
            f = f.older()

        for _ in range(limit):
            gdb.execute("stepi", to_string=True)
            frame = gdb.selected_frame()
            sal = frame.find_sal()
            fn = frame.function()
            if sal.symtab is not None and fn is not None and fn != start_fn:
                # finish the prologue so arguments such as self are valid
                gdb.execute("next", to_string=True)
                gdb.execute("frame", to_string=False)
                return
            if sal.symtab is not None and fn == start_fn and sal.line != start.find_sal().line:
                gdb.execute("frame", to_string=False)
                return
        print("ostep: gave up after %d instructions" % limit)


OStep()
