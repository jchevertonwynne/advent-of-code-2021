const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []const u8, out: anytype) !i128 {
    var start = std.time.nanoTimestamp();

    var solved = solveAll(contents);
    var p1 = solved.part1;
    var p2 = solved.part2;

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 4, p1, p2, duration);

    return duration;
}

const Result = struct {
    part1: usize,
    part2: usize,
};

fn compute(board: *Board, last: u7) usize {
    var result: usize = 0;

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        if (board.board[i] != comptime std.math.maxInt(u5)) {
            result += i;
        }
    }
    return result * last;
}

fn solveAll(contents: []const u8) Result {
    var calledS: [100]u7 = undefined;

    var readInd: usize = 0;
    var ind: usize = 0;
    while (contents[ind] != '\n') : (readInd += 1) {
        var number: u7 = 0;
        while ('0' <= contents[ind] and contents[ind] <= '9') : (ind += 1) {
            number *= 10;
            number += @truncate(u7, contents[ind] - '0');
        }
        calledS[readInd] = number;
        ind += 1;
    }

    ind += 1;

    var smallest: Board = undefined;
    var sind: usize = comptime std.math.maxInt(usize);
    var send: u7 = undefined;
    var largest: Board = undefined;
    var lind: usize = 0;
    var lend: u7 = undefined;

    while (ind < contents.len) {
        var board: Board = .{
            .board = [_]u5{comptime std.math.maxInt(u5)} ** 100,
            .setRow = [_]u3{5} ** 5,
            .setCol = [_]u3{5} ** 5,
        };
        var row: u5 = 0;
        while (row < 5) : (row += 1) {
            var col: u5 = 0;
            while (col < 5) : (col += 1) {
                const mapper = comptime blk: {
                    var tab: ['9' - ' ' + 1]u7 = undefined;
                    tab[' ' - ' '] = 0;
                    var tabI: u8 = '0';
                    while (tabI <= '9') : (tabI += 1) {
                        tab[tabI - ' '] = tabI - '0';
                    }
                    break :blk tab;
                };
                var num: u7 = mapper[contents[ind] - ' '] * 10 + mapper[contents[ind + 1] - ' '];
                board.board[num] = row * 5 + col;

                ind += 3;
            }
        }

        for (calledS) |called, cind| {
            if (board.mark(called)) {
                if (cind <= sind) {
                    smallest = board;
                    sind = cind;
                    send = called;
                } else if (cind >= lind) {
                    largest = board;
                    lind = cind;
                    lend = called;
                }
                break;
            }
        }

        ind += 1;
    }

    return Result{
        .part1 = compute(&smallest, send),
        .part2 = compute(&largest, lend),
    };
}

const Board = struct {
    const Self = @This();

    board: [100]u5,
    setRow: [5]u3,
    setCol: [5]u3,

    fn mark(self: *Self, val: u7) bool {
        var ind = self.board[val];
        self.board[val] = comptime std.math.maxInt(u5);
        if (ind != comptime std.math.maxInt(u5)) {
            var col = ind % 5;
            var row = ind / 5;
            self.setCol[col] -= 1;
            self.setRow[row] -= 1;
            return self.setCol[col] == 0 or self.setRow[row] == 0;
        }
        return false;
    }
};
