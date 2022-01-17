const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var state = State(2).load(contents);
    var p1: usize = try solve(2, state, allocator);
    var p2: usize = try solve(4, state.enlargen(), allocator);

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

    while (states.removeMinOrNull()) |*entry| {
        if (entry.minState.complete()) {
            return entry.cost;
        }

        if (!try seenStates.insertCheck(entry.minState)) {
            continue;
        }

        try entry.minState.state().transition(&transitions);
        var transitionsIterator = transitions.iterator();
        while (transitionsIterator.next()) |next| {
            var newCost = entry.cost + next.value_ptr.*;
            try states.add(.{ .minState = next.key_ptr.min(), .cost = newCost });
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

    fn homeColumn(self: @This()) usize {
        return switch (self) {
            .a => 3,
            .b => 5,
            .c => 7,
            .d => 9,
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
        ) !void {
            states.clearRetainingCapacity();

            for (self.tiles[1]) |cell, i| {
                if (cell.isLetter()) {
                    var homeColumn = cell.homeColumn();

                    var canMoveToColumn = true;
                    var x = std.math.min(i, homeColumn);
                    var end = std.math.max(i, homeColumn);
                    while (x <= end) : (x += 1) {
                        if (x == i)
                            continue;
                        canMoveToColumn = canMoveToColumn and !self.tiles[1][x].isLetter();
                    }
                    if (!canMoveToColumn) {
                        continue;
                    }

                    var canMoveIntoColumn = true;
                    var y: usize = 2;
                    while (y < rows + 2) : (y += 1) {
                        canMoveIntoColumn = canMoveIntoColumn and (self.tiles[y][homeColumn] == .floor or self.tiles[y][homeColumn] == cell);
                    }
                    if (!canMoveIntoColumn) {
                        continue;
                    }

                    // TODO - if moving into home column it wants to go down as far as possible since it will stay there
                    var rowMoveCost = if (i > homeColumn) i - homeColumn else homeColumn - i;
                    y = 2;
                    while (y < rows + 2) : (y += 1) {
                        if (!self.tiles[y][homeColumn].isLetter()) {
                            var cost = (rowMoveCost + (y - 1)) * cell.cost();
                            var state = self;
                            std.mem.swap(Tile, &state.tiles[y][homeColumn], &state.tiles[1][i]);
                            try states.put(state, cost);
                        } else {
                            break;
                        }
                    }
                }
            }

            for ([_]usize{ 3, 5, 7, 9 }) |column| {
                var y: usize = 2;
                var rowComplete = true;
                while (y < rows + 2) : (y += 1) {
                    rowComplete = rowComplete and (self.tiles[y][column].isLetter() and self.tiles[y][column].homeColumn() == column);
                }
                if (rowComplete) {
                    continue;
                }

                y = 2;
                while (y < rows + 2) : (y += 1) {
                    if (self.tiles[y][column] == .floor) {
                        continue;
                    }
                    if (self.tiles[y][column].isLetter()) {
                        var distToHallway = y - 1;
                        var x: usize = column;
                        while (!self.tiles[1][x].isLetter() and self.tiles[1][x] != .wall) : (x += 1) {
                            var distAlongHallway = x - column;
                            if (self.tiles[1][x] == .floor) {
                                var state = self;
                                std.mem.swap(Tile, &state.tiles[1][x], &state.tiles[y][column]);
                                try states.put(state, (distToHallway + distAlongHallway) * self.tiles[y][column].cost());
                            }
                        }
                        x = column;
                        while (!self.tiles[1][x].isLetter() and self.tiles[1][x] != .wall) : (x -= 1) {
                            var distAlongHallway = column - x;
                            if (self.tiles[1][x] == .floor) {
                                var state = self;
                                std.mem.swap(Tile, &state.tiles[1][x], &state.tiles[y][column]);
                                try states.put(state, (distToHallway + distAlongHallway) * self.tiles[y][column].cost());
                            }
                        }

                        break;
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
