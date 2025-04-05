const std = @import("std");
const L = std.unicode.utf8ToUtf16LeStringLiteral;
const win32 = @import("./zigwin32/win32/everything.zig");

pub fn wWinMain(
    hInstance: std.os.windows.HINSTANCE,
    _: ?std.os.windows.HINSTANCE,
    _: std.os.windows.LPWSTR,
    _: c_int,
) std.os.windows.INT {
    const className = L("Window Class");
    const wc = win32.WNDCLASSW{
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hCursor = win32.LoadCursorW(null, win32.IDC_ARROW),
        .hIcon = win32.LoadIconW(null, win32.IDI_WINLOGO),
        .lpszMenuName = null,
        .style = std.mem.zeroes(win32.WNDCLASS_STYLES),
        .hbrBackground = null,
        .lpfnWndProc = WindowProc,
        .hInstance = hInstance,
        .lpszClassName = className,
    };

    const err = win32.RegisterClassW(&wc);
    if (err == 0) {
        std.debug.print("WTF RegisterClassW returned 0\n", .{});
        std.debug.print("error: {?}\n", .{win32.GetLastError()});
        return 0;
    }

    const hwnd = win32.CreateWindowExW(.{}, // Optional window styles.
        className, // Window class
        L("Learn to Program Windows"), // Window text
        win32.WS_OVERLAPPEDWINDOW, // Window style

        // Size and position
        win32.CW_USEDEFAULT, win32.CW_USEDEFAULT, win32.CW_USEDEFAULT, win32.CW_USEDEFAULT, null, // Parent window
        null, // Menu
        null, // Instance handle
        null // Additional application data
    );
    if (hwnd == null) {
        std.debug.print("WTF hwnd IS {?}\n", .{hwnd});
        std.debug.print("error: {?}\n", .{win32.GetLastError()});
        return -1;
    }
    std.debug.print("Showing window! hwnd: {?}\n", .{hwnd});

    _ = win32.ShowWindow(hwnd, .{
        .SHOWNORMAL = 1,
    });

    //Main message loop
    var msg: win32.MSG = std.mem.zeroes(win32.MSG);
    while (win32.GetMessageW(&msg, hwnd, 0, 0) > 0) {
        _ = win32.TranslateMessage(&msg);
        _ = win32.DispatchMessageW(&msg);
    }
    return 0;
}

// fn WindowProc(hwnd: *win32.foundation.HWND, uMsg: u32, wParam: usize, lParam: isize) callconv(.c) isize {
fn WindowProc(hwnd: win32.HWND, uMsg: u32, wParam: usize, lParam: isize) callconv(.c) isize {
    return win32.DefWindowProcW(hwnd, uMsg, wParam, lParam);
}
