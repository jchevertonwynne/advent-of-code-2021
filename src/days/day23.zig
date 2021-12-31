const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var state = State(2).load(contents);
    var p1: usize = try solve(2, state, allocator);
    var p2: usize = 0;
    // var p1: usize = 0;
    // var p2: usize = try solve(4, state.enlargen(), allocator);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 23, p1, p2, duration);

    return duration;
}

fn PrioQueueEntry(comptime rows: usize) type {
    return struct {
        minState: MinState(rows),
        cost: usize,

        fn compare(_: void, a: @This(), b: @This()) std.math.Order {
            return std.math.order(a.cost, b.cost);
        }
    };
}

fn solve(comptime rows: usize, startingState: State(rows), allocator: std.mem.Allocator) !usize {
    var states = std.PriorityDequeue(PrioQueueEntry(rows), void, PrioQueueEntry(rows).compare).init(allocator, {});
    defer states.deinit();
    try states.add(.{ .minState = startingState.min(), .cost = 0 });

    var seenStates = util.HashSet(MinState(rows)).init(allocator);
    defer seenStates.deinit();

    var transitions = std.AutoHashMap(State(rows), usize).init(allocator);
    defer transitions.deinit();

    var transitionsSeen = util.HashSet(MinState(rows)).init(allocator);
    defer transitionsSeen.deinit();

    var bestSoFar: ?usize = null;

    while (states.removeMinOrNull()) |*entry| {
        if (entry.minState.complete())
            return entry.cost;

        if (!try seenStates.insertCheck(entry.minState))
            continue;

        try entry.minState.state().transition(&transitions, &transitionsSeen);
        var transitionsIterator = transitions.iterator();
        while (transitionsIterator.next()) |next| {
            if (!seenStates.contains(next.key_ptr.min())) {
                var newCost = entry.cost + next.value_ptr.*;

                if (bestSoFar) |best| {
                    if (newCost <= best) {
                        try states.add(.{ .minState = next.key_ptr.min(), .cost = newCost });
                    }
                } else {
                    try states.add(.{ .minState = next.key_ptr.min(), .cost = newCost });
                }

                if (next.key_ptr.complete()) {
                    if (bestSoFar) |best| {
                        if (best > newCost) {
                            bestSoFar = newCost;
                            std.debug.print("found a potential best! - {}\n", .{newCost});
                            var startLen = states.count();
                            while (states.removeMaxOrNull()) |max| {
                                if (max.cost <= newCost) {
                                    try states.add(max);
                                    break;
                                }
                            }
                            std.debug.print("reduced from {} states to {} - removed {}\n", .{ startLen, states.count(), startLen - states.count() });
                        }
                    } else {
                        bestSoFar = newCost;
                        std.debug.print("found a potential best! - {}\n", .{newCost});
                        var startLen = states.count();
                        while (states.removeMaxOrNull()) |max| {
                            if (max.minState.complete()) {
                                try states.add(max);
                                break;
                            }
                        }
                        std.debug.print("reduced from {} states to {} - removed {}\n", .{ startLen, states.count(), startLen - states.count() });
                    }
                }
            }
        }
    }

    unreachable;
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

        fn print(self: @This()) void {
            self.state().print();
        }

        fn complete(self: @This()) bool {
            const table = [_]struct { column: [rows]Point, index: usize }{
                .{ .column = self.a, .index = 3 },
                .{ .column = self.b, .index = 5 },
                .{ .column = self.c, .index = 7 },
                .{ .column = self.d, .index = 9 },
            };
            for (table) |t| {
                for (t.column) |entry, i| {
                    if (entry.i != t.index)
                        return false;
                    if (entry.j != 2 + i)
                        return false;
                }
            }
            return true;
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

            const checks = [4]struct { tile: Tile, dest: *[rows]Point, counter: *usize }{
                .{ .tile = .a, .dest = &res.a, .counter = &a },
                .{ .tile = .b, .dest = &res.b, .counter = &b },
                .{ .tile = .c, .dest = &res.c, .counter = &c },
                .{ .tile = .d, .dest = &res.d, .counter = &d },
            };

            for (self.tiles[1]) |cell, i| {
                for (checks) |check| {
                    if (cell == check.tile) {
                        check.dest[check.counter.*] = Point{ .i = @truncate(u4, i), .j = 1 };
                        check.counter.* += 1;
                    }
                }
            }

            inline for ([4]u4{ 3, 5, 7, 9 }) |i| {
                var j: u4 = 2;
                while (j < 2 + rows) : (j += 1) {
                    for (checks) |check| {
                        if (self.tiles[j][i] == check.tile) {
                            check.dest[check.counter.*] = Point{ .i = i, .j = j };
                            check.counter.* += 1;
                        }
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

        fn transition(
            self: @This(),
            states: *std.AutoHashMap(State(rows), usize),
            seen: *util.HashSet(MinState(rows)),
        ) !void {
            states.clearRetainingCapacity();
            seen.clearRetainingCapacity();
            for (self.tiles) |row, j| {
                row: for (row) |cell, i| {
                    if (cell.isLetter()) {
                        const options = [_]struct { tile: Tile, column: usize }{
                            .{ .tile = .a, .column = 3 },
                            .{ .tile = .b, .column = 5 },
                            .{ .tile = .c, .column = 7 },
                            .{ .tile = .d, .column = 9 },
                        };
                        for (options) |opt| {
                            if (cell == opt.tile and i == opt.column and j > 1) {
                                var start: usize = 1 + rows;
                                var safe = true;
                                while (start > j) : (start -= 1) {
                                    safe = safe and self.tiles[start][opt.column] == cell;
                                }
                                if (safe) {
                                    continue :row;
                                }
                            }
                        }
                        try explore(rows, self, i, j, 0, states, seen);
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
                        .entry => ',',
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

fn explore(
    comptime rows: usize,
    state: State(rows),
    i: usize,
    j: usize,
    runningCost: usize,
    states: *std.AutoHashMap(State(rows), usize),
    seen: *util.HashSet(MinState(rows)),
) anyerror!void {
    var moveCost = state.tiles[j][i].cost();

    try seen.insert(state.min());

    inline for ([_]struct { i: u1, iPos: bool, j: u1, jPos: bool }{
        .{ .i = 1, .iPos = true, .j = 0, .jPos = true },
        .{ .i = 1, .iPos = false, .j = 0, .jPos = true },
        .{ .i = 0, .iPos = true, .j = 1, .jPos = true },
        .{ .i = 0, .iPos = true, .j = 1, .jPos = false },
    }) |dir| {
        var newI = if (dir.iPos) i + dir.i else i - dir.i;
        var newJ = if (dir.jPos) j + dir.j else j - dir.j;
        if (state.tiles[newJ][newI] == .floor) {
            var newState = state;
            std.mem.swap(Tile, &newState.tiles[newJ][newI], &newState.tiles[j][i]);
            var newCost = runningCost + moveCost;

            var entry = try states.getOrPut(newState);
            if (!entry.found_existing or entry.value_ptr.* > newCost)
                entry.value_ptr.* = newCost;

            if (!entry.found_existing)
                try explore(rows, newState, newI, newJ, newCost, states, seen);
        } else if (state.tiles[newJ][newI] == .entry) {
            inline for ([_]struct { x: usize, posX: bool, y: usize, posY: bool }{
                .{ .x = 1, .posX = true, .y = 0, .posY = true },
                .{ .x = 1, .posX = false, .y = 0, .posY = true },
                .{ .x = 0, .posX = true, .y = 1, .posY = true },
            }) |redirect| {
                var newerI = if (redirect.posX) newI + redirect.x else newI - redirect.x;
                var newerJ = if (redirect.posY) newJ + redirect.y else newJ - redirect.y;

                if (!(newerI == i and newerJ == j) and state.tiles[newerJ][newerI] == .floor) {
                    var newState = state;
                    std.mem.swap(Tile, &newState.tiles[newerJ][newerI], &newState.tiles[j][i]);
                    var newCost = runningCost + (moveCost * 2);

                    var entry = try states.getOrPut(newState);
                    if (!entry.found_existing or entry.value_ptr.* > newCost)
                        entry.value_ptr.* = newCost;

                    if (!entry.found_existing)
                        try explore(rows, newState, newerI, newerJ, newCost, states, seen);
                }
            }
        }
    }
}
