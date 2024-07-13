const std = @import("std");
const assert = std.debug.assert;

const expect = std.testing.expect;

fn RingBuffer(
    comptime T: type,
) type {
    return struct {
        const Self = @This();

        items: []T,
        head: u32,
        tail: u32,
        capacity: u32,
        size: u32,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator, capacity: u32) !Self {
            const item_buffer = try allocator.alloc(T, capacity);
            @memset(item_buffer, 0);

            return .{
                .head = 0,
                .tail = 0,
                .size = 0,
                .capacity = capacity,
                .allocator = allocator,
                .items = item_buffer,
            };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.items);
        }

        pub fn push(self: *Self, item: T) !void {
            if (self.is_full()) {
                return error.RingBufferFull;
            }

            // Write item at current tail
            self.items[self.tail] = item;

            // update new tail position
            self.tail = (self.tail + 1) % self.capacity;
            self.size += 1;
        }

        pub fn pop(self: *Self) ?T {
            if (self.is_empty()) return null;

            // read item
            const item: T = self.items[self.head];

            // update new head position
            self.head = (self.head + 1) % self.capacity;
            self.size -= 1;

            return item;
        }

        pub fn is_empty(self: *Self) bool {
            return self.size == 0;
        }

        pub fn is_full(self: *Self) bool {
            return self.size == self.capacity;
        }

        pub fn free_spots(self: *Self) usize {
            if (self.is_full()) return 0;
            return self.capacity - self.size;
        }
    };
}

test "Initialize Ring buffer" {
    var ringbuffer = try RingBuffer(u8).init(std.testing.allocator, 10);
    defer ringbuffer.deinit();

    try expect(ringbuffer.head == 0);
    try expect(ringbuffer.tail == 0);
    try expect(ringbuffer.capacity == 10);
    try expect(ringbuffer.size == 0);
    try expect(ringbuffer.is_empty());
    try expect(ringbuffer.is_full() == false);
}

test "Push item to ring buffer" {
    var ringbuffer = try RingBuffer(u8).init(std.testing.allocator, 10);
    defer ringbuffer.deinit();

    try ringbuffer.push(7);

    try expect(ringbuffer.head == 0);
    try expect(ringbuffer.tail == 1);
    try expect(ringbuffer.size == 1);
    try expect(ringbuffer.items[ringbuffer.tail - 1] == 7);

    try ringbuffer.push(8);
    try expect(ringbuffer.head == 0);
    try expect(ringbuffer.tail == 2);
    try expect(ringbuffer.size == 2);
    try expect(ringbuffer.items[ringbuffer.tail - 1] == 8);
}

test "Pop item from ring buffer" {
    var ringbuffer = try RingBuffer(u8).init(std.testing.allocator, 10);
    defer ringbuffer.deinit();

    const item = ringbuffer.pop();
    try expect(item == null);

    try ringbuffer.push(8);
    try expect(ringbuffer.head == 0);
    try expect(ringbuffer.tail == 1);

    try expect(ringbuffer.pop() == 8);
}

test "Overflow the ring buffer" {
    var ringbuffer = try RingBuffer(u8).init(std.testing.allocator, 3);
    defer ringbuffer.deinit();

    try ringbuffer.push(1);
    try ringbuffer.push(2);
    try ringbuffer.push(3);

    ringbuffer.push(4) catch |err| {
        try std.testing.expect(err == error.RingBufferFull);
    };
}
