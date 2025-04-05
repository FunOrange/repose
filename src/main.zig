const std = @import("std");

const win32 = @cImport({
    @cInclude("windows.h");
});

pub fn main() void {
    _ = win32.MessageBoxA(null, // HWND hWnd
        "Hello from Zig!", // LPCSTR lpText
        "Zig MessageBox", // LPCSTR lpCaption
        win32.MB_OK | win32.MB_ICONINFORMATION // UINT uType
    );
}
