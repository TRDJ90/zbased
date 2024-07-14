const std = @import("std");
const expect = std.testing.expect;

fn Stack(comptime T: type) type {
    return struct {
        const Self = @This();

        items: []T,
        head: usize,
        capacity: usize,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator, capacity: usize) !Self {
            const items_buffer = try allocator.alloc(T, capacity);
            @memset(items_buffer, 0);

            return .{
                .head = 0,
                .capacity = capacity,
                .items = items_buffer,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.items);
        }

        pub fn push(self: *Self, item: T) !void {
            if (self.head == self.capacity) return error.StackFull;
            self.items[self.head] = item;
            // update new head position
            self.head += 1;
        }

        pub fn pop(self: *Self) ?T {
            if (self.head == 0) return null;

            self.head -= 1;
            return self.items[self.head];
        }

        pub fn peek(self: *Self) ?*T {
            if (self.head == 0) return null;
            return &self.items[self.head - 1];
        }
    };
}

test "Initialize stack" {
    var stack = try Stack(u8).init(std.testing.allocator, 10);
    defer stack.deinit();

    try expect(stack.head == 0);
    try expect(stack.capacity == 10);
}

test "push item on stack" {
    var stack = try Stack(u8).init(std.testing.allocator, 10);
    defer stack.deinit();

    try stack.push(10);

    try expect(stack.head == 1);
    try expect(stack.items[stack.head - 1] == 10);
}

test "pop item off stack" {
    var stack = try Stack(u8).init(std.testing.allocator, 10);
    defer stack.deinit();

    try stack.push(1);
    try stack.push(2);

    const item = stack.pop();

    try expect(stack.head == 1);
    try expect(item.? == 2);

    // the Stack should now be empty after this pop.
    _ = stack.pop();
    const item_null = stack.pop();

    try expect(item_null == null);
}

test "peek item on stack" {
    var stack = try Stack(u8).init(std.testing.allocator, 10);
    defer stack.deinit();

    try stack.push(1);
    try stack.push(2);

    const item = stack.peek();

    try expect(item.?.* == 2);
}

test "User iteraction with stack" {
    var stack = try Stack(u8).init(std.testing.allocator, 2);
    defer stack.deinit();

    try stack.push(1);
    try stack.push(2);

    const peeked_item = stack.peek();
    const item = stack.pop();

    try expect(peeked_item.?.* == 2);
    try expect(item.? == 2);

    const peeked_item_2 = stack.peek();
    const item2 = stack.pop();
    const item_null = stack.pop();

    try expect(peeked_item_2.?.* == 1);
    try expect(item2.? == 1);
    try expect(item_null == null);

    // overflow stack scenario
    try stack.push(1);
    try stack.push(2);

    stack.push(3) catch |err| {
        try std.testing.expect(err == error.StackFull);
    };
}
