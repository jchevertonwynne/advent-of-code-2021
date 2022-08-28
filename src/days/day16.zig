const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype) !i128 {
    var start = std.time.nanoTimestamp();

    var reader = try BitReader.new(contents);
    var parsed = try solve(&reader);

    var p1: usize = parsed.packetSum;
    var p2: usize = parsed.value;

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 16, p1, p2, duration);

    return duration;
}

const RunError = error{
    InvalidInput,
};

const SolveResult = struct {
    value: usize,
    packetSum: usize,
};

fn solve(reader: *BitReader) RunError!SolveResult {
    var packetVersion = try reader.int(u3, 3);
    var packetType = try reader.int(u3, 3);
    var packetSum: usize = packetVersion;

    var value: usize = switch (packetType) {
        0 => try solveN(reader, add, 0, &packetSum),
        1 => try solveN(reader, prod, 1, &packetSum),
        2 => try solveN(reader, min, std.math.maxInt(usize), &packetSum),
        3 => try solveN(reader, max, 0, &packetSum),
        4 => try literal(reader),
        5 => try solve2(reader, gt, &packetSum),
        6 => try solve2(reader, lt, &packetSum),
        7 => try solve2(reader, eq, &packetSum),
    };

    return SolveResult{
        .value = value,
        .packetSum = packetSum,
    };
}

fn solveN(reader: *BitReader, comptime f: fn (usize, usize) usize, start: usize, packetSum: *usize) RunError!usize {
    var value = start;
    var lengthTypeID = try reader.single();
    if (lengthTypeID == 0) {
        var totalLength = try reader.int(u15, 15);
        var startRead = reader.totalRead;
        while (reader.totalRead - startRead != totalLength) {
            var subparse = try solve(reader);
            value = f(value, subparse.value);
            packetSum.* += subparse.packetSum;
        }
    } else {
        var totalFollowing = try reader.int(u11, 11);
        var i: usize = 0;
        while (i < totalFollowing) : (i += 1) {
            var subparse = try solve(reader);
            value = f(value, subparse.value);
            packetSum.* += subparse.packetSum;
        }
    }

    return value;
}

fn solve2(reader: *BitReader, comptime f: fn (usize, usize) usize, packetSum: *usize) RunError!usize {
    var lengthTypeID = try reader.single();
    if (lengthTypeID == 0) {
        try reader.skip(15);
    } else {
        try reader.skip(11);
    }

    var a = try solve(reader);
    var b = try solve(reader);

    packetSum.* += a.packetSum + b.packetSum;

    return f(a.value, b.value);
}

fn literal(reader: *BitReader) !usize {
    var lit: usize = 0;
    while (true) {
        var shouldBreak = try reader.single() == 0;
        lit = (lit << 4) + try reader.int(u4, 4);
        if (shouldBreak) {
            break;
        }
    }
    return lit;
}

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

fn lt(a: usize, b: usize) usize {
    return @boolToInt(a < b);
}

fn gt(a: usize, b: usize) usize {
    return @boolToInt(a > b);
}

fn eq(a: usize, b: usize) usize {
    return @boolToInt(a == b);
}

const BitReader = struct {
    const Self = @This();

    source: []u8,
    sourceInd: usize,
    current: u8,
    left: u3,
    totalRead: usize,

    fn new(source: []u8) !Self {
        return Self{
            .source = source,
            .sourceInd = 0,
            .current = undefined,
            .left = 0,
            .totalRead = 0,
        };
    }

    fn _ensureReady(self: *Self) RunError!void {
        if (self.left == 0) {
            try self._readyNext();
        }
    }

    fn single(self: *Self) RunError!u1 {
        try self._ensureReady();
        self.current <<= 1;
        var result = @boolToInt(self.current & 0b10000 != 0);
        self.left -= 1;
        self.totalRead += 1;
        return result;
    }

    fn skip(self: *Self, toSkip: usize) RunError!void {
        _ = try self.int(usize, toSkip);
    }

    fn _readyNext(self: *Self) !void {
        self.current = try convertHex(self.source[self.sourceInd]);
        self.sourceInd += 1;
        self.left = 4;
    }

    fn int(self: *Self, comptime T: type, bits: usize) RunError!T {
        try self._ensureReady();
        var _bits = bits;
        var result: T = 0;
        while (_bits != 0) : (_bits -= 1) {
            result = (result << 1) + try self.single();
        }
        return result;
    }
};

fn convertHex(val: u8) RunError!u8 {
    return switch (val) {
        '0'...'9' => |b| b - '0',
        'A'...'F' => |b| 10 + b - 'A',
        else => return error.InvalidInput,
    };
}
