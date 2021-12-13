const std = @import("std");

pub const Contents = struct {
    const Self = @This();

    allocator: *std.mem.Allocator,
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

    pub fn load(allocator: *std.mem.Allocator) !Self {
        var dir = std.fs.cwd();
        var day01String = try dir.readFileAlloc(allocator, "files/01.txt", std.math.maxInt(usize));
        errdefer allocator.free(day01String);
        var day02String = try dir.readFileAlloc(allocator, "files/02.txt", std.math.maxInt(usize));
        errdefer allocator.free(day02String);
        var day03String = try dir.readFileAlloc(allocator, "files/03.txt", std.math.maxInt(usize));
        errdefer allocator.free(day03String);
        var day04String = try dir.readFileAlloc(allocator, "files/04.txt", std.math.maxInt(usize));
        errdefer allocator.free(day04String);
        var day05String = try dir.readFileAlloc(allocator, "files/05.txt", std.math.maxInt(usize));
        errdefer allocator.free(day05String);
        var day06String = try dir.readFileAlloc(allocator, "files/06.txt", std.math.maxInt(usize));
        errdefer allocator.free(day06String);
        var day07String = try dir.readFileAlloc(allocator, "files/07.txt", std.math.maxInt(usize));
        errdefer allocator.free(day07String);
        var day08String = try dir.readFileAlloc(allocator, "files/08.txt", std.math.maxInt(usize));
        errdefer allocator.free(day08String);
        var day09String = try dir.readFileAlloc(allocator, "files/09.txt", std.math.maxInt(usize));
        errdefer allocator.free(day09String);
        var day10String = try dir.readFileAlloc(allocator, "files/10.txt", std.math.maxInt(usize));
        errdefer allocator.free(day10String);
        var day11String = try dir.readFileAlloc(allocator, "files/11.txt", std.math.maxInt(usize));
        errdefer allocator.free(day11String);
        var day12String = try dir.readFileAlloc(allocator, "files/12.txt", std.math.maxInt(usize));
        errdefer allocator.free(day12String);
        var day13String = try dir.readFileAlloc(allocator, "files/13.txt", std.math.maxInt(usize));
        errdefer allocator.free(day13String);

        return Self{
            .allocator = allocator,
            .day01 = day01String,
            .day02 = day02String,
            .day03 = day03String,
            .day04 = day04String,
            .day05 = day05String,
            .day06 = day06String,
            .day07 = day07String,
            .day08 = day08String,
            .day09 = day09String,
            .day10 = day10String,
            .day11 = day11String,
            .day12 = day12String,
            .day13 = day13String,
        };
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
    }
};

pub fn HashSet(comptime T: type) type {
    const mapType = if (T == []const u8) std.StringHashMap(void) else std.AutoHashMap(T, void);

    return struct {
        const Self = @This();

        map: mapType,

        pub fn init(allocator: *std.mem.Allocator) Self {
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

pub fn toInt(comptime T: type, contents: []u8, number: *T, size: *usize) void {
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
