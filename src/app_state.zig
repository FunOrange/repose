pub const MainAppState = struct {
    id: u32,
    start_time: i64,
};

pub const AppStateError = error{IsNull};
