const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var commands = try loadCommands(contents, allocator);
    defer allocator.free(commands);

    var p1: usize = part1(commands);
    var p2: usize = 0;

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 22, p1, p2, duration);

    return duration;
}

fn part1(commands: []Command) usize {
    var res: usize = 0;

    var x: isize = -50;
    while (x <= 50) : (x += 1) {
        var y: isize = -50;
        while (y <= 50) : (y += 1) {
            var z: isize = -50;
            while (z <= 50) : (z += 1) {
                var point = Point{ .x = x, .y = y, .z = z };
                var on = false;
                for (commands[0..20]) |command| {
                    if (command.cube.contains(point))
                        on = command.on;
                }
                if (on)
                    res += 1;
            }
        }
    }

    return res;
}

fn part2(commands: []Command, allocator: std.mem.Allocator) !usize {
    // overlapping on A + on B = vol(A) + vol(B) - vol(intersection(A, B))
    // overlapping on A + off B = vol(A) - vol(intersection(A, B))
    _ = commands;
    _ = allocator;
    return 0;
}

const SubpartsResult = struct {
    intersection: Cube,
    subpartsA: std.BoundedArray(Cube, 7),
    subpartsB: std.BoundedArray(Cube, 7),
};
const Command = struct { on: bool, cube: Cube };
const Point = struct { x: isize, y: isize, z: isize };
const Cube = struct {
    start: Point,
    end: Point,

    fn contains(self: @This(), point: Point) bool {
        return self.start.x <= point.x and point.x <= self.end.x and self.start.y <= point.y and point.y <= self.end.y and self.start.z <= point.z and point.z <= self.end.z;
    }

    fn volume(self: @This()) isize {
        var x = self.end.x - self.start.x + 1;
        var y = self.end.y - self.start.y + 1;
        var z = self.end.z - self.start.z + 1;
        return x * y * z;
    }

    fn subparts(a: @This(), b: @This()) ?SubpartsResult {
        var possibleIntersection = a.intersection(b);
        if (possibleIntersection == null)
            return null;
        var _intersection = possibleIntersection.?;
        if (a.start.x > b.start.x) {
            var res = Cube.subparts(b, a).?;
            std.mem.swap(std.BoundedArray(Cube, 7), &res.subpartsA, &res.subpartsB);
            return res;
        }
        // assume a is lower than b
        var res = SubpartsResult{
            .intersection = _intersection,
            .subpartsA = std.BoundedArray(Cube, 7).init(0) catch unreachable,
            .subpartsB = std.BoundedArray(Cube, 7).init(0) catch unreachable,
        };

        if (a.start.x < _intersection.start.x) {
            // -x -y -z
            res.subpartsA.append(Cube{ .start = Point{ .x = a.start.x, .y = a.start.y, .z = a.start.z }, .end = Point{ .x = _intersection.start.x - 1, .y = _intersection.start.y - 1, .z = _intersection.start.z - 1 } }) catch unreachable;
            // -x y -z
            res.subpartsA.append(Cube{ .start = Point{ .x = a.start.x, .y = _intersection.start.y, .z = a.start.z }, .end = Point{ .x = _intersection.start.x - 1, .y = _intersection.end.y, .z = _intersection.start.z - 1 } }) catch unreachable;
            // -x -y z
            res.subpartsA.append(Cube{ .start = Point{ .x = a.start.x, .y = a.start.y, .z = _intersection.start.z }, .end = Point{ .x = _intersection.start.x - 1, .y = _intersection.start.y - 1, .z = _intersection.end.z } }) catch unreachable;
            // -x y z
            res.subpartsA.append(Cube{ .start = Point{ .x = a.start.x, .y = _intersection.start.y, .z = _intersection.start.z }, .end = Point{ .x = _intersection.start.x - 1, .y = _intersection.end.y, .z = _intersection.end.z } }) catch unreachable;
        }
        if (a.start.y < _intersection.start.y) {
            // x -y -z
            res.subpartsA.append(Cube{ .start = Point{ .x = _intersection.start.x, .y = a.start.y, .z = a.start.z }, .end = Point{ .x = _intersection.end.x, .y = _intersection.start.y - 1, .z = _intersection.start.z - 1 } }) catch unreachable;
            // x -y z
            res.subpartsA.append(Cube{ .start = Point{ .x = _intersection.start.x, .y = a.start.y, .z = _intersection.start.z }, .end = Point{ .x = _intersection.end.x, .y = _intersection.start.y - 1, .z = _intersection.end.z } }) catch unreachable;
        }
        if (a.start.z < _intersection.start.z) {
            // x y -z
            res.subpartsA.append(Cube{ .start = Point{ .x = _intersection.start.x, .y = _intersection.start.y, .z = a.start.z }, .end = Point{ .x = _intersection.end.x, .y = _intersection.end.y, .z = _intersection.start.z - 1 } }) catch unreachable;
        }

        if (b.end.x > _intersection.end.x) {
            // x y z
            res.subpartsA.append(Cube{ .start = Point{ .x = _intersection.end.x + 1, .y = _intersection.end.y + 1, .z = _intersection.end.z + 1 }, .end = Point{ .x = b.end.x, .y = b.end.y, .z = b.end.z } }) catch unreachable;
            // x -y z
            res.subpartsA.append(Cube{ .start = Point{ .x = _intersection.end.x + 1, .y = b.start.y, .z = _intersection.end.z + 1 }, .end = Point{ .x = b.end.x, .y = _intersection.end.y, .z = b.end.z } }) catch unreachable;
            // x y -z
            res.subpartsA.append(Cube{ .start = Point{ .x = _intersection.end.x + 1, .y = _intersection.end.y + 1, .z = b.start.z }, .end = Point{ .x = b.end.x, .y = b.end.y, .z = _intersection.end.z } }) catch unreachable;
            // x -y -z
            res.subpartsA.append(Cube{ .start = Point{ .x = _intersection.end.x + 1, .y = b.start.y, .z = b.start.z }, .end = Point{ .x = b.end.x, .y = _intersection.end.y, .z = _intersection.end.z } }) catch unreachable;
        }
        if (b.end.y > _intersection.end.y) {
            // -x y z
            res.subpartsA.append(Cube{ .start = Point{ .x = b.start.z, .y = _intersection.end.y + 1, .z = _intersection.end.z + 1 }, .end = Point{ .x = _intersection.end.x, .y = b.end.y, .z = b.end.z } }) catch unreachable;
            // -x y -z
            res.subpartsA.append(Cube{ .start = Point{ .x = b.start.x, .y = _intersection.end.y + 1, .z = b.start.z }, .end = Point{ .x = _intersection.end.x, .y = b.end.y - 1, .z = _intersection.end.z } }) catch unreachable;
        }
        if (b.end.z > _intersection.end.z) {
            // -x -y z
            res.subpartsA.append(Cube{ .start = Point{ .x = b.start.z, .y = b.start.y, .z = _intersection.end.z + 1 }, .end = Point{ .x = _intersection.end.x, .y = _intersection.end.y, .z = b.end.z } }) catch unreachable;
        }

        return res;
    }

    fn intersection(a: @This(), b: @This()) ?@This() {
        var result = Cube{
            .start = Point{ .x = std.math.max(a.start.x, b.start.x), .y = std.math.max(a.start.y, b.start.y), .z = std.math.max(a.start.z, b.start.z) },
            .end = Point{ .x = std.math.min(a.end.x, b.end.x), .y = std.math.min(a.end.y, b.end.y), .z = std.math.min(a.end.z, b.end.z) },
        };

        if (result.start.x > result.end.x)
            return null;

        if (result.start.y > result.end.y)
            return null;

        if (result.start.z > result.end.z)
            return null;

        return result;
    }
};

fn loadCommands(contents: []u8, allocator: std.mem.Allocator) ![]Command {
    var commands = std.ArrayList(Command).init(allocator);
    defer commands.deinit();

    var ind: usize = 0;
    while (ind < contents.len) {
        var command: Command = undefined;
        var size: usize = undefined;
        command.on = contents[ind + 1] == 'n';
        ind += 5;
        if (!command.on)
            ind += 1;
        util.toSignedInt(isize, contents[ind..], &command.cube.start.x, &size);
        ind += size + 2;
        util.toSignedInt(isize, contents[ind..], &command.cube.end.x, &size);
        ind += size + 3;
        util.toSignedInt(isize, contents[ind..], &command.cube.start.y, &size);
        ind += size + 2;
        util.toSignedInt(isize, contents[ind..], &command.cube.end.y, &size);
        ind += size + 3;
        util.toSignedInt(isize, contents[ind..], &command.cube.start.z, &size);
        ind += size + 2;
        util.toSignedInt(isize, contents[ind..], &command.cube.end.z, &size);
        ind += size + 1;
        try commands.append(command);
    }

    return commands.toOwnedSlice();
}
