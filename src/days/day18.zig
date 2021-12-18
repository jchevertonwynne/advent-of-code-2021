const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var numbers = try loadSnailFishNumbers(contents, allocator);
    defer {
        for (numbers) |*n|
            n.deinit(allocator);
        allocator.free(numbers);
    }

    var p1: usize = try part1(numbers, allocator);
    var p2: usize = try part2(numbers, allocator);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 18, p1, p2, duration);

    return duration;
}

fn part1(numbers: []SnailFishNumber, allocator: *std.mem.Allocator) !usize {
    var base = try numbers[0].copy(allocator);
    defer base.deinit(allocator);
    for (numbers[1..]) |number| {
        var base2 = try SnailFishNumber.add(base, number, allocator);
        base.deinit(allocator);
        base = base2;
    }
    return base.magnitude();
}

fn part2(numbers: []SnailFishNumber, allocator: *std.mem.Allocator) !usize {
    var largest: usize = 0;

    for (numbers) |a, i| {
        for (numbers) |b, j| {
            if (i == j)
                continue;
            var number = try SnailFishNumber.add(a, b, allocator);
            defer number.deinit(allocator);
            largest = std.math.max(largest, number.magnitude());
        }
    }

    return largest;
}

const SnailFishNumber = struct {
    entries: [2]SnailFishEntry,
    filled: u2,

    fn deinit(self: *@This(), allocator: *std.mem.Allocator) void {
        for (self.entries) |*entry|
            entry.deinit(allocator);
    }

    fn normalise(self: *@This(), allocator: *std.mem.Allocator) !void {
        while (true) {
            var explodeResult = self.explode(0, allocator);
            if (!explodeResult.shouldContinue) {
                continue;
            }

            var splitResult = try self.split(allocator);

            if (explodeResult.shouldContinue and splitResult.shouldContinue) {
                break;
            }
        }
    }

    fn split(self: *@This(), allocator: *std.mem.Allocator) anyerror!SplitResult {
        var result = SplitResult{ .value = null, .shouldContinue = true };
        for (self.entries) |*entry| {
            var innerResult = try entry.split(allocator);
            result.shouldContinue = result.shouldContinue and innerResult.shouldContinue;
            if (innerResult.value) |value| {
                var left = value / 2;
                var right = value - left;
                var inner = try allocator.create(SnailFishNumber);
                inner.filled = 2;
                inner.entries[0] = SnailFishEntry{ .value = left };
                inner.entries[1] = SnailFishEntry{ .value = right };
                entry.* = SnailFishEntry{ .nested = inner };
            }
            if (!result.shouldContinue)
                break;
        }

        return result;
    }

    fn explode(self: *@This(), nesting: usize, allocator: *std.mem.Allocator) ExplodeResult {
        if (nesting == 4) {
            return ExplodeResult{ .left = self.entries[0].innerValue(), .right = self.entries[1].innerValue(), .shouldContinue = false, .source = true };
        }
        var result: ExplodeResult = .{ .left = null, .right = null, .shouldContinue = true, .source = false };
        for (self.entries) |*entry, i| {
            var innerResult = entry.explode(nesting, allocator);
            result.shouldContinue = result.shouldContinue and innerResult.shouldContinue;
            if (innerResult.source) {
                entry.deinit(allocator);
                entry.* = SnailFishEntry{ .value = 0 };
            }
            if (innerResult.left) |left| {
                if (i > 0)
                    self.entries[i - 1].addValue(.left, left)
                else
                    result.left = left;
            }
            if (innerResult.right) |right| {
                if (i + 1 < self.entries.len)
                    self.entries[i + 1].addValue(.right, right)
                else
                    result.right = right;
            }
            if (!result.shouldContinue)
                break;
        }
        return result;
    }

    fn addValue(self: *@This(), comptime side: Side, extraValue: usize) void {
        var ind: usize = switch (side) {
            .left => 1,
            .right => 0,
        };
        self.entries[ind].addValue(side, extraValue);
    }

    fn copy(self: @This(), allocator: *std.mem.Allocator) anyerror!SnailFishNumber {
        var number = SnailFishNumber{ .entries = undefined, .filled = 1 };
        errdefer number.deinit(allocator);

        for (self.entries) |entry, i| {
            var entryCopy = try entry.copy(allocator);
            number.entries[i] = entryCopy;
        }

        return number;
    }

    fn add(a: SnailFishNumber, b: SnailFishNumber, allocator: *std.mem.Allocator) !SnailFishNumber {
        var aCopy = try a.copy(allocator);
        errdefer aCopy.deinit(allocator);
        var bCopy = try b.copy(allocator);
        errdefer bCopy.deinit(allocator);
        var aPointer = try allocator.create(SnailFishNumber);
        errdefer allocator.destroy(aPointer);
        aPointer.* = aCopy;
        var bPointer = try allocator.create(SnailFishNumber);
        errdefer allocator.destroy(bPointer);
        bPointer.* = bCopy;

        var number = SnailFishNumber{ .entries = undefined, .filled = 2 };
        number.entries[0] = SnailFishEntry{ .nested = aPointer };
        number.entries[1] = SnailFishEntry{ .nested = bPointer };
        try number.normalise(allocator);
        return number;
    }

    fn print(self: @This()) void {
        self._print(0);
    }

    fn _print(self: @This(), depth: usize) void {
        tab(depth);
        std.debug.print("v\n", .{});
        for (self.entries) |entry| {
            entry.print(depth);
        }
        tab(depth);
        std.debug.print("^\n", .{});
    }

    fn magnitude(self: @This()) usize {
        return 3 * self.entries[0].magnitude() + 2 * self.entries[1].magnitude();
    }
};

