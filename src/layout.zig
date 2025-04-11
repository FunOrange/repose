const std = @import("std");
const win32 = @import("./zigwin32/win32/everything.zig");
const color = @import("./color.zig");

// some design decisions:
// no margin - just use padding
// no justify - just use spacers (hwnd = null) to fill in remaining space
// no grid
// no wrap (will implement if needed)

pub const Node = struct {
    hwnd: ?win32.HWND = null, // null for spacer or hidden

    // self
    debug_bg: u32 = color.SLATE800,
    debug_border: u32 = color.SLATE400,
    size: Size = Size{ .Fr = 1 },
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

    // computated results
    computed_free_flex_space: Computation = .TBD,
    computed_x: Computation = .TBD,
    computed_y: Computation = .TBD,
    computed_width: Computation = .TBD,
    computed_height: Computation = .TBD,

    pub fn getComputedRect(this: *Node) !win32.RECT {
        const left = try switch (this.computed_x) {
            .TBD => error.ComputationNotComplete,
            .Result => |v| v,
        };
        const top = try switch (this.computed_y) {
            .TBD => error.ComputationNotComplete,
            .Result => |v| v,
        };
        const width = try switch (this.computed_width) {
            .TBD => error.ComputationNotComplete,
            .Result => |v| v,
        };
        const height = try switch (this.computed_height) {
            .TBD => error.ComputationNotComplete,
            .Result => |v| v,
        };
        return win32.RECT{
            .top = top,
            .left = left,
            .right = left + width,
            .bottom = top + height,
        };
    }
};

const Size = union(enum) {
    Fr: u8,
    Fixed: i32,
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

const Computation = union(enum) {
    TBD: void,
    Result: i32,
};

pub fn compute(screen_rect: *const win32.RECT, node_tree: *Node) void {
    const screen_width = screen_rect.right;
    const screen_height = screen_rect.bottom;
    // root is entire screen
    node_tree.computed_x = Computation{ .Result = 0 };
    node_tree.computed_y = Computation{ .Result = 0 };
    node_tree.computed_width = Computation{ .Result = screen_width };
    node_tree.computed_height = Computation{ .Result = screen_height };

    const len = node_tree.children.items.len;
    for (node_tree.children.items, 0..) |*child, i| {
        const index: i32 = @intCast(i);
        const x = index * @divTrunc(screen_width, @as(i32, @intCast(len)));
        const y = 0;
        const width = @divTrunc(screen_width, @as(i32, @intCast(len)));
        const height = screen_height;
        child.computed_x = Computation{ .Result = x };
        child.computed_y = Computation{ .Result = y };
        child.computed_width = Computation{ .Result = width };
        child.computed_height = Computation{ .Result = height };
    }
}
// fn computeLayoutRec(node_tree: *layout.Node) void {
//
// }

// pub fn resolveIntrinsicSize(node: *Node) void {
//     var rect: win32.RECT = .{};
//     _ = win32.GetWindowRect(node.hwnd, &rect);
// }
