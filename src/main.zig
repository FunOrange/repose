const std = @import("std");
const W = std.unicode.utf8ToUtf16LeStringLiteral;
const win32 = @import("./zigwin32/win32/everything.zig");

pub fn main() void {
    const utf16Message = W("Hello from ZigWin32!");
    const utf16Title = W("Zig Window");
    _ = win32.MessageBoxW(null, utf16Message, utf16Title, win32.MB_OK);
}
