const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var crabs = try loadCrabs(contents, allocator);
    defer allocator.free(crabs);

    var min = std.mem.min(usize, crabs);
    var max = std.mem.max(usize, crabs);

    var p1: usize = part1(crabs, min, max);
    var p2: usize = part2(crabs, min, max);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 7, p1, p2, duration);

    return duration;
}

fn part1(crabs: []usize, _min: usize, max: usize) usize {
    var min = _min;

    var best: usize = std.math.maxInt(usize);
    while (min <= max) : (min += 1) {
        var fuel: usize = 0;
        for (crabs) |crab| {
            fuel += if (crab < min)
                min - crab
            else
                crab - min;
        }
        if (fuel < best)
            best = fuel
        else 
            break;
    }
    return best;
}

fn part2(crabs: []usize, _min: usize, max: usize) usize {
    var min = _min;

    var best: usize = std.math.maxInt(usize);
    while (min <= max) : (min += 1) {
        var fuel: usize = 0;
        for (crabs) |crab| {
            var distance = if (crab < min)
                min - crab
            else
                crab - min;
            fuel += distance * (distance + 1) / 2;
        }
        if (fuel < best)
            best = fuel
        else 
            break;
    }
    return best;
}

fn loadCrabs(contents: []u8, allocator: *std.mem.Allocator) ![]usize {
    var crabs = std.ArrayList(usize).init(allocator);
    errdefer crabs.deinit();

    var ind: usize = 0;
    while (ind < contents.len) {
        var number: usize = undefined;
        var size: usize = 0;
        util.toUint(usize, contents[ind..], &number, &size);
        try crabs.append(number);
        ind += size + 1;
    }

    return crabs.toOwnedSlice();
}