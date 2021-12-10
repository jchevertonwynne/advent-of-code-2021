const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var strings = try loadStrings(contents, allocator);
    defer allocator.free(strings);

    var p1: usize = undefined;
    var p2: usize = undefined;
    try solve(strings, allocator, &p1, &p2);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 10, p1, p2, duration);

    return duration;
}

fn solve(strings: [][]u8, allocator: *std.mem.Allocator, p1: *usize, p2: *usize) !void {
    var stack = std.ArrayList(u8).init(allocator);
    defer stack.deinit();

    var scores = std.ArrayList(usize).init(allocator);
    defer scores.deinit();

    p1.* = 0;
    p2.* = 0;

    outer: for (strings) |string| {
        stack.clearRetainingCapacity();
        for (string) |c| {
            switch (c) {
                '(', '{', '[', '<' => try stack.append(c),
                else => {
                    var last = stack.pop();
                    var paired: u8 = switch (c) {
                        ')' => '(',
                        ']' => '[',
                        '>' => '<',
                        '}' => '{',
                        else => unreachable,
                    };
                    if (paired != last) {
                        p1.* += switch (c) {
                            ')' => @as(usize, 3),
                            ']' => @as(usize, 57),
                            '}' => @as(usize, 1_197),
                            '>' => @as(usize, 25_137),
                            else => unreachable,
                        };
                        continue :outer;
                    }
                },
            }
        }
        // complete a string for part 2
        var score: usize = 0;
        var toDo = stack.items.len;
        while (toDo > 0) : (toDo -= 1) {
            var c = stack.items[toDo - 1];

            score *= 5;
            score += switch (c) {
                '(' => @as(usize, 1),
                '[' => @as(usize, 2),
                '{' => @as(usize, 3),
                '<' => @as(usize, 4),
                else => unreachable,
            };
        }
        try scores.append(score);
    }

    std.sort.sort(usize, scores.items, {}, comptime std.sort.asc(usize));

    p2.* = scores.items[scores.items.len / 2];
}

fn loadStrings(contents: []u8, allocator: *std.mem.Allocator) ![][]u8 {
    var result = std.ArrayList([]u8).init(allocator);
    errdefer result.deinit();

    var ind: usize = 0;
    while (ind < contents.len) {
        var start = ind;
        while (contents[ind] != '\n')
            ind += 1;
        try result.append(contents[start..ind]);
        ind += 1;
    }

    return result.toOwnedSlice();
}
