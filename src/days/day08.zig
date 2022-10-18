const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []const u8, out: anytype) !i128 {
    var start = std.time.nanoTimestamp();

    var solve = megaSolve(contents);
    var p1 = solve.part1;
    var p2 = solve.part2;

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 8, p1, p2, duration);

    return duration;
}

fn sortPop(_: void, a: u7, b: u7) bool {
    return @popCount(a) < @popCount(b);
}

fn megaSolve(contents: []const u8) struct { part1: usize, part2: usize } {
    var p1: usize = 0;
    var p2: usize = 0;

    var ind: usize = 0;
    while (ind < contents.len) {
        var patterns = [_]u7{0} ** 10;
        var outputs = [_]u7{0} ** 4;
        for (patterns) |*pattern| {
            var pat: u7 = 0;
            while ('a' <= contents[ind] and contents[ind] <= 'g') : (ind += 1) {
                pat |= @as(u7, 1) << @truncate(u3, contents[ind] - 'a');
            }
            pattern.* = pat;
            ind += 1;
        }

        std.sort.sort(u7, &patterns, {}, sortPop);

        ind += 2;
        for (outputs) |*output| {
            var out: u7 = 0;
            while ('a' <= contents[ind] and contents[ind] <= 'g') : (ind += 1) {
                out |= @as(u7, 1) << @truncate(u3, contents[ind] - 'a');
            }
            output.* = out;
            ind += 1;
        }

        for (outputs) |output| {
            var pc = @popCount(output);
            if (pc == 2 or pc == 3 or pc == 4 or pc == 7) {
                p1 += 1;
            }
        }

        var numbers: [10]u8 = undefined;
        numbers[1] = 0;
        numbers[7] = 1;
        numbers[4] = 2;
        numbers[8] = 9;

        if (@popCount(patterns[6] & patterns[numbers[1]]) == 1) {
            numbers[6] = 6;
            if (patterns[7] & patterns[numbers[4]] == patterns[numbers[4]]) {
                numbers[9] = 7;
                numbers[0] = 8;
            } else {
                numbers[9] = 8;
                numbers[0] = 7;
            }
        } else if (@popCount(patterns[7] & patterns[numbers[1]]) == 1) {
            numbers[6] = 7;
            if (patterns[6] & patterns[numbers[4]] == patterns[numbers[4]]) {
                numbers[9] = 6;
                numbers[0] = 8;
            } else {
                numbers[9] = 8;
                numbers[0] = 6;
            }
        } else {
            numbers[6] = 8;
            if (patterns[6] & patterns[numbers[4]] == patterns[numbers[4]]) {
                numbers[9] = 6;
                numbers[0] = 7;
            } else {
                numbers[9] = 7;
                numbers[0] = 6;
            }
        }

        if (@popCount(patterns[3] & patterns[numbers[1]]) == 2) {
            numbers[3] = 3;
            if (patterns[4] & patterns[numbers[6]] == patterns[4]) {
                numbers[5] = 4;
                numbers[2] = 5;
            } else {
                numbers[5] = 5;
                numbers[2] = 4;
            }
        } else if (@popCount(patterns[4] & patterns[numbers[1]]) == 2) {
            numbers[3] = 4;
            if (patterns[3] & patterns[numbers[6]] == patterns[3]) {
                numbers[5] = 3;
                numbers[2] = 5;
            } else {
                numbers[5] = 5;
                numbers[2] = 3;
            }
        } else {
            numbers[3] = 5;
            if (patterns[3] & patterns[numbers[6]] == patterns[3]) {
                numbers[5] = 3;
                numbers[2] = 4;
            } else {
                numbers[5] = 4;
                numbers[2] = 3;
            }
        }

        var res: usize = 0;
        for (outputs) |o| {
            res *= 10;
            for (numbers) |n, i| {
                if (o == patterns[n]) {
                    res += i;
                    break;
                }
            }
        }

        p2 += res;
    }

    return .{ .part1 = p1, .part2 = p2 };
}

fn getString(contents: []const u8) []const u8 {
    var length: usize = 0;
    while ('a' <= contents[length] and contents[length] <= 'g')
        length += 1;

    return contents[0..length];
}
