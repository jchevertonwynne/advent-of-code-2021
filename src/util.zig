const std = @import("std");

pub const Contents = struct {
    const Self = @This();

    day01: []u8,
    day02: []u8,
    day03: []u8,
    day04: []u8,
    day05: []u8,
    day06: []u8,
    day07: []u8,
    day08: []u8,
    day09: []u8,
    day10: []u8,
    day11: []u8,
    day12: []u8,
    day13: []u8,
    day14: []u8,
    day15: []u8,
    day16: []u8,
    day17: []u8,
    day18: []u8,
    day19: []u8,
    day20: []u8,
    day21: []u8,
    day22: []u8,
    day23: []u8,
    day24: []u8,
    day25: []u8,

    pub fn load(allocator: std.mem.Allocator) !Self {
        @setEvalBranchQuota(100_000);
        var dir = std.fs.cwd();

        var self: Self = undefined;

        var set = std.mem.zeroes([@typeInfo(Self).Struct.fields.len]bool);

        errdefer {
            inline for (@typeInfo(Self).Struct.fields) |field, i| {
                if (set[i]) {
                    allocator.free(@field(self, field.name));
                }
            }
        }

        inline for (@typeInfo(Self).Struct.fields) |field, i| {
            @field(self, field.name) = try dir.readFileAlloc(allocator, "files/" ++ field.name[3..] ++ ".txt", std.math.maxInt(usize));
            set[i] = true;
        }

        return self;
    }

    pub fn discard(self: Self, allocator: std.mem.Allocator) void {
        inline for (@typeInfo(Self).Struct.fields) |field| {
            allocator.free(@field(self, field.name));
        }
    }
};

pub fn HashSet(comptime T: type) type {
    const mapType = if (T == []const u8) std.StringHashMap(void) else std.AutoHashMap(T, void);

    return struct {
        const Self = @This();

        map: mapType,

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{ .map = mapType.init(allocator) };
        }

        pub fn count(self: Self) u64 {
            return self.map.count();
        }

        pub fn insertCheck(self: *Self, val: T) !bool {
            var entry = try self.map.getOrPut(val);
            return !entry.found_existing;
        }

        pub fn insert(self: *Self, val: T) !void {
            return self.map.put(val, {});
        }

        pub fn remove(self: *Self, val: T) bool {
            return self.map.remove(val);
        }

        pub fn contains(self: Self, val: T) bool {
            return self.map.contains(val);
        }

        pub fn clearRetainingCapacity(self: *Self) void {
            self.map.clearRetainingCapacity();
        }

        pub fn deinit(self: *Self) void {
            self.map.deinit();
        }

        pub fn iterator(self: Self) mapType.KeyIterator {
            return self.map.keyIterator();
        }
    };
}

pub fn writeResponse(out: anytype, comptime day: usize, part1: anytype, part2: anytype, duration: i128) !void {
    try out.print("problem {}:\n", .{day});
    try out.print("\tpart 1:\t{}\n", .{part1});
    if (@TypeOf(part2) == [6][40]u8) {
        try out.print("\tpart 2: {s}\n", .{part2[0]});
        for (part2[1..]) |row|
            try out.print("\t\t{s}\n", .{row});
    } else {
        try out.print("\tpart 2:\t{}\n", .{part2});
    }
    if (duration < 1000) {
        try out.print("\ttime:\t{d}ns\n\n", .{duration});
    } else if (duration < 1_000_000) {
        try out.print("\ttime:\t{d}us\n\n", .{@divFloor(duration, 1_000)});
    } else if (duration < 1_000_000_000) {
        try out.print("\ttime:\t{d}ms\n\n", .{@divFloor(duration, 1_000_000)});
    } else {
        try out.print("\ttime:\t{d}s\n\n", .{@divFloor(duration, 1_000_000_000)});
    }
}

pub fn toUnsignedInt(comptime T: type, contents: []const u8) struct { result: T, size: usize } {
    if (@typeInfo(T).Int.signedness == .signed)
        @compileError("must supply a signed integer");

    var result: T = 0;
    var characters: usize = 0;

    for (contents) |char, i| {
        if ('0' <= char and char <= '9') {
            result *= 10;
            result += @as(T, char - '0');
            characters = i;
        } else break;
    }

    return .{ .result = result, .size = characters + 1 };
}

pub fn toSignedInt(comptime T: type, contents: []const u8, number: *T, size: *usize) void {
    if (@typeInfo(T).Int.signedness == .unsigned)
        @compileError("must supply a signed integer");

    var result: T = 0;
    var characters: usize = 0;
    var negative = false;

    for (contents) |char, i| {
        if ('0' <= char and char <= '9') {
            result *= 10;
            result += @as(T, char - '0');
            characters = i;
        } else if (char == '-') {
            negative = true;
            characters = i;
        } else break;
    }

    if (negative)
        result = -result;

    number.* = result;
    size.* = characters + 1;
}
