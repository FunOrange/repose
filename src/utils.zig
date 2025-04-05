const std = @import("std");

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
