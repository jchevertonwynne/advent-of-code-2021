const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []const u8, out: anytype, alloc: std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var p1: usize = undefined;
    var p2: usize = undefined;
    try solve(contents, &p1, &p2, alloc);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 10, p1, p2, duration);

    return duration;
}

fn solve(contents: []const u8, p1: *usize, p2: *usize, alloc: std.mem.Allocator) !void {
    var scores = std.ArrayList(usize).init(alloc);
    defer scores.deinit();

    var buf = std.ArrayList(u8).init(alloc);
    defer buf.deinit();

    p1.* = 0;

    var ind: usize = 0;
    while (ind < contents.len) {
        defer buf.clearRetainingCapacity();
        var incomplete = true;

        while (contents[ind] != '\n') {
            switch (contents[ind]) {
                '(', '{', '[', '<' => |openingBracket| {
                    try buf.append(openingBracket);
                },
                else => {
                    var paired: u8 = switch (contents[ind]) {
                        ')' => '(',
                        ']' => '[',
                        '>' => '<',
                        '}' => '{',
                        else => unreachable,
                    };
                    if (buf.items[buf.items.len - 1] == paired) {
                        _ = buf.pop();
                    } else {
                        incomplete = false;

                        p1.* += @as(usize, switch (contents[ind]) {
                            ')' => 3,
                            ']' => 57,
                            '}' => 1_197,
                            '>' => 25_137,
                            else => unreachable,
                        });

                        while (contents[ind] != '\n') {
                            ind += 1;
                        }

                        break;
                    }
                },
            }
            ind += 1;
        }

        ind += 1;

        if (incomplete) {
            var score: usize = 0;
            var bufInd = buf.items.len;
            while (bufInd != 0) {
                bufInd -= 1;
                var c = buf.items[bufInd];
                score *= 5;
                score += @as(usize, switch (c) {
                    '(' => 1,
                    '[' => 2,
                    '{' => 3,
                    '<' => 4,
                    else => unreachable,
                });
            }
            try scores.append(score);
        }
    }

    std.sort.sort(usize, scores.items, {}, comptime std.sort.asc(usize));

    p2.* = scores.items[scores.items.len / 2];
}
