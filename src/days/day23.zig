const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    _ = contents;
    // _ = allocator;

    var state = State.load(contents);
    // var state = (MinState{
    //     .a = .{ .{ 2, 1 }, .{ 3, 3 } },
    //     .b = .{ .{ 5, 2 }, .{ 5, 3 } },
    //     .c = .{ .{ 7, 2 }, .{ 7, 3 } },
    //     .d = .{ .{ 9, 2 }, .{ 9, 3 } },
    // }).state();
    state.print();
    // // finished.state().print();
    // for (state.transition().slice()) |next| {
    //     next.state.print();
    //     std.debug.print("{}\n", .{next.state.complete()});
    //     if (next.state.complete())
    //         return 0;
    // }

    var p1: usize = try part1(state, allocator);
    var p2: usize = 0;

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 23, p1, p2, duration);

    return duration;
}

const BFSState = struct {
    minState: MinState,
    cost: usize,
};

fn prioCompare(_: void, a: BFSState, b: BFSState) std.math.Order {
    var aVal = a.cost + a.minState.distFromIdeal();
    var bVal = b.cost + b.minState.distFromIdeal();
    return std.math.order(aVal, bVal);
}

fn part1(startingState: State, allocator: std.mem.Allocator) !usize {
    var states = std.AutoHashMap(MinState, usize).init(allocator);
    defer states.deinit();
    try states.put(startingState.min(), 0);

    var newStates = std.AutoHashMap(MinState, usize).init(allocator);
    defer newStates.deinit();

    var seenStates = std.AutoHashMap(MinState, usize).init(allocator);
    defer seenStates.deinit();
    try seenStates.put(startingState.min(), 0);

    var bestCost: ?usize = null;

    while (states.count() != 0) {
        newStates.clearRetainingCapacity();

        std.debug.print("to check = {}\n", .{states.count()});

        var it = states.iterator();

        while (it.next()) |entry| {
            if (bestCost) |cost| {
                if (entry.key_ptr.distFromIdeal() > cost - entry.value_ptr.*)
                    continue;
            }
            for (entry.key_ptr.state().transition().slice()) |next| {
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

    if (bestCost) |cost|
        return cost;

    unreachable;
}

const TransitionResult = struct {
    state: State,
    cost: usize,
};

fn lessThan(a: [2]u4, b: [2]u4) bool {
    return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]);
}

const MinState = struct {
    a: [2][2]u4,
    b: [2][2]u4,
    c: [2][2]u4,
    d: [2][2]u4,

    fn state(self: @This()) State {
        var res: State = State{ .tiles = [5][13]Tile{
            .{ .wall, .wall, .wall, .wall, .wall, .wall, .wall, .wall, .wall, .wall, .wall, .wall, .wall },
            .{ .wall, .floor, .floor, .entry, .floor, .entry, .floor, .entry, .floor, .entry, .floor, .floor, .wall },
            .{ .wall, .wall, .wall, .floor, .wall, .floor, .wall, .floor, .wall, .floor, .wall, .wall, .wall },
            .{ .wall, .wall, .wall, .floor, .wall, .floor, .wall, .floor, .wall, .floor, .wall, .wall, .wall },
            .{ .wall, .wall, .wall, .wall, .wall, .wall, .wall, .wall, .wall, .wall, .wall, .wall, .wall },
        } };

        for (self.a) |coords|
            res.tiles[coords[1]][coords[0]] = .a;

        for (self.b) |coords|
            res.tiles[coords[1]][coords[0]] = .b;

        for (self.c) |coords|
            res.tiles[coords[1]][coords[0]] = .c;

        for (self.d) |coords|
            res.tiles[coords[1]][coords[0]] = .d;

        return res;
    }

    fn distFromIdeal(self: @This()) usize {
        var result: usize = 0;

        const aGoal = [2]u4{ 3, 3 };
        const bGoal = [2]u4{ 5, 3 };
        const cGoal = [2]u4{ 7, 3 };
        const dGoal = [2]u4{ 9, 3 };

        const parts = [4]struct { coords: [2][2]u4, goal: [2]u4, multiplier: usize }{
            .{ .coords = self.a, .goal = aGoal, .multiplier = 1 },
            .{ .coords = self.b, .goal = bGoal, .multiplier = 10 },
            .{ .coords = self.c, .goal = cGoal, .multiplier = 100 },
            .{ .coords = self.d, .goal = dGoal, .multiplier = 1000 },
        };

        for (parts) |part| {
            for (part.coords) |coord| {
                for (coord) |_realCoord, i| {
                    var realCoord = _realCoord;
                    var goalCoord = part.goal[i];

                    if (goalCoord > realCoord)
                        std.mem.swap(u4, &goalCoord, &realCoord);

                    result += (@as(usize, realCoord) - @as(usize, goalCoord)) * part.multiplier;
                }
            }
        }

        return result;
    }

    fn print(self: @This()) void {
        self.state().print();
    }
};

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

const State = struct {
    tiles: [5][13]Tile,

    fn min(self: @This()) MinState {
        var res: MinState = undefined;
        var a: usize = 0;
        var b: usize = 0;
        var c: usize = 0;
        var d: usize = 0;

        for (self.tiles[1][1..12]) |cell, i| {
            if (cell == .a) {
                res.a[a] = [2]u4{ @truncate(u4, i) + 1, 1 };
                a += 1;
            }
            if (cell == .b) {
                res.b[b] = [2]u4{ @truncate(u4, i) + 1, 1 };
                b += 1;
            }
            if (cell == .c) {
                res.c[c] = [2]u4{ @truncate(u4, i) + 1, 1 };
                c += 1;
            }
            if (cell == .d) {
                res.d[d] = [2]u4{ @truncate(u4, i) + 1, 1 };
                d += 1;
            }
        }

        const verts = [4]u4{ 3, 5, 7, 9 };
        inline for (verts) |i| {
            var j: u4 = 2;
            while (j < 4) : (j += 1) {
                if (self.tiles[j][i] == .a) {
                    res.a[a] = [2]u4{ i, j };
                    a += 1;
                }
                if (self.tiles[j][i] == .b) {
                    res.b[b] = [2]u4{ i, j };
                    b += 1;
                }
                if (self.tiles[j][i] == .c) {
                    res.c[c] = [2]u4{ i, j };
                    c += 1;
                }
                if (self.tiles[j][i] == .d) {
                    res.d[d] = [2]u4{ i, j };
                    d += 1;
                }
            }
        }

        if (!lessThan(res.a[0], res.a[1]))
            std.mem.swap([2]u4, &res.a[0], &res.a[1]);
        if (!lessThan(res.b[0], res.b[1]))
            std.mem.swap([2]u4, &res.b[0], &res.b[1]);
        if (!lessThan(res.c[0], res.c[1]))
            std.mem.swap([2]u4, &res.c[0], &res.c[1]);
        if (!lessThan(res.d[0], res.d[1]))
            std.mem.swap([2]u4, &res.d[0], &res.d[1]);

        return res;
    }

    fn complete(self: @This()) bool {
        var completeA = self.tiles[2][3] == .a and self.tiles[3][3] == .a;
        var completeB = self.tiles[2][5] == .b and self.tiles[3][5] == .b;
        var completeC = self.tiles[2][7] == .c and self.tiles[3][7] == .c;
        var completeD = self.tiles[2][9] == .d and self.tiles[3][9] == .d;
        return completeA and completeB and completeC and completeD;
    }

    fn transition(self: @This()) std.BoundedArray(TransitionResult, 32) {
        // TODO -
        // 1 - attempt to move tiles in their home row down if possible
        // 2 - attempt to move tiles with an available home row into their home row
        // 3 - else just check for the next available moves
        var states = std.BoundedArray(TransitionResult, 32).init(0) catch unreachable;

        for (self.tiles) |row, j| {
            for (row) |cell, i| {
                if (cell.isLetter()) {
                    switch (cell) {
                        .a => {
                            if (i == 3 and j == 3)
                                continue;
                            if (i == 3 and j == 2) {
                                if (self.tiles[3][3] == .a) {
                                    continue;
                                }
                                if (self.tiles[3][3] == .floor) {
                                    var copy = self;
                                    std.mem.swap(Tile, &copy.tiles[3][3], &copy.tiles[2][3]);
                                    var cost = cell.cost();
                                    states.append(.{ .state = copy, .cost = cost }) catch unreachable;
                                    continue;
                                }
                            }
                        },
                        .b => {
                            if (i == 5 and j == 3)
                                continue;
                            if (i == 5 and j == 2) {
                                if (self.tiles[3][5] == .b) {
                                    continue;
                                }
                                if (self.tiles[3][5] == .floor) {
                                    var copy = self;
                                    std.mem.swap(Tile, &copy.tiles[3][5], &copy.tiles[2][5]);
                                    var cost = cell.cost();
                                    states.append(.{ .state = copy, .cost = cost }) catch unreachable;
                                    continue;
                                }
                            }
                        },
                        .c => {
                            if (i == 7 and j == 3)
                                continue;
                            if (i == 7 and j == 2) {
                                if (self.tiles[3][7] == .c) {
                                    continue;
                                }
                                if (self.tiles[3][7] == .floor) {
                                    var copy = self;
                                    std.mem.swap(Tile, &copy.tiles[3][7], &copy.tiles[2][7]);
                                    var cost = cell.cost();
                                    states.append(.{ .state = copy, .cost = cost }) catch unreachable;
                                    continue;
                                }
                            }
                        },
                        .d => {
                            if (i == 9 and j == 3)
                                continue;
                            if (i == 9 and j == 2) {
                                if (self.tiles[3][9] == .d) {
                                    continue;
                                }
                                if (self.tiles[3][9] == .floor) {
                                    var copy = self;
                                    std.mem.swap(Tile, &copy.tiles[3][9], &copy.tiles[2][9]);
                                    var cost = cell.cost();
                                    states.append(.{ .state = copy, .cost = cost }) catch unreachable;
                                    continue;
                                }
                            }
                        },
                        else => unreachable,
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
                        switch (self.tiles[newJ][newI]) {
                            .floor => {
                                var copy = self;
                                std.mem.swap(Tile, &copy.tiles[j][i], &copy.tiles[newJ][newI]);
                                var cost = cell.cost();
                                states.append(.{ .state = copy, .cost = cost }) catch unreachable;
                            },
                            .entry => {
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
                                        states.append(.{ .state = copy, .cost = cost * 2 }) catch unreachable;
                                    }
                                }
                            },
                            else => {},
                        }
                    }
                }
            }
        }

        return states;
    }

    fn load(contents: []u8) @This() {
        var result: State = undefined;
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
