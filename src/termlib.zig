const std = @import("std");

pub const Terminal = struct {
    allocator: std.mem.Allocator,
    lines: std.ArrayList([]u8),

    pub fn init(allocator: std.mem.Allocator) Terminal {
        return Terminal{ .allocator = allocator, .lines = std.ArrayList([]u8).init(allocator) };
    }

    pub fn deinit(self: *Terminal) void {
        for (self.lines.items) |line| {
            self.allocator.free(line);
        }
        self.lines.deinit();
    }

    pub fn render(self: *Terminal, new_lines: []const []const u8, writer: anytype) !void {
        const old_lines = self.lines.items;
        const max_rows = if (new_lines.len > old_lines.len) new_lines.len else old_lines.len;

        for (std.math.range(0, max_rows)) |i| {
            const old_line = if (i < old_lines.len) old_lines[i] else "";
            const new_line = if (i < new_lines.len) new_lines[i] else "";
            if (!std.mem.eql(u8, old_line, new_line)) {
                try writer.print("\x1b[{};{}H\x1b[2K", .{ i + 1, 1 });
                try writer.writeAll(new_line);
            }
        }

        for (self.lines.items) |line| self.allocator.free(line);
        self.lines.clearRetainingCapacity();
        try self.lines.ensureTotalCapacity(new_lines.len);
        for (new_lines) |line| {
            const dup = try self.allocator.dupe(u8, line);
            self.lines.appendAssumeCapacity(dup);
        }
    }
};
