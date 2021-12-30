const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var scanners = try parseScanners(contents, allocator);
    defer {
        for (scanners) |*scanner|
            scanner.readings.deinit();
        allocator.free(scanners);
    }

    var answers = try solve(scanners, allocator);
    var p1: usize = answers.part1;
    var p2: i32 = answers.part2;

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 19, p1, p2, duration);

    return duration;
}

const KnownPosition = struct { rotation: usize, referenceGridDelta: Vec3 };
const Pair = struct { a: Vec3, b: Vec3 };
const SolveResult = struct { part1: usize, part2: i32 };
const MagnitudeMapVal = struct { count: usize, last: ?Pair };

fn solve(scanners: []Scanner, allocator: std.mem.Allocator) !SolveResult {
    var knownPostions = std.AutoHashMap(*Scanner, KnownPosition).init(allocator);
    defer knownPostions.deinit();

    var unsolvedScanner = std.ArrayList(*Scanner).init(allocator);
    defer unsolvedScanner.deinit();
    for (scanners[1..]) |*scanner|
        try unsolvedScanner.append(scanner);

    var stillUnsolved = std.ArrayList(*Scanner).init(allocator);
    defer stillUnsolved.deinit();

    var solved = &scanners[0];
    try knownPostions.put(solved, KnownPosition{ .rotation = 0, .referenceGridDelta = Vec3{ .x = 0, .y = 0, .z = 0 } });

    var referenceGrid = util.HashSet(Vec3).init(allocator);
    defer referenceGrid.deinit();

    for (solved.readings.items) |reading|
        try referenceGrid.insert(reading[0]);

    var magnitudes = std.AutoHashMap(i32, MagnitudeMapVal).init(allocator);
    defer magnitudes.deinit();

    while (unsolvedScanner.items.len != 0) {
        while (unsolvedScanner.popOrNull()) |unsolved| {
            var rotation: usize = 0;
            block: while (rotation < 24) : (rotation += 1) {
                magnitudes.clearRetainingCapacity();

                for (unsolved.readings.items) |reading| {
                    var rot = reading[rotation];
                    var referenceIt = referenceGrid.iterator();
                    while (referenceIt.next()) |referenceCoord| {
                        var mag = referenceCoord.sub(rot).magnitude();
                        var entry = try magnitudes.getOrPut(mag);
                        if (!entry.found_existing)
                            entry.value_ptr.* = MagnitudeMapVal{ .count = 0, .last = null };
                        entry.value_ptr.count += 1;
                        entry.value_ptr.last = Pair{ .a = referenceCoord.*, .b = rot };
                    }
                }

                var magIt = magnitudes.iterator();
                while (magIt.next()) |m| {
                    if (m.value_ptr.count >= 12) {
                        var coords = m.value_ptr.last.?;
                        var newReferenceGridDelta = coords.a.sub(coords.b);
                        try knownPostions.put(unsolved, KnownPosition{ .rotation = rotation, .referenceGridDelta = newReferenceGridDelta });
                        for (unsolved.readings.items) |reading|
                            try referenceGrid.insert(reading[rotation].add(newReferenceGridDelta));
                        break :block;
                    }
                }
            } else {
                try stillUnsolved.append(unsolved);
            }
        }

        std.mem.swap(@TypeOf(unsolvedScanner), &unsolvedScanner, &stillUnsolved);
    }

    var part2: i32 = 0;
    var aIt = knownPostions.iterator();
    while (aIt.next()) |aVal| {
        var bIt = knownPostions.iterator();
        while (bIt.next()) |bVal| {
            part2 = std.math.max(part2, aVal.value_ptr.referenceGridDelta.manhattan(bVal.value_ptr.referenceGridDelta));
        }
    }

    return SolveResult{ .part1 = referenceGrid.count(), .part2 = part2 };
}

