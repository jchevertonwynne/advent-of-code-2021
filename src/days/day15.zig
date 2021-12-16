const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var p1: usize = undefined;
    var p2: usize = undefined;
    try solve(100, contents, allocator, &p1, &p2);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 15, p1, p2, duration);

    return duration;
}

fn solve(comptime world_size: usize, contents: []u8, allocator: *std.mem.Allocator, p1: *usize, p2: *usize) !void {
    var world = loadWorld(world_size, contents);
    p1.* = try part1(world_size, world, allocator);
    p2.* = try part2(world_size, world, allocator);
}

const Point = struct { i: usize, j: usize };

const QueuePoint = struct {
    point: Point,
    lowestNeighbourScore: usize,

    fn compare(a: QueuePoint, b: QueuePoint) std.math.Order {
        return std.math.order(a.lowestNeighbourScore, b.lowestNeighbourScore);
    }
};

fn part1(comptime world_size: usize, world: World(world_size), allocator: *std.mem.Allocator) !usize {
    var queue = std.PriorityQueue(QueuePoint, QueuePoint.compare).init(allocator);
    defer queue.deinit();
    try queue.add(QueuePoint{ .point = Point{ .i = 0, .j = 0 }, .lowestNeighbourScore = 0 });

    var seen = std.mem.zeroes([world_size][world_size]bool);
    seen[0][0] = true;

    while (queue.removeOrNull()) |queuePoint| {
        var point = queuePoint.point;
        var i = point.i;
        var j = point.j;
        var score = queuePoint.lowestNeighbourScore;

        if (i == world_size - 1 and j == world_size - 1)
            return score;

        if (i > 0 and !seen[j][i - 1]) {
            seen[j][i - 1] = true;
            try queue.add(QueuePoint{ .point = Point{ .i = i - 1, .j = j }, .lowestNeighbourScore = score + world[j][i - 1] });
        }
        if (i + 1 < world_size and !seen[j][i + 1]) {
            seen[j][i + 1] = true;
            try queue.add(QueuePoint{ .point = Point{ .i = i + 1, .j = j }, .lowestNeighbourScore = score + world[j][i + 1] });
        }
        if (j > 0 and !seen[j - 1][i]) {
            seen[j - 1][i] = true;
            try queue.add(QueuePoint{ .point = Point{ .i = i, .j = j - 1 }, .lowestNeighbourScore = score + world[j - 1][i] });
        }
        if (j + 1 < world_size and !seen[j + 1][i]) {
            seen[j + 1][i] = true;
            try queue.add(QueuePoint{ .point = Point{ .i = i, .j = j + 1 }, .lowestNeighbourScore = score + world[j + 1][i] });
        }
    }

    unreachable;
}

fn part2(comptime world_size: usize, world: World(world_size), allocator: *std.mem.Allocator) !usize {
    var largerWorld: World(world_size * 5) = undefined;
    for (world) |row, j| {
        for (row) |cell, i|
            largerWorld[j][i] = cell;
    }
    var i: u8 = 0;
    while (i < 5) : (i += 1) {
        var j: usize = 0;
        while (j < 5) : (j += 1) {
            if (i == 0 and j == 0)
                continue;
            var x: usize = 0;
            while (x < world_size) : (x += 1) {
                var y: usize = 0;
                while (y < world_size) : (y += 1) {
                    if (i == 0)
                        largerWorld[world_size * j + y][world_size * i + x] = largerWorld[world_size * (j - 1) + y][world_size * i + x] + 1
                    else
                        largerWorld[world_size * j + y][world_size * i + x] = largerWorld[world_size * j + y][world_size * (i - 1) + x] + 1;
                    if (largerWorld[world_size * j + y][world_size * i + x] > 9)
                        largerWorld[world_size * j + y][world_size * i + x] = 1;
                }
            }
        }
    }
    return try part1(world_size * 5, largerWorld, allocator);
}

fn World(comptime world_size: usize) type {
    return [world_size][world_size]u8;
}

fn loadWorld(comptime world_size: usize, contents: []u8) World(world_size) {
    var world: World(world_size) = undefined;

    var i: usize = 0;
    while (i < world_size) : (i += 1) {
        var j: usize = 0;
        while (j < world_size) : (j += 1)
            world[j][i] = contents[i + (world_size + 1) * j] - '0';
    }

    return world;
}
