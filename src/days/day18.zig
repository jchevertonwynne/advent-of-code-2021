const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    _ = allocator;
    _ = contents;

    // var a = "[[[[4,3],4],4],[7,[[8,4],9]]]\n";
    // var b = "[1,1]\n";
    // var aNum = SnailNumber.parse(a);
    // var bNum = SnailNumber.parse(b);
    // var sum = SnailNumber.add(aNum, bNum);

    var c = "[[[[[4,3],4],4],[7,[[8,4],9]]],[1,1]]\n";
    var cNum = SnailNumber.parse(c);
    cNum.print();

    // std.debug.print("{}\n", .{cNum.explode(0, 0)});
    cNum.normalise();

    cNum.print();

    var p1: usize = 0;
    var p2: usize = 0;

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 18, p1, p2, duration);

    return duration;
}

const SnailNumber = struct {
    contents: [129]?u8, // if null - check index * 2 + 1 and index * 2 + 2 for contents

    fn parse(source: []const u8) SnailNumber {
        var result = SnailNumber{ .contents = [_]?u8{null} ** 129 };

        var snailIndex: usize = 0;

        var ind: usize = 0;
        while (source[ind] != '\n') : (ind += 1) {
            switch (source[ind]) {
                '[' => snailIndex = snailIndex * 2 + 1,
                ']' => snailIndex = (snailIndex - 1) / 2,
                ',' => snailIndex += 1,
                '0'...'9' => |digit| result.contents[snailIndex] = digit - '0',
                else => unreachable,
            }
        }

        return result;
    }

    fn fill(self: *@This(), base: usize, ind: usize, depth: usize, other: SnailNumber) void {
        if (depth > 5) {
            return;
        }
        self.contents[base] = other.contents[ind];
        self.fill(base * 2 + 1, ind * 2 + 1, depth + 1, other);
        self.fill(base * 2 + 2, ind * 2 + 2, depth + 1, other);
    }

    fn add(a: SnailNumber, b: SnailNumber) SnailNumber {
        var result = SnailNumber{ .contents = [_]?u8{null} ** 129 };
        result.fill(1, 0, 0, a);
        result.fill(2, 0, 0, b);
        result.normalise();
        return result;
    }

    fn addValue(self: *@This(), comptime side: Side, index: usize, value: u8) void {
        if (self.contents[index]) |*val| {
            val.* += value;
        } else {
            switch (side) {
                .left => self.addValue(side, index * 2 + 2, value),
                .right => self.addValue(side, index * 2 + 1, value),
            }
        }
    }

    fn print(self: @This()) void {
        self._print(0);
        std.debug.print("\n", .{});
    }

    fn _print(self: @This(), index: usize) void {
        if (self.contents[index]) |value| {
            std.debug.print("{}", .{value});
        } else {
            std.debug.print("[", .{});
            self._print(index * 2 + 1);
            std.debug.print(",", .{});
            self._print(index * 2 + 2);
            std.debug.print("]", .{});
        }
    }

    fn normalise(self: *@This()) void {
        self.print();
        while (true) {
            while (self.explode(0, 0).explosionDone) {
                std.debug.print("exploded\n", .{});
                self.print();
            }
            if (!self.split(0))
                break;
            std.debug.print("split\n", .{});
            self.print();
        }
    }

    fn explode(self: *@This(), i: usize, depth: usize) ExplodeResult {
        if (depth == 4 and self.contents[i] == null) {
            // TODO - attempt to apply the left and right parts, else pass in result
            std.debug.print("explode - i = {} next={} left = {} right = {}\n", .{ i, self.contents[i + 1], self.contents[i * 2 + 1], self.contents[i * 2 + 2] });
            return ExplodeResult{ .left = self.contents[i * 2 + 1], .right = self.contents[i * 2 + 2], .explosionDone = true, .source = true };
        }
        if (self.contents[i] != null) {
            return ExplodeResult{ .left = null, .right = null, .explosionDone = false, .source = false };
        }
        var result = ExplodeResult{ .left = null, .right = null, .explosionDone = false, .source = false };
        var leftResult = self.explode(i * 2 + 1, depth + 1);
        result.explosionDone = result.explosionDone or leftResult.explosionDone;
        if (leftResult.source) {
            self.contents[i * 2 + 1] = 0;
        }
        if (leftResult.left) |left| {
            if (i % 2 == 0 and i != 0) {
                self.addValue(.left, i - 1, left);
            } else {
                result.left = left;
            }
        }
        if (leftResult.right) |right| {
            if (i % 2 == 1) {
                self.addValue(.right, i + 1, right);
            } else {
                result.right = right;
            }
        }
        if (leftResult.explosionDone)
            return result;
        var rightResult = self.explode(i * 2 + 2, depth + 1);
        result.explosionDone = result.explosionDone or rightResult.explosionDone;
        if (rightResult.source) {
            self.contents[i * 2 + 2] = 0;
        }
        if (rightResult.left) |left| {
            if (i % 2 == 0) {
                self.addValue(.left, i - 1, left);
            } else {
                result.left = left;
            }
        }
        if (rightResult.right) |right| {
            if (i % 2 == 1) {
                self.addValue(.right, i + 1, right);
            } else {
                result.right = right;
            }
        }
        _ = "[[[[0,7],4],[[7,8],[0,[6,7]]]],[1,1]]";

        return result;
    }

    fn split(self: *@This(), i: usize) bool {
        if (self.contents[i]) |value| {
            if (value >= 10) {
                var left = value / 2;
                var right = value - left;
                self.contents[i] = null;
                self.contents[i * 2 + 1] = left;
                self.contents[i * 2 + 2] = right;
                return true;
            } else {
                return false;
            }
        }
        if (self.split(i * 2 + 1)) {
            return true;
        } else {
            return self.split(i * 2 + 2);
        }
    }
};

const Side = enum { left, right };

const ExplodeResult = struct { left: ?u8, right: ?u8, explosionDone: bool, source: bool };
