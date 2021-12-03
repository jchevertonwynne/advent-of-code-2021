const std = @import("std");

const ArrayList = std.ArrayList;

pub fn SlabAllocator(comptime T: type, comptime size: usize) type {
    return struct {
        const Self = @This();

        allocator: *std.mem.Allocator,
        inner: ArrayList(*[size]T),
        ind: usize,

        pub fn init(allocator: *std.mem.Allocator) Self {
            return .{ .allocator = allocator, .inner = ArrayList(*[size]T).init(allocator), .ind = 0 };
        }

        pub fn next(self: *Self) !*T {
            if (self.ind % size == 0) {
                var nextSlab = try self.allocator.create([size]T);
                errdefer self.allocator.free(nextSlab);
                try self.inner.append(nextSlab);
            }
            var res = &self.inner.items[self.ind / size].*[self.ind % size];
            self.ind += 1;
            return res;
        }

        pub fn deinit(self: *Self) void {
            for (self.inner.items) |contents| {
                self.allocator.free(contents);
            }
            self.inner.deinit();
        }
    };
}

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

pub fn RC(comptime T: type) type {
    const internal = struct { val: T, count: usize };

    return struct {
        const Self = @This();

        inner: *internal,
        alloc: *std.mem.Allocator,

        pub fn new(val: T, allocator: *std.mem.Allocator) !Self {
            var inner = try allocator.create(internal);
            inner.count = 1;
            inner.val = val;
            return Self{ .inner = inner, .alloc = allocator };
        }

        pub fn ptr(self: Self) *T {
            return &self.inner.val;
        }

        pub fn copy(self: Self) Self {
            self.inner.count += 1;
            return self;
        }

        pub fn destroy(self: Self) void {
            self.inner.count -= 1;
            if (self.inner.count == 0) {
                self.alloc.destroy(self.inner);
            }
        }
    };
}

pub const Contents = struct {
    const Self = @This();

    allocator: *std.mem.Allocator,
    day01: []u8,
    day02: []u8,
    day03: []u8,

    pub fn load(allocator: *std.mem.Allocator) !Self {
        var dir = std.fs.cwd();
        var day01String = try dir.readFileAlloc(allocator, "files/01.txt", std.math.maxInt(usize));
        errdefer allocator.free(day01String);
        var day02String = try dir.readFileAlloc(allocator, "files/02.txt", std.math.maxInt(usize));
        errdefer allocator.free(day02String);
        var day03String = try dir.readFileAlloc(allocator, "files/03.txt", std.math.maxInt(usize));
        errdefer allocator.free(day03String);

        return Self{
            .allocator = allocator,
            .day01 = day01String,
            .day02 = day02String,
            .day03 = day03String,
        };
    }

    pub fn discard(self: Self) void {
        self.allocator.free(self.day01);
        self.allocator.free(self.day02);
        self.allocator.free(self.day03);
    }
};

pub fn writeResponse(out: anytype, comptime day: usize, part1: anytype, part2: anytype, duration: i128) !void {
    try out.print("problem {}:\n", .{day});
    try out.print("\tpart 1:\t{}\n", .{part1});
    try out.print("\tpart 2:\t{}\n", .{part2});
    if (@divFloor(duration, 1_000) < 1000) {
        try out.print("\ttime:\t{d}us\n\n", .{@divFloor(duration, 1_000)});
    } else {
        try out.print("\ttime:\t{d}ms\n\n", .{@divFloor(duration, 1_000_000)});
    }
}

pub var ZeroAllocator = std.mem.Allocator{ .allocFn = fakeAlloc, .resizeFn = fakeResize };

fn fakeAlloc(_: *std.mem.Allocator, _: usize, _: u29, _: u29, _: usize) ![]u8 {
    @panic("never call me please");
}

fn fakeResize(
    _: *std.mem.Allocator,
    _: []u8,
    _: u29,
    _: usize,
    _: u29,
    _: usize,
) std.mem.Allocator.Error!usize {
    @panic("never call me please");
}
