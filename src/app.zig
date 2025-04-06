const std = @import("std");
const layout = @import("./layout.zig");

pub fn initNodeTree(allocator: std.mem.Allocator) !*layout.Node {
    const head = try allocator.create(layout.Node);
    head.* = .{
        .parent = null,
        .children = std.ArrayList(layout.Node).init(allocator),
    };
    return head;
}
