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

const SolveResult = struct {
    value: usize,
    packetSum: usize,
};

fn solve(reader: *BitReader) SolveResult {
    var packetVersion = reader.int(u3, 3);
    var packetType = reader.int(u3, 3);
    var packetSum: usize = packetVersion;

    var value: usize = switch (packetType) {
        0 => solveN(reader, add, 0, &packetSum),
        1 => solveN(reader, prod, 1, &packetSum),
        2 => solveN(reader, min, std.math.maxInt(usize), &packetSum),
        3 => solveN(reader, max, 0, &packetSum),
        4 => literal(reader),
        5 => solve2(reader, gt, &packetSum),
        6 => solve2(reader, lt, &packetSum),
        7 => solve2(reader, eq, &packetSum),
    };

    return SolveResult{
        .value = value,
        .packetSum = packetSum,
    };
}

fn solveN(reader: *BitReader, comptime f: fn (usize, usize) usize, start: usize, packetSum: *usize) usize {
    var value = start;
    var lengthTypeID = reader.single();
    if (lengthTypeID == 0) {
        var totalLength = reader.int(u15, 15);
        var startRead = reader.totalRead;
        while (reader.totalRead - startRead != totalLength) {
            var subparse = solve(reader);
            value = f(value, subparse.value);
            packetSum.* += subparse.packetSum;
        }
    } else {
        var totalFollowing = reader.int(u11, 11);
        var i: usize = 0;
        while (i < totalFollowing) : (i += 1) {
            var subparse = solve(reader);
            value = f(value, subparse.value);
            packetSum.* += subparse.packetSum;
        }
    }

    return value;
}

fn solve2(reader: *BitReader, comptime f: fn (usize, usize) usize, packetSum: *usize) usize {
    var lengthTypeID = reader.single();
    if (lengthTypeID == 0) {
        reader.skip(15);
    } else {
        reader.skip(11);
    }

    var a = solve(reader);
    var b = solve(reader);

    packetSum.* += a.packetSum + b.packetSum;

    return f(a.value, b.value);
}

fn literal(reader: *BitReader) usize {
    var lit: usize = 0;
    while (true) {
        var shouldBreak = reader.single() == 0;
        lit = (lit << 4) + reader.int(u4, 4);
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

    fn new(source: []u8) Self {
        return Self{
            .source = source,
            .sourceInd = 0,
            .current = undefined,
            .left = 0,
            .totalRead = 0,
        };
    }

    fn _ensureReady(self: *Self) void {
        if (self.left == 0) {
            self._readyNext();
        }
    }

    fn single(self: *Self) u1 {
        self._ensureReady();
        self.current <<= 1;
        var result = @boolToInt(self.current & 0b10000 != 0);
        self.left -= 1;
        self.totalRead += 1;
        return result;
    }

    fn skip(self: *Self, toSkip: usize) void {
        _ = self.int(usize, toSkip);
    }

    fn _readyNext(self: *Self) void {
        self.current = convertHex(self.source[self.sourceInd]);
        self.sourceInd += 1;
        self.left = 4;
    }

    fn int(self: *Self, comptime T: type, bits: usize) T {
        self._ensureReady();
        var _bits = bits;
        var result: T = 0;
        while (_bits != 0) : (_bits -= 1) {
            result = (result << 1) + self.single();
        }
        return result;
    }
};

fn convertHex(val: u8) u8 {
    const lookup = comptime blk: {
        var table: [std.math.maxInt(u8)]u8 = undefined;
        var i = '0';
        var value: u8 = 0;
        while (i <= '9') {
            table[i] = value;
            i += 1;
            value += 1;
        }
        i = 'A';
        while (i <= 'F') {
            table[i] = value;
            i += 1;
            value += 1;
        }
        break :blk table;
    };
    return lookup[val];
}
