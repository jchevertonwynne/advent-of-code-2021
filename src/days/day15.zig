const std = @import("std");

const util = @import("../util.zig");

pub fn run(comptime world_size: usize, contents: []u8, out: anytype, allocator: *std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();
    _ = allocator;
    var world = loadWorld(world_size, contents);

    var p1: usize = try part1(world_size, world, allocator);
    var p2: usize = try part2(world_size, world, allocator);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 15, p1, p2, duration);

    return duration;
}

const Point = struct {
    i: usize,
    j: usize
};

fn part2(comptime world_size: usize, world: World(world_size), allocator: *std.mem.Allocator) !usize {
    var largerWorld: World(world_size * 5) = undefined;
    for (world) |row, j| {
        for (row) |cell, i| {
            largerWorld[j][i] = cell;
        }
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

fn part1(comptime world_size: usize, world: World(world_size), allocator: *std.mem.Allocator) !usize {
    var lowestRisk = std.mem.zeroes([world_size][world_size]usize);
    var seen = std.mem.zeroes([world_size][world_size]bool);
    
    lowestRisk[world_size - 1][world_size - 1] = world[world_size - 1][world_size - 1];
    seen[world_size - 1][world_size - 1] = true;
    var doable = util.HashSet(Point).init(allocator);
    defer doable.deinit();
    try doable.insert(Point{ .i = world_size - 2, .j = world_size - 1 });
    try doable.insert(Point{ .i = world_size - 1, .j = world_size - 2 });

    while (doable.count() != 0) {
        var it = doable.iterator();
        var best: Point = undefined;
        var lowestBest: usize = std.math.maxInt(usize);
        while (it.next()) |point| {
            var i = point.i;
            var j = point.j;
            var localBest: usize = std.math.maxInt(usize);

            if (i > 0 and seen[j][i - 1])
                localBest = std.math.min(localBest, lowestRisk[j][i - 1]);
            if (i + 1 < world_size and seen[j][i + 1])
                localBest = std.math.min(localBest, lowestRisk[j][i + 1]);
            if (j > 0 and seen[j - 1][i])
                localBest = std.math.min(localBest, lowestRisk[j - 1][i]);
            if (j + 1 < world_size and seen[j + 1][i])
                localBest = std.math.min(localBest, lowestRisk[j + 1][i]);

            if (localBest < lowestBest) {
                best = point.*;
                lowestBest = localBest;
            }   
        }
        if (best.i == 0 and best.j == 0) 
            return lowestBest;
        lowestRisk[best.j][best.i] = world[best.j][best.i] + lowestBest;
        seen[best.j][best.i] = true;
        _ = doable.remove(best);
        if (best.i > 0 and !seen[best.j][best.i - 1])
            try doable.insert(Point{ .i = best.i - 1, .j = best.j });
        if (best.i + 1 < world_size and !seen[best.j][best.i + 1])
            try doable.insert(Point{ .i = best.i + 1, .j = best.j });
        if (best.j > 0 and !seen[best.j - 1][best.i])
            try doable.insert(Point{ .i = best.i, .j = best.j - 1 });
        if (best.j + 1 < world_size and !seen[best.j + 1][best.i])
            try doable.insert(Point{ .i = best.i, .j = best.j + 1 });
    }

    return lowestRisk[0][0] - world[0][0];
}

fn World(comptime world_size: usize) type {
    return [world_size][world_size]u8;
}

fn loadWorld(comptime world_size: usize, contents: []u8) World(world_size) {
    var world: World(world_size) = undefined;

    var i: usize = 0;
    while (i < world_size) : (i += 1) {
        var j: usize = 0;
        while (j < world_size) : (j += 1) {
            world[j][i] = contents[i + (world_size + 1) * j] - '0';
        }
    }

    return world;
}