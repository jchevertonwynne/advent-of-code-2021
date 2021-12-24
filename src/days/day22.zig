const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var commands = try loadCommands(contents, allocator);
    defer allocator.free(commands);

    var p1: isize = try part1(commands, allocator);
    var p2: isize = 0;

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 22, p1, p2, duration);

    return duration;
}

fn part1(commands: []Command, allocator: std.mem.Allocator) !isize {
    var on = std.ArrayList(Cube).init(allocator);
    defer on.deinit();
    try on.append(commands[0].cube);

    var newOn = std.ArrayList(Cube).init(allocator);
    defer newOn.deinit();

    for (commands[1..]) |command| {
        if (!command.cube.initialisation())
            break;

        newOn.clearRetainingCapacity();

        std.debug.print("on items len = {}\n", .{on.items.len});

        var wasIntersection = false;

        for (on.items) |onCube| {
            // std.debug.print("looking at {}\n", .{command.cube});
            if (onCube.subparts(command.cube)) |*subparts| {
                wasIntersection = true;
                // std.debug.print("parts = {d}\n", .{subparts.slice()});
                var toAdd = std.BoundedArray(Cube, 27).init(0) catch unreachable;
                for (subparts.slice()) |s| {
                    // std.debug.print("{}\n", .{s});
                    if (command.on) {
                        if (onCube.intersection(s) != null or command.cube.intersection(s) != null)
                            toAdd.append(s) catch unreachable;
                    } else {
                        if (onCube.intersection(s) != null and command.cube.intersection(s) == null)
                            toAdd.append(s) catch unreachable;
                    }
                }
                // std.debug.print("wanted parts = {d}\n", .{toAdd.slice()});
                optimise(&toAdd);
                // std.debug.print("optimised wanted parts = {d}\n", .{toAdd.slice()});
                try newOn.appendSlice(toAdd.slice());
            } else {
                try newOn.append(onCube);
            }
        }

        if (!wasIntersection and command.on)
            try newOn.append(command.cube);

        std.mem.swap(@TypeOf(on, newOn), &on, &newOn);
    }

    std.debug.print("final len = {}\n", .{on.items.len});

    var res: isize = 0;
    for (on.items) |c| {
        res += c.volume();
        std.debug.print("{}\n", .{c});
    }

    return res;
}

fn part2(commands: []Command, allocator: std.mem.Allocator) !isize {
    var on = std.ArrayList(Cube).init(allocator);
    defer on.deinit();
    try on.append(commands[0].cube);

    // for (commands[1..]) |command| {
    //     var newOn = std.ArrayList(Cube).init(allocator);
    //     defer newOn.deinit();

    //     // for (on.items) |onCube| {
    //     //     if (onCube.intersection(command.cube)) |_| {
    //     //         var subparts = onCube.subparts(command.cube);
    //     //     }
    //     // }

    //     std.mem.swap(@TypeOf(on, newOn), &on, &newOn);
    // }

    return 0;
}

fn optimise(cubes: *std.BoundedArray(Cube, 27)) void {
    while (true) {
        var change = false;

        var slice = cubes.slice();

        loop: for (slice) |a, ind| {
            for (slice[ind + 1 ..]) |b, ind2| {
                if (a.start.x == b.start.x and a.start.y == b.start.y and a.end.x == b.end.x and a.end.y == b.end.y and a.end.z == b.start.z) {
                    var newCube = Cube{ .start = a.start, .end = b.end };
                    // std.debug.print("combining\n{} and\n{} into\n{}\n{} + {} == {}", .{a,b,newCube,a.volume(),b.volume(),newCube.volume()});
                    slice[ind] = newCube;
                    slice[ind + 1 + ind2] = slice[slice.len - 1];
                    _ = cubes.pop();
                    change = true;
                    break :loop;
                }
                if (a.start.x == b.start.x and a.start.z == b.start.z and a.end.x == b.end.x and a.end.z == b.end.z and a.end.y == b.start.y) {
                    var newCube = Cube{ .start = a.start, .end = b.end };
                    // std.debug.print("combining\n{} and\n{} into\n{}\n{} + {} == {}", .{a,b,newCube,a.volume(),b.volume(),newCube.volume()});
                    slice[ind] = newCube;
                    slice[ind + 1 + ind2] = slice[slice.len - 1];
                    _ = cubes.pop();
                    change = true;
                    break :loop;
                }
                if (a.start.y == b.start.y and a.start.z == b.start.z and a.end.y == b.end.y and a.end.z == b.end.z and a.end.x == b.start.x) {
                    var newCube = Cube{ .start = a.start, .end = b.end };
                    // std.debug.print("combining\n{} and\n{} into\n{}\n{} + {} == {}", .{a,b,newCube,a.volume(),b.volume(),newCube.volume()});
                    slice[ind] = newCube;
                    slice[ind + 1 + ind2] = slice[slice.len - 1];
                    _ = cubes.pop();
                    change = true;
                    break :loop;
                }
            }
        }

        if (!change)
            return;
    }
}

