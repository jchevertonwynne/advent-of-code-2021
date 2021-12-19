const builtin = @import("builtin");
const std = @import("std");

const day01 = @import("./days/day01.zig");
const day02 = @import("./days/day02.zig");
const day03 = @import("./days/day03.zig");
const day04 = @import("./days/day04.zig");
const day05 = @import("./days/day05.zig");
const day06 = @import("./days/day06.zig");
const day07 = @import("./days/day07.zig");
const day08 = @import("./days/day08.zig");
const day09 = @import("./days/day09.zig");
const day10 = @import("./days/day10.zig");
const day11 = @import("./days/day11.zig");
const day12 = @import("./days/day12.zig");
const day13 = @import("./days/day13.zig");
const day14 = @import("./days/day14.zig");
const day15 = @import("./days/day15.zig");
const day16 = @import("./days/day16.zig");
const day17 = @import("./days/day17.zig");
const day18 = @import("./days/day18.zig");
const day19 = @import("./days/day19.zig");
const util = @import("util.zig");

const Contents = util.Contents;

pub fn main() !void {
    var arenaAlloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arenaAlloc.deinit();
    var genAllocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!genAllocator.deinit());

    var allocator = if (builtin.mode == .Debug)
        &genAllocator.allocator
    else
        &arenaAlloc.allocator;

    var contents = try Contents.load(allocator);
    defer contents.discard();

    var out = try std.ArrayList(u8).initCapacity(allocator, 8192);
    defer out.deinit();
    var writer = out.writer();

    var duration: i128 = 0;

    // duration += try day01.run(contents.day01, &writer);
    // duration += try day02.run(contents.day02, &writer);
    // duration += try day03.run(contents.day03, &writer, allocator);
    // duration += try day04.run(contents.day04, &writer, allocator);
    // duration += try day05.run(contents.day05, &writer, allocator);
    // duration += try day06.run(contents.day06, &writer);
    // duration += try day07.run(contents.day07, &writer, allocator);
    // duration += try day08.run(contents.day08, &writer, allocator);
    // duration += try day09.run(contents.day09, &writer);
    // duration += try day10.run(contents.day10, &writer);
    // duration += try day11.run(contents.day11, &writer);
    // duration += try day12.run(contents.day12, &writer, allocator);
    // duration += try day13.run(contents.day13, &writer, allocator);
    // duration += try day14.run(contents.day14, &writer, allocator);
    // duration += try day15.run(contents.day15, &writer, allocator);
    // duration += try day16.run(contents.day16, &writer, allocator);
    // duration += try day17.run(contents.day17, &writer);
    // duration += try day18.run(contents.day18, &writer, allocator);
    duration += try day19.run(contents.day19, &writer, allocator);

    try writer.print("aoc ran in:\n", .{});
    try writer.print("\t{d}ms\n", .{@divFloor(duration, 1_000_000)});
    try writer.print("\t{d}us\n", .{@divFloor(duration, 1_000)});

    const stdout = std.io.getStdOut();
    defer stdout.close();
    _ = try stdout.write(out.items);
}
