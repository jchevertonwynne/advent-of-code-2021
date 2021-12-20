const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var image = try Image.load(contents, allocator);
    defer image.deinit();

    var p1: usize = try solve(image, allocator, 2);
    var p2: usize = try solve(image, allocator, 50);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 20, p1, p2, duration);

    return duration;
}

fn solve(image: Image, allocator: *std.mem.Allocator, repeats: usize) !usize {
    var pixels = std.AutoHashMap(Point, u8).init(allocator);
    defer pixels.deinit();
    var pixelsSwap = std.AutoHashMap(Point, u8).init(allocator);
    defer pixelsSwap.deinit();

    var minX: isize = 0;
    var minY: isize = 0;
    var maxX: isize = 0;
    var maxY: isize = 0;

    {
        var it = image.pixels.iterator();
        while (it.next()) |px| {
            try pixels.put(px.key_ptr.*, px.value_ptr.*);
            maxX = std.math.max(maxX, px.key_ptr.i);
            maxY = std.math.max(maxX, px.key_ptr.j);
        }
    }
    var infinite: u8 = '.';

    var repeat: usize = 0;
    while (repeat < repeats) : (repeat += 1) {
        pixelsSwap.clearRetainingCapacity();
        var x = minX - 1;
        while (x <= maxX + 1) : (x += 1) {
            var y = minY - 1;
            while (y <= maxY + 1) : (y += 1) {
                var number: usize = 0;

                var iy = y - 1;
                while (iy <= y + 1) : (iy += 1) {
                    var ix = x - 1;
                    while (ix <= x + 1) : (ix += 1) {
                        var val = pixels.get(Point{ .i = ix, .j = iy }) orelse infinite;
                        number <<= 1;
                        number += @boolToInt(val == '#');
                    }
                }
                try pixelsSwap.put(Point{ .i = x, .j = y }, image.lookupTable[number]);
            }
        }

        std.mem.swap(@TypeOf(pixels), &pixels, &pixelsSwap);
        minX -= 1;
        minY -= 1;
        maxX += 1;
        maxY += 1;
        infinite = if (infinite == '.') image.lookupTable[0] else image.lookupTable[511];
    }

    var result: usize = 0;
    var it = pixels.iterator();
    while (it.next()) |px| {
        if (px.value_ptr.* == '#')
            result += 1;
    }

    return result;
}

const Point = struct { i: isize, j: isize };

const Image = struct {
    lookupTable: [512]u8,
    pixels: std.AutoHashMap(Point, u8),

    fn deinit(self: *@This()) void {
        self.pixels.deinit();
    }

    fn load(contents: []u8, allocator: *std.mem.Allocator) !Image {
        var result: Image = undefined;
        for (result.lookupTable) |*t, i|
            t.* = contents[i];

        result.pixels = std.AutoHashMap(Point, u8).init(allocator);
        errdefer result.pixels.deinit();

        var ind: usize = 514;
        var line: isize = 0;
        var lineInd: isize = 0;
        while (ind < contents.len) : (ind += 1) {
            switch (contents[ind]) {
                '#', '.' => |char| {
                    try result.pixels.put(Point{ .i = lineInd, .j = line }, char);
                    lineInd += 1;
                },
                '\n' => {
                    line += 1;
                    lineInd = 0;
                },
                else => unreachable,
            }
        }

        return result;
    }
};
