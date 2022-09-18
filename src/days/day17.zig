const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []const u8, out: anytype) !i128 {
    var min = std.time.nanoTimestamp();

    var area = Area.parse(contents);

    var sol = solve(area);
    var p1 = sol.part1;
    var p2 = sol.part2;

    var duration = std.time.nanoTimestamp() - min;

    try util.writeResponse(out, 17, p1, p2, duration);

    return duration;
}

fn triangular(i: i32) i32 {
    return @divFloor(i * (i + 1), 2);
}

fn solve(area: Area) struct { part1: i32, part2: usize } {
    var bestY: i32 = std.math.minInt(i32);
    var hits: usize = 0;

    var minX: i32 = 0;
    while (triangular(minX + 1) <= area.max.x)
        minX += 1;

    var x: i32 = minX;
    while (x <= area.max.x) : (x += 1) {
        var y: i32 = area.min.y;
        while (y < std.math.absInt(area.min.y) catch unreachable) : (y += 1) yBlock: {
            var position = Point{ .x = 0, .y = 0 };
            var momentum = Point{ .x = x, .y = y };
            var maxY: i32 = std.math.minInt(i32);
            while (true) : (momentum.timestep()) {
                position.add(momentum);
                maxY = std.math.max(maxY, position.y);
                if (area.contains(position)) {
                    bestY = std.math.max(bestY, maxY);
                    hits += 1;
                    break;
                }
                if (position.y < area.min.y)
                    break :yBlock;
            }
        }
    }

    return .{ .part1 = bestY, .part2 = hits };
}

const Area = struct {
    min: Point,
    max: Point,

    fn from(x1: i32, y1: i32, x2: i32, y2: i32) @This() {
        return .{ .min = .{ .x = x1, .y = y1 }, .max = .{ .x = x2, .y = y2 } };
    }

    fn contains(self: @This(), point: Point) bool {
        return point.x >= self.min.x and point.x <= self.max.x and point.y >= self.min.y and point.y <= self.max.y;
    }

    fn parse(contents: []const u8) Area {
        var area: Area = undefined;

        var ind: usize = 15;

        var parsed = util.toSignedInt(i32, contents[ind..]);
        area.min.x = parsed.result;
        ind += 2 + parsed.size;
        parsed = util.toSignedInt(i32, contents[ind..]);
        area.max.x = parsed.result;
        ind += 4 + parsed.size;
        parsed = util.toSignedInt(i32, contents[ind..]);
        area.min.y = parsed.result;
        ind += 2 + parsed.size;
        parsed = util.toSignedInt(i32, contents[ind..]);
        area.max.y = parsed.result;

        return area;
    }
};

const Point = struct {
    x: i32,
    y: i32,

    fn equal(a: Point, b: Point) bool {
        return a.x == b.x and a.y == b.y;
    }

    fn lt(_: void, a: Point, b: Point) bool {
        return a.x < b.x or a.y < b.y;
    }

    fn add(self: *@This(), point: Point) void {
        self.x += point.x;
        self.y += point.y;
    }

    fn timestep(self: *@This()) void {
        if (self.x > 0)
            self.x -= 1;
        if (self.x < 0)
            self.x += 1;
        self.y -= 1;
    }
};
