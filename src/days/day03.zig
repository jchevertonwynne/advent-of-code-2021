const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var newLine = std.mem.indexOf(u8, contents, "\n") orelse return error.NoNewLine;
    // var totalCount = contents.len / (newLine + 1);

    var table = try allocator.alloc(usize, std.math.pow(usize, 2, newLine));
    defer allocator.free(table);

    for (table) |*t|
        t.* = 0;

    var ind: usize = 0;
    while (ind < contents.len) : (ind += newLine + 1) {
        var curr: usize = 0;
        for (contents[ind .. ind + newLine]) |c| {
            table[curr] += 1;
            curr *= 2;
            curr += c - '0';
        }
    }

    var gamma: usize = 0;
    ind = 0;
    while (ind * 2 + 2 < table.len) {
        gamma <<= 1;
        var a = table[ind * 2 + 1];
        var b = table[ind * 2 + 2];
        ind *= 2;
        ind += @boolToInt(b > a) + 1;
        gamma += @boolToInt(b > a) + 1;
    }

    var mask: usize = 1;
    mask <<= @truncate(u6, newLine);
    var p1: usize = gamma * ((~gamma) & (mask - 1));

    var p2: usize = 0;

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 3, p1, p2, duration);

    return duration;
}

fn oxygenCondition(count: usize, actual: usize) u8 {
    return @as(u8, @boolToInt(count >= actual)) + '0';
}

fn co2Condition(count: usize, actual: usize) u8 {
    return @as(u8, @boolToInt(count < actual)) + '0';
}

fn runner(lineLength: usize, main: *std.ArrayList([]u8), swap: *std.ArrayList([]u8), buf: []usize, condition: fn (usize, usize) u8) !usize {
    var ind: usize = 0;
    while (ind < lineLength) : (ind += 1) {
        swap.clearRetainingCapacity();

        var toAccept: u8 = condition(buf[ind], main.items.len);
        for (main.items) |potential| {
            if (potential[ind] == toAccept)
                try swap.append(potential)
            else for (potential) |digit, i|
                buf[i] -= (digit - '0') * 2;
        }

        if (swap.items.len == 1) {
            var res: usize = 0;
            for (swap.items[0]) |b| {
                res <<= 1;
                res += b - '0';
            }
            return res;
        }

        var t = main.*;
        main.* = swap.*;
        swap.* = t;
    }

    return error.NoSolutionFound;
}
