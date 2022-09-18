const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []const u8, out: anytype, allocator: std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var p1: usize = 0;
    var p2: usize = 0;

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 1, p1, p2, duration);

    return duration;
}
