const builtin = @import("builtin");
const std = @import("std");

const day01 = @import("./days/day01.zig");
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

    // run days here
    duration += try day01.run(contents.day01, &writer, allocator);

    try writer.print("aoc ran in:\n", .{});
    try writer.print("\t{d}ms\n", .{@divFloor(duration, 1_000_000)});
    try writer.print("\t{d}us\n", .{@divFloor(duration, 1_000)});

    const stdout = std.io.getStdOut();
    defer stdout.close();
    _ = try stdout.write(out.items);
}
