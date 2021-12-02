const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype) !i128 {
    var start = std.time.nanoTimestamp();

    var p1: usize = 0;
    var p2: usize = 0;
    try solve2(contents, &p1, &p2);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 1, p1, p2, duration);

    return duration;
}

const Direction = enum(u8) { forward = 'f', down = 'd', up = 'u' };

const Action = struct { direction: Direction, distance: usize };

const Part1Stats = struct { depth: usize, horizontal: usize };

const Part2Stats = struct { depth: usize, horizontal: usize, aim: usize };

fn solve2(contents: []u8, p1: *usize, p2: *usize) !void {
    var part1Stats: Part1Stats = .{ .depth = 0, .horizontal = 0 };
    var part2Stats: Part2Stats = .{ .depth = 0, .horizontal = 0, .aim = 0 };

    var lines = std.mem.tokenize(u8, contents, "\n");
    while (lines.next()) |line| {
        var split = std.mem.indexOf(u8, line, " ") orelse return error.NoSpace;

        var distance = try std.fmt.parseInt(usize, line[split + 1 ..], 10);
        var action = Action{ .direction = @intToEnum(Direction, line[0]), .distance = distance };

        switch (action.direction) {
            .down => {
                part1Stats.depth += action.distance;
                part2Stats.aim += action.distance;
            },
            .up => {
                part1Stats.depth -= action.distance;
                part2Stats.aim -= action.distance;
            },
            .forward => {
                part1Stats.horizontal += action.distance;
                part2Stats.horizontal += action.distance;
                part2Stats.depth += part2Stats.aim * action.distance;
            },
        }
    }

    p1.* = part1Stats.depth * part1Stats.horizontal;
    p2.* = part2Stats.depth * part2Stats.horizontal;
}
