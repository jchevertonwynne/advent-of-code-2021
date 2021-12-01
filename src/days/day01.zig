const std = @import("std");

const util = @import("../util.zig");

const ArrayList = std.ArrayList;

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var numbers = try loadNumbers(contents, allocator);
    defer allocator.free(numbers);

    var p1 = part1(numbers);
    var p2 = part2(numbers);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 1, p1, p2, duration);

    return duration;
}

fn loadNumbers(contents: []u8, allocator: *std.mem.Allocator) ![]usize {
    var numbers = ArrayList(usize).init(allocator);
    errdefer numbers.deinit();

    var lines = std.mem.tokenize(u8, contents, "\n");
    while (lines.next()) |line|
        try numbers.append(try std.fmt.parseInt(usize, line, 10));

    return numbers.toOwnedSlice();
}

fn part1(numbers: []usize) usize {
    return solve(numbers, 1);
}

fn part2(numbers: []usize) usize {
    return solve(numbers, 3);
}

fn solve(numbers: []usize, dist: usize) usize {
    var result: usize = 0;

    for (numbers[0..numbers.len - dist]) |_, i| {
        if (numbers[i] < numbers[i + dist])
            result += 1;
    }

    return result;
}