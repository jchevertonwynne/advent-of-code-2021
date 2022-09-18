const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []const u8, out: anytype) !i128 {
    var start = std.time.nanoTimestamp();

    var answer = solve(contents);
    var p1 = answer.p1;
    var p2 = answer.p2;

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 1, p1, p2, duration);

    return duration;
}

fn solve(contents: []const u8) struct { p1: usize, p2: usize } {
    var p1: usize = 0;
    var p2: usize = 0;
    var parsed: [4]usize = [_]usize{std.math.maxInt(usize)} ** 4;
    var ind: usize = 0;
    var n: u2 = 0;
    while (ind < contents.len) : (n +%= 1) {
        var parse = util.toUnsignedInt(usize, contents[ind..]);
        parsed[n] = parse.result;
        p1 += @boolToInt(parsed[n] > parsed[n -% 1]);
        p2 += @boolToInt(parsed[n] > parsed[n -% 3]);
        ind += parse.size + 1;
    }
    return .{ .p1 = p1, .p2 = p2 };
}
