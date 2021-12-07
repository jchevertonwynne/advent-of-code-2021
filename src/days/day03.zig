const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var newline = std.mem.indexOf(u8, contents, "\n") orelse return error.Nonewline;
    var totalCount = contents.len / (newline + 1);

    var part1Table = try allocator.alloc(usize, newline);
    defer allocator.free(part1Table);
    for (part1Table) |*t|
        t.* = 0;

    var part2Table = try allocator.alloc(usize, std.math.pow(usize, 2, newline + 1));
    defer allocator.free(part2Table);
    for (part2Table) |*t|
        t.* = 0;

    var ind: usize = 0;
    while (ind < contents.len) : (ind += newline + 1) {
        var curr: usize = 1;
        for (contents[ind .. ind + newline]) |c, i| {
            part1Table[i] += c - '0';
            part2Table[curr + c - '0' - 1] += 1;
            curr += c - '0';
            curr *= 2;
            curr += 1;
        }
    }

    var gamma: usize = 0;
    ind = 1;
    for (part1Table) |t| {
        gamma <<= 1;
        gamma += @boolToInt((t * 2) >= totalCount);
    }

    var epsilon = ((~gamma) & ((@as(usize, 1) << @truncate(u6, newline)) - 1));
    var p1: usize = gamma * epsilon;

    var oxygen = calculateChemical(.oxygen, newline, part2Table);
    var co2 = calculateChemical(.co2, newline, part2Table);
    var p2: usize = oxygen * co2;

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 3, p1, p2, duration);

    return duration;
}

const Chemical = enum { oxygen, co2 };

fn calculateChemical(comptime chemical: Chemical, newline: usize, table: []usize) usize {
    var bits: usize = 0;
    var ind: usize = 1;
    var result: usize = 0;
    while (bits < newline) : (bits += 1) {
        var left = table[ind - 1];
        var right = table[ind];
        var res = switch (chemical) {
            .oxygen => block: {
                if (left + right == 1) {
                    break :block 1 - left;
                }
                break :block @boolToInt(left <= right);
            },
            .co2 => block: {
                if (left + right == 1) {
                    break :block 1 - left;
                }
                break :block @boolToInt(right < left);
            },
        };

        result <<= 1;
        result += res;
        ind += res;
        ind *= 2;
        ind += 1;
    }

    return result;
}
