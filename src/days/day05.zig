const std = @import("std");
const builtin = @import("builtin");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var lines = try loadLines(contents, allocator);
    defer allocator.free(lines);

    var p1: usize = 0;
    var p2: usize = 0;
    try solve(lines, allocator, &p1, &p2);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 5, p1, p2, duration);

    return duration;
}

fn loadLines(contents: []u8, allocator: *std.mem.Allocator) ![]Line {
    var lines = std.ArrayList(Line).init(allocator);
    errdefer lines.deinit();

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

        if (line.start.x > line.end.x)
            std.mem.swap(Point, &line.start, &line.end);

        try lines.append(line);
    }

    return lines.toOwnedSlice();
}

fn solve(lines: []Line, allocator: *std.mem.Allocator, p1: *usize, p2: *usize) !void {
    var intersections1 = util.HashSet(Point).init(allocator);
    defer intersections1.deinit();
    var intersections2 = util.HashSet(Point).init(allocator);
    defer intersections2.deinit();

    for (lines) |line, i| {
        for (lines[0..i]) |other| {
            var lineFlat = line.start.x == line.end.x or line.start.y == line.end.y;
            var otherFlat = other.start.x == other.end.x or other.start.y == other.end.y;
            if (Line.findIntersection(line, other)) |intersection| {
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

const min = std.math.min;
const max = std.math.max;

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

        var adx = a.end.x - a.start.x;
        var bdx = b.end.x - b.start.x;

        if (bdx == 0) {
            std.mem.swap(Line, &a, &b);
            std.mem.swap(i32, &adx, &bdx);
        }

        var minAX = min(a.start.x, a.end.x);
        var maxAX = max(a.start.x, a.end.x);
        var minAY = min(a.start.y, a.end.y);
        var maxAY = max(a.start.y, a.end.y);

        var minBX = min(b.start.x, b.end.x);
        var maxBX = max(b.start.x, b.end.x);
        var minBY = min(b.start.y, b.end.y);
        var maxBY = max(b.start.y, b.end.y);

        if (adx == 0) { // a is vertical
            if (bdx == 0) { // b is vertical
                if (a.start.x != b.start.x) // check if on same x
                    return null;
                var aLen = maxAY - minAY;
                var bLen = maxBY - minBY;
                var potLen = max4(a.start.y, a.end.y, b.start.y, b.end.y) - min4(a.start.y, a.end.y, b.start.y, b.end.y);
                if (aLen + bLen <= potLen) // check if within range of each other - total segment lengths should not exceed the potential combined
                    return null;
                var botY = max(minAY, minBY);
                var topY = min(maxAY, maxBY);
                return Line{ .start = Point{ .x = a.start.x, .y = botY }, .end = Point{ .x = a.start.x, .y = topY } };
            }
            // b is not vertical
            if (a.start.x < minBX or a.start.x > maxBX) // check if lines are within range
                return null;
            var bdy = b.end.y - b.start.y;
            var bdydx = @divFloor(bdy, bdx);
            var bIntersect = b.start.y - (b.start.x * bdydx); // where b crosses x=0
            var actualY = bdydx * a.start.x + bIntersect; // y at which b crosses a
            // check if intersect is within a
            if (actualY < minAY or actualY > maxAY)
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
            var aLen = maxAX - minAX;
            var bLen = maxBX - minBX;
            var potLen = max4(a.start.x, a.end.x, b.start.x, b.end.x) - min4(a.start.x, a.end.x, b.start.x, b.end.x);
            if (aLen + bLen <= potLen)
                return null;

            if (adydx == -1) { // negative diag
                var xStart = max(minAX, minBX);
                var yStart = min(maxAY, maxBY);
                var xEnd = min(maxAX, maxBX);
                var yEnd = max(minAY, minBY);
                return Line{ .start = Point{ .x = xStart, .y = yStart }, .end = Point{ .x = xEnd, .y = yEnd } };
            }

            // else pos diag or horizontal
            var xStart = max(minAX, minBX);
            var yStart = max(minAY, minBY);
            var xEnd = min(maxAX, maxBX);
            var yEnd = min(maxAY, maxBY);
            return Line{ .start = Point{ .x = xStart, .y = yStart }, .end = Point{ .x = xEnd, .y = yEnd } };
        }

        // calculate x intersection of the lines and check if in range for both
        var xIntersect = @divFloor(aIntersect - bIntersect, bdydx - adydx);
        if (xIntersect * (bdydx - adydx) != (aIntersect - bIntersect)) // if not an int position
            return null;

        // check if in range
        if (xIntersect < minAX or xIntersect > maxAX)
            return null;

        if (xIntersect < minBX or xIntersect > maxBX)
            return null;

        var yIntersect = adydx * xIntersect + aIntersect;

        if (yIntersect < minAY or yIntersect > maxAY)
            return null;

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

fn max4(a: anytype, b: anytype, c: anytype, d: anytype) @TypeOf(a, b, c, d) {
    return max(max(a, b), max(c, d));
}

fn min4(a: anytype, b: anytype, c: anytype, d: anytype) @TypeOf(a, b, c, d) {
    return min(min(a, b), min(c, d));
}
