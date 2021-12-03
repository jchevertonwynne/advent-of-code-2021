const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var newLine = std.mem.indexOf(u8, contents, "\n") orelse return error.NoNewLine;
    var buf = try allocator.alloc(usize, newLine);
    defer allocator.free(buf);

    for (buf) |*b|
        b.* = 0;

    var ind: usize = 0;
    var totalCount: usize = 0;

    var oxygenNumbers = try std.ArrayList([]u8).initCapacity(allocator, contents.len / newLine + 1);
    defer oxygenNumbers.deinit();

    while (ind < contents.len) : (ind += newLine + 1) {
        try oxygenNumbers.append(contents[ind .. ind + newLine]);
        var i: usize = 0;
        while (i < newLine) : (i += 1) {
            if (contents[ind + i] == '1')
                buf[i] += 1;
        }

        totalCount += 1;
    }

    var gamma: usize = 0;
    var epsilon: usize = 0;

    for (buf) |b| {
        gamma <<= 1;
        epsilon <<= 1;
        if ((b * 2) >= totalCount)
            gamma += 1
        else {
            epsilon += 1;
        }
    }

    var co2Numbers = try std.ArrayList([]u8).initCapacity(allocator, oxygenNumbers.items.len);
    defer co2Numbers.deinit();
    try co2Numbers.appendSlice(oxygenNumbers.items);

    var swap = try std.ArrayList([]u8).initCapacity(allocator, oxygenNumbers.items.len);
    defer swap.deinit();

    var oxygen: usize = 0;

    ind = 0;
    while (ind < newLine) : (ind += 1) {
        swap.clearRetainingCapacity();

        var count: usize = 0;
        for (oxygenNumbers.items) |n| {
            if (n[ind] == '1') {
                count += 1;
            }
        }

        var toAccept: u8 = if (count * 2 >= oxygenNumbers.items.len) '1' else '0';
        for (oxygenNumbers.items) |n| {
            if (n[ind] == toAccept) {
                try swap.append(n);
            }
        }

        if (swap.items.len == 1) {
            oxygen = block: {
                var res: usize = 0;
                for (swap.items[0]) |b| {
                    res <<= 1;
                    if (b == '1')
                        res += 1;
                }
                break :block res;
            };

            break;
        }

        var t = oxygenNumbers;
        oxygenNumbers = swap;
        swap = t;
    }

    var co2: usize = 0;

    ind = 0;
    while (ind < newLine) : (ind += 1) {
        swap.clearRetainingCapacity();

        var count: usize = 0;
        for (co2Numbers.items) |n| {
            if (n[ind] == '1') {
                count += 1;
            }
        }

        var toAccept: u8 = if (count * 2 >= co2Numbers.items.len) '0' else '1';
        for (co2Numbers.items) |c| {
            if (c[ind] == toAccept) {
                try swap.append(c);
            }
        }

        if (swap.items.len == 1) {
            co2 = block: {
                var res: usize = 0;
                for (swap.items[0]) |b| {
                    res <<= 1;
                    if (b == '1')
                        res += 1;
                }
                break :block res;
            };

            break;
        }

        var t = co2Numbers;
        co2Numbers = swap;
        swap = t;
    }

    var p1: usize = gamma * epsilon;
    var p2: usize = oxygen * co2;

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 3, p1, p2, duration);

    return duration;
}
