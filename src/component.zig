const std = @import("std");
const win32 = @import("./zigwin32/win32/everything.zig");

pub const Component = struct {
    state: State,
    hwnd: win32.HWND,
    fn getType(this: *Component) Type {
        return @enumFromInt(@intFromEnum(this.state));
    }
};

const Type = enum {
    Div,
    Button,
};

pub const State = union(Type) {
    Div: DivState,
    Button: ButtonState,
};

pub const DivState = struct {
    a: u8,
};

pub const ButtonState = struct {
    b: u16,
};
