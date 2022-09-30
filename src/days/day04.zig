const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []const u8, out: anytype, allocator: std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var state = try State.load(contents, allocator);
    defer state.deinit();

    var p1: usize = part1(state);
    var p2: usize = part2(state);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 4, p1, p2, duration);

    return duration;
}

fn part1(state: State) usize {
    for (state.called) |called| {
        for (state.boards) |*board| {
            if (board.*.mark(called)) {
                var result: usize = 0;

                var i: usize = 0;
                while (i < 100) : (i += 1) {
                    if (board.board.get(i) != comptime std.math.maxInt(u5)) {
                        result += i;
                    }
                }

                std.mem.swap(Board, board, &state.boards[state.boards.len - 1]);

                return result * called;
            }
        }
    }

    unreachable;
}

fn part2(state: State) usize {
    var ind: usize = undefined;
    var boards = state.boards[0..state.boards.len - 1];

    for (state.called) |called, i| {
        ind = i;
        var boardsInd: usize = 0;

        while (boardsInd < boards.len) {
            if (boards[boardsInd].mark(called)) {
                boards[boardsInd] = boards[boards.len - 1];
                boards = boards[0 .. boards.len - 1];
            } else {
                boardsInd += 1;
            }
        }
        if (boards.len == 1) {
            break;
        }
    }

    while (!boards[0].mark(state.called[ind])) {
        ind += 1;
    }

    var result: usize = 0;

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        if (boards[0].board.get(i) != comptime std.math.maxInt(u5)) {
            result += i;
        }
    }

    return result * state.called[ind];
}

const State = struct {
    const Self = @This();

    called: []u7,
    boards: []Board,
    allocator: std.mem.Allocator,

    fn deinit(self: *Self) void {
        self.allocator.free(self.called);
        self.allocator.free(self.boards);
    }

    fn load(contents: []const u8, allocator: std.mem.Allocator) !State {
        var called = std.ArrayList(u7).init(allocator);
        defer called.deinit();
        var boards = std.ArrayList(Board).init(allocator);
        defer boards.deinit();

        var ind: usize = 0;
        while (contents[ind] != '\n') {
            var number: u7 = 0;
            while ('0' <= contents[ind] and contents[ind] <= '9') : (ind += 1) {
                number *= 10;
                number += @truncate(u7, contents[ind] - '0');
            }
            try called.append(number);
            ind += 1;
        }

        ind += 1;

        while (ind < contents.len) {
            var board: Board = .{
                .board = std.PackedIntArray(u5, 100).initAllTo(comptime std.math.maxInt(u5)),
                .setRow = std.PackedIntArray(u3, 5).initAllTo(5),
                .setCol = std.PackedIntArray(u3, 5).initAllTo(5),
            };
            var row: u5 = 0;
            while (row < 5) : (row += 1) {
                var col: u5 = 0;
                while (col < 5) : (col += 1) {
                    var num: u7 = 0;
                    for (contents[ind .. ind + 2]) |c| {
                        if ('0' <= c and c <= '9') {
                            num *= 10;
                            num += @truncate(u7, c - '0');
                        }
                    }
                    board.board.set(num, row * 5 + col);

                    ind += 3;
                }
            }

            try boards.append(board);
            ind += 1;
        }

        var cowned = called.toOwnedSlice();
        var bowned = boards.toOwnedSlice();

        return State{
            .called = cowned,
            .boards = bowned,
            .allocator = allocator,
        };
    }
};

const Board = struct {
    const Self = @This();

    board: std.PackedIntArray(u5, 100),
    setRow: std.PackedIntArray(u3, 5),
    setCol: std.PackedIntArray(u3, 5),

    fn mark(self: *Self, val: u7) bool {
        var ind = self.board.get(val);
        self.board.set(val, comptime std.math.maxInt(u5));
        if (ind != comptime std.math.maxInt(u5)) {
            var col = ind % 5;
            var row = ind / 5;
            var currCol = self.setCol.get(col);
            var currRow = self.setRow.get(row);
            self.setCol.set(col, currCol - 1);
            self.setRow.set(row, currRow - 1);
            return currCol == 1 or currRow == 1;
        }
        return false;
    }
};
