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
    inline for (p1Mults) |f1, i|
        p1.* += f1 * fish[i];

    p2.* = 0;
    inline for (p2Mults) |f2, i|
        p2.* += f2 * fish[i];
}

fn loadFish(contents: []u8) [9]usize {
    var fish = std.mem.zeroes([9]usize);

    var ind: usize = 0;
    while (ind < contents.len) {
        fish[contents[ind] - '0'] += 1;
        ind += 2;
    }

    return fish;
}

fn createTable(comptime limit: usize) [7]usize {
    @setEvalBranchQuota(100_000);
    var buckets = std.mem.zeroes([9][9]usize);
    for (buckets[0..7]) |*m, i|
        m.*[i] = 1;

    var repeat: usize = 0;
    while (repeat < limit) : (repeat += 1) {
        std.mem.rotate(@TypeOf(buckets[0]), &buckets, 1);
        for (buckets[6]) |*b, i|
            b.* += buckets[8][i];
    }

    var result = std.mem.zeroes([7]usize);
    for (result) |*r, i| {
        for (buckets) |origins|
            r.* += origins[i];
    }

    return result;
}
