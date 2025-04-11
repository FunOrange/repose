const std = @import("std");
const L = std.unicode.utf8ToUtf16LeStringLiteral;
const win32 = @import("./zigwin32/win32/everything.zig");
const d2d1 = @import("./zigwin32/win32/graphics/direct2d.zig");
const dw = @import("./zigwin32/win32/graphics/direct_write.zig");
const d2d1helper = @import("./zigwin32/win32/graphics/direct2d/d2d1helper.zig");
const Guid = @import("./zigwin32/win32/zig.zig").Guid;
const com = @import("./zigwin32/win32/system/com.zig");
const util = @import("./util.zig");
const color = @import("./color.zig");
const layout = @import("./layout.zig");
const app = @import("./app.zig");

const app_class = L("App");

var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
const allocator = gpa.allocator();

pub const AppState = struct {
    d2d_factory: *win32.ID2D1Factory,
    text_format: *dw.IDWriteTextFormat,
    render_target: ?*win32.ID2D1RenderTarget,
    node_tree: *layout.Node,
};

pub fn wWinMain(
    hInstance: std.os.windows.HINSTANCE,
    _: ?std.os.windows.HINSTANCE,
    _: std.os.windows.LPWSTR,
    _: c_int,
) std.os.windows.INT {
    _ = win32.HeapSetInformation(null, win32.HeapEnableTerminationOnCorruption, null, 0);

    var hr = win32.CoInitializeEx(null, .{
        .APARTMENTTHREADED = 1,
        .DISABLE_OLE1DDE = 1,
    });
    defer win32.CoUninitialize();

    if (win32.FAILED(hr)) {
        std.debug.print("CoInitialize hr: {?}\n", .{hr});
        return -1;
    }

    // #region init Direct2D stuff
    var d2d_factory: *anyopaque = allocator.create(win32.ID2D1Factory) catch return -1;
    hr = win32.D2D1CreateFactory(win32.D2D1_FACTORY_TYPE_SINGLE_THREADED, win32.IID_ID2D1Factory, null, &d2d_factory);
    if (win32.FAILED(hr)) {
        std.debug.print("D2D1CreateFactory hr: {?}\n", .{hr});
        return -1;
    }

    // Create a DirectWrite factory.
    var write_factory: *dw.IDWriteFactory = undefined;
    hr = dw.DWriteCreateFactory(dw.DWRITE_FACTORY_TYPE_SHARED, dw.IID_IDWriteFactory1, @ptrCast(&write_factory));
    if (win32.FAILED(hr)) {
        std.debug.print("DWriteCreateFactory hr: {?}\n", .{hr});
        return -1;
    }

    // Create a DirectWrite text format object.
    const font_name = L("Verdana");
    const font_size: f32 = 50;
    const locale = L("");
    var text_format: *dw.IDWriteTextFormat = undefined;
    hr = write_factory.CreateTextFormat(font_name, null, dw.DWRITE_FONT_WEIGHT_NORMAL, dw.DWRITE_FONT_STYLE_NORMAL, dw.DWRITE_FONT_STRETCH_NORMAL, font_size, locale, &text_format);
    if (win32.FAILED(hr)) {
        std.debug.print("CreateTextFormat hr: {?}\n", .{hr});
        return -1;
    }
    text_format.SetTextAlignment(.CENTER);
    text_format.SetParagraphAlignment(.CENTER);
    // #endregion init Direct2D stuff

    // Register the window class
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

    const app_state = allocator.create(AppState) catch return -1;
    var node_tree = app.initNodeTree(allocator) catch return -1;
    app_state.* = .{
        .d2d_factory = @ptrCast(@alignCast(d2d_factory)),
        .render_target = null,
        .text_format = text_format,
        .node_tree = node_tree,
    };
    // FLOAT dpiX, dpiY;
    // m_pD2DFactory->GetDesktopDpi(&dpiX, &dpiY);
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
        hInstance, // Instance handle
        app_state, // Additional application data
    );
    if (hwnd == null) {
        std.debug.print("WTF hwnd IS {?}\n", .{hwnd});
        std.debug.print("error: {?}\n", .{win32.GetLastError()});
        return -1;
    }
    node_tree.hwnd = hwnd;

    _ = win32.ShowWindow(hwnd, .{
        .SHOWNORMAL = 1,
    });

    // Main message loop
    var msg: win32.MSG = std.mem.zeroes(win32.MSG);
    while (win32.GetMessageW(&msg, hwnd, 0, 0) > 0) {
        _ = win32.TranslateMessage(&msg);
        _ = win32.DispatchMessageW(&msg);
    }

    return 0;
}

