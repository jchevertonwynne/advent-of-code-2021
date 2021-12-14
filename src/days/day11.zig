const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype) !i128 {
    var start = std.time.nanoTimestamp();

    var octopi = loadOctopi(contents);

    var p1: usize = 0;
    var p2: usize = 0;
    solve(octopi, &p1, &p2);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 11, p1, p2, duration);

    return duration;
}

const Coord = struct { x: usize, y: usize };

fn solve(_octopi: Octopi, p1: *usize, p2: *usize) void {
    var octopi = _octopi;

    var step: usize = 0;
    while (true) : (step += 1) {
        var flashing = std.BoundedArray(Coord, 100).init(0) catch unreachable;
        var flashed = std.mem.zeroes([10][10]bool);

        for (octopi) |*row| {
            for (row.*) |*octopus|
                octopus.* += 1;
        }

        for (octopi) |row, j| {
            for (row) |octopus, i| {
                if (octopus >= 10) {
                    flashing.append(Coord{ .x = i, .y = j }) catch unreachable;
                    flashed[i][j] = true;
                }
            }
        }

        while (flashing.len > 0) {
            while (flashing.popOrNull()) |f| {
                var x = f.x;
                var y = f.y;

                if (x > 0 and y > 0) {
                    octopi[y - 1][x - 1] += 1;
                    if (!flashed[x - 1][y - 1] and octopi[y - 1][x - 1] >= 10) {
                        flashing.append(Coord{ .x = x - 1, .y = y - 1 }) catch unreachable;
                        flashed[x - 1][y - 1] = true;
                    }
                }

                if (x > 0) {
                    octopi[y][x - 1] += 1;
                    if (!flashed[x - 1][y] and octopi[y][x - 1] >= 10) {
                        flashing.append(Coord{ .x = x - 1, .y = y }) catch unreachable;
                        flashed[x - 1][y] = true;
                    }
                }

                if (y > 0) {
                    octopi[y - 1][x] += 1;
                    if (!flashed[x][y - 1] and octopi[y - 1][x] >= 10) {
                        flashing.append(Coord{ .x = x, .y = y - 1 }) catch unreachable;
                        flashed[x][y - 1] = true;
                    }
                }

                if (x + 1 < 10 and y + 1 < 10) {
                    octopi[y + 1][x + 1] += 1;
                    if (!flashed[x + 1][y + 1] and octopi[y + 1][x + 1] >= 10) {
                        flashing.append(Coord{ .x = x + 1, .y = y + 1 }) catch unreachable;
                        flashed[x + 1][y + 1] = true;
                    }
                }

                if (x > 0 and y + 1 < 10) {
                    octopi[y + 1][x - 1] += 1;
                    if (!flashed[x - 1][y + 1] and octopi[y + 1][x - 1] >= 10) {
                        flashing.append(Coord{ .x = x - 1, .y = y + 1 }) catch unreachable;
                        flashed[x - 1][y + 1] = true;
                    }
                }

                if (x + 1 < 10 and y > 0) {
                    octopi[y - 1][x + 1] += 1;
                    if (!flashed[x + 1][y - 1] and octopi[y - 1][x + 1] >= 10) {
                        flashing.append(Coord{ .x = x + 1, .y = y - 1 }) catch unreachable;
                        flashed[x + 1][y - 1] = true;
                    }
                }

                if (x + 1 < 10) {
                    octopi[y][x + 1] += 1;
                    if (!flashed[x + 1][y] and octopi[y][x + 1] >= 10) {
                        flashing.append(Coord{ .x = x + 1, .y = y }) catch unreachable;
                        flashed[x + 1][y] = true;
                    }
                }

                if (y + 1 < 10) {
                    octopi[y + 1][x] += 1;
                    if (!flashed[x][y + 1] and octopi[y + 1][x] >= 10) {
                        flashing.append(Coord{ .x = x, .y = y + 1 }) catch unreachable;
                        flashed[x][y + 1] = true;
                    }
                }
            }
        }

        var flashesOnTurn: usize = 0;
        for (flashed) |row, i| {
            for (row) |octopusFlashed, j| {
                if (octopusFlashed) {
                    octopi[j][i] = 0;
                    flashesOnTurn += 1;
                    if (step < 100)
                        p1.* += 1;
                }
            }
        }

        if (flashesOnTurn == 100) {
            p2.* = step + 1;
            return;
        }
    }
}

const Octopi = [10][10]u8;

fn loadOctopi(contents: []u8) Octopi {
    var octopi: Octopi = undefined;

    var i: usize = 0;
    while (i < 10) : (i += 1) {
        var j: usize = 0;
        while (j < 10) : (j += 1) {
            octopi[j][i] = contents[i + 11 * j] - '0';
        }
    }

    return octopi;
}
