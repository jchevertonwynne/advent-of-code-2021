const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var scanners = try parseScanners(contents, allocator);
    defer {
        for (scanners) |*scanner|
            scanner.readings.deinit();
        allocator.free(scanners);
    }
    std.debug.print("there are {} scanners\n", .{scanners.len});

    var p1: usize = try part1(scanners, allocator);
    var p2: usize = 0;

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 1, p1, p2, duration);

    return duration;
}

const KnownPosition = struct { rotation: usize, referenceGridDelta: Vec3 };
const Pair = struct{a: Vec3, b: Vec3};

fn part1(scanners: []Scanner, allocator: *std.mem.Allocator) !usize {
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

    while (unsolvedScanner.items.len != 0) {
        std.debug.print("\n\nunsolved = {}\n", .{unsolvedScanner.items.len});
        for (unsolvedScanner.items) |u|
            std.debug.print("    number = {d}\n", .{u.number});
        std.debug.print("solved = {}\n", .{knownPostions.count()});
        {
            var it = knownPostions.keyIterator();
            while (it.next()) |k|
                std.debug.print("    number = {}\n", .{k.*.number});
        }

        while (unsolvedScanner.popOrNull()) |unsolved| {
            std.debug.print("checking scanner number {}\n", .{unsolved.number});
            var knownIt = knownPostions.iterator();

            var mostHits: usize = 0;
            knownBlock: while (knownIt.next()) |k| {
                var rotation: usize = 0;
                while (rotation < 24) : (rotation += 1) {
                    var magnitudes = std.AutoHashMap(i32, std.ArrayList(Pair)).init(allocator);
                    defer {
                        var it = magnitudes.valueIterator();
                        while (it.next()) |val|
                            val.deinit();
                        magnitudes.deinit();
                    }

                    for (unsolved.readings.items) |reading| {
                        var rot = reading[rotation];
                        for (k.key_ptr.*.readings.items) |referenceReading| {
                            var fixedReferenceReading = referenceReading[k.value_ptr.rotation];
                            var mag = fixedReferenceReading.sub(rot).magnitude();
                            var entry = try magnitudes.getOrPut(mag);
                            if (!entry.found_existing)
                                entry.value_ptr.* = std.ArrayList(Pair).init(allocator);
                            try entry.value_ptr.append(.{ .a = fixedReferenceReading, .b = rot });
                        }
                    }

                    var magIt = magnitudes.iterator();
                    while (magIt.next()) |m| {
                        if ( m.value_ptr.items.len >= 12) {
                            std.debug.print("hit on scanner number = {d} against known {d}\n", .{unsolved.number, k.key_ptr.*.number});
                            var first = m.value_ptr.items[0];
                            var delta = first.b.sub(first.a);
                            var newReferenceGridDelta = k.value_ptr.referenceGridDelta.sub(delta);
                            std.debug.print("placing scanner {} at delta {}\n", .{unsolved.number, newReferenceGridDelta});
                            try knownPostions.put(unsolved, KnownPosition{ .rotation = rotation, .referenceGridDelta = newReferenceGridDelta });
                            break :knownBlock;
                        }
                        mostHits = std.math.max(mostHits, m.value_ptr.items.len);
                    }
                    
                }
            } else {
                std.debug.print("not enough hits - most {d}\n", .{mostHits});
                try stillUnsolved.append(unsolved);
            }
        }

        std.mem.swap(@TypeOf(unsolvedScanner), &unsolvedScanner, &stillUnsolved);
    }



    // var it = knownPostions.iterator();
    // while (it.next()) |known| {
    //     for (known.key_ptr.*.readings.items) |reading| {
    //         var truePosition = reading[known.value_ptr.rotation].add(known.value_ptr.referenceGridDelta);
    //         try referenceGrid.insert(truePosition);
    //     }
    // }

    return referenceGrid.count();
}

const Vec3 = struct {
    x: i32,
    y: i32,
    z: i32,

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
            .{ .x = -self.z, .y = self.y, .z = self.x }, // x -> z
            .{ .x = -self.x, .y = self.y, .z = -self.z }, // x -> -x
            .{ .x = self.z, .y = self.y, .z = -self.x }, // x -> -z
            .{ .x = -self.y, .y = self.x, .z = self.z }, // x -> +y
            .{ .x = self.y, .y = -self.x, .z = self.z }, // x -> -y
        };
    }

    fn rotations(self: @This()) [24]@This() {
        var backing: [6][3][4]@This() = undefined;
        for (self.positions()) |*pos, posInd| {
            var i: usize = 0;
            while (i < 4) : (i += 1) {
                backing[posInd][0][i] = pos.*;
                pos.* = pos.rotateAroundX();
            }
            i = 0;
            while (i < 4) : (i += 1) {
                backing[posInd][1][i] = pos.*;
                pos.* = pos.rotateAroundY();
            }
            i = 0;
            while (i < 4) : (i += 1) {
                backing[posInd][2][i] = pos.*;
                pos.* = pos.rotateAroundZ();
            }
        }
        const wanted = [24]struct { x: usize, y: usize, z: usize }{
            .{ .x = 0, .y = 0, .z = 0 },
            .{ .x = 0, .y = 0, .z = 1 },
            .{ .x = 0, .y = 0, .z = 2 },
            .{ .x = 0, .y = 0, .z = 3 },
            .{ .x = 0, .y = 1, .z = 0 },
            .{ .x = 0, .y = 1, .z = 1 },
            .{ .x = 0, .y = 1, .z = 2 },
            .{ .x = 0, .y = 2, .z = 0 },
            .{ .x = 0, .y = 2, .z = 1 },
            .{ .x = 0, .y = 2, .z = 2 },
            .{ .x = 1, .y = 0, .z = 0 },
            .{ .x = 1, .y = 0, .z = 1 },
            .{ .x = 1, .y = 0, .z = 2 },
            .{ .x = 1, .y = 2, .z = 0 },
            .{ .x = 1, .y = 2, .z = 1 },
            .{ .x = 1, .y = 2, .z = 2 },
            .{ .x = 2, .y = 0, .z = 0 },
            .{ .x = 2, .y = 0, .z = 2 },
            .{ .x = 2, .y = 2, .z = 0 },
            .{ .x = 2, .y = 2, .z = 2 },
            .{ .x = 3, .y = 0, .z = 0 },
            .{ .x = 3, .y = 0, .z = 2 },
            .{ .x = 3, .y = 2, .z = 0 },
            .{ .x = 3, .y = 2, .z = 2 },
        };
        var result: [24]@This() = undefined;
        inline for (wanted) |coord, i| {
            result[i] = backing[coord.x][coord.y][coord.z];
        }
        return result;
    }
};

const Scanner = struct { number: usize, readings: std.ArrayList([24]Vec3) };

fn parseScanners(contents: []u8, allocator: *std.mem.Allocator) ![]Scanner {
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
        util.toInt(usize, contents[ind..], &scanner.number, &size);
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
