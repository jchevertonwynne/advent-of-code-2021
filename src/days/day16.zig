const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var newLine = std.mem.lastIndexOfLinear(u8, contents, "\n") orelse unreachable;
    var bits = try toBits(contents[0..newLine], allocator);
    defer allocator.free(bits);

    var parsed = solve(bits, 0);

    var p1: usize = parsed.packetSum;
    var p2: usize = parsed.value;

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 16, p1, p2, duration);

    return duration;
}

fn solve(bits: []u1, depth: usize,) struct{ value: usize, packetSum: usize, remaining: []u1 } {
    var packetVersion = uintFrom(u3, bits[0..3]);
    var packetType = uintFrom(u3, bits[3..6]);
    if (packetType == 4) {
        var literal: usize = 0;
        var remaining = bits[6..];
        while (true) {
            var segment = remaining[0..5];
            for (segment[1..]) |b| {
                literal <<= 1;
                literal += b;
            }            
            remaining = remaining[5..];
            if (segment[0] == 0) {
                break;
            }
        }
        return .{
            .value = literal,
            .packetSum = packetVersion,
            .remaining = remaining,
        };
    }

    var op = @intToEnum(Operator, packetType);
    var packetSum: usize = packetVersion;
    var remaining: []u1 = undefined;

    var value: usize = switch (op) {
        .sum => block: {
            var sum: usize = 0;
            var lengthTypeID = bits[6];
            if (lengthTypeID == 0) {
                var totalLength = uintFrom(usize, bits[7..22]);
                remaining = bits[22..];
                var startLen = remaining.len;
                while (startLen - remaining.len != totalLength) {
                    var subparse = solve(remaining, depth + 1);
                    sum += subparse.value;
                    remaining = subparse.remaining;
                    packetSum += subparse.packetSum;
                }
            } else {
                var totalFollowing = uintFrom(usize, bits[7..18]);
                remaining = bits[18..];
                var i: usize = 0;
                while (i < totalFollowing) : (i += 1) {
                    var subparse = solve(remaining, depth + 1);
                    sum += subparse.value;
                    remaining = subparse.remaining;
                    packetSum += subparse.packetSum;
                }
            }
            break :block sum;
        },
        .product => block: {
            var product: usize = 1;
            var lengthTypeID = bits[6];
            if (lengthTypeID == 0) {
                var totalLength = uintFrom(usize, bits[7..22]);
                remaining = bits[22..];
                var startLen = remaining.len;
                while (startLen - remaining.len != totalLength) {
                    var subparse = solve(remaining, depth + 1);
                    product *= subparse.value;
                    remaining = subparse.remaining;
                    packetSum += subparse.packetSum;
                }
            } else {
                var totalFollowing = uintFrom(usize, bits[7..18]);
                remaining = bits[18..];
                var i: usize = 0;
                while (i < totalFollowing) : (i += 1) {
                    var subparse = solve(remaining, depth + 1);
                    product *= subparse.value;
                    remaining = subparse.remaining;
                    packetSum += subparse.packetSum;
                }
            }
            break :block product;
        },
        .minimum => block: {
            var minimum: usize = comptime std.math.maxInt(usize);
            var lengthTypeID = bits[6];
            if (lengthTypeID == 0) {
                var totalLength = uintFrom(usize, bits[7..22]);
                remaining = bits[22..];
                var startLen = remaining.len;
                while (startLen - remaining.len != totalLength) {
                    var subparse = solve(remaining, depth + 1);
                    minimum = std.math.min(minimum, subparse.value);
                    remaining = subparse.remaining;
                    packetSum += subparse.packetSum;
                }
            } else {
                var totalFollowing = uintFrom(usize, bits[7..18]);
                remaining = bits[18..];
                var i: usize = 0;
                while (i < totalFollowing) : (i += 1) {
                    var subparse = solve(remaining, depth + 1);
                    minimum = std.math.min(minimum, subparse.value);
                    remaining = subparse.remaining;
                    packetSum += subparse.packetSum;
                }
            }
            break :block minimum;
        },
        .maximum => block: {
            var maximum: usize = 0;
            var lengthTypeID = bits[6];
            if (lengthTypeID == 0) {
                var totalLength = uintFrom(usize, bits[7..22]);
                remaining = bits[22..];
                var startLen = remaining.len;
                while (startLen - remaining.len != totalLength) {
                    var subparse = solve(remaining, depth + 1);
                    maximum = std.math.max(maximum, subparse.value);
                    remaining = subparse.remaining;
                    packetSum += subparse.packetSum;
                }
            } else {
                var totalFollowing = uintFrom(usize, bits[7..18]);
                remaining = bits[18..];
                var i: usize = 0;
                while (i < totalFollowing) : (i += 1) {
                    var subparse = solve(remaining, depth + 1);
                    maximum = std.math.max(maximum, subparse.value);
                    remaining = subparse.remaining;
                    packetSum += subparse.packetSum;
                }
            }
            break :block maximum;
        },
        .gt => block: {
            var lengthTypeID = bits[6];
            if (lengthTypeID == 0) {
                remaining = bits[22..];
            } else {
                remaining = bits[18..];
            }
            var a = solve(remaining, depth + 1);
            remaining = a.remaining;
            packetSum += a.packetSum;
            var b = solve(remaining, depth + 1);
            remaining = b.remaining;
            packetSum += b.packetSum;
            break :block @boolToInt(a.value > b.value);
        },
        .lt => block: {
            var lengthTypeID = bits[6];
            if (lengthTypeID == 0) {
                remaining = bits[22..];
            } else {
                remaining = bits[18..];
            }
            var a = solve(remaining, depth + 1);
            remaining = a.remaining;
            packetSum += a.packetSum;
            var b = solve(remaining, depth + 1);
            remaining = b.remaining;
            packetSum += b.packetSum;
            break :block @boolToInt(a.value < b.value);
        },
        .eq => block: {
            var lengthTypeID = bits[6];
            if (lengthTypeID == 0) {
                remaining = bits[22..];
            } else {
                remaining = bits[18..];
            }
            var a = solve(remaining, depth + 1);
            remaining = a.remaining;
            packetSum += a.packetSum;
            var b = solve(remaining, depth + 1);
            remaining = b.remaining;
            packetSum += b.packetSum;
            break :block @boolToInt(a.value == b.value);
        },
    };

    return .{
        .value = value,
        .packetSum = packetSum,
        .remaining = remaining,
    };
}

