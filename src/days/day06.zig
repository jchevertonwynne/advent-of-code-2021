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
    const p1Mults = comptime createTable(80);
    const p2Mults = comptime createTable(256);

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

fn createTable(comptime limit: usize) [9]usize {
    const Vector = std.meta.Vector;
    @setEvalBranchQuota(100_000);
    var buckets = [_]Vector(9, usize){Vector(9, usize){ 0, 0, 0, 0, 0, 0, 0, 0, 0 }} ** 9;
    for (buckets[0..7]) |*m, i|
        m.*[i] = 1;

    var repeat: usize = 0;
    while (repeat < limit) : (repeat += 1) {
        std.mem.rotate(Vector(9, usize), &buckets, 1);
        buckets[6] += buckets[8];
    }

    var result = [_]usize{0} ** 9;
    for (buckets) |origins| {
        for (result) |*r, i|
            r.* += origins[i];
    }

    return result;
}
