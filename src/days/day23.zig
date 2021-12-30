const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var state = State(2).load(contents);
    // var p1: usize = try part1(state, allocator);
    // var p1: usize = try solve(2, state, allocator);
    var p1: usize = 0;
    var p2: usize = try solve(4, state.enlargen(), allocator);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 23, p1, p2, duration);

    return duration;
}

fn solve(comptime rows: usize, startingState: State(rows), allocator: std.mem.Allocator) !usize {
    var states = std.AutoHashMap(MinState(rows), usize).init(allocator);
    defer states.deinit();
    try states.put(startingState.min(), 0);

    var newStates = std.AutoHashMap(MinState(rows), usize).init(allocator);
    defer newStates.deinit();

    var seenStates = std.AutoHashMap(MinState(rows), usize).init(allocator);
    defer seenStates.deinit();
    try seenStates.put(startingState.min(), 0);

    var bestCost: ?usize = null;

    var transitions = std.ArrayList(TransitionResult(rows)).init(allocator);
    defer transitions.deinit();

    while (states.count() != 0) {
        newStates.clearRetainingCapacity();

        std.debug.print("to check = {}\n", .{states.count()});

        var it = states.iterator();

        while (it.next()) |entry| {
            if (bestCost) |cost| {
                if (entry.value_ptr.* > cost)
                    continue;
            }

            try entry.key_ptr.state().transition(&transitions);
            for (transitions.items) |next| {
                var newCost = entry.value_ptr.* + next.cost;
                if (next.state.complete()) {
                    if (bestCost) |cost| {
                        if (cost > newCost) {
                            bestCost = newCost;
                            std.debug.print("bestCost = {}\n", .{bestCost});
                            next.state.print();
                        }
                    } else {
                        bestCost = newCost;
                        std.debug.print("bestCost = {}\n", .{bestCost});
                        next.state.print();
                    }

                    continue;
                }

                var seenRecord = try seenStates.getOrPut(next.state.min());
                if (!seenRecord.found_existing or seenRecord.value_ptr.* > newCost) {
                    seenRecord.value_ptr.* = newCost;
                    try newStates.put(next.state.min(), newCost);
                }
            }
        }

        std.mem.swap(@TypeOf(states, newStates), &states, &newStates);
    }

    return bestCost.?;
}

const Tile = enum {
    wall,
    floor,
    entry,
    a,
    b,
    c,
    d,

    fn isLetter(self: @This()) bool {
        return self == .a or self == .b or self == .c or self == .d;
    }

    fn cost(self: @This()) usize {
        return switch (self) {
            .a => 1,
            .b => 10,
            .c => 100,
            .d => 1000,
            else => unreachable,
        };
    }
};

const Point = packed struct {
    i: u4,
    j: u4,

    fn lessThan(_: void, a: Point, b: Point) bool {
        return a.i < b.i or (a.i == b.i and a.j < b.j);
    }
};

fn MinState(comptime rows: usize) type {
    return struct {
        a: [rows]Point,
        b: [rows]Point,
        c: [rows]Point,
        d: [rows]Point,

        fn state(self: @This()) State(rows) {
            var res: State(rows) = undefined;
            res.tiles[0] = .{ .wall, .wall, .wall, .wall, .wall, .wall, .wall, .wall, .wall, .wall, .wall, .wall, .wall };
            res.tiles[1] = .{ .wall, .floor, .floor, .entry, .floor, .entry, .floor, .entry, .floor, .entry, .floor, .floor, .wall };
            for (res.tiles[2 .. res.tiles.len - 1]) |*row|
                row.* = .{ .wall, .wall, .wall, .floor, .wall, .floor, .wall, .floor, .wall, .floor, .wall, .wall, .wall };
            res.tiles[res.tiles.len - 1] = .{ .wall, .wall, .wall, .wall, .wall, .wall, .wall, .wall, .wall, .wall, .wall, .wall, .wall };

            for (self.a) |point|
                res.tiles[point.j][point.i] = .a;

            for (self.b) |point|
                res.tiles[point.j][point.i] = .b;

            for (self.c) |point|
                res.tiles[point.j][point.i] = .c;

            for (self.d) |point|
                res.tiles[point.j][point.i] = .d;

            return res;
        }
    };
}