const Command = struct { on: bool, cube: Cube };
const Point = struct { x: isize, y: isize, z: isize };
const Cube = struct {
    start: Point,
    end: Point,

    fn contains(self: @This(), point: Point) bool {
        return self.start.x <= point.x and point.x < self.end.x and self.start.y <= point.y and point.y < self.end.y and self.start.z <= point.z and point.z < self.end.z;
    }

    fn initialisation(self: @This()) bool {
        return self.start.x >= -50 and self.start.y >= -50 and self.start.z >= -50 and self.end.x <= 50 and self.end.y <= 50 and self.end.z <= 50;
    }

    fn volume(self: @This()) isize {
        var x = self.end.x - self.start.x;
        var y = self.end.y - self.start.y;
        var z = self.end.z - self.start.z;
        return x * y * z;
    }

    fn subparts(a: @This(), b: @This()) ?std.BoundedArray(Cube, 27) {
        var possibleIntersection = a.intersection(b);
        if (possibleIntersection == null)
            return null;

        var result = std.BoundedArray(Cube, 27).init(0) catch unreachable;

        var x = [4]isize{ a.start.x, a.end.x, b.start.x, b.end.x };
        var y = [4]isize{ a.start.y, a.end.y, b.start.y, b.end.y };
        var z = [4]isize{ a.start.z, a.end.z, b.start.z, b.end.z };

        std.sort.sort(isize, &x, {}, comptime std.sort.asc(isize));
        std.sort.sort(isize, &y, {}, comptime std.sort.asc(isize));
        std.sort.sort(isize, &z, {}, comptime std.sort.asc(isize));

        for (x[0..3]) |_, i| {
            for (y[0..3]) |_, j| {
                for (z[0..3]) |_, k| {
                    var cube: Cube = undefined;
                    cube.start.x = x[i];
                    cube.start.y = y[j];
                    cube.start.z = z[k];
                    cube.end.x = x[i + 1];
                    cube.end.y = y[j + 1];
                    cube.end.z = z[k + 1];
                    if (cube.start.x == cube.end.x)
                        continue;
                    if (cube.start.y == cube.end.y)
                        continue;
                    if (cube.start.z == cube.end.z)
                        continue;
                    result.append(cube) catch unreachable;
                }
            }
        }

        return result;
    }

    fn intersection(a: @This(), b: @This()) ?@This() {
        var result = Cube{
            .start = Point{ .x = std.math.max(a.start.x, b.start.x), .y = std.math.max(a.start.y, b.start.y), .z = std.math.max(a.start.z, b.start.z) },
            .end = Point{ .x = std.math.min(a.end.x, b.end.x), .y = std.math.min(a.end.y, b.end.y), .z = std.math.min(a.end.z, b.end.z) },
        };

        if (result.start.x >= result.end.x)
            return null;

        if (result.start.y >= result.end.y)
            return null;

        if (result.start.z >= result.end.z)
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
        command.cube.end.x += 1;
        ind += size + 3;
        util.toSignedInt(isize, contents[ind..], &command.cube.start.y, &size);
        ind += size + 2;
        util.toSignedInt(isize, contents[ind..], &command.cube.end.y, &size);
        command.cube.end.y += 1;
        ind += size + 3;
        util.toSignedInt(isize, contents[ind..], &command.cube.start.z, &size);
        ind += size + 2;
        util.toSignedInt(isize, contents[ind..], &command.cube.end.z, &size);
        command.cube.end.z += 1;
        ind += size + 1;
        try commands.append(command);
    }

    return commands.toOwnedSlice();
}
