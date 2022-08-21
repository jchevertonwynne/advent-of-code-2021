const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var newLine = std.mem.indexOf(u8, contents, "\n") orelse unreachable;
    var bits = try toBits(contents[0..newLine], allocator);
    defer allocator.free(bits);

    var parsed = try BITS.parse(bits, allocator);
    var packet = parsed.packet;
    defer packet.deinit(allocator);

    var p1: usize = parsed.packetSum;
    var p2: usize = packet.value();

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 16, p1, p2, duration);

    return duration;
}

const BITSResult = struct {
    packetSum: usize,
    packet: BITS,
    remaining: []u1,
};

const Operator = enum(u3) {
    sum = 0,
    product = 1,
    minimum = 2,
    maximum = 3,
    gt = 5,
    lt = 6,
    eq = 7,
};

const BITSOperator = struct {
    const Self = @This();

    op: Operator,
    subpackets: []BITS,

    fn value(self: Self) usize {
        return switch (self.op) {
            .sum => block: {
                var sum: usize = 0;
                for (self.subpackets) |subpacket| {
                    sum += subpacket.value();
                }
                break :block sum;
            },
            .product => block: {
                var product: usize = 1;
                for (self.subpackets) |subpacket| {
                    product *= subpacket.value();
                }
                break :block product;
            },
            .minimum => block: {
                var minimum: usize = self.subpackets[0].value();
                for (self.subpackets) |subpacket| {
                    minimum = std.math.min(minimum, subpacket.value());
                }
                break :block minimum;
            },
            .maximum => block: {
                var maximum: usize = self.subpackets[0].value();
                for (self.subpackets) |subpacket| {
                    maximum = std.math.max(maximum, subpacket.value());
                }
                break :block maximum;
            },
            .gt => @boolToInt(self.subpackets[0].value() > self.subpackets[1].value()),
            .lt => @boolToInt(self.subpackets[0].value() < self.subpackets[1].value()),
            .eq => @boolToInt(self.subpackets[0].value() == self.subpackets[1].value()),
        };
    }

    fn deinit(self: *Self, alloc: std.mem.Allocator) void {
        for (self.subpackets) |*sub| {
            sub.deinit(alloc);
        }
        alloc.free(self.subpackets);
    }
};

const BITSContents = union(enum) {
    const Self = @This();

    literal: usize,
    operator: BITSOperator,

    fn value(self: Self) usize {
        return switch (self) {
            .literal => |literal| literal,
            .operator => |operator| operator.value(),
        };
    }

    fn deinit(self: *Self, alloc: std.mem.Allocator) void {
        switch (self.*) {
            .literal => {},
            .operator => |*op| op.deinit(alloc),
        }
    }
};

const BITS = union(enum) {
    const Self = @This();

    literal: usize,
    operator: BITSOperator,

    fn value(self: Self) usize {
        return switch (self) {
            .literal => |literal| literal,
            .operator => |operator| operator.value(),
        };
    }

    fn parse(bits: []u1, alloc: std.mem.Allocator) anyerror!BITSResult {
        var packetVersion = uintFrom(u3, bits[0..3]);
        var packetType = uintFrom(u3, bits[3..6]);

        if (packetType == 4) {
            var literal: usize = 0;
            var ind: usize = 6;
            var segment = bits[ind .. ind + 5];
            while (true) {
                for (segment[1..]) |b| {
                    literal <<= 1;
                    literal += b;
                }
                if (segment[0] == 0)
                    break;
                ind += 5;
                segment = bits[ind .. ind + 5];
            }
            return BITSResult{
                .packetSum = packetVersion,
                .packet = .{ .literal = literal },
                .remaining = bits[ind + 5 ..],
            };
        } else {
            var packetSum: usize = packetVersion;
            var remaining: []u1 = undefined;

            var subpackets = std.ArrayList(BITS).init(alloc);
            errdefer subpackets.deinit();

            var lengthTypeID = bits[6];
            if (lengthTypeID == 0) {
                var totalLength = uintFrom(usize, bits[7..22]);
                remaining = bits[22..];
                var startLen = remaining.len;
                while (startLen - remaining.len != totalLength) {
                    var subpacketParse = try BITS.parse(remaining, alloc);
                    errdefer subpacketParse.packet.deinit(alloc);
                    try subpackets.append(subpacketParse.packet);
                    remaining = subpacketParse.remaining;
                    packetSum += subpacketParse.packetSum;
                }
            } else {
                var totalFollowing = uintFrom(usize, bits[7..18]);
                remaining = bits[18..];
                var i: usize = 0;
                while (i < totalFollowing) : (i += 1) {
                    var subpacketParse = try BITS.parse(remaining, alloc);
                    errdefer subpacketParse.packet.deinit(alloc);
                    try subpackets.append(subpacketParse.packet);
                    remaining = subpacketParse.remaining;
                    packetSum += subpacketParse.packetSum;
                }
            }

            return BITSResult{
                .packetSum = packetSum,
                .packet = .{
                    .operator = BITSOperator{
                        .op = @intToEnum(Operator, packetType),
                        .subpackets = subpackets.toOwnedSlice(),
                    },
                },
                .remaining = remaining,
            };
        }
    }

    fn deinit(self: *Self, alloc: std.mem.Allocator) void {
        switch (self.*) {
            .literal => {},
            .operator => |*op| op.deinit(alloc),
        }
    }
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
