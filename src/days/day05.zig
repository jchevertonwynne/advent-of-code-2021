const std = @import("std");
const builtin = @import("builtin");

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

        if (line.start.x > line.end.x)
            std.mem.swap(Point, &line.start, &line.end);

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
                var traverse = intersection.traverse();
                // std.debug.print("({},{}) => ({},{}) intersects ({},{}) => ({},{})\n", .{line.start.x, line.start.y, line.end.x, line.end.y, other.start.x, other.start.y, other.end.x, other.end.y});
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
        var dy: i32 = 0;
        if (from.start.y < from.end.y)
            dy = 1;
        if (from.start.y > from.end.y)
            dy = -1;
        return .{ .line = from, .dx = @boolToInt(from.start.x < from.end.x), .dy = dy, .first = true };
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

    fn findIntersection(a: Line, b: Line) ?Line {
        var aFlat = a.start.y == a.end.y;
        var aVert = a.start.x == a.end.x;

        var bFlat = b.start.y == b.end.y;
        var bVert = b.start.x == b.end.x;

        if ((aFlat or aVert) and (bFlat or bVert)) {
            if (a.start.x > b.end.x or b.start.x > a.end.x or a.start.y > b.end.y or b.start.y > a.end.y)
                return null;

            return Line{ .start = Point{
                .x = std.math.max(a.start.x, b.start.x),
                .y = std.math.max(a.start.y, b.start.y),
            }, .end = Point{ .x = std.math.min(a.end.x, b.end.x), .y = std.math.min(a.end.y, b.end.y) } };
        }

        return null;
    }
};

const Point = struct {
    x: i32,
    y: i32,

    fn equal(a: Point, b: Point) bool {
        return a.x == b.x and a.y == b.y;
    }
};