const SnailFishEntry = union(enum) {
    value: usize,
    nested: *SnailFishNumber,

    fn print(self: @This(), depth: usize) void {
        switch (self) {
            .value => |value| {
                tab(depth);
                std.debug.print("literal: {}\n", .{value});
            },
            .nested => |nested| nested._print(depth + 1),
        }
    }

    fn deinit(self: *@This(), allocator: *std.mem.Allocator) void {
        switch (self.*) {
            .value => {},
            .nested => |nested| {
                nested.deinit(allocator);
                allocator.destroy(nested);
            },
        }
    }

    fn innerValue(self: @This()) usize {
        return switch (self) {
            .value => |value| value,
            .nested => unreachable,
        };
    }

    fn explode(self: *@This(), nesting: usize, allocator: *std.mem.Allocator) ExplodeResult {
        return switch (self.*) {
            .value => ExplodeResult{ .left = null, .right = null, .shouldContinue = true, .source = false },
            .nested => |nested| nested.explode(nesting + 1, allocator),
        };
    }

    fn split(self: *@This(), allocator: *std.mem.Allocator) anyerror!SplitResult {
        return switch (self.*) {
            .value => |value| {
                if (value >= 10) {
                    return SplitResult{ .value = value, .shouldContinue = false };
                } else {
                    return SplitResult{ .value = null, .shouldContinue = true };
                }
            },
            .nested => |nested| try nested.split(allocator),
        };
    }

    fn copy(self: @This(), allocator: *std.mem.Allocator) anyerror!SnailFishEntry {
        return switch (self) {
            .value => |value| SnailFishEntry{ .value = value },
            .nested => |nested| {
                var nestedCopy = try nested.copy(allocator);
                errdefer nestedCopy.deinit(allocator);
                var copyP = try allocator.create(SnailFishNumber);
                copyP.* = nestedCopy;
                return SnailFishEntry{ .nested = copyP };
            },
        };
    }

    fn addValue(self: *@This(), comptime side: Side, extraValue: usize) void {
        return switch (self.*) {
            .value => |*value| value.* += extraValue,
            .nested => |nested| nested.addValue(side, extraValue),
        };
    }

    fn magnitude(self: @This()) usize {
        return switch (self) {
            .value => |value| value,
            .nested => |nested| nested.magnitude(),
        };
    }
};

const Side = enum { left, right };

const ExplodeResult = struct { left: ?usize, right: ?usize, shouldContinue: bool, source: bool };

const SplitResult = struct { value: ?usize, shouldContinue: bool };

fn loadSnailFishNumbers(contents: []u8, allocator: *std.mem.Allocator) ![]SnailFishNumber {
    var numbers = std.ArrayList(SnailFishNumber).init(allocator);
    errdefer {
        for (numbers.items) |*snailNumber|
            snailNumber.deinit(allocator);
        numbers.deinit();
    }

    var ind: usize = 1;
    while (ind < contents.len) {
        var number = SnailFishNumber{ .entries = undefined, .filled = 0 };
        errdefer number.deinit(allocator);

        var builder = std.ArrayList(*SnailFishNumber).init(allocator);
        defer builder.deinit();
        try builder.append(&number);

        while (contents[ind + 1] != '\n') : (ind += 1) {
            switch (contents[ind]) {
                '[' => {
                    var inner = try allocator.create(SnailFishNumber);
                    errdefer allocator.destroy(inner);
                    inner.filled = 0;
                    builder.items[builder.items.len - 1].entries[builder.items[builder.items.len - 1].filled] = SnailFishEntry{ .nested = inner };
                    builder.items[builder.items.len - 1].filled += 1;
                    try builder.append(inner);
                },
                ']' => _ = builder.pop(),
                ',' => {},
                '0'...'9' => |digit| {
                    builder.items[builder.items.len - 1].entries[builder.items[builder.items.len - 1].filled] = SnailFishEntry{ .value = digit - '0' };
                    builder.items[builder.items.len - 1].filled += 1;
                },
                else => unreachable,
            }
        }

        try numbers.append(number);

        ind += 3;
    }

    return numbers.toOwnedSlice();
}

fn tab(count: usize) void {
    var i: usize = 0;
    while (i < count) : (i += 1) {
        std.debug.print("  ", .{});
    }
}
