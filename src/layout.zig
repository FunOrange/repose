const std = @import("std");
const win32 = @import("./zigwin32/win32/everything.zig");

pub const Node = struct {
    hwnd: ?win32.HWND = null, // null for spacer or hidden

    // self
    size: Size = .Auto,
    alignSelf: Align = .Start,
    invisible: bool = false, // do not participate in layout + SW_HIDE

    // children
    direction: Direction = .Row,
    alignChildren: Align = .Start,
    padding: [4]u16 = .{ 0, 0, 0, 0 },
    gap: u16 = 0,

    // tree
    parent: ?*Node,
    children: std.ArrayList(Node),
};

const Size = union(enum) {
    Fr: u8,
    Fixed: i32,
    Auto: void,
};

const Direction = enum {
    Row,
    Column,
};

const Align = enum {
    Start,
    Center,
    End,
};

// some design decisions:
// no margin - just use padding
// no justify - just use spacers (hwnd = null) to fill in remaining space
// no grid
// no wrap (will implement if needed)
