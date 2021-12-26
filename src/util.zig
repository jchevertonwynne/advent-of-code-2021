const std = @import("std");

pub const Contents = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
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

    pub fn load(allocator: std.mem.Allocator) !Self {
        var dir = std.fs.cwd();

        var self: Self = undefined;
        self.allocator = allocator;

        self.day01 = try dir.readFileAlloc(allocator, "files/01.txt", std.math.maxInt(usize));
        errdefer allocator.free(self.day01);
        self.day02 = try dir.readFileAlloc(allocator, "files/02.txt", std.math.maxInt(usize));
        errdefer allocator.free(self.day02);
        self.day03 = try dir.readFileAlloc(allocator, "files/03.txt", std.math.maxInt(usize));
        errdefer allocator.free(self.day03);
        self.day04 = try dir.readFileAlloc(allocator, "files/04.txt", std.math.maxInt(usize));
        errdefer allocator.free(self.day04);
        self.day05 = try dir.readFileAlloc(allocator, "files/05.txt", std.math.maxInt(usize));
        errdefer allocator.free(self.day05);
        self.day06 = try dir.readFileAlloc(allocator, "files/06.txt", std.math.maxInt(usize));
        errdefer allocator.free(self.day06);
        self.day07 = try dir.readFileAlloc(allocator, "files/07.txt", std.math.maxInt(usize));
        errdefer allocator.free(self.day07);
        self.day08 = try dir.readFileAlloc(allocator, "files/08.txt", std.math.maxInt(usize));
        errdefer allocator.free(self.day08);
        self.day09 = try dir.readFileAlloc(allocator, "files/09.txt", std.math.maxInt(usize));
        errdefer allocator.free(self.day09);
        self.day10 = try dir.readFileAlloc(allocator, "files/10.txt", std.math.maxInt(usize));
        errdefer allocator.free(self.day10);
        self.day11 = try dir.readFileAlloc(allocator, "files/11.txt", std.math.maxInt(usize));
        errdefer allocator.free(self.day11);
        self.day12 = try dir.readFileAlloc(allocator, "files/12.txt", std.math.maxInt(usize));
        errdefer allocator.free(self.day12);
        self.day13 = try dir.readFileAlloc(allocator, "files/13.txt", std.math.maxInt(usize));
        errdefer allocator.free(self.day13);
        self.day14 = try dir.readFileAlloc(allocator, "files/14.txt", std.math.maxInt(usize));
        errdefer allocator.free(self.day14);
        self.day15 = try dir.readFileAlloc(allocator, "files/15.txt", std.math.maxInt(usize));
        errdefer allocator.free(self.day15);
        self.day16 = try dir.readFileAlloc(allocator, "files/16.txt", std.math.maxInt(usize));
        errdefer allocator.free(self.day16);
        self.day17 = try dir.readFileAlloc(allocator, "files/17.txt", std.math.maxInt(usize));
        errdefer allocator.free(self.day17);
        self.day18 = try dir.readFileAlloc(allocator, "files/18.txt", std.math.maxInt(usize));
        errdefer allocator.free(self.day18);
        self.day19 = try dir.readFileAlloc(allocator, "files/19.txt", std.math.maxInt(usize));
        errdefer allocator.free(self.day19);
        self.day20 = try dir.readFileAlloc(allocator, "files/20.txt", std.math.maxInt(usize));
        errdefer allocator.free(self.day20);
        self.day21 = try dir.readFileAlloc(allocator, "files/21.txt", std.math.maxInt(usize));
        errdefer allocator.free(self.day21);
        self.day22 = try dir.readFileAlloc(allocator, "files/22_2.txt", std.math.maxInt(usize));
        errdefer allocator.free(self.day22);
        self.day23 = try dir.readFileAlloc(allocator, "files/23.txt", std.math.maxInt(usize));
        errdefer allocator.free(self.day23);
        self.day24 = try dir.readFileAlloc(allocator, "files/24.txt", std.math.maxInt(usize));
        errdefer allocator.free(self.day24);

        return self;
    }

    pub fn discard(self: Self) void {
        self.allocator.free(self.day01);
        self.allocator.free(self.day02);
        self.allocator.free(self.day03);
        self.allocator.free(self.day04);
        self.allocator.free(self.day05);
        self.allocator.free(self.day06);
        self.allocator.free(self.day07);
        self.allocator.free(self.day08);
        self.allocator.free(self.day09);
        self.allocator.free(self.day10);
        self.allocator.free(self.day11);
        self.allocator.free(self.day12);
        self.allocator.free(self.day13);
        self.allocator.free(self.day14);
        self.allocator.free(self.day15);
        self.allocator.free(self.day16);
        self.allocator.free(self.day17);
        self.allocator.free(self.day18);
        self.allocator.free(self.day19);
        self.allocator.free(self.day20);
        self.allocator.free(self.day21);
        self.allocator.free(self.day22);
        self.allocator.free(self.day23);
        self.allocator.free(self.day24);
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

        pub fn count(self: Self) u32 {
            return self.map.count();
        }

        pub fn insertCheck(self: *Self, val: T) !bool {
            var contained = self.contains(val);
            if (contained) {
                return false;
            }
            try self.insert(val);
            return true;
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

        pub fn clear(self: *Self) void {
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
    } else {
        try out.print("\ttime:\t{d}ms\n\n", .{@divFloor(duration, 1_000_000)});
    }
}

pub fn toInt(comptime T: type, contents: []const u8, number: *T, size: *usize) void {
    var result: T = 0;
    var characters: usize = 0;

    for (contents) |char, i| {
        if ('0' <= char and char <= '9') {
            result *= 10;
            result += @as(T, char - '0');
            characters = i;
        } else break;
    }

    number.* = result;
    size.* = characters + 1;
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
