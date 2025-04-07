const std = @import("std");
const win32 = @import("./zigwin32/win32/everything.zig");
const layout = @import("./layout.zig");

pub fn initNodeTree(allocator: std.mem.Allocator, hwnd: win32.HWND) !*layout.Node {
    const head = try allocator.create(layout.Node);
    head.* = .{
        .hwnd = hwnd,
        .parent = null,
        .children = std.ArrayList(layout.Node).init(allocator),
    };
    return head;
}
