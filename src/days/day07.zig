const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var crabs = try loadCrabs(contents, allocator);
    defer allocator.free(crabs);

    std.sort.sort(usize, crabs, {}, comptime std.sort.asc(usize));

    var p1: usize = part1(crabs);
    var p2: usize = part2(crabs);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 7, p1, p2, duration);

    return duration;
}

fn part1(crabs: []usize) usize {
    var middle = crabs.len / 2;
    var middlePos = crabs[middle];

    var defaultScore: usize = 0;
    for (crabs) |crab|
        defaultScore += if (crab < middlePos) middlePos - crab else crab - middlePos;

    var leftScore = defaultScore;
    while (true) : (middle -= 1) {
        var current = crabs[middle];
        var lower = crabs[middle - 1];
        var difference = current - lower;

        if (difference == 0)
            continue;

        var newScore = leftScore;
        newScore -= difference * (middle - 1);
        newScore += difference * (crabs.len - (middle - 1));
        if (newScore <= leftScore) {
            leftScore = newScore;
        } else {
            break;
        }
    }

    middle = crabs.len / 2;
    var rightScore = defaultScore;
    while (true) : (middle += 1) {
        var current = crabs[middle];
        var higher = crabs[middle + 1];
        var difference = higher - current;

        if (difference == 0)
            continue;

        var newScore = rightScore;
        newScore -= difference * (crabs.len - (middle + 1));
        newScore += difference * (middle + 1);
        if (newScore <= rightScore) {
            rightScore = newScore;
        } else {
            break;
        }
    }

    return std.math.min(leftScore, rightScore);
}

fn part2(crabs: []usize) usize {
    var sum: usize = 0;
    for (crabs) |crab|
        sum += crab;
    var average = sum / crabs.len;

    var leftPos = average;
    var left: usize = 0;
    for (crabs) |crab| {
        var dist = if (crab < leftPos) leftPos - crab else crab - leftPos;
        left += dist * (dist + 1) / 2;
    }

    var rightPos = average + 1;
    var right: usize = 0;
    for (crabs) |crab| {
        var dist = if (crab < rightPos) rightPos - crab else crab - rightPos;
        right += dist * (dist + 1) / 2;
    }

    return std.math.min(left, right);
}

fn loadCrabs(contents: []u8, allocator: *std.mem.Allocator) ![]usize {
    var crabs = std.ArrayList(usize).init(allocator);
    errdefer crabs.deinit();

    var ind: usize = 0;
    while (ind < contents.len) {
        var number: usize = undefined;
        var size: usize = 0;
        util.toInt(usize, contents[ind..], &number, &size);
        try crabs.append(number);
        ind += size + 1;
    }

    return crabs.toOwnedSlice();
}
