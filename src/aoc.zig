const builtin = @import("builtin");
const std = @import("std");

const util = @import("util.zig");

const Contents = util.Contents;

pub fn main() !void {
    var genAllocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!genAllocator.deinit());

    var alloc = genAllocator.allocator();

    var contents = try Contents.load(alloc);
    defer contents.discard(alloc);

    var out = std.ArrayList(u8).init(alloc);
    defer out.deinit();
    var writer = out.writer();

    var duration: i128 = 0;

    // duration += try @import("./days/day01.zig").run(contents.day01, &writer);
    // duration += try @import("./days/day02.zig").run(contents.day02, &writer);
    // duration += try @import("./days/day03.zig").run(contents.day03, &writer, alloc);
    // duration += try @import("./days/day04.zig").run(contents.day04, &writer, alloc);
    // duration += try @import("./days/day05.zig").run(contents.day05, &writer, alloc);
    // duration += try @import("./days/day06.zig").run(contents.day06, &writer);
    // duration += try @import("./days/day07.zig").run(contents.day07, &writer, alloc);
    // duration += try @import("./days/day08.zig").run(contents.day08, &writer, alloc);
    // duration += try @import("./days/day09.zig").run(contents.day09, &writer, alloc);
    duration += try @import("./days/day10.zig").run(contents.day10, &writer, alloc);
    // duration += try @import("./days/day11.zig").run(contents.day11, &writer);
    // duration += try @import("./days/day12.zig").run(contents.day12, &writer, alloc);
    // duration += try @import("./days/day13.zig").run(contents.day13, &writer, alloc);
    // duration += try @import("./days/day14.zig").run(contents.day14, &writer, alloc);
    // duration += try @import("./days/day15.zig").run(contents.day15, &writer, alloc);
    // duration += try @import("./days/day16.zig").run(contents.day16, &writer);
    duration += try @import("./days/day17.zig").run(contents.day17, &writer);
    // duration += try @import("./days/day18.zig").run(contents.day18, &writer, alloc);
    // duration += try @import("./days/day19.zig").run(contents.day19, &writer, alloc);
    // duration += try @import("./days/day20.zig").run(contents.day20, &writer, alloc);
    // duration += try @import("./days/day21.zig").run(contents.day21, &writer);
    // duration += try @import("./days/day22.zig").run(contents.day22, &writer, alloc);
    // duration += try @import("./days/day23.zig").run(contents.day23, &writer, alloc);
    // duration += try @import("./days/day24.zig").run(contents.day24, &writer, allocator);

    try writer.print("aoc ran in:\n", .{});
    try writer.print("\t{d}s\n", .{@divFloor(duration, 1_000_000_000)});
    try writer.print("\t{d}ms\n", .{@divFloor(duration, 1_000_000)});
    try writer.print("\t{d}us\n", .{@divFloor(duration, 1_000)});

    const stdout = std.io.getStdOut();
    defer stdout.close();
    _ = try stdout.write(out.items);
}
