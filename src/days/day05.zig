const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var p1: usize = 0;
    var p2: usize = 0;
    try solve(contents, allocator, &p1, &p2);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 5, p1, p2, duration);

    return duration;
}

fn solve(contents: []u8, allocator: *std.mem.Allocator, p1: *usize, p2: *usize) !void {
    var p1Sols = std.AutoHashMap(Point, usize).init(allocator);
    defer p1Sols.deinit();
    var p2Sols = std.AutoHashMap(Point, usize).init(allocator);
    defer p2Sols.deinit();

    var ind: usize = 0;
    while (ind < contents.len) {
        var line: Line = undefined;
        var size: usize = undefined;
        util.toUint(u16, contents[ind..], &line.start.x, &size);
        ind += size + 1;
        util.toUint(u16, contents[ind..], &line.start.y, &size);
        ind += size + 4;
        util.toUint(u16, contents[ind..], &line.end.x, &size);
        ind += size + 1;
        util.toUint(u16, contents[ind..], &line.end.y, &size);
        ind += size + 1;

        if (line.start.x == line.end.x) {
            var y = std.math.min(line.start.y, line.end.y);
            var yLimit = std.math.max(line.start.y, line.end.y);

            while (y <= yLimit) : (y += 1) {
                var entry1 = try p1Sols.getOrPut(Point{ .x = line.start.x, .y = y });
                if (!entry1.found_existing)
                    entry1.value_ptr.* = 0;
                entry1.value_ptr.* += 1;
                var entry2 = try p2Sols.getOrPut(Point{ .x = line.start.x, .y = y });
                if (!entry2.found_existing)
                    entry2.value_ptr.* = 0;
                entry2.value_ptr.* += 1;
            }
        } else if (line.start.y == line.end.y) {
            var x = std.math.min(line.start.x, line.end.x);
            var xLimit = std.math.max(line.start.x, line.end.x);

            while (x <= xLimit) : (x += 1) {
                var entry1 = try p1Sols.getOrPut(Point{ .x = x, .y = line.start.y });
                if (!entry1.found_existing)
                    entry1.value_ptr.* = 0;
                entry1.value_ptr.* += 1;
                var entry2 = try p2Sols.getOrPut(Point{ .x = x, .y = line.start.y });
                if (!entry2.found_existing)
                    entry2.value_ptr.* = 0;
                entry2.value_ptr.* += 1;
            }
        } else {
            var incX = line.start.x < line.end.x;
            var incY = line.start.y < line.end.y;

            if (incX == incY) {
                var x = std.math.min(line.start.x, line.end.x);
                var xLimit = std.math.max(line.start.x, line.end.x);
                var y = std.math.min(line.start.y, line.end.y);

                while (x <= xLimit) {
                    var entry = try p2Sols.getOrPut(Point{ .x = x, .y = y });
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
                    var entry = try p2Sols.getOrPut(Point{ .x = x, .y = y });
                    if (!entry.found_existing)
                        entry.value_ptr.* = 0;
                    entry.value_ptr.* += 1;
                    x += 1;
                    y -%= 1;
                }
            }
        }
    }

    p1.* = 0;
    var it1 = p1Sols.valueIterator();
    while (it1.next()) |val|
        p1.* += @boolToInt(val.* > 1);
    p2.* = 0;
    var it2 = p2Sols.valueIterator();
    while (it2.next()) |val|
        p2.* += @boolToInt(val.* > 1);
}

const Line = struct { start: Point, end: Point };

const Point = struct { x: u16, y: u16 };
