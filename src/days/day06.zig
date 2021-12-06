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

fn solve(fish: [9]usize, p1: *usize, p2: *usize) void {
    const p1Mults = [_]usize{ 1421, 1401, 1191, 1154, 1034, 950, 905, 0, 0 };
    const p2Mults = [_]usize{ 6703087164, 6206821033, 5617089148, 5217223242, 4726100874, 4368232009, 3989468462, 0, 0 };

    p1.* = 0;
    inline for (p1Mults) |mult, i|
        p1.* += mult * fish[i];

    p2.* = 0;
    inline for (p2Mults) |mult, i|
        p2.* += mult * fish[i];
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
