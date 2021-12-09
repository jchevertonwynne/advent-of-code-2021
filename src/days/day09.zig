const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var width = std.mem.indexOf(u8, contents, "\n") orelse unreachable;
    var height = contents.len / (width + 1);

    var p1: usize = 0;

    var i: usize = 0;
    while (i < width) : (i += 1) {
        var j: usize = 0;
        while (j < height) : (j += 1) {
            var val = contents[i + (width + 1) * j];
            var deepest = true;

            if (i > 0)
                deepest = deepest and contents[(i - 1) + (width + 1) * j] > val;

            if (i + 1 < width)
                deepest = deepest and contents[(i + 1) + (width + 1) * j] > val;

            if (j > 0)
                deepest = deepest and contents[i + (width + 1) * (j - 1)] > val;

            if (j + 1 < height)
                deepest = deepest and contents[i + (width + 1) * (j + 1)] > val;

            if (deepest)
                p1 += 1 + val - '0';
        }
    }

    // part 2

    var table = try allocator.alloc(usize, width * height);
    defer allocator.free(table);
    for (table) |*t|
        t.* = 0;
    
    var basinCount: usize = 0;
    i = 0;
    while (i < width) : (i += 1) {
        var j: usize = 0;
        while (j < height) : (j += 1) {
            var val = contents[i + (width + 1) * j];
            if (val == '9')
                continue;

            var nextToBasin: ?usize = null;
            if (i > 0 and table[(i - 1) + width * j] != 0)
                nextToBasin = table[(i - 1) + width * j];

            if (j > 0 and table[i + width * (j - 1)] != 0)
                nextToBasin = table[i + width * (j - 1)];
            
            if (nextToBasin) |nextTo| {
                table[i + width * j] = nextTo;
            } else {
                basinCount += 1;
                table[i + width * j] = basinCount;
            }
        }
    }

    var changes = true;
    while (changes) {
        changes = false;
        i = 0;
        while (i < width) : (i += 1) {
            var j: usize = 0;
            while (j < height) : (j += 1) {
                var lowest = table[i + width * j];
                if (lowest == 0) 
                    continue;

                if (i > 0 and table[(i - 1) + width * j] != 0 and table[(i - 1) + width * j] < lowest)
                    lowest = table[(i - 1) + width * j];

                if (i + 1 < width and table[(i + 1) + width * j] != 0 and table[(i + 1) + width * j] < lowest)
                    lowest = table[(i + 1) + width * j];

                if (j > 0 and table[i + width * (j - 1)] != 0 and table[i + width * (j - 1)] < lowest)
                    lowest = table[i + width * (j - 1)];

                if (j + 1 < height and table[i + width * (j + 1)] != 0 and table[i + width * (j + 1)] < lowest)
                    lowest = table[i + width * (j + 1)];

                changes = changes or table[i + width * j] != lowest;
                table[i + width * j] = lowest;
            }
        }
    }

    var counts = try allocator.alloc(usize, basinCount + 1);
    defer allocator.free(counts);
    for (counts) |*c|
        c.* = 0;
    for (table) |t| {
        if (t == 0)
            continue;
        counts[t] += 1;
    }

    std.sort.sort(usize, counts, {}, comptime std.sort.desc(usize));

    var p2: usize = counts[0] * counts[1] * counts[2];

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 9, p1, p2, duration);

    return duration;
}
