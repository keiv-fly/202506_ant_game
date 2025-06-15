const std = @import("std");
const Term = @import("termlib.zig").Term;

const Position = struct {
    x: usize,
    y: usize,
};

pub fn applyMove(input: u8, pos: *Position, width: usize, height: usize) void {
    switch (input) {
        'w' => {
            if (pos.y > 0) pos.y -= 1;
        },
        's' => {
            if (pos.y + 1 < height) pos.y += 1;
        },
        'a' => {
            if (pos.x > 0) pos.x -= 1;
        },
        'd' => {
            if (pos.x + 1 < width) pos.x += 1;
        },
        else => {},
    }
}

fn render(term: *Term, pos: Position, width: usize, height: usize) !void {
    term.clearBuffer();
    for (0..height) |y| {
        for (0..width) |x| {
            term.setChar(x, y, if (x == pos.x and y == pos.y) '@' else '.');
        }
    }
    try term.render();
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer().any();
    const stdin = std.io.getStdIn().reader();

    const width: usize = 20;
    const height: usize = 10;

    var term = try Term.init(std.heap.page_allocator, stdout, width, height);
    defer term.deinit(std.heap.page_allocator);

    var pos = Position{ .x = width / 2, .y = height / 2 };

    try render(&term, pos, width, height);

    while (true) {
        const c = stdin.readByte() catch break;
        if (c == 'q') break;
        if (c == '\n' or c == '\r') continue;
        applyMove(c, &pos, width, height);
        try render(&term, pos, width, height);
    }
}

test "applyMove works within bounds" {
    var pos = Position{ .x = 1, .y = 1 };
    applyMove('w', &pos, 3, 3);
    try std.testing.expectEqual(@as(usize, 0), pos.y);
    pos = Position{ .x = 1, .y = 1 };
    applyMove('s', &pos, 3, 3);
    try std.testing.expectEqual(@as(usize, 2), pos.y);
    pos = Position{ .x = 1, .y = 1 };
    applyMove('a', &pos, 3, 3);
    try std.testing.expectEqual(@as(usize, 0), pos.x);
    pos = Position{ .x = 1, .y = 1 };
    applyMove('d', &pos, 3, 3);
    try std.testing.expectEqual(@as(usize, 2), pos.x);
}

test "render prints @ in grid" {
    var buffer: [1024]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buffer);
    const width: usize = 3;
    const height: usize = 2;
    const pos = Position{ .x = 1, .y = 0 };
    var term = try Term.init(std.testing.allocator, fbs.writer().any(), width, height);
    defer term.deinit(std.testing.allocator);
    try render(&term, pos, width, height);
    const output = fbs.getWritten();

    var expected_list = std.ArrayList(u8).init(std.testing.allocator);
    defer expected_list.deinit();
    try expected_list.writer().writeAll("\x1b[2J");
    for (0..height) |y| {
        for (0..width) |x| {
            try expected_list.writer().print("\x1b[{d};{d}H", .{ y + 1, x + 1 });
            try expected_list.writer().writeByte(if (x == pos.x and y == pos.y) '@' else '.');
        }
    }
    try expected_list.writer().print("\x1b[{d};{d}H", .{ height + 1, 1 });
    const expected = try expected_list.toOwnedSlice();
    defer std.testing.allocator.free(expected);
    try std.testing.expectEqualSlices(u8, expected, output);
}
