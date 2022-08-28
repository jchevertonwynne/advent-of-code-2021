const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype) !i128 {
    var start = std.time.nanoTimestamp();

    var reader = BitReader.new(contents);

    var parsed = solve(&reader);

    var p1: usize = parsed.packetSum;
    var p2: usize = parsed.value;

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 16, p1, p2, duration);

    return duration;
}

const BitReader = struct {
    const Self = @This();
    
    source: []u8,
    sourceInd: usize,
    current: u8,
    left: u3,
    totalRead: usize,

    fn new(source: []u8) Self {
        return .{
            .source = source,
            .sourceInd = 0,
            .current = undefined,
            .left = 0,
            .totalRead = 0,
        };
    }

    fn single(self: *Self) u1 {
        defer {
            self.left -= 1;
            self.current <<= 1;
            self.totalRead += 1;
        }
        if (self.left == 0) {
            var b = self.source[self.sourceInd];
            if ('0' <= b and b <= '9') {
                b -= '0';
            } else if ('A' <= b and b <= 'F') {
                b = 10 + b - '0';
            }
            self.current = b;
            self.sourceInd += 1;
        }
        return @boolToInt(self.current & 0b10000 != 0);
    }

    fn arr(self: *Self, comptime size: usize) [size]u1 {
        var result: [size]u1 = undefined;
        for (result) |*r| {
            r.* = self.single();
        }
        return result;
    }

    fn int(self: *Self, comptime T: type, bits: usize) T {
        var _bits = bits;
        var result: T = 0;
        if (self.left < _bits) {
            self.totalRead += self.left;
            var shift = @as(u8, 4) - self.left;
            while (true) : (shift -= @truncate(u3, 1)) {
                if (shift == 0)
                    break;
                self.current >>= 1;
            }
            result = @as(T, self.current);
            _bits -= self.left;
        }
        while (_bits >= 4) : (_bits -= 4) {
            self.totalRead += 4;
            result <<= 4;
            var b = self.source[self.sourceInd];
            if ('0' <= b and b <= '9') {
                b -= '0';
            } else if ('A' <= b and b <= 'F') {
                b = 10 + b - '0';
            }
            result += @truncate(u4, b);
            self.sourceInd += 1;
        }
        var b = self.source[self.sourceInd];
        if ('0' <= b and b <= '9') {
            b -= '0';
        } else if ('A' <= b and b <= 'F') {
            b = 10 + b - '0';
        }
        self.current = b;
        self.left = 4;
        while (_bits != 0) : (_bits -= 1) {
            result <<= 1;
            result += self.single();
        }
        return result;
    }
};

fn _solve(reader: *BitReader, comptime f: fn(usize, usize) usize, start: usize, packetSum: *usize) usize {
    var value = start;
    var lengthTypeID = reader.single();
    if (lengthTypeID == 0) {
        var totalLength = reader.int(u16, 15);
        var startRead = reader.totalRead;
        while (reader.totalRead - startRead != totalLength) {
            var subparse = solve(reader);
            value = f(value, subparse.value);
            packetSum.* += subparse.packetSum;
        }
    } else {
        var totalFollowing = reader.int(u16, 11);
        var i: usize = 0;
        while (i < totalFollowing) : (i += 1) {
            var subparse = solve(reader);
            value = f(value, subparse.value);
            packetSum.* += subparse.packetSum;
        }
    }

    return value;
}

fn solve(reader: *BitReader) struct{ value: usize, packetSum: usize } {
    var packetVersion = reader.int(u3, 3);
    var packetType = reader.int(u3, 3);
    if (packetType == 4) {
        var literal: usize = 0;
        while (true) {
            var shouldBreak = reader.single() == 0;
            for (reader.arr(4)) |b| {
                literal <<= 1;
                literal += b;
            }            
            if (shouldBreak) {
                break;
            }
        }
        return .{
            .value = literal,
            .packetSum = packetVersion,
        };
    }

    var op = @intToEnum(Operator, packetType);
    var packetSum: usize = packetVersion;

    var value: usize = switch (op) {
        .sum => _solve(reader, add, 0, &packetSum),
        .product => _solve(reader, prod, 1, &packetSum),
        .minimum => _solve(reader, min, comptime std.math.maxInt(usize), &packetSum),
        .maximum => _solve(reader, max, 0, &packetSum),
        .gt => block: {
            var lengthTypeID = reader.single();
            if (lengthTypeID == 0) {
                _ = reader.int(u16, 15);
            } else {
                _ = reader.int(u16, 11);
            }
            var a = solve(reader);
            packetSum += a.packetSum;
            var b = solve(reader);
            packetSum += b.packetSum;
            break :block @boolToInt(a.value > b.value);
        },
        .lt => block: {
            var lengthTypeID = reader.single();
            if (lengthTypeID == 0) {
                _ = reader.int(u16, 15);
            } else {
                _ = reader.int(u16, 11);
            }
            var a = solve(reader);
            packetSum += a.packetSum;
            var b = solve(reader);
            packetSum += b.packetSum;
            break :block @boolToInt(a.value < b.value);
        },
        .eq => block: {
            var lengthTypeID = reader.single();
            if (lengthTypeID == 0) {
                _ = reader.int(u16, 15);
            } else {
                _ = reader.int(u16, 11);
            }
            var a = solve(reader);
            packetSum += a.packetSum;
            var b = solve(reader);
            packetSum += b.packetSum;
            break :block @boolToInt(a.value == b.value);
        },
    };

    return .{
        .value = value,
        .packetSum = packetSum,
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

fn add(a: usize, b: usize) usize {
    return a + b;
}

fn prod(a: usize, b: usize) usize {
    return a * b;
}

fn min(a: usize, b: usize) usize {
    return std.math.min(a, b);
}

fn max(a: usize, b: usize) usize {
    return std.math.max(a, b);
}