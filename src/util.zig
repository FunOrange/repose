const std = @import("std");
const win32 = @import("./zigwin32/win32/everything.zig");

pub fn isizeToPtr(comptime T: type, ptr: isize) ?*T {
    const u: usize = @intCast(ptr);
    return if (u == 0) null else @ptrFromInt(u);
}

pub fn ptrToIsize(ptr: ?*anyopaque) isize {
    return if (ptr == null) 0 else @intCast(@intFromPtr(ptr));
}

pub fn opaqPtrTo(comptime T: type, ptr: ?*anyopaque) ?*T {
    return @ptrCast(@alignCast(ptr));
}

pub fn rgb32(r: u8, g: u8, b: u8) u32 {
    var rgb: u32 = r;
    rgb |= @as(u32, r) << 0;
    rgb |= @as(u32, g) << 8;
    rgb |= @as(u32, b) << 16;
    return rgb;
}
