const std = @import("std");
const builtin = @import("builtin");

const util = @import("../util.zig");

const min = std.math.min;
const max = std.math.max;

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    // var a = Line.from(10, 0, 0, 10);
    // var b = Line.from(8, 2, 2, 8);
    // if (Line.findIntersection(a, b)) |intersection| {
    //     std.debug.print("found intersection along {}\n", .{intersection});
    //     var t = intersection.traverse();
    //     while (t.next()) |p|
    //         std.debug.print("{}\n", .{p});
    //     @panic("be done pls");
    // } else {
    //     @panic("no intersection found");
    // }

    var p1: usize = 0;
    var p2: usize = 0;
    try solve(contents, allocator, &p1, &p2);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 5, p1, p2, duration);

    return duration;
}

fn solve(contents: []u8, allocator: *std.mem.Allocator, p1: *usize, p2: *usize) !void {
    var lines = std.ArrayList(Line).init(allocator);
    defer lines.deinit();

    var ind: usize = 0;
    while (ind < contents.len) {
        var line: Line = undefined;
        var size: usize = undefined;
        util.toInt(i32, contents[ind..], &line.start.x, &size);
        ind += size + 1;
        util.toInt(i32, contents[ind..], &line.start.y, &size);
        ind += size + 4;
        util.toInt(i32, contents[ind..], &line.end.x, &size);
        ind += size + 1;
        util.toInt(i32, contents[ind..], &line.end.y, &size);
        ind += size + 1;

        if (line.start.x > line.end.x) {
            std.mem.swap(Point, &line.start, &line.end);
        }

        try lines.append(line);
    }

    var intersections1 = util.HashSet(Point).init(allocator);
    defer intersections1.deinit();
    var intersections2 = util.HashSet(Point).init(allocator);
    defer intersections2.deinit();

    for (lines.items) |line, i| {
        for (lines.items[0..i]) |other| {
            var lineFlat = line.start.x == line.end.x or line.start.y == line.end.y;
            var otherFlat = other.start.x == other.end.x or other.start.y == other.end.y;
            if (Line.findIntersection(line, other)) |intersection| {
                // std.debug.print("{}\n{}\n", .{line, other});
                // std.debug.print("{}\n", .{intersection});
                var traverse = intersection.traverse();
                while (traverse.next()) |point| {
                    try intersections2.insert(point);
                    if (lineFlat and otherFlat)
                        try intersections1.insert(point);
                }
            }
        }
    }

    p1.* = intersections1.count();
    p2.* = intersections2.count();
}

const LineTraverser = struct {
    line: Line,
    dx: i32,
    dy: i32,
    first: bool,

    fn new(from: Line) LineTraverser {
        var dx: i32 = 0;
        if (from.start.x < from.end.x)
            dx = 1;
        if (from.start.x > from.end.x)
            dx = -1;
        var dy: i32 = 0;
        if (from.start.y < from.end.y)
            dy = 1;
        if (from.start.y > from.end.y)
            dy = -1;
        return .{ .line = from, .dx = dx, .dy = dy, .first = true };
    }

    fn next(self: *@This()) ?Point {
        if (self.first) {
            self.first = false;
            return self.line.start;
        }

        if (Point.equal(self.line.start, self.line.end))
            return null;

        self.line.start.x += self.dx;
        self.line.start.y += self.dy;

        return self.line.start;
    }
};

