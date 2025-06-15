const std = @import("std");

pub const Term = struct {
    width: usize,
    height: usize,
    prev: []u8,
    buffer: []u8,
    writer: std.io.AnyWriter,
    first_render: bool = true,

    pub fn init(allocator: std.mem.Allocator, writer: std.io.AnyWriter, width: usize, height: usize) !Term {
        const prev = try allocator.alloc(u8, width * height);
        const buffer = try allocator.alloc(u8, width * height);
        for (prev) |*c| c.* = ' ';
        for (buffer) |*c| c.* = ' ';
        return Term{ .width = width, .height = height, .prev = prev, .buffer = buffer, .writer = writer };
    }

    pub fn deinit(self: *Term, allocator: std.mem.Allocator) void {
        allocator.free(self.prev);
        allocator.free(self.buffer);
    }

    pub fn clearBuffer(self: *Term) void {
        for (self.buffer) |*c| c.* = ' ';
    }

    pub fn setChar(self: *Term, x: usize, y: usize, ch: u8) void {
        if (x >= self.width or y >= self.height) return;
        self.buffer[y * self.width + x] = ch;
    }

    pub fn render(self: *Term) !void {
        var w = self.writer;
        if (self.first_render) {
            try w.writeAll("\x1b[2J");
            self.first_render = false;
        }
        for (self.buffer, 0..) |newch, idx| {
            const oldch = self.prev[idx];
            if (newch != oldch) {
                const x = idx % self.width;
                const y = idx / self.width;
                try w.print("\x1b[{d};{d}H", .{ y + 1, x + 1 });
                try w.writeByte(newch);
                self.prev[idx] = newch;
            }
        }
        try w.print("\x1b[{d};{d}H", .{ self.height + 1, 1 });
    }
};

const testing = std.testing;

test "initial render draws full buffer" {
    var buf: [256]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);
    var term = try Term.init(testing.allocator, fbs.writer().any(), 2, 2);
    defer term.deinit(testing.allocator);

    term.setChar(0, 0, 'A');
    term.setChar(1, 0, 'B');
    term.setChar(0, 1, 'C');
    term.setChar(1, 1, 'D');
    try term.render();
    const expected = "\x1b[2J\x1b[1;1HA\x1b[1;2HB\x1b[2;1HC\x1b[2;2HD\x1b[3;1H";
    try testing.expectEqualStrings(expected, fbs.getWritten());
}

test "second render only updates diff" {
    var buf: [256]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);
    var term = try Term.init(testing.allocator, fbs.writer().any(), 2, 2);
    defer term.deinit(testing.allocator);

    term.setChar(0, 0, 'A');
    term.setChar(1, 0, 'B');
    term.setChar(0, 1, 'C');
    term.setChar(1, 1, 'D');
    try term.render();
    fbs.reset();
    term.setChar(1, 0, 'X');
    try term.render();
    const expected = "\x1b[1;2HX\x1b[3;1H";
    try testing.expectEqualStrings(expected, fbs.getWritten());
}
