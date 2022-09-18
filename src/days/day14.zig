const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []const u8, out: anytype, allocator: std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var polymers = try loadPolymers(contents, allocator);
    defer polymers.deinit();

    var p1: usize = undefined;
    var p2: usize = undefined;
    try solve(polymers, allocator, &p1, &p2);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 14, p1, p2, duration);

    return duration;
}

fn solve(polymers: Polymers, allocator: std.mem.Allocator, p1: *usize, p2: *usize) !void {
    var currentPolymer = std.AutoHashMap([2]u8, usize).init(allocator);
    defer currentPolymer.deinit();
    var buildingPolymer = std.AutoHashMap([2]u8, usize).init(allocator);
    defer buildingPolymer.deinit();

    for (polymers.base[0 .. polymers.base.len - 1]) |_, i| {
        var key = [2]u8{ polymers.base[i], polymers.base[i + 1] };
        var entry = try currentPolymer.getOrPut(key);
        if (!entry.found_existing)
            entry.value_ptr.* = 0;
        entry.value_ptr.* += 1;
    }

    try runRepeats(10, polymers.combos, &currentPolymer, &buildingPolymer);
    p1.* = findScore(polymers.base, currentPolymer);

    try runRepeats(30, polymers.combos, &currentPolymer, &buildingPolymer);
    p2.* = findScore(polymers.base, currentPolymer);
}

fn findScore(baseString: []const u8, currentPolymer: std.AutoHashMap([2]u8, usize)) usize {
    var table = std.mem.zeroes([26]usize);
    var it = currentPolymer.iterator();
    while (it.next()) |entry|
        table[entry.key_ptr[1] - 'A'] += entry.value_ptr.*;
    table[baseString[0] - 'A'] += 1;
    std.sort.sort(usize, &table, {}, comptime std.sort.asc(usize));
    var smallest: usize = 0;
    while (table[smallest] == 0)
        smallest += 1;
    return table[25] - table[smallest];
}

fn runRepeats(repeats: usize, combos: std.AutoHashMap([2]u8, u8), currentPolymer: *std.AutoHashMap([2]u8, usize), buildingPolymer: *std.AutoHashMap([2]u8, usize)) !void {
    var repeat: usize = 0;
    while (repeat < repeats) : (repeat += 1) {
        buildingPolymer.clearRetainingCapacity();
        var currIt = currentPolymer.iterator();
        while (currIt.next()) |pair| {
            var contained = combos.get(pair.key_ptr.*).?;

            var a = [2]u8{ pair.key_ptr[0], contained };
            var aEntry = try buildingPolymer.getOrPut(a);
            if (!aEntry.found_existing)
                aEntry.value_ptr.* = 0;
            aEntry.value_ptr.* += pair.value_ptr.*;

            var b = [2]u8{ contained, pair.key_ptr[1] };
            var bEntry = try buildingPolymer.getOrPut(b);
            if (!bEntry.found_existing)
                bEntry.value_ptr.* = 0;
            bEntry.value_ptr.* += pair.value_ptr.*;
        }
        std.mem.swap(std.AutoHashMap([2]u8, usize), currentPolymer, buildingPolymer);
    }
}

const Polymers = struct {
    base: []const u8,
    combos: std.AutoHashMap([2]u8, u8),

    fn deinit(self: *@This()) void {
        self.combos.deinit();
    }
};

fn loadPolymers(contents: []const u8, allocator: std.mem.Allocator) !Polymers {
    var ind: usize = 0;
    while (contents[ind] != '\n')
        ind += 1;

    var base = contents[0..ind];

    ind += 2;
    var combos = std.AutoHashMap([2]u8, u8).init(allocator);
    errdefer combos.deinit();
    while (ind < contents.len) : (ind += 8) {
        var entry = [2]u8{ contents[ind], contents[ind + 1] };
        var result = contents[ind + 6];
        try combos.put(entry, result);
    }

    return Polymers{ .base = base, .combos = combos };
}