const Operator = enum(u3) {
    sum = 0,
    product = 1,
    minimum = 2,
    maximum = 3,
    gt = 5,
    lt = 6,
    eq = 7,
};

fn uintFrom(comptime T: type, source: []u1) T {
    var result: T = 0;
    for (source) |s| {
        result <<= 1;
        result += s;
    }
    return result;
}

fn toBits(contents: []u8, allocator: std.mem.Allocator) ![]u1 {
    var res = std.ArrayList(u1).init(allocator);
    errdefer res.deinit();

    for (contents) |c| {
        var binaryContents = switch (c) {
            '0' => [4]u1{ 0, 0, 0, 0 },
            '1' => [4]u1{ 0, 0, 0, 1 },
            '2' => [4]u1{ 0, 0, 1, 0 },
            '3' => [4]u1{ 0, 0, 1, 1 },
            '4' => [4]u1{ 0, 1, 0, 0 },
            '5' => [4]u1{ 0, 1, 0, 1 },
            '6' => [4]u1{ 0, 1, 1, 0 },
            '7' => [4]u1{ 0, 1, 1, 1 },
            '8' => [4]u1{ 1, 0, 0, 0 },
            '9' => [4]u1{ 1, 0, 0, 1 },
            'A' => [4]u1{ 1, 0, 1, 0 },
            'B' => [4]u1{ 1, 0, 1, 1 },
            'C' => [4]u1{ 1, 1, 0, 0 },
            'D' => [4]u1{ 1, 1, 0, 1 },
            'E' => [4]u1{ 1, 1, 1, 0 },
            'F' => [4]u1{ 1, 1, 1, 1 },
            else => unreachable,
        };
        try res.appendSlice(&binaryContents);
    }

    return res.toOwnedSlice();
}
