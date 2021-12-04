const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype) !i128 {
    var start = std.time.nanoTimestamp();

    var p1: usize = 0;
    var p2: usize = 0;
    try solve(contents, &p1, &p2);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 1, p1, p2, duration);

    return duration;
}

fn solve(contents: []u8, p1: *usize, p2: *usize) !void {
    var parsed: [4]usize = undefined;
    var ind: usize = 0;
    var n: usize = 0;
    while (ind < contents.len) : (n += 1) {
        var number: usize = undefined;
        var size: usize = undefined;
        toUsize(contents[ind..], &number, &size);
        parsed[n % parsed.len] = number;
        if (n >= 1 and parsed[n % parsed.len] > parsed[(n - 1) % parsed.len])
            p1.* += 1;
        if (n >= 3 and parsed[n % parsed.len] > parsed[(n - 3) % parsed.len])
            p2.* += 1;

        ind += size + 1;
    }
}

fn toUsize(contents: []u8, number: *usize, size: *usize) void {
    var result: usize = 0;
    var characters: usize = 0;

    for (contents) |char, i| {
        if ('0' <= char and char <= '9') {
            result *= 10;
            result += @as(usize, char - '0');
            characters = i;
        } else break;
    }

    number.* = result;
    size.* = characters + 1;
}
