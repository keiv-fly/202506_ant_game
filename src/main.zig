const std = @import("std");

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

fn render(stdout: anytype, pos: Position, width: usize, height: usize) !void {
    try stdout.print("\x1b[2J\x1b[H", .{});
    for (0..height) |y| {
        for (0..width) |x| {
            if (x == pos.x and y == pos.y)
                try stdout.writeByte('@')
            else
                try stdout.writeByte('.');
        }
        try stdout.writeByte('\n');
    }
    try stdout.print("Use WASD to move, q to quit.\n", .{});
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    const width: usize = 20;
    const height: usize = 10;

    var pos = Position{ .x = width / 2, .y = height / 2 };

    try render(stdout, pos, width, height);

    while (true) {
        const c = stdin.readByte() catch break;
        if (c == 'q') break;
        if (c == '\n' or c == '\r') continue;
        applyMove(c, &pos, width, height);
        try render(stdout, pos, width, height);
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
    try render(fbs.writer(), pos, width, height);
    const output = fbs.getWritten();

    var expected_list = std.ArrayList(u8).init(std.testing.allocator);
    defer expected_list.deinit();
    try expected_list.writer().print("\x1b[2J\x1b[H", .{});
    for (0..height) |y| {
        for (0..width) |x| {
            if (x == pos.x and y == pos.y)
                try expected_list.writer().writeByte('@')
            else
                try expected_list.writer().writeByte('.');
        }
        try expected_list.writer().writeByte('\n');
    }
    try expected_list.writer().print("Use WASD to move, q to quit.\n", .{});
    const expected = try expected_list.toOwnedSlice();
    defer std.testing.allocator.free(expected);
    try std.testing.expectEqualSlices(u8, expected, output);
}
