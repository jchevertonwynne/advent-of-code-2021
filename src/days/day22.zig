const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var commands = try loadCommands(contents, allocator);
    defer allocator.free(commands);

    var p1: isize = try solve(.part1, commands, allocator);
    var p2: isize = try solve(.part2, commands, allocator);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 22, p1, p2, duration);

    return duration;
}

const Part = enum {
    part1,
    part2
};

fn solve(comptime part: Part, commands: []Command, allocator: std.mem.Allocator) !isize {
    var allX = std.ArrayList(isize).init(allocator);
    defer allX.deinit();
    var allY = std.ArrayList(isize).init(allocator);
    defer allY.deinit();
    var allZ = std.ArrayList(isize).init(allocator);
    defer allZ.deinit();

    for (commands) |command| {
        if (part == .part1 and !command.cube.inInitialisationArea())
            break;
        var cube = command.cube;
        try allX.append(cube.start.x);
        try allX.append(cube.end.x);
        try allY.append(cube.start.y);
        try allY.append(cube.end.y);
        try allZ.append(cube.start.z);
        try allZ.append(cube.end.z);
    }

    std.sort.sort(isize, allX.items, {}, comptime std.sort.asc(isize));
    std.sort.sort(isize, allY.items, {}, comptime std.sort.asc(isize));
    std.sort.sort(isize, allZ.items, {}, comptime std.sort.asc(isize));

    var uniqueX = std.ArrayList(isize).init(allocator);
    defer uniqueX.deinit();
    var uniqueY = std.ArrayList(isize).init(allocator);
    defer uniqueY.deinit();
    var uniqueZ = std.ArrayList(isize).init(allocator);
    defer uniqueZ.deinit();

    try uniqueX.append(allX.items[0]);
    for (allX.items) |potX| {
        if (uniqueX.items[uniqueX.items.len - 1] != potX)
            try uniqueX.append(potX);
    }

    try uniqueY.append(allY.items[0]);
    for (allY.items) |potY| {
        if (uniqueY.items[uniqueY.items.len - 1] != potY)
            try uniqueY.append(potY);
    }

    try uniqueZ.append(allZ.items[0]);
    for (allZ.items) |potZ| {
        if (uniqueZ.items[uniqueZ.items.len - 1] != potZ)
            try uniqueZ.append(potZ);
    }

    var res: isize = 0;

    var cube: Cube = undefined;
    for (uniqueX.items[0 .. uniqueX.items.len - 1]) |x, i| {
        cube.start.x = x;
        cube.end.x = uniqueX.items[i + 1];
        for (uniqueY.items[0 .. uniqueY.items.len - 1]) |y, j| {
            cube.start.y = y;
            cube.end.y = uniqueY.items[j + 1];
            for (uniqueZ.items[0 .. uniqueZ.items.len - 1]) |z, k| {
                cube.start.z = z;
                cube.end.z = uniqueZ.items[k + 1];
                var active = false;
                for (commands) |command| {
                    if (part == .part1 and !command.cube.inInitialisationArea())
                        break;
                    if (command.cube.contains(cube))
                        active = command.on;
                }
                if (active)
                    res += cube.volume();
            }
        }
    }

    return res;
}

const Command = struct { on: bool, cube: Cube };
const Point = struct { x: isize, y: isize, z: isize };
const Cube = struct {
    start: Point,
    end: Point,

    fn contains(self: @This(), other: @This()) bool {
        return self.containsPoint(other.start) and self.containsPoint(other.end);
    }

    fn containsPoint(self: @This(), point: Point) bool {
        return self.start.x <= point.x and point.x <= self.end.x and self.start.y <= point.y and point.y <= self.end.y and self.start.z <= point.z and point.z <= self.end.z;
    }

    fn inInitialisationArea(self: @This()) bool {
        return self.start.x >= -50 and self.start.y >= -50 and self.start.z >= -50 and self.end.x <= 50 and self.end.y <= 50 and self.end.z <= 50;
    }

    fn volume(self: @This()) isize {
        var x = self.end.x - self.start.x;
        var y = self.end.y - self.start.y;
        var z = self.end.z - self.start.z;
        return x * y * z;
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