const Line = struct {
    start: Point,
    end: Point,

    fn from(x1: i32, y1: i32, x2: i32, y2: i32) @This() {
        return .{ .start = .{ .x = x1, .y = y1 }, .end = .{ .x = x2, .y = y2 } };
    }

    fn traverse(self: @This()) LineTraverser {
        return LineTraverser.new(self);
    }

    fn findIntersection(_a: Line, _b: Line) ?Line {
        var a = _a;
        var b = _b;

        if (a.start.x > a.end.x)
            std.mem.swap(Point, &a.start, &a.end);

        if (b.start.x > b.end.x)
            std.mem.swap(Point, &b.start, &b.end);

        var adx = a.end.x - a.start.x;
        var bdx = b.end.x - b.start.x;

        if (bdx == 0) {
            std.mem.swap(Line, &a, &b);
            std.mem.swap(i32, &adx, &bdx);
        }

        if (adx == 0) { // a is vertical
            if (bdx == 0) { // b is vertical
                if (a.start.x != b.start.x) // check if on same x
                    return null;
                var aLen = std.math.absInt(a.end.y - a.start.y) catch unreachable;
                var bLen = std.math.absInt(b.end.y - b.start.y) catch unreachable;
                var potLen = max(max(a.start.y, a.end.y), max(b.start.y, b.end.y)) - min(min(a.start.y, a.end.y), min(b.start.y, b.end.y));
                if (aLen + bLen <= potLen) // check if within range of each other - total segment lengths should not exceed the potential combined
                    return null;
                var botY = max(min(a.start.y, a.end.y), min(b.start.y, b.end.y));
                var topY = min(max(a.start.y, a.end.y), max(b.start.y, b.end.y));
                return Line{ .start = Point{ .x = a.start.x, .y = botY }, .end = Point{ .x = a.start.x, .y = topY } };
            }
            // b is not vertical
            var bdy = b.end.y - b.start.y;
            var bdydx = @divFloor(bdy, bdx);
            var bIntersect = b.start.y - (b.start.x * bdydx); // where b crosses x=0
            var actualY = bdydx * a.start.x + bIntersect; // y at which b crosses a
            // check if intersect is within a
            if (actualY < min(a.start.y, a.end.y) or actualY > max(a.start.y, a.end.y))
                return null;
            return return Line{ .start = Point{ .x = a.start.x, .y = actualY }, .end = Point{ .x = a.start.x, .y = actualY } };
        }

        // calculate y = ax + b for both lines & check for intersection
        var ady = a.end.y - a.start.y;
        var adydx = @divFloor(ady, adx);
        var aIntersect = a.start.y - (a.start.x * adydx);

        var bdy = b.end.y - b.start.y;
        var bdydx = @divFloor(bdy, bdx);
        var bIntersect = b.start.y - (b.start.x * bdydx);

        // if the lines are on the same slope and intersect then we have a length
        if (adydx == bdydx) {
            if (aIntersect != bIntersect) // if on the same slops then the intersects must be the same
                return null;
            // check if the segment legnth is possible
            var aLen = a.end.x - a.start.x;
            var bLen = b.end.x - b.start.x;
            var potLen = max(max(a.start.x, a.end.x), max(b.start.x, b.end.x)) - min(min(a.start.x, a.end.x), min(b.start.x, b.end.x));
            if (aLen + bLen <= potLen)
                return null;

            if (adydx == -1) { // negative diag
                var xStart = max(min(a.start.x, a.end.x), min(b.start.x, b.end.x));
                var yStart = min(max(a.start.y, a.end.y), max(b.start.y, b.end.y));
                var xEnd = min(max(a.start.x, a.end.x), max(b.start.x, b.end.x));
                var yEnd = max(min(a.start.y, a.end.y), min(b.start.y, b.end.y));
                return Line{ .start = Point{ .x = xStart, .y = yStart }, .end = Point{ .x = xEnd, .y = yEnd } };
            }

            // else pos diag or horizontal
            var xStart = max(min(a.start.x, a.end.x), min(b.start.x, b.end.x));
            var yStart = max(min(a.start.y, a.end.y), min(b.start.y, b.end.y));
            var xEnd = min(max(a.start.x, a.end.x), max(b.start.x, b.end.x));
            var yEnd = min(max(a.start.y, a.end.y), max(b.start.y, b.end.y));
            return Line{ .start = Point{ .x = xStart, .y = yStart }, .end = Point{ .x = xEnd, .y = yEnd } };
        }

        // calculate x intersection of the lines and check if in range for both
        var xIntersect = @divFloor(aIntersect - bIntersect, bdydx - adydx);
        if (xIntersect * (bdydx - adydx) != (aIntersect - bIntersect)) // if not an int position
            return null;

        // check if in range
        var minAX = min(a.start.x, a.end.x);
        var maxAX = max(a.start.x, a.end.x);
        if (xIntersect < minAX or xIntersect > maxAX)
            return null;

        var minBX = min(b.start.x, b.end.x);
        var maxBX = max(b.start.x, b.end.x);
        if (xIntersect < minBX or xIntersect > maxBX)
            return null;

        var yIntersect = adydx * xIntersect + aIntersect;

        var minAY = min(a.start.y, a.end.y);
        var maxAY = max(a.start.y, a.end.y);
        if (yIntersect < minAY or yIntersect > maxAY)
            return null;

        var minBY = min(b.start.y, b.end.y);
        var maxBY = max(b.start.y, b.end.y);
        if (yIntersect < minBY or yIntersect > maxBY)
            return null;

        return Line{ .start = Point{ .x = xIntersect, .y = yIntersect }, .end = Point{ .x = xIntersect, .y = yIntersect } };
    }

    fn equal(a: Line, b: Line) bool {
        return (Point.equal(a.start, b.start) and Point.equal(a.end, b.end)) or (Point.equal(a.start, b.end) and Point.equal(a.end, b.start));
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
};