fn WindowProc(hwnd: win32.HWND, uMsg: u32, wParam: usize, lParam: isize) callconv(.c) std.os.windows.LRESULT {
    switch (uMsg) {
        win32.WM_CREATE => {
            std.debug.print("WM_CREATE\n", .{});
            const create_struct = util.isizeToPtr(win32.CREATESTRUCTW, lParam) orelse return -1;
            const maybe_app_state: ?*AppState = @ptrCast(@alignCast(create_struct.lpCreateParams));
            const app_state = maybe_app_state orelse return -1;
            _ = win32.SetWindowLongPtrW(hwnd, win32.GWLP_USERDATA, util.ptrToIsize(app_state));
        },
        win32.WM_SIZE => {
            const app_state = getAppState(hwnd) orelse return -1;
            if (app_state.render_target) |render_target| {
                const size: win32.D2D_SIZE_U = .{
                    .width = util.LOWORD(lParam),
                    .height = util.HIWORD(lParam),
                };
                const hwnd_render_target: *win32.ID2D1HwndRenderTarget = @ptrCast(render_target);
                _ = hwnd_render_target.Resize(&size);
            }

            // _ = win32.InvalidateRect(hwnd, null, win32.TRUE);
        },
        win32.WM_PAINT, win32.WM_DISPLAYCHANGE => {
            var ps: win32.PAINTSTRUCT = undefined;
            const hdc = win32.BeginPaint(hwnd, &ps) orelse return -1;

            // d2dRender(hwnd);
            gdiRender(hwnd, hdc, &ps);

            _ = win32.EndPaint(hwnd, &ps);
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
        // win32.WM_ERASEBKGND => std.debug.print("WM_ERASEBKGND\n", .{}),
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

fn d2dRender(hwnd: win32.HWND) void {
    const app_state = getAppState(hwnd) orelse return;

    var rc: win32.RECT = undefined;
    _ = win32.GetClientRect(hwnd, &rc);

    const size: win32.D2D_SIZE_U = .{ .width = @intCast(rc.right - rc.left), .height = @intCast(rc.bottom - rc.top) };

    // create render target
    var render_target: *win32.ID2D1RenderTarget = undefined;
    const render_target_properties = d2d1helper.RenderTargetProperties();
    const hwnd_render_target_properties = d2d1helper.HwndRenderTargetProperties(hwnd, size);
    var hr = app_state.d2d_factory.CreateHwndRenderTarget(
        &render_target_properties,
        &hwnd_render_target_properties,
        &render_target,
    );
    if (win32.FAILED(hr)) {
        std.debug.print("CreateHwndRenderTarget hr: {?}\n", .{hr});
        return;
    }
    app_state.render_target = render_target;
    defer app_state.render_target = null;

    // create solid brush
    var black_brush: *win32.ID2D1SolidColorBrush = undefined;
    const black = win32.D2D_COLOR_F{
        .r = 20,
        .g = 20,
        .b = 20,
        .a = 255,
    };
    hr = render_target.CreateSolidColorBrush(&black, null, &black_brush);
    if (win32.FAILED(hr)) {
        std.debug.print("CreateSolidColorBrush hr: {?}\n", .{hr});
        return;
    }

    // #region begin drawing stuff
    // if (!(render_target.CheckWindowState() & D2D1_WINDOW_STATE_OCCLUDED)) {
    // Retrieve the size of the render target.
    const render_target_size = render_target.GetSize();

    render_target.BeginDraw();

    var identity = std.mem.zeroes([6]f32);
    identity[0] = 1;
    identity[1] = 0;
    identity[2] = 0;
    identity[3] = 1;
    identity[4] = 0;
    identity[5] = 0;
    render_target.SetTransform(@ptrCast(&identity));

    const white = win32.D2D_COLOR_F{
        .r = 255,
        .g = 255,
        .b = 255,
        .a = 255,
    };
    render_target.Clear(&white);

    const hello_world = L("Hello world");
    const rect = win32.D2D_RECT_F{
        .left = 0,
        .top = 0,
        .right = render_target_size.width,
        .bottom = render_target_size.height,
    };
    render_target.DrawText(hello_world, hello_world.len - 1, app_state.text_format, &rect, @ptrCast(black_brush), .{}, .NATURAL);

    hr = render_target.EndDraw(null, null);

    if (hr == win32.D2DERR_RECREATE_TARGET) {
        hr = win32.S_OK;
        // DiscardDeviceResources();
    }
    // }
    // #endregion begin drawing stuff

    // release shit here
}

fn gdiRender(hwnd: win32.HWND, hdc: win32.HDC, ps: *win32.PAINTSTRUCT) void {
    const app_state = getAppState(hwnd) orelse return;

    const screen_rect = ps.rcPaint;
    layout.compute(&screen_rect, app_state.node_tree);

    paintLayoutRec(hdc, app_state.node_tree);

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

fn createDeviceIndependentResources() void {
    // static const WCHAR msc_fontName[] = L"Verdana";
    // static const FLOAT msc_fontSize = 50;
    // HRESULT hr;
    // ID2D1GeometrySink *pSink = NULL;
    //
    // // Create a Direct2D factory.
    // const hr = win32.D2D1CreateFactory(win32.D2D1_FACTORY_TYPE_SINGLE_THREADED, win32.IID_ID2D1Factory, .{}, &d2d_factory);
    //
    // if (SUCCEEDED(hr))
    // {
    //     // Create a DirectWrite factory.
    //     hr = DWriteCreateFactory(
    //         DWRITE_FACTORY_TYPE_SHARED,
    //         __uuidof(write_factory),
    //         reinterpret_cast<IUnknown **>(&write_factory)
    //         );
    // }
    // if (SUCCEEDED(hr))
    // {
    //     // Create a DirectWrite text format object.
    //     hr = write_factory->CreateTextFormat(
    //         msc_fontName,
    //         NULL,
    //         DWRITE_FONT_WEIGHT_NORMAL,
    //         DWRITE_FONT_STYLE_NORMAL,
    //         DWRITE_FONT_STRETCH_NORMAL,
    //         msc_fontSize,
    //         L"", //locale
    //         &m_pTextFormat
    //         );
    // }
    // if (SUCCEEDED(hr))
    // {
    //     // Center the text horizontally and vertically.
    //     m_pTextFormat->SetTextAlignment(DWRITE_TEXT_ALIGNMENT_CENTER);
    //
    //     m_pTextFormat->SetParagraphAlignment(DWRITE_PARAGRAPH_ALIGNMENT_CENTER);
    //
    // }
    //
    // SafeRelease(&pSink);
    //
    // return hr;
    return 0;
}
