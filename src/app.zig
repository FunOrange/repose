const std = @import("std");
const win32 = @import("./zigwin32/win32/everything.zig");
const layout = @import("./layout.zig");
const color = @import("./color.zig");

pub fn initNodeTree(allocator: std.mem.Allocator, hwnd: win32.HWND) !*layout.Node {
    const head = try allocator.create(layout.Node);
    head.* = .{
        .hwnd = hwnd,
        .size = .{ .Fr = 1 },
        .direction = .Row,
        .gap = 0,
        .parent = null,
        .children = std.ArrayList(layout.Node).init(allocator),
    };
    try head.children.append(.{
        .hwnd = null,
        .debug_bg = color.BLUE600,
        .parent = head,
        .children = std.ArrayList(layout.Node).init(allocator),
    });
    try head.children.append(.{
        .hwnd = null,
        .debug_bg = color.EMERALD600,
        .parent = head,
        .children = std.ArrayList(layout.Node).init(allocator),
    });
    try head.children.append(.{
        .hwnd = null,
        .debug_bg = color.AMBER600,
        .parent = head,
        .children = std.ArrayList(layout.Node).init(allocator),
    });
    return head;
}
