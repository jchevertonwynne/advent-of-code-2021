const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var newLine = std.mem.indexOf(u8, contents, "\n") orelse unreachable;
    var bits = try toBits(contents[0..newLine], allocator);
    defer allocator.free(bits);

    var packet = (try BITS.parse(bits, allocator)).packet;
    defer packet.deinit(allocator);

    var p1: usize = packet.versionSum();
    var p2: usize = packet.value();

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 16, p1, p2, duration);

    return duration;
}

const BITSResult = struct {
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

    fn versionSum(self: Self) usize {
        var sum: usize = 0;
        for (self.subpackets) |subpacket| {
            sum += subpacket.versionSum();
        }
        return sum;
    }

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

    fn versionSum(self: Self) usize {
        return switch (self) {
            .literal => 0,
            .operator => |operator| operator.versionSum(),
        };
    }

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

const BITS = struct {
    const Self = @This();

    packetVersion: u3,
    contents: BITSContents,

    fn value(self: Self) usize {
        return self.contents.value();
    }

    fn versionSum(self: Self) usize {
        return @as(usize, self.packetVersion) + self.contents.versionSum();
    }

    fn parse(bits: []u1, allocator: std.mem.Allocator) anyerror!BITSResult {
        var result: Self = .{
            .packetVersion = 0,
            .contents = undefined,
        };

        result.packetVersion += bits[0];
        result.packetVersion <<= 1;
        result.packetVersion += bits[1];
        result.packetVersion <<= 1;
        result.packetVersion += bits[2];

        var packetType: u3 = 0;
        packetType += bits[3];
        packetType <<= 1;
        packetType += bits[4];
        packetType <<= 1;
        packetType += bits[5];

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
            result.contents = .{ .literal = literal };
            return BITSResult{ .packet = result, .remaining = bits[ind + 5 ..] };
        } else {
            var op = BITSOperator{
                .op = @intToEnum(Operator, packetType),
                .subpackets = undefined,
            };

            var lengthTypeID = bits[6];
            if (lengthTypeID == 0) {
                var totalLength: usize = 0;
                for (bits[7..22]) |t| {
                    totalLength <<= 1;
                    totalLength += t;
                }
                var remaining = bits[22..];
                var startLen = remaining.len;
                var subpackets = std.ArrayList(BITS).init(allocator);
                errdefer subpackets.deinit();
                while (startLen - remaining.len != totalLength) {
                    var subpacket = try BITS.parse(remaining, allocator);
                    try subpackets.append(subpacket.packet);
                    remaining = subpacket.remaining;
                }
                op.subpackets = subpackets.toOwnedSlice();
                result.contents = BITSContents{ .operator = op };
                return BITSResult{ .packet = result, .remaining = remaining };
            } else {
                var totalFollowing: usize = 0;
                for (bits[7..18]) |t| {
                    totalFollowing <<= 1;
                    totalFollowing += t;
                }
                var remaining = bits[18..];
                var subpackets = std.ArrayList(BITS).init(allocator);
                errdefer subpackets.deinit();
                var i: usize = 0;
                while (i < totalFollowing) : (i += 1) {
                    var subpacket = try BITS.parse(remaining, allocator);
                    try subpackets.append(subpacket.packet);
                    remaining = subpacket.remaining;
                }
                op.subpackets = subpackets.toOwnedSlice();
                result.contents = BITSContents{ .operator = op };
                return BITSResult{ .packet = result, .remaining = remaining };
            }
        }
    }

    fn deinit(self: *Self, alloc: std.mem.Allocator) void {
        self.contents.deinit(alloc);
    }
};

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
