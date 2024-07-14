const std = @import("std");
const testing = std.testing;

const Ringbuffer = @import("core/ringbuffer.zig");

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test {
    _ = @import("core/ringbuffer.zig");
    _ = @import("core/stack.zig");
}
