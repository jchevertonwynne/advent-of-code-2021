const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []const u8, out: anytype) !i128 {
    var start = std.time.nanoTimestamp();

    var p1: usize = 0;
    var p2: usize = 0;
    try solve(contents, &p1, &p2);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 2, p1, p2, duration);

    return duration;
}

fn solve(contents: []const u8, p1: *usize, p2: *usize) !void {
    var horizontal: usize = 0;
    var part1DepthPart2Aim: usize = 0;
    var part2Depth: usize = 0;

    var ind: usize = 0;
    while (ind < contents.len) {
        switch (contents[ind]) {
            'f' => {
                var distance: usize = @as(usize, contents[ind + 8] - '0');
                horizontal += distance;
                part2Depth += part1DepthPart2Aim * distance;
                ind += 10;
            },
            'u' => {
                var distance: usize = @as(usize, contents[ind + 3] - '0');
                part1DepthPart2Aim -= distance;
                ind += 5;
            },
            'd' => {
                var distance: usize = @as(usize, contents[ind + 5] - '0');
                part1DepthPart2Aim += distance;
                ind += 7;
            },
            else => unreachable,
        }
    }

    p1.* = part1DepthPart2Aim * horizontal;
    p2.* = part2Depth * horizontal;
}
