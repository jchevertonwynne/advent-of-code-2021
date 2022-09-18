const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []const u8, out: anytype, allocator: std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var caves = try loadCaves(contents, allocator);
    defer {
        for (caves) |*c|
            c.deinit();
    }

    var p1: usize = try part1(caves);
    var p2: usize = try part2(caves);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 12, p1, p2, duration);

    return duration;
}

fn part1(caves: [2706]std.ArrayList([]const u8)) !usize {
    var start = "start";
    var history = std.mem.zeroes([2706]bool);

    return explore(.part1, start, &history, null, caves);
}

fn part2(caves: [2706]std.ArrayList([]const u8)) !usize {
    var start = "start";
    var history = std.mem.zeroes([2706]bool);

    return explore(.part2, start, &history, null, caves);
}

const Part = enum { part1, part2 };

fn explore(comptime part: Part, current: []const u8, history: *[2706]bool, _doubleVisited: ?[]const u8, caves: [2706]std.ArrayList([]const u8)) usize {
    var res: usize = 0;

    for (caves[caveToIndex(current)].items) |option| {
        if (std.mem.eql(u8, "start", option))
            continue;

        if (std.mem.eql(u8, "end", option)) {
            res += 1;
            continue;
        }

        var doubleVisited = _doubleVisited;

        var legal = if (isSmallCave(option)) block: {
            if (history[caveToIndex(option)]) {
                break :block switch (part) {
                    .part1 => false,
                    .part2 => if (doubleVisited) |_| false else block2: {
                        doubleVisited = option;
                        break :block2 true;
                    },
                };
            } else break :block true;
        } else true;

        if (legal) {
            history[caveToIndex(current)] = true;
            res += explore(part, option, history, doubleVisited, caves);
        }
    }

    if (_doubleVisited) |d| {
        if (!std.mem.eql(u8, current, d))
            history[caveToIndex(current)] = false;
    } else {
        history[caveToIndex(current)] = false;
    }

    return res;
}

fn caveToIndex(cave: []const u8) usize {
    if (std.mem.eql(u8, cave, "start"))
        return 2704;
    if (std.mem.eql(u8, cave, "end"))
        return 2705;
    return if (isSmallCave(cave))
        @as(usize, cave[0] - 'a') * 52 + cave[1] - 'a'
    else
        @as(usize, cave[0] - 'A') * 52 + cave[1] - 'A';
}

fn isSmallCave(cave: []const u8) bool {
    return 'a' <= cave[0] and cave[0] <= 'z';
}

fn loadCaves(contents: []const u8, allocator: std.mem.Allocator) ![2706]std.ArrayList([]const u8) {
    var result: [2706]std.ArrayList([]const u8) = undefined;
    for (result) |*r|
        r.* = std.ArrayList([]const u8).init(allocator);
    errdefer {
        for (result) |*r|
            r.deinit();
    }

    var ind: usize = 0;
    while (ind < contents.len) {
        var hyphen = std.mem.indexOf(u8, contents[ind..], "-") orelse unreachable;
        var newline = std.mem.indexOf(u8, contents[ind..], "\n") orelse unreachable;

        var a = contents[ind .. ind + hyphen];
        var b = contents[ind + hyphen + 1 .. ind + newline];

        try result[caveToIndex(a)].append(b);
        try result[caveToIndex(b)].append(a);

        ind += newline + 1;
    }

    return result;
}
