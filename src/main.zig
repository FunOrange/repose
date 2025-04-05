const std = @import("std");
const L = std.unicode.utf8ToUtf16LeStringLiteral;
const win32 = @import("./zigwin32/win32/everything.zig");
const AppState = @import("./app_state.zig").AppState;
const AppStateError = @import("./app_state.zig").AppStateError;

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

    const allocator = std.heap.page_allocator;
    const app_state = allocator.create(AppState) catch return -1;
    app_state.* = .{
        .start_time = std.time.timestamp(),
    };

    const hwnd = win32.CreateWindowExW(.{}, // Optional window styles.
        className, // Window class
        L("Learn to Program Windows"), // Window text
        win32.WS_OVERLAPPEDWINDOW, // Window style

        // Size and position
        win32.CW_USEDEFAULT, win32.CW_USEDEFAULT, win32.CW_USEDEFAULT, win32.CW_USEDEFAULT, null, // Parent window
        null, // Menu
        null, // Instance handle
        app_state // Additional application data
    );
    if (hwnd == null) {
        std.debug.print("WTF hwnd IS {?}\n", .{hwnd});
        std.debug.print("error: {?}\n", .{win32.GetLastError()});
        return -1;
    }

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

fn to_usize(num: anytype) usize {
    return @intCast(num);
}
fn WindowProc(hwnd: win32.HWND, uMsg: u32, wParam: usize, lParam: isize) callconv(.c) isize {
    switch (uMsg) {
        win32.WM_CREATE => {
            std.debug.print("WM_CREATE\n", .{});
            const app_state_result: AppStateError!*AppState = blk: {
                const pCreate: *win32.CREATESTRUCTW = @ptrFromInt(to_usize(lParam));
                const maybe_app_state: ?*AppState = @ptrCast(@alignCast(pCreate.lpCreateParams));
                break :blk maybe_app_state orelse AppStateError.IsNull;
            };
            const app_state = app_state_result catch return -1;
            std.debug.print("{}\n", .{app_state});
        },
        win32.WM_PAINT => {
            std.debug.print("WM_PAINT\n", .{});
            var ps: win32.PAINTSTRUCT = undefined;
            const hdc = win32.BeginPaint(hwnd, &ps);

            // #region paint
            const hbr = win32.CreateSolidBrush(@intFromEnum(win32.COLOR_WINDOWFRAME));
            _ = win32.FillRect(hdc, &ps.rcPaint, hbr);
            // #endregion paint

            _ = win32.EndPaint(hwnd, &ps);
            return 0;
        },
        win32.WM_DROPFILES => std.debug.print("WM_DROPFILES\n", .{}),
        win32.WM_ENABLE => std.debug.print("WM_ENABLE\n", .{}),
        win32.WM_CONTEXTMENU => std.debug.print("WM_CONTEXTMENU\n", .{}),
        win32.WM_HOTKEY => std.debug.print("WM_HOTKEY\n", .{}),
        win32.WM_TIMER => std.debug.print("WM_TIMER\n", .{}),
        win32.WM_NOTIFY => std.debug.print("WM_NOTIFY\n", .{}),
        win32.WM_COMMAND => std.debug.print("WM_COMMAND\n", .{}),
        win32.WM_INPUT => std.debug.print("WM_INPUT\n", .{}),
        win32.WM_MOUSEWHEEL => std.debug.print("WM_MOUSEWHEEL\n", .{}),
        win32.WM_RBUTTONUP => std.debug.print("WM_RBUTTONUP\n", .{}),
        win32.WM_RBUTTONDOWN => std.debug.print("WM_RBUTTONDOWN\n", .{}),
        win32.WM_LBUTTONUP => std.debug.print("WM_LBUTTONUP\n", .{}),
        win32.WM_LBUTTONDOWN => std.debug.print("WM_LBUTTONDOWN\n", .{}),
        win32.WM_CHAR => std.debug.print("WM_CHAR\n", .{}),
        win32.WM_KEYUP => std.debug.print("WM_KEYUP\n", .{}),
        win32.WM_KEYDOWN => std.debug.print("WM_KEYDOWN\n", .{}),
        win32.WM_KILLFOCUS => std.debug.print("WM_KILLFOCUS\n", .{}),
        win32.WM_SETFOCUS => std.debug.print("WM_SETFOCUS\n", .{}),
        win32.WM_ACTIVATE => std.debug.print("WM_ACTIVATE\n", .{}),
        win32.WM_SIZE => std.debug.print("WM_SIZE\n", .{}),
        win32.WM_ERASEBKGND => std.debug.print("WM_ERASEBKGND\n", .{}),
        win32.WM_QUIT => std.debug.print("WM_QUIT\n", .{}),
        win32.WM_CLOSE => std.debug.print("WM_CLOSE\n", .{}),
        win32.WM_DESTROY => std.debug.print("WM_DESTROY\n", .{}),
        else => {},
    }
    return win32.DefWindowProcW(hwnd, uMsg, wParam, lParam);
}