fn State(comptime rows: usize) type {
    return struct {
        tiles: [3 + rows][13]Tile,

        fn min(self: @This()) MinState(rows) {
            var res: MinState(rows) = undefined;
            var a: usize = 0;
            var b: usize = 0;
            var c: usize = 0;
            var d: usize = 0;

            for (self.tiles[1]) |cell, i| {
                if (cell == .a) {
                    res.a[a] = Point{ .i = @truncate(u4, i), .j = 1 };
                    a += 1;
                }
                if (cell == .b) {
                    res.b[b] = Point{ .i = @truncate(u4, i), .j = 1 };
                    b += 1;
                }
                if (cell == .c) {
                    res.c[c] = Point{ .i = @truncate(u4, i), .j = 1 };
                    c += 1;
                }
                if (cell == .d) {
                    res.d[d] = Point{ .i = @truncate(u4, i), .j = 1 };
                    d += 1;
                }
            }

            const verts = [4]u4{ 3, 5, 7, 9 };
            inline for (verts) |i| {
                var j: u4 = 2;
                while (j < 2 + rows) : (j += 1) {
                    if (self.tiles[j][i] == .a) {
                        res.a[a] = Point{ .i = i, .j = j };
                        a += 1;
                    }
                    if (self.tiles[j][i] == .b) {
                        res.b[b] = Point{ .i = i, .j = j };
                        b += 1;
                    }
                    if (self.tiles[j][i] == .c) {
                        res.c[c] = Point{ .i = i, .j = j };
                        c += 1;
                    }
                    if (self.tiles[j][i] == .d) {
                        res.d[d] = Point{ .i = i, .j = j };
                        d += 1;
                    }
                }
            }

            std.sort.sort(Point, &res.a, {}, Point.lessThan);
            std.sort.sort(Point, &res.b, {}, Point.lessThan);
            std.sort.sort(Point, &res.c, {}, Point.lessThan);
            std.sort.sort(Point, &res.d, {}, Point.lessThan);

            return res;
        }

        fn complete(self: @This()) bool {
            var completeA = true;
            var j: usize = 2;
            while (j < 2 + rows) : (j += 1) {
                completeA = completeA and self.tiles[j][3] == .a;
            }

            var completeB = true;
            j = 2;
            while (j < 2 + rows) : (j += 1) {
                completeB = completeB and self.tiles[j][5] == .b;
            }

            var completeC = true;
            j = 2;
            while (j < 2 + rows) : (j += 1) {
                completeC = completeC and self.tiles[j][7] == .c;
            }

            var completeD = true;
            j = 2;
            while (j < 2 + rows) : (j += 1) {
                completeD = completeD and self.tiles[j][9] == .d;
            }

            return completeA and completeB and completeC and completeD;
        }

        fn transition(self: @This(), states: *std.ArrayList(TransitionResult(rows))) !void {
            states.clearRetainingCapacity();
            for (self.tiles) |row, j| {
                for (row) |cell, i| {
                    if (cell.isLetter()) {
                        var homeI: u4 = switch (cell) {
                            .a => 3,
                            .b => 5,
                            .c => 7,
                            .d => 9,
                            else => undefined,
                        };

                        if (i == homeI and j > 1) {
                            var allBelowAreCorrect = true;
                            var legalToPlace = false;
                            var pos = rows + 1;
                            while (pos > j) : (pos -= 1) {
                                allBelowAreCorrect = allBelowAreCorrect and self.tiles[pos][i] == cell;
                                if (self.tiles[pos][i] != cell and self.tiles[pos][i] != .floor) {
                                    legalToPlace = false;
                                    break;
                                }
                                legalToPlace = self.tiles[pos][i] == .floor;
                            }

                            if (allBelowAreCorrect)
                                continue;

                            if (legalToPlace) {
                                var copy = self;
                                std.mem.swap(Tile, &copy.tiles[pos + 1][i], &copy.tiles[pos][i]);
                                var cost = cell.cost();
                                states.append(.{ .state = copy, .cost = cost }) catch unreachable;
                                continue;
                            }
                        }

                        const dirs = [4]struct { x: usize, negX: bool, y: usize, negY: bool }{
                            .{ .x = 1, .negX = false, .y = 0, .negY = false },
                            .{ .x = 1, .negX = true, .y = 0, .negY = false },
                            .{ .x = 0, .negX = false, .y = 1, .negY = false },
                            .{ .x = 0, .negX = false, .y = 1, .negY = true },
                        };

                        inline for (dirs) |dir| {
                            var newI = if (dir.negX) i - dir.x else i + dir.x;
                            var newJ = if (dir.negY) j - dir.y else j + dir.y;

                            if (self.tiles[newJ][newI] == .floor) {
                                var copy = self;
                                std.mem.swap(Tile, &copy.tiles[j][i], &copy.tiles[newJ][newI]);
                                var cost = cell.cost();
                                try states.append(.{ .state = copy, .cost = cost });
                            }

                            if (self.tiles[newJ][newI] == .entry) {
                                const redirects = [3]struct { x: usize, negX: bool, y: usize, negY: bool }{
                                    .{ .x = 1, .negX = false, .y = 0, .negY = false },
                                    .{ .x = 1, .negX = true, .y = 0, .negY = false },
                                    .{ .x = 0, .negX = false, .y = 1, .negY = false },
                                };

                                for (redirects) |redirect| {
                                    var newerI = if (redirect.negX) newI - redirect.x else newI + redirect.x;
                                    var newerJ = if (redirect.negY) newJ - redirect.y else newJ + redirect.y;

                                    if (newerI == i and newerJ == j)
                                        continue;

                                    if (self.tiles[newerJ][newerI] == .floor) {
                                        var copy = self;
                                        std.mem.swap(Tile, &copy.tiles[j][i], &copy.tiles[newerJ][newerI]);
                                        var cost = cell.cost();
                                        try states.append(.{ .state = copy, .cost = cost * 2 });
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        fn enlargen(self: @This()) State(rows + 2) {
            var result: State(rows + 2) = undefined;
            result.tiles[0] = self.tiles[0];
            result.tiles[1] = self.tiles[1];
            result.tiles[2] = self.tiles[2];
            result.tiles[3] = .{ .wall, .wall, .wall, .d, .wall, .c, .wall, .b, .wall, .a, .wall, .wall, .wall };
            result.tiles[4] = .{ .wall, .wall, .wall, .d, .wall, .b, .wall, .a, .wall, .c, .wall, .wall, .wall };
            for (self.tiles[3..]) |row, i| {
                result.tiles[5 + i] = row;
            }
            return result;
        }

        fn load(contents: []u8) State(rows) {
            if (rows != 2) 
                @compileError("can only load a 2 row state");

            var result: State(2) = undefined;
            for (result.tiles) |*row| {
                for (row) |*cell|
                    cell.* = .wall;
            }

            for (result.tiles[1][1..12]) |*cell|
                cell.* = .floor;

            result.tiles[2][3] = switch (contents[31]) {
                'A' => .a,
                'B' => .b,
                'C' => .c,
                'D' => .d,
                else => unreachable,
            };
            result.tiles[2][5] = switch (contents[33]) {
                'A' => .a,
                'B' => .b,
                'C' => .c,
                'D' => .d,
                else => unreachable,
            };
            result.tiles[2][7] = switch (contents[35]) {
                'A' => .a,
                'B' => .b,
                'C' => .c,
                'D' => .d,
                else => unreachable,
            };
            result.tiles[2][9] = switch (contents[37]) {
                'A' => .a,
                'B' => .b,
                'C' => .c,
                'D' => .d,
                else => unreachable,
            };

            result.tiles[3][3] = switch (contents[45]) {
                'A' => .a,
                'B' => .b,
                'C' => .c,
                'D' => .d,
                else => unreachable,
            };
            result.tiles[3][5] = switch (contents[47]) {
                'A' => .a,
                'B' => .b,
                'C' => .c,
                'D' => .d,
                else => unreachable,
            };
            result.tiles[3][7] = switch (contents[49]) {
                'A' => .a,
                'B' => .b,
                'C' => .c,
                'D' => .d,
                else => unreachable,
            };
            result.tiles[3][9] = switch (contents[51]) {
                'A' => .a,
                'B' => .b,
                'C' => .c,
                'D' => .d,
                else => unreachable,
            };

            return result;
        }

        fn print(self: @This()) void {
            for (self.tiles) |row| {
                for (row) |cell| {
                    var tile: u8 = switch (cell) {
                        .a => 'A',
                        .b => 'B',
                        .c => 'C',
                        .d => 'D',
                        .entry => '.',
                        .floor => '.',
                        .wall => '#',
                    };
                    std.debug.print("{c}", .{tile});
                }
                std.debug.print("\n", .{});
            }
        }
    };
}

fn TransitionResult(comptime rows: usize) type {
    return struct { state: State(rows), cost: usize };
}