const Vec3 = struct {
    x: i32,
    y: i32,
    z: i32,

    fn manhattan(self: @This(), other: @This()) i32 {
        return (std.math.absInt(self.x - other.x) catch unreachable) + (std.math.absInt(self.y - other.y) catch unreachable) + (std.math.absInt(self.z - other.z) catch unreachable);
    }

    fn magnitude(self: @This()) i32 {
        return self.x * self.x + self.y * self.y + self.z * self.z;
    }

    fn inverse(self: @This()) @This() {
        var x = -self.x;
        var y = -self.y;
        var z = -self.z;
        return .{ .x = x, .y = y, .z = z };
    }

    fn add(self: @This(), other: @This()) @This() {
        var x = self.x + other.x;
        var y = self.y + other.y;
        var z = self.z + other.z;
        return .{ .x = x, .y = y, .z = z };
    }

    fn sub(self: @This(), other: @This()) @This() {
        var x = self.x - other.x;
        var y = self.y - other.y;
        var z = self.z - other.z;
        return .{ .x = x, .y = y, .z = z };
    }

    fn rotateAroundX(self: @This()) @This() {
        var x = self.x;
        var y = -self.z;
        var z = self.y;
        return .{ .x = x, .y = y, .z = z };
    }

    fn rotateAroundY(self: @This()) @This() {
        var x = -self.z;
        var y = self.y;
        var z = self.x;
        return .{ .x = x, .y = y, .z = z };
    }

    fn rotateAroundZ(self: @This()) @This() {
        var x = self.y;
        var y = -self.x;
        var z = self.z;
        return .{ .x = x, .y = y, .z = z };
    }

    fn positions(self: @This()) [6]@This() {
        return .{
            .{ .x = self.x, .y = self.y, .z = self.z }, // x -> +x
            .{ .x = -self.x, .y = self.y, .z = -self.z }, // x -> -x
            .{ .x = -self.y, .y = self.x, .z = self.z }, // x -> +y
            .{ .x = self.y, .y = -self.x, .z = self.z }, // x -> -y
            .{ .x = -self.z, .y = self.y, .z = self.x }, // x -> z
            .{ .x = self.z, .y = self.y, .z = -self.x }, // x -> -z
        };
    }

    fn rotations(self: @This()) [24]@This() {
        var result: [24]@This() = undefined;

        var _positions = self.positions();
        var i: usize = 0;
        while (i < 4) : (i += 1) {
            result[i] = _positions[0];
            _positions[0] = _positions[0].rotateAroundX();
        }
        while (i < 8) : (i += 1) {
            result[i] = _positions[1];
            _positions[1] = _positions[1].rotateAroundX();
        }
        while (i < 12) : (i += 1) {
            result[i] = _positions[2];
            _positions[2] = _positions[2].rotateAroundY();
        }
        while (i < 16) : (i += 1) {
            result[i] = _positions[3];
            _positions[3] = _positions[3].rotateAroundY();
        }
        while (i < 20) : (i += 1) {
            result[i] = _positions[4];
            _positions[4] = _positions[4].rotateAroundZ();
        }
        while (i < 24) : (i += 1) {
            result[i] = _positions[5];
            _positions[5] = _positions[5].rotateAroundZ();
        }

        return result;
    }
};

const Scanner = struct { number: usize, readings: std.ArrayList([24]Vec3) };

fn parseScanners(contents: []u8, allocator: std.mem.Allocator) ![]Scanner {
    var scanners = std.ArrayList(Scanner).init(allocator);
    errdefer {
        for (scanners.items) |*scanner|
            scanner.readings.deinit();
        scanners.deinit();
    }

    var ind: usize = 0;
    while (ind < contents.len) {
        ind += 12;
        var size: usize = undefined;

        var scanner: Scanner = .{ .number = undefined, .readings = std.ArrayList([24]Vec3).init(allocator) };
        errdefer scanner.readings.deinit();
        util.toUnsignedInt(usize, contents[ind..], &scanner.number, &size);
        ind += size + 5;
        while (ind + 1 < contents.len and contents[ind] != '\n') {
            var scanResult: Vec3 = undefined;
            util.toSignedInt(i32, contents[ind..], &scanResult.x, &size);
            ind += size + 1;
            util.toSignedInt(i32, contents[ind..], &scanResult.y, &size);
            ind += size + 1;
            util.toSignedInt(i32, contents[ind..], &scanResult.z, &size);
            ind += size + 1;
            try scanner.readings.append(scanResult.rotations());
        }
        ind += 1;
        try scanners.append(scanner);
    }

    return scanners.toOwnedSlice();
}
