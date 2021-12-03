const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var newLine = std.mem.indexOf(u8, contents, "\n") orelse return error.NoNewLine;
    var buf = try allocator.alloc(usize, newLine);
    errdefer allocator.free(buf);

    for (buf) |*b|
        b.* = 0;

    var ind: usize = 0;
    var totalCount: usize = 0;

    try std.io.getStdOut().writer().print("length: {}, newline: {}\n", .{ contents.len, newLine });

    var numbers = try std.ArrayList([]u8).initCapacity(allocator, contents.len / newLine + 1);
    defer numbers.deinit();

    while (ind < contents.len) : (ind += newLine + 1) {
        var i: usize = 0;
        while (i < newLine) : (i += 1) {
            try numbers.append(contents[ind .. ind + newLine - 1]);
            if (contents[ind + i] == '0')
                buf[i] += 1;
        }

        totalCount += 1;
    }

    var gamma: usize = 0;
    var epsilon: usize = 0;

    for (buf) |b| {
        gamma <<= 1;
        epsilon <<= 1;
        if ((b * 2) > totalCount)
            gamma += 1
        else {
            epsilon += 1;
        }
    }

    var oxygenNumbers = numbers;
    defer oxygenNumbers.deinit();

    var co2Numbers = try std.ArrayList([]u8).initCapacity(allocator, oxygenNumbers.items.len);
    defer co2Numbers.deinit();
    try co2Numbers.appendSlice(oxygenNumbers.items);

    var oxygenNumbers2 = try std.ArrayList([]u8).initCapacity(allocator, oxygenNumbers.items.len);
    defer oxygenNumbers2.deinit();

    var co2Numbers2 = try std.ArrayList([]u8).initCapacity(allocator, oxygenNumbers.items.len);
    defer co2Numbers2.deinit();

    var oResult: usize = 0;
    var cResult: usize = 0;

    ind = 0;
    while (ind < newLine) : (ind += 1) {
        oxygenNumbers2.clearRetainingCapacity();

        for (oxygenNumbers.items) |n|
            if (buf[ind] * 2 > totalCount)
                try oxygenNumbers2.append(n);

        if (oxygenNumbers2.items.len == 1) {
            oResult = {
                var res: usize = 0;
                for (oxygenNumbers2.items[0]) |b| {
                    res <<= 1;
                    if (b == '1')
                        res += 1;
                }
                break res;
            };
            break;
        }
    }

    ind = 0;
    while (ind < newLine) : (ind += 1) {
        co2Numbers2.clearRetainingCapacity();

        for (co2Numbers.items) |n|
            if (buf[ind] * 2 < totalCount)
                try co2Numbers2.append(n);
                
        if (co2Numbers2.items.len == 1) {
            cResult = {
                var res: usize = 0;
                for (co2Numbers2.items[0]) |b| {
                    res <<= 1;
                    if (b == '1')
                        res += 1;
                }
                break res;
            };
            break;
        }
    }

    var p1: usize = gamma * epsilon;
    var p2: usize = 0;

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 1, p1, p2, duration);

    return duration;
}
