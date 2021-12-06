const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype) !i128 {
    var start = std.time.nanoTimestamp();

    var fish = loadFish(contents);

    var p1: usize = undefined;
    var p2: usize = undefined;
    solve(fish, &p1, &p2);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 6, p1, p2, duration);

    return duration;
}

fn solve(_fish: [9]usize, p1: *usize, p2: *usize) void {
    var fish = _fish;

    var turn: usize = 0;
    while (turn < 80) : (turn += 1) {
        var newFish = fish[0];
        var i: usize = 0;
        while (i < fish.len - 1) : (i += 1) {
            fish[i] = fish[i + 1];
        }
        fish[6] += newFish;
        fish[8] = newFish;
    }

    p1.* = 0;
    for (fish) |f|
        p1.* += f;

    while (turn < 256) : (turn += 1) {
        var newFish = fish[0];
        var i: usize = 0;
        while (i < fish.len - 1) : (i += 1) {
            fish[i] = fish[i + 1];
        }
        fish[6] += newFish;
        fish[8] = newFish;
    }

    p2.* = 0;
    for (fish) |f|
        p2.* += f;
}

fn loadFish(contents: []u8) [9]usize {
    var fish = [_]usize{0} ** 9;

    var ind: usize = 0;
    while (ind < contents.len) {
        fish[contents[ind] - '0'] += 1;
        ind += 2;
    }

    return fish;
}