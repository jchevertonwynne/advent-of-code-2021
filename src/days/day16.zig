const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var newLine = std.mem.indexOf(u8, contents, "\n") orelse unreachable;
    var bits = try toBits(contents[0..newLine], allocator);
    defer allocator.free(bits);

    var packet = (try BITSPacket.parse(bits, allocator)).packet;
    defer packet.deinit(allocator);

    var p1: usize = packet.versionSum();
    var p2: usize = packet.value();

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 16, p1, p2, duration);

    return duration;
}

const BITSPacketResult = struct { packet: BITSPacket, remaining: []u1 };

const BITSPacket = struct {
    packetVersion: u3,
    packetType: u3,
    literal: ?usize,
    subpackets: ?[]BITSPacket,

    fn parse(bits: []u1, allocator: std.mem.Allocator) anyerror!BITSPacketResult {
        var result: @This() = .{ .packetVersion = 0, .packetType = 0, .literal = null, .subpackets = null };

        result.packetVersion += bits[0];
        result.packetVersion <<= 1;
        result.packetVersion += bits[1];
        result.packetVersion <<= 1;
        result.packetVersion += bits[2];

        result.packetType += bits[3];
        result.packetType <<= 1;
        result.packetType += bits[4];
        result.packetType <<= 1;
        result.packetType += bits[5];

        if (result.packetType == 4) {
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
            result.literal = literal;
            return BITSPacketResult{ .packet = result, .remaining = bits[ind + 5 ..] };
        } else {
            var lengthTypeID = bits[6];
            if (lengthTypeID == 0) {
                var totalLength: usize = 0;
                for (bits[7..22]) |t| {
                    totalLength <<= 1;
                    totalLength += t;
                }
                var remaining = bits[22..];
                var startLen = remaining.len;
                var subpackets = std.ArrayList(BITSPacket).init(allocator);
                errdefer subpackets.deinit();
                while (startLen - remaining.len != totalLength) {
                    var subpacket = try BITSPacket.parse(remaining, allocator);
                    try subpackets.append(subpacket.packet);
                    remaining = subpacket.remaining;
                }
                result.subpackets = subpackets.toOwnedSlice();
                return BITSPacketResult{ .packet = result, .remaining = remaining };
            } else {
                var totalFollowing: usize = 0;
                for (bits[7..18]) |t| {
                    totalFollowing <<= 1;
                    totalFollowing += t;
                }
                var remaining = bits[18..];
                var subpackets = std.ArrayList(BITSPacket).init(allocator);
                errdefer subpackets.deinit();
                var i: usize = 0;
                while (i < totalFollowing) : (i += 1) {
                    var subpacket = try BITSPacket.parse(remaining, allocator);
                    try subpackets.append(subpacket.packet);
                    remaining = subpacket.remaining;
                }
                result.subpackets = subpackets.toOwnedSlice();
                return BITSPacketResult{ .packet = result, .remaining = remaining };
            }
        }

        return result;
    }

    fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        if (self.subpackets) |*subpackets| {
            for (subpackets.*) |*s|
                s.deinit(allocator);
            allocator.free(subpackets.*);
        }
    }

    fn versionSum(self: @This()) usize {
        var result: usize = self.packetVersion;

        if (self.subpackets) |subpackets| {
            for (subpackets) |s|
                result += s.versionSum();
        }

        return result;
    }

    fn value(self: @This()) usize {
        switch (self.packetType) {
            0 => {
                var sum: usize = 0;
                for (self.subpackets.?) |subpacket|
                    sum += subpacket.value();
                return sum;
            },
            1 => {
                var product: usize = 1;
                for (self.subpackets.?) |subpacket|
                    product *= subpacket.value();
                return product;
            },
            2 => {
                var minimum: usize = std.math.maxInt(usize);
                for (self.subpackets.?) |subpacket|
                    minimum = std.math.min(minimum, subpacket.value());
                return minimum;
            },
            3 => {
                var maximum: usize = std.math.minInt(usize);
                for (self.subpackets.?) |subpacket|
                    maximum = std.math.max(maximum, subpacket.value());
                return maximum;
            },
            4 => return self.literal.?,
            5 => return if (self.subpackets.?[0].value() > self.subpackets.?[1].value()) 1 else 0,
            6 => return if (self.subpackets.?[0].value() < self.subpackets.?[1].value()) 1 else 0,
            7 => return if (self.subpackets.?[0].value() == self.subpackets.?[1].value()) 1 else 0,
        }
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
