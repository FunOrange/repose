const std = @import("std");
const L = std.unicode.utf8ToUtf16LeStringLiteral;
const win32 = @import("./zigwin32/win32/everything.zig");
const util = @import("./util.zig");
const color = @import("./color.zig");
const layout = @import("./layout.zig");
const app = @import("./app.zig");

const app_class = L("App");

var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
const allocator = gpa.allocator();

pub const AppState = struct {
    node_tree: *layout.Node,
};

pub fn wWinMain(
    hInstance: std.os.windows.HINSTANCE,
    _: ?std.os.windows.HINSTANCE,
    _: std.os.windows.LPWSTR,
    _: c_int,
) std.os.windows.INT {
    const hr = win32.CoInitializeEx(null, .{
        .APARTMENTTHREADED = 1,
        .DISABLE_OLE1DDE = 1,
    });
    if (win32.FAILED(hr)) {
        std.debug.print("CoInitialize error: {?}\n", .{win32.GetLastError()});
        return -1;
    }

    const class = win32.WNDCLASSW{
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hCursor = win32.LoadCursorW(null, win32.IDC_ARROW),
        .hIcon = win32.LoadIconW(null, win32.IDI_WINLOGO),
        .lpszMenuName = null,
        .style = std.mem.zeroes(win32.WNDCLASS_STYLES),
        .hbrBackground = null,
        .lpfnWndProc = WindowProc,
        .hInstance = hInstance,
        .lpszClassName = app_class,
    };
    if (win32.RegisterClassW(&class) == 0) {
        std.debug.print("RegisterClassW error: {?}\n", .{win32.GetLastError()});
        return -1;
    }

    const hwnd = win32.CreateWindowExW(
        .{}, // Optional window styles.
        app_class, // Window class
        L("Learn to Program Windows"), // Window text
        win32.WS_OVERLAPPEDWINDOW, // Window style

        // Size and position
        win32.CW_USEDEFAULT,
        win32.CW_USEDEFAULT,
        win32.CW_USEDEFAULT,
        win32.CW_USEDEFAULT,
        null, // Parent window
        null, // Menu
        null, // Instance handle
        null, // Additional application data
    );
    if (hwnd == null) {
        std.debug.print("WTF hwnd IS {?}\n", .{hwnd});
        std.debug.print("error: {?}\n", .{win32.GetLastError()});
        return -1;
    }

    _ = win32.ShowWindow(hwnd, .{
        .SHOWNORMAL = 1,
    });

    // Main message loop
    var msg: win32.MSG = std.mem.zeroes(win32.MSG);
    while (win32.GetMessageW(&msg, hwnd, 0, 0) > 0) {
        _ = win32.TranslateMessage(&msg);
        _ = win32.DispatchMessageW(&msg);
    }
    win32.CoUninitialize();
    return 0;
}

fn WindowProc(hwnd: win32.HWND, uMsg: u32, wParam: usize, lParam: isize) callconv(.c) std.os.windows.LRESULT {
    switch (uMsg) {
        win32.WM_CREATE => {
            std.debug.print("WM_CREATE\n", .{});
            const app_state = allocator.create(AppState) catch return -1;
            const node_tree = app.initNodeTree(allocator, hwnd) catch return -1;
            app_state.* = .{
                .node_tree = node_tree,
            };
            _ = win32.SetWindowLongPtrW(hwnd, win32.GWLP_USERDATA, util.ptrToIsize(app_state));
        },
        win32.WM_PAINT => {
            paintMainWindow(hwnd);
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
        win32.WM_SIZE => {
            _ = win32.InvalidateRect(hwnd, null, win32.TRUE);
        },
        win32.WM_ERASEBKGND => std.debug.print("WM_ERASEBKGND\n", .{}),
        win32.WM_QUIT => std.debug.print("WM_QUIT\n", .{}),
        win32.WM_CLOSE => std.debug.print("WM_CLOSE\n", .{}),
        win32.WM_DESTROY => {
            std.debug.print("WM_DESTROY\n", .{});

            // free resources here
            if (getAppState(hwnd)) |app_state| {
                allocator.destroy(app_state);
            }
        },
        else => {},
    }
    return win32.DefWindowProcW(hwnd, uMsg, wParam, lParam);
}

fn getAppState(hwnd: win32.HWND) ?*AppState {
    const ptr: isize = win32.GetWindowLongPtrW(hwnd, win32.GWLP_USERDATA);
    return util.isizeToPtr(AppState, ptr);
}

fn paintMainWindow(hwnd: win32.HWND) void {
    var ps: win32.PAINTSTRUCT = undefined;
    const hdc = win32.BeginPaint(hwnd, &ps) orelse return;
    const screen_rect = ps.rcPaint;

    const app_state = getAppState(hwnd) orelse return;
    layout.compute(&screen_rect, app_state.node_tree);

    paintLayoutRec(hdc, app_state.node_tree);

    _ = win32.EndPaint(hwnd, &ps);
    return;
}

fn paintLayoutRec(hdc: win32.HDC, node: *layout.Node) void {
    const rect = node.getComputedRect() catch {
        return;
    };
    const brush = win32.CreateSolidBrush(node.debug_bg);
    _ = win32.FillRect(hdc, &rect, brush);

    for (node.children.items) |*child| {
        paintLayoutRec(hdc, child);
    }
}
fn drawRect(hdc: win32.HDC, rect: win32.RECT, rgb: u32) void {
    const brush = win32.CreateSolidBrush(rgb);
    _ = win32.FillRect(hdc, &rect, brush);
}
