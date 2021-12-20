const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var numbers = try loadNumbers(contents, allocator);
    defer allocator.free(numbers);

    var p1: usize = part1(numbers);
    var p2: usize = part2(numbers);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 18, p1, p2, duration);

    return duration;
}

fn part1(numbers: []SnailNumber) usize {
    var number = numbers[0];
    for (numbers[1..]) |n|
        number = SnailNumber.add(number, n);

    return number.magnitude();
}
fn part2(numbers: []SnailNumber) usize {
    var best: usize = 0;
    for (numbers) |a, aInd| {
        for (numbers) |b, bInd| {
            if (aInd == bInd)
                continue;
            best = std.math.max(best, SnailNumber.add(a, b).magnitude());
        }
    }
    return best;
}

const SnailNumber = struct {
    contents: [65]?u8, // if null - check index * 2 + 1 and index * 2 + 2 for contents

    fn parse(source: []const u8) SnailNumber {
        var result = SnailNumber{ .contents = [_]?u8{null} ** 65 };

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

    fn magnitude(self: @This()) usize {
        return self._magnitude(0);
    }

    fn _magnitude(self: @This(), i: usize) usize {
        if (self.contents[i]) |val|
            return val;
        return 3 * self._magnitude(i * 2 + 1) + 2 * self._magnitude(i * 2 + 2);
    }

    fn fill(self: *@This(), base: usize, ind: usize, depth: usize, other: SnailNumber) void {
        if (depth > 4)
            return;
        self.contents[base] = other.contents[ind];
        self.fill(base * 2 + 1, ind * 2 + 1, depth + 1, other);
        self.fill(base * 2 + 2, ind * 2 + 2, depth + 1, other);
    }

    fn add(a: SnailNumber, b: SnailNumber) SnailNumber {
        var result = SnailNumber{ .contents = [_]?u8{null} ** 65 };
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
        while (true) {
            while (self.explode().explosionDone) {}
            if (!self.split())
                break;
        }
    }

    fn explode(self: *@This()) ExplodeResult {
        return self._explode(0, 0);
    }

    fn _explode(self: *@This(), i: usize, depth: usize) ExplodeResult {
        if (depth == 4 and self.contents[i] == null) {
            var left: ?u8 = self.contents[i * 2 + 1];
            if (i % 2 == 0) { // righthand branch
                self.addValue(.right, i - 1, left.?);
                left = null;
            }

            var right: ?u8 = self.contents[i * 2 + 2];
            if (i % 2 == 1) { //lefthand branch
                self.addValue(.right, i + 1, right.?);
                right = null;
            }

            return ExplodeResult{ .left = left, .right = right, .explosionDone = true, .source = true };
        }
        if (self.contents[i] != null) {
            return ExplodeResult{ .left = null, .right = null, .explosionDone = false, .source = false };
        }
        var result = ExplodeResult{ .left = null, .right = null, .explosionDone = false, .source = false };
        var leftResult = self._explode(i * 2 + 1, depth + 1);
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
        var rightResult = self._explode(i * 2 + 2, depth + 1);
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

        return result;
    }

    fn split(self: *@This()) bool {
        return self._split(0);
    }

    fn _split(self: *@This(), i: usize) bool {
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
        if (self._split(i * 2 + 1)) {
            return true;
        } else {
            return self._split(i * 2 + 2);
        }
    }
};

const Side = enum { left, right };

const ExplodeResult = struct { left: ?u8, right: ?u8, explosionDone: bool, source: bool };

fn loadNumbers(contents: []u8, allocator: *std.mem.Allocator) ![]SnailNumber {
    var numbers = std.ArrayList(SnailNumber).init(allocator);
    defer numbers.deinit();

    var ind: usize = 0;
    while (ind < contents.len) {
        var start = ind;
        while (contents[ind] != '\n')
            ind += 1;
        try numbers.append(SnailNumber.parse(contents[start .. ind + 1]));

        ind += 1;
    }

    return numbers.toOwnedSlice();
}
