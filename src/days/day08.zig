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
        
        for (patterns) |*pattern| {
            var pat: u7 = 0;
            while ('a' <= contents[ind] and contents[ind] <= 'g') : (ind += 1) {
                pat |= @as(u7, 1) << @truncate(u3, contents[ind] - 'a');
            }
            pattern.* = pat;
            ind += 1;
        }
        ind += 2;

        std.sort.sort(u7, &patterns, {}, sortPop);

        var outputs = [_]u7{0} ** 4;
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

        // from raw value to index in numbers
        var segmentsToNumber: [std.math.maxInt(u7)]u8 = undefined;

        segmentsToNumber[patterns[0]] = 1;
        segmentsToNumber[patterns[1]] = 7;
        segmentsToNumber[patterns[2]] = 4;
        segmentsToNumber[patterns[9]] = 8;

        if (@popCount(patterns[6] & patterns[0]) == 1) {
            segmentsToNumber[patterns[6]] = 6;

            if (patterns[7] & patterns[2] == patterns[2]) {
                segmentsToNumber[patterns[7]] = 9;
                segmentsToNumber[patterns[8]] = 0;
            } else {
                segmentsToNumber[patterns[8]] = 9;
                segmentsToNumber[patterns[7]] = 0;
            }
        } else if (@popCount(patterns[7] & patterns[0]) == 1) {
            segmentsToNumber[patterns[7]] = 6;

            if (patterns[6] & patterns[2] == patterns[2]) {
                segmentsToNumber[patterns[6]] = 9;
                segmentsToNumber[patterns[8]] = 0;
            } else {
                segmentsToNumber[patterns[8]] = 9;
                segmentsToNumber[patterns[6]] = 0;
            }
        } else {
            segmentsToNumber[patterns[8]] = 6;

            if (patterns[6] & patterns[2] == patterns[2]) {
                segmentsToNumber[patterns[6]] = 9;
                segmentsToNumber[patterns[7]] = 0;
            } else {
                segmentsToNumber[patterns[7]] = 9;
                segmentsToNumber[patterns[6]] = 0;
            }
        }

        if (@popCount(patterns[3] & patterns[0]) == 2) {
            segmentsToNumber[patterns[3]] = 3;

            if (patterns[4] & patterns[3] == patterns[4]) {
                segmentsToNumber[patterns[4]] = 5;
                segmentsToNumber[patterns[5]] = 2;
            } else {
                segmentsToNumber[patterns[5]] = 5;
                segmentsToNumber[patterns[4]] = 2;
            }
        } else if (@popCount(patterns[4] & patterns[0]) == 2) {
            segmentsToNumber[patterns[4]] = 3;

            if (patterns[3] & patterns[4] == patterns[3]) {
                segmentsToNumber[patterns[3]] = 5;
                segmentsToNumber[patterns[5]] = 2;
            } else {
                segmentsToNumber[patterns[5]] = 5;
                segmentsToNumber[patterns[3]] = 2;
            }
        } else {
            segmentsToNumber[patterns[5]] = 3;

            if (patterns[3] & patterns[5] == patterns[3]) {
                segmentsToNumber[patterns[3]] = 5;
                segmentsToNumber[patterns[4]] = 2;
            } else {
                segmentsToNumber[patterns[4]] = 5;
                segmentsToNumber[patterns[3]] = 2;
            }
        }

        var res: usize = 0;
        for (outputs) |o| {
            res *= 10;
            res += segmentsToNumber[o];
        }

        p2 += res;
    }

    return .{ .part1 = p1, .part2 = p2 };
}

