const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var state = try loadState(contents, allocator);
    defer state.deinit();

    var p1: usize = try part1(state);
    var p2: usize = try part2(state);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 4, p1, p2, duration);

    return duration;
}

fn part1(state: State) !usize {
    for (state.called) |called| {
        for (state.boards) |*board| {
            board.mark(called);
            if (board.won()) {
                var result: usize = 0;

                for (board.board[0..5]) |row| {
                    var i: u7 = 0;
                    while (i < 100) : (i += 1) {
                        if (row & (@as(u100, 1) << i) != 0)
                            result += i;
                    }
                }

                return result * called;
            }
        }
    }

    return error.NoWinner;
}

fn part2(state: State) !usize {
    for (state.called) |called, i| {
        var winnerInd: usize = 0;
        var remaining: usize = 0;
        for (state.boards) |*b, boardInd| {
            if (b.wonGame) {
                continue;
            }
            b.mark(called);
            if (!b.won()) {
                remaining += 1;
                winnerInd = boardInd;
            }
        }

        if (remaining == 1) {
            var ind = i;
            var lastBoard = state.boards[winnerInd];

            while (!lastBoard.won()) : (ind += 1)
                lastBoard.mark(state.called[ind]);

            var result: usize = 0;

            for (lastBoard.board[0..5]) |row| {
                var shift: u7 = 0;
                while (shift < 100) : (shift += 1) {
                    if (row & (@as(u100, 1) << shift) != 0)
                        result += shift;
                }
            }

            return result * state.called[ind - 1];
        }
    }

    return error.NoSolutionFound;
}

const State = struct {
    const Self = @This();

    called: []usize,
    boards: []Board,
    allocator: *std.mem.Allocator,

    fn deinit(self: *Self) void {
        self.allocator.free(self.called);
        self.allocator.free(self.boards);
    }
};

const Board = struct {
    const Self = @This();

    board: [10]u100,
    wonGame: bool,

    fn mark(self: *Self, val: usize) void {
        var mask = ~(@as(u100, 1) << @truncate(u7, val));
        for (self.board) |*b|
            b.* &= mask;
    }

    fn won(self: *Self) bool {
        for (self.board) |b| {
            if (b == 0) {
                self.wonGame = true;
                return true;
            }
        }

        return false;
    }
};

fn loadState(contents: []u8, allocator: *std.mem.Allocator) !State {
    var called = std.ArrayList(usize).init(allocator);
    defer called.deinit();
    var boards = std.ArrayList(Board).init(allocator);
    defer boards.deinit();

    var ind: usize = 0;
    while (contents[ind] != '\n') {
        var number: usize = 0;
        while ('0' <= contents[ind] and contents[ind] <= '9') : (ind += 1) {
            number *= 10;
            number += contents[ind] - '0';
        }
        try called.append(number);
        ind += 1;
    }

    ind += 1;

    while (ind < contents.len) {
        var board: Board = .{ .board = [_]u100{0} ** 10, .wonGame = false };
        var row: usize = 0;
        var temp: [5][5]u100 = [_][5]u100{[_]u100{0} ** 5} ** 5;
        while (row < 5) : (row += 1) {
            var cell: usize = 0;
            while (cell < 5) : (cell += 1) {
                temp[row][cell] = 0;
                for (contents[ind .. ind + 2]) |c| {
                    if ('0' <= c and c <= '9') {
                        temp[row][cell] *= 10;
                        temp[row][cell] += c - '0';
                    }
                }

                ind += 3;
            }
        }
        for (temp) |tempRow, i| {
            for (tempRow) |cell| {
                board.board[i] |= @as(u100, 1) << @truncate(u7, cell);
            }
        }

        var column: usize = 0;
        while (column < 5) : (column += 1) {
            var tempRow: usize = 0;
            while (tempRow < 5) : (tempRow += 1) {
                board.board[column + 5] |= @as(u100, 1) << @truncate(u7, temp[tempRow][column]);
            }
        }

        try boards.append(board);
        ind += 1;
    }

    return State{ .called = called.toOwnedSlice(), .boards = boards.toOwnedSlice(), .allocator = allocator };
}
