const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []const u8, out: anytype, alloc: std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var contentsCopy = try alloc.dupe(u8, contents);
    defer alloc.free(contentsCopy);

    var width = std.mem.indexOf(u8, contents, "\n") orelse unreachable;
    var height = contents.len / (width + 1);

    var p1: usize = 0;

    var largest = std.mem.zeroes([4]usize);

    var i: usize = 0;
    while (i < width) : (i += 1) {
        var j: usize = 0;
        while (j < height) : (j += 1) {
            var val = contentsCopy[i + (width + 1) * j];
            if (val == '9')
                continue;

            var deepest = true;

            if (i > 0)
                deepest = deepest and contentsCopy[(i - 1) + (width + 1) * j] > val;

            if (i + 1 < width)
                deepest = deepest and contentsCopy[(i + 1) + (width + 1) * j] > val;

            if (j > 0)
                deepest = deepest and contentsCopy[i + (width + 1) * (j - 1)] > val;

            if (j + 1 < height)
                deepest = deepest and contentsCopy[i + (width + 1) * (j + 1)] > val;

            if (deepest) {
                p1 += 1 + val - '0';
                largest[3] = floodFill(i, j, width, height, contentsCopy);
                std.sort.sort(usize, &largest, {}, comptime std.sort.desc(usize));
            }
        }
    }

    var p2: usize = largest[0] * largest[1] * largest[2];

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 9, p1, p2, duration);

    return duration;
}

fn floodFill(i: usize, j: usize, width: usize, height: usize, world: []u8) usize {
    var filled: usize = 1;
    world[i + (width + 1) * j] = '9';

    if (i > 0 and world[(i - 1) + (width + 1) * j] != '9')
        filled += floodFill(i - 1, j, width, height, world);

    if (i + 1 < width and world[(i + 1) + (width + 1) * j] != '9')
        filled += floodFill(i + 1, j, width, height, world);

    if (j > 0 and world[i + (width + 1) * (j - 1)] != '9')
        filled += floodFill(i, j - 1, width, height, world);

    if (j + 1 < height and world[i + (width + 1) * (j + 1)] != '9')
        filled += floodFill(i, j + 1, width, height, world);

    return filled;
}
