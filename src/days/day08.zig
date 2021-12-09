const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var entries = try loadEntries(contents, allocator);
    defer allocator.free(entries);

    var p1: usize = part1(entries);
    var p2: usize = part2(entries);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 8, p1, p2, duration);

    return duration;
}

fn part1(entries: []Entry) usize {
    var result: usize = 0;
    for (entries) |entry| {
        for (entry.outputs) |output| {
            const knownLengths = [_]usize{ 2, 3, 4, 7 };
            inline for (knownLengths) |knownLength| {
                if (output.len == knownLength) {
                    result += 1;
                    break;
                }
            }
        }
    }
    return result;
}

const patterns = [10]u7{ 0b1011111, 0b0000011, 0b1110110, 0b1110011, 0b0101011, 0b1111001, 0b1111101, 0b1000011, 0b1111111, 0b1111011 };

fn part2(entries: []Entry) usize {
    var result: usize = 0;

    for (entries) |entry| {
        var numbers: [10]?[]u8 = .{null} ** 10;
        var segments: [7]?u8 = .{null} ** 7;

        var table: [7]usize = .{0} ** 7;
        for (entry.patterns) |pattern| {
            for (pattern) |p| {
                table[p] += 1;
            }
        }

        // segments 3, 4 and 6 exist 6, 4 and 9 times in the table
        segments[3] = @truncate(u8, std.mem.indexOf(usize, &table, &[_]usize{6}) orelse unreachable);
        segments[4] = @truncate(u8, std.mem.indexOf(usize, &table, &[_]usize{4}) orelse unreachable);
        segments[6] = @truncate(u8, std.mem.indexOf(usize, &table, &[_]usize{9}) orelse unreachable);

        // we know that numbers 1, 4, 7 and 8 have patterns uniquely of lengths 2, 4, 3 and 7
        const known = [_]usize{ 1, 4, 7, 8 };
        const knownLengths = [_]usize{ 2, 4, 3, 7 };

        for (entry.patterns) |pattern| {
            inline for (known) |k, i| {
                if (pattern.len == knownLengths[i]) {
                    numbers[k] = pattern;
                    break;
                }
            }
        }

        // adjust table to only unknown counts
        for (known) |k| {
            for (numbers[k].?) |n| {
                table[n] -= 1;
            }
        }

        // set table undiscoverably high
        table[segments[3].?] = 100;
        table[segments[4].?] = 100;
        table[segments[6].?] = 100;

        // { 6, 5, 6, _, _, 4, _ }
        // { 6, 5, 6, 4, 3, 4, 5}

        segments[1] = @truncate(u8, std.mem.indexOf(usize, &table, &[_]usize{5}) orelse unreachable);
        segments[5] = @truncate(u8, std.mem.indexOf(usize, &table, &[_]usize{4}) orelse unreachable);
        // set table undiscoverably high
        table[segments[1].?] = 100;
        table[segments[5].?] = 100;

        // 0 (1) 2 3 (4) 5 6 (7) (8) 9
        // 0 (1) 2 (3) (4) (5) (6)

        // diff between seven and one is the 0 segment
        for (table) |*t|
            t.* = 0;
        for (numbers[7].?) |n|
            table[n] += 1;
        for (numbers[1].?) |n|
            table[n] -= 1;
        segments[0] = @truncate(u8, std.mem.indexOf(usize, &table, &[_]usize{1}) orelse unreachable);

        // 0 (1) 2 3 (4) 5 6 (7) (8) 9
        // (0) (1) 2 (3) (4) (5) (6)

        // only segment 2 remains, just work out which it is
        for (table) |*t|
            t.* = 0;
        for (segments) |segment| {
            if (segment) |s| {
                table[s] += 1;
            }
        }
        segments[2] = @truncate(u8, std.mem.indexOf(usize, &table, &[_]usize{0}) orelse unreachable);

        // all segments are now know, calculate 0, 2, 3, 5, 6 and 9.
        numbers[0] = calculateNumber(6, segments, [_]usize{ 0, 2, 3, 4, 5, 6 }, entry.patterns);
        numbers[2] = calculateNumber(5, segments, [_]usize{ 0, 1, 2, 4, 5 }, entry.patterns);
        numbers[3] = calculateNumber(5, segments, [_]usize{ 0, 1, 2, 5, 6 }, entry.patterns);
        numbers[5] = calculateNumber(5, segments, [_]usize{ 0, 1, 2, 3, 6 }, entry.patterns);
        numbers[6] = calculateNumber(6, segments, [_]usize{ 0, 1, 2, 3, 4, 6 }, entry.patterns);
        numbers[9] = calculateNumber(6, segments, [_]usize{ 0, 1, 2, 3, 5, 6 }, entry.patterns);

        // use this to calculate based on the outputs
        var number: usize = 0;
        for (entry.outputs) |output| {
            number *= 10;
            for (numbers) |n, ind| {
                if (std.mem.eql(u8, n.?, output)) {
                    number += ind;
                    break;
                }
            }
        }
        result += number;
    }

    return result;
}

fn calculateNumber(comptime expectedSize: usize, segments: [7]?u8, expectedSegments: [expectedSize]usize, entryPatterns: [10][]u8) []u8 {
    var buf: [expectedSize]u8 = .{0} ** expectedSize;
    for (expectedSegments) |exp, i| {
        buf[i] = segments[exp].?;
    }

    std.sort.sort(u8, &buf, {}, comptime std.sort.asc(u8));

    for (entryPatterns) |pattern| {
        if (std.mem.eql(u8, pattern, &buf)) {
            return pattern;
        }
    }

    unreachable;
}

const Entry = struct {
    patterns: [10][]u8,
    outputs: [4][]u8,
};

fn loadEntries(contents: []u8, allocator: *std.mem.Allocator) ![]Entry {
    var entries = std.ArrayList(Entry).init(allocator);
    errdefer entries.deinit();

    var ind: usize = 0;
    while (ind < contents.len) {
        var entry = Entry{ .patterns = undefined, .outputs = undefined };
        for (entry.patterns) |*pattern| {
            var pat = getString(contents[ind..]);
            for (pat) |*p|
                p.* -= 'a';
            std.sort.sort(u8, pat, {}, comptime std.sort.asc(u8));
            pattern.* = pat;
            ind += 1 + pattern.*.len;
        }
        ind += 2;
        for (entry.outputs) |*output| {
            var out = getString(contents[ind..]);
            for (out) |*o|
                o.* -= 'a';
            std.sort.sort(u8, out, {}, comptime std.sort.asc(u8));
            output.* = out;
            ind += 1 + output.*.len;
        }
        try entries.append(entry);
    }

    return entries.toOwnedSlice();
}

fn getString(contents: []u8) []u8 {
    var length: usize = 0;
    while ('a' <= contents[length] and contents[length] <= 'g')
        length += 1;

    return contents[0..length];
}
