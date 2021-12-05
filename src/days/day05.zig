const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var lines = try loadLines(contents, allocator);
    defer allocator.free(lines);

    var p1: usize = try part1(lines, allocator);
    var p2: usize = try part2(lines, allocator);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 5, p1, p2, duration);

    return duration;
}

const Line = struct { start: Point, end: Point };

const Point = struct { x: usize, y: usize };

fn loadLines(contents: []u8, allocator: *std.mem.Allocator) ![]Line {
    var lines = std.ArrayList(Line).init(allocator);
    errdefer lines.deinit();

    var ind: usize = 0;
    while (ind < contents.len) {
        var line: Line = undefined;
        var size: usize = undefined;
        util.toUsize(contents[ind..], &line.start.x, &size);
        ind += size + 1;
        util.toUsize(contents[ind..], &line.start.y, &size);
        ind += size + 4;
        util.toUsize(contents[ind..], &line.end.x, &size);
        ind += size + 1;
        util.toUsize(contents[ind..], &line.end.y, &size);
        ind += size + 1;
        try lines.append(line);
    }

    _ = try std.io.getStdOut().write("done loading\n");

    return lines.toOwnedSlice();
}

fn part1(lines: []Line, allocator: *std.mem.Allocator) !usize {
    var seen = std.AutoHashMap(Point, usize).init(allocator);
    defer seen.deinit();

    for (lines) |line| {
        if (line.start.x == line.end.x) {
            var y = std.math.min(line.start.y, line.end.y);
            var yLimit = std.math.max(line.start.y, line.end.y);

            while (y <= yLimit) : (y += 1) {
                var entry = try seen.getOrPut(Point{ .x = line.start.x, .y = y });
                if (!entry.found_existing)
                    entry.value_ptr.* = 0;
                entry.value_ptr.* += 1;
            }
        } else if (line.start.y == line.end.y) {
            var x = std.math.min(line.start.x, line.end.x);
            var xLimit = std.math.max(line.start.x, line.end.x);

            while (x <= xLimit) : (x += 1) {
                var entry = try seen.getOrPut(Point{ .x = x, .y = line.start.y });
                if (!entry.found_existing)
                    entry.value_ptr.* = 0;
                entry.value_ptr.* += 1;
            }
        }
    }

    var result: usize = 0;
    var it = seen.valueIterator();
    while (it.next()) |val| {
        if (val.* >= 2)
            result += 1;
    }

    return result;
}

fn part2(lines: []Line, allocator: *std.mem.Allocator) !usize {
    var seen = std.AutoHashMap(Point, usize).init(allocator);
    defer seen.deinit();

    for (lines) |line| {
        if (line.start.x == line.end.x) {
            var y = std.math.min(line.start.y, line.end.y);
            var yLimit = std.math.max(line.start.y, line.end.y);

            while (y <= yLimit) : (y += 1) {
                var entry = try seen.getOrPut(Point{ .x = line.start.x, .y = y });
                if (!entry.found_existing)
                    entry.value_ptr.* = 0;
                entry.value_ptr.* += 1;
            }
        } else if (line.start.y == line.end.y) {
            var x = std.math.min(line.start.x, line.end.x);
            var xLimit = std.math.max(line.start.x, line.end.x);

            while (x <= xLimit) : (x += 1) {
                var entry = try seen.getOrPut(Point{ .x = x, .y = line.start.y });
                if (!entry.found_existing)
                    entry.value_ptr.* = 0;
                entry.value_ptr.* += 1;
            }
        } else {
            var incX = line.start.x < line.end.x;
            var incY = line.start.y < line.end.y;

            if (incX == incY) {
                var x = std.math.min(line.start.x, line.end.x);
                var xLimit = std.math.max(line.start.x, line.end.x);
                var y = std.math.min(line.start.y, line.end.y);

                while (x <= xLimit) {
                    var entry = try seen.getOrPut(Point{ .x = x, .y = y });
                    if (!entry.found_existing)
                        entry.value_ptr.* = 0;
                    entry.value_ptr.* += 1;
                    x += 1;
                    y += 1;
                }
            } else {
                var x = std.math.min(line.start.x, line.end.x);
                var xLimit = std.math.max(line.start.x, line.end.x);
                var y = std.math.max(line.start.y, line.end.y);

                while (x <= xLimit) {
                    var entry = try seen.getOrPut(Point{ .x = x, .y = y });
                    if (!entry.found_existing)
                        entry.value_ptr.* = 0;
                    entry.value_ptr.* += 1;
                    x += 1;
                    y -%= 1;
                }
            }
        }
    }

    var result: usize = 0;
    var it = seen.valueIterator();
    while (it.next()) |val| {
        if (val.* >= 2)
            result += 1;
    }

    return result;
}
