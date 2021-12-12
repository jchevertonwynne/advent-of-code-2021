const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var caves = try loadCaves(contents, allocator);
    defer {
        var it = caves.valueIterator();
        while (it.next()) |v|
            v.deinit();
        caves.deinit();
    }

    var p1: usize = try part1(caves, allocator);
    var p2: usize = try part2(caves, allocator);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 12, p1, p2, duration);

    return duration;
}

fn part1(caves: std.StringHashMap(std.ArrayList([]const u8)), allocator: *std.mem.Allocator) !usize {
    var start = "start";
    var history = std.ArrayList([]const u8).init(allocator);
    defer history.deinit();

    return try explore(.part1, start, &history, false, caves);
}

fn part2(caves: std.StringHashMap(std.ArrayList([]const u8)), allocator: *std.mem.Allocator) !usize {
    var start = "start";
    var history = std.ArrayList([]const u8).init(allocator);
    defer history.deinit();

    return try explore(.part2, start, &history, false, caves);
}

const Part = enum { part1, part2 };

fn explore(comptime part: Part, current: []const u8, history: *std.ArrayList([]const u8), _doubleVisited: bool, caves: std.StringHashMap(std.ArrayList([]const u8))) anyerror!usize {
    var res: usize = 0;

    for ((caves.get(current) orelse unreachable).items) |option| {
        if (std.mem.eql(u8, "start", option))
            continue;

        if (std.mem.eql(u8, "end", option)) {
            res += 1;
            continue;
        }

        var doubleVisited = _doubleVisited;

        var legal = switch (part) {
            .part1 => if (isSmallCave(option)) block: {
                for (history.items) |h| {
                    if (std.mem.eql(u8, h, option))
                        break :block false;
                }

                break :block true;
            } else true,
            .part2 => if (isSmallCave(option)) block: {
                for (history.items) |h| {
                    if (std.mem.eql(u8, h, option)) {
                        if (doubleVisited) {
                            break :block false;
                        } else {
                            doubleVisited = true;
                        }
                    }
                }

                break :block true;
            } else true,
        };

        if (legal) {
            try history.append(current);
            res += try explore(part, option, history, doubleVisited, caves);
        }
    }

    _ = history.popOrNull();

    return res;
}

fn isSmallCave(cave: []const u8) bool {
    for (cave) |c| {
        if (c < 'a' or c > 'z')
            return false;
    }

    return true;
}

fn loadCaves(contents: []u8, allocator: *std.mem.Allocator) !std.StringHashMap(std.ArrayList([]const u8)) {
    var result = std.StringHashMap(std.ArrayList([]const u8)).init(allocator);
    errdefer {
        var it = result.valueIterator();
        while (it.next()) |v|
            v.*.deinit();
        result.deinit();
    }

    var ind: usize = 0;
    while (ind < contents.len) {
        var hyphen = std.mem.indexOf(u8, contents[ind..], "-") orelse unreachable;
        var newline = std.mem.indexOf(u8, contents[ind..], "\n") orelse unreachable;

        var a = contents[ind .. ind + hyphen];
        var b = contents[ind + hyphen + 1 .. ind + newline];

        var aEntry = try result.getOrPut(a);
        if (!aEntry.found_existing)
            aEntry.value_ptr.* = std.ArrayList([]const u8).init(allocator);
        try aEntry.value_ptr.*.append(b);

        var bEntry = try result.getOrPut(b);
        if (!bEntry.found_existing)
            bEntry.value_ptr.* = std.ArrayList([]const u8).init(allocator);
        try bEntry.value_ptr.*.append(a);

        ind += newline + 1;
    }

    return result;
}
