const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var state = try loadState(contents, allocator);
    defer {
        allocator.free(state.boards);
        allocator.free(state.called);
    }

    var p1: usize = try part1(state);
    var p2: usize = try part2(state, allocator);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 4, p1, p2, duration);

    return duration;
}

fn part1(state: State) !usize {
    var seen = [_]bool{false} ** 100;

    for (state.called) |called| {
        seen[called] = true;
        for (state.boards) |board| {
            if (board.won(seen)) {
                var result: usize = 0;

                for (board.board) |row| {
                    for (row) |c| {
                        if (!seen[c])
                            result += c;
                    }
                }

                return result * called;
            }
        }
    }

    return error.NoWinner;
}

fn part2(state: State, allocator: *std.mem.Allocator) !usize {
    var boards = std.ArrayList(*Board).init(allocator);
    defer boards.deinit();
    try boards.ensureTotalCapacity(state.boards.len);
    var swap = std.ArrayList(*Board).init(allocator);
    defer swap.deinit();
    try swap.ensureTotalCapacity(state.boards.len);

    for (state.boards) |*board|
        try boards.append(board);

    var seen = [_]bool{false} ** 100;

    for (state.called) |called, i| {
        swap.clearRetainingCapacity();

        seen[called] = true;
        for (boards.items) |b|
            if (!b.won(seen))
                try swap.append(b);

        if (swap.items.len == 1) {
            var ind = i;
            var lastBoard = swap.items[0];

            while (!lastBoard.won(seen)) : (ind += 1)
                seen[state.called[ind]] = true;

            var result: usize = 0;

            for (lastBoard.board) |row| {
                for (row) |c| {
                    if (!seen[c])
                        result += c;
                }
            }

            return result * state.called[ind - 1];
        }

        var temp = boards;
        boards = swap;
        swap = temp;
    }

    return error.NoSolutionFound;
}

const State = struct { called: []usize, boards: []Board };

const Board = struct {
    const Self = @This();

    board: [5][5]usize,

    fn won(self: Self, seen: [100]bool) bool {
        {
            var row: usize = 0;
            while (row < 5) : (row += 1) {
                var col: usize = 0;
                while (col < 5) : (col += 1) {
                    if (!seen[self.board[row][col]])
                        break;
                } else return true;
            }
        }

        {
            var col: usize = 0;
            while (col < 5) : (col += 1) {
                var row: usize = 0;
                while (row < 5) : (row += 1) {
                    if (!seen[self.board[row][col]])
                        break;
                } else return true;
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
        var board: Board = .{ .board = undefined };
        var row: usize = 0;
        while (row < 5) : (row += 1) {
            var cell: usize = 0;
            while (cell < 5) : (cell += 1) {
                board.board[row][cell] = 0;
                for (contents[ind .. ind + 2]) |c| {
                    if ('0' <= c and c <= '9') {
                        board.board[row][cell] *= 10;
                        board.board[row][cell] += c - '0';
                    }
                }

                ind += 3;
            }
        }
        try boards.append(board);
        ind += 1;
    }

    return State{ .called = called.toOwnedSlice(), .boards = boards.toOwnedSlice() };
}
