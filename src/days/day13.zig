const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var instructions = try Instructions.load(contents, allocator);
    defer instructions.deinit(allocator);

    var p1: usize = undefined;
    var p2: [6][40]u8 = undefined;
    try solve(instructions, allocator, &p1, &p2);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 13, p1, p2, duration);

    return duration;
}

fn solve(instructions: Instructions, allocator: std.mem.Allocator, p1: *usize, p2: *[6][40]u8) !void {
    var dots = util.HashSet(Point).init(allocator);
    defer dots.deinit();
    for (instructions.dots) |dot|
        try dots.insert(dot);
    var newDots = util.HashSet(Point).init(allocator);
    defer newDots.deinit();

    var first = true;

    for (instructions.folds) |fold| {
        newDots.clearRetainingCapacity();

        var it = dots.iterator();
        while (it.next()) |dot| {
            switch (fold.direction) {
                .x => {
                    if (dot.x > fold.index) {
                        try newDots.insert(Point{ .x = fold.index - (dot.x - fold.index), .y = dot.y });
                    } else {
                        try newDots.insert(dot.*);
                    }
                },
                .y => {
                    if (dot.y > fold.index) {
                        try newDots.insert(Point{ .x = dot.x, .y = fold.index - (dot.y - fold.index) });
                    } else {
                        try newDots.insert(dot.*);
                    }
                },
            }
        }

        if (first) {
            p1.* = newDots.count();
            first = false;
        }

        std.mem.swap(util.HashSet(Point), &dots, &newDots);
    }

    for (p2) |*row| {
        for (row) |*cell|
            cell.* = ' ';
    }

    var it = dots.iterator();
    while (it.next()) |point| {
        p2[point.y][point.x] = '#';
    }
}

const Point = struct { x: usize, y: usize };

const Direction = enum(u8) { x = 'x', y = 'y' };

const Fold = struct { direction: Direction, index: usize };

const Instructions = struct {
    dots: []Point,
    folds: []Fold,

    fn load(contents: []u8, allocator: std.mem.Allocator) !Instructions {
        var dots = std.ArrayList(Point).init(allocator);
        defer dots.deinit();
        var folds = std.ArrayList(Fold).init(allocator);
        defer folds.deinit();

        var ind: usize = 0;
        while (contents[ind] != '\n') {
            var size: usize = undefined;
            var dot: Point = undefined;
            util.toUnsignedInt(usize, contents[ind..], &dot.x, &size);
            ind += size + 1;
            util.toUnsignedInt(usize, contents[ind..], &dot.y, &size);
            ind += size + 1;
            try dots.append(dot);
        }

        ind += 1;
        while (ind < contents.len) {
            var size: usize = undefined;
            var fold = Fold{ .direction = @intToEnum(Direction, contents[ind + 11]), .index = undefined };
            util.toUnsignedInt(usize, contents[ind + 13 ..], &fold.index, &size);
            ind += 13 + size + 1;
            try folds.append(fold);
        }

        return Instructions{ .dots = dots.toOwnedSlice(), .folds = folds.toOwnedSlice() };
    }

    fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        allocator.free(self.dots);
        allocator.free(self.folds);
    }
};
