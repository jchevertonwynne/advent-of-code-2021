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
    var knownRefTable: [7]usize = .{ 0 } ** 7;

    const knownStart = [_]usize{ 1, 4, 7, 8 };
    inline for (knownStart) |k| {
        var p = patterns[k];
        while (@popCount(u7, p) != 0) {
            knownRefTable[@ctz(u7, p)] += 1;
            p &= ~(@as(u7, 1) << @ctz(u7, p));
        }
    }

    var refTable: [7]usize = .{ 0 } ** 7;
    for (patterns) |pattern| {
        var p = pattern;
        while (@popCount(u7, p) != 0) {
            refTable[@ctz(u7, p)] += 1;
            p &= ~(@as(u7, 1) << @ctz(u7, p));
        }
    }

    var segmentCount: [8]usize = .{ 0 } ** 8;
    for (patterns) |p|
        segmentCount[@popCount(u7, p)] += 1;

    var diffs: [7]usize = undefined;
    for (diffs) |*d, i|
        d.* = refTable[i] - knownRefTable[i];

    std.io.getStdOut().writer().print("known = {d}\n", .{knownRefTable}) catch unreachable;
    std.io.getStdOut().writer().print("all = {d}\n", .{refTable}) catch unreachable;
    std.io.getStdOut().writer().print("diffs = {d}\n", .{diffs}) catch unreachable;
    std.io.getStdOut().writer().print("segment counts = {d}\n", .{segmentCount}) catch unreachable;

    var result: usize = 0;
    for (entries) |entry| {
        var numbers: [10]?[]u8 = .{ null } ** 10;
        var segments: [7]?u8 = .{ null } ** 7;

        var table: [7]usize = .{ 0 } ** 7;
        for (entry.patterns) |pattern| {
            for (pattern) |p| {
                table[p] += 1;
            }
        }

        std.io.getStdOut().writer().print("{d}\n", .{table}) catch unreachable;

        const known = [_]usize{ 1, 4, 7, 8 };
        const knownLengths = [_]usize{2, 4, 3, 7};

        for (known) |k, i| {
            for (entry.patterns) |pattern| {
                if (pattern.len == knownLengths[i]) {
                    numbers[k] = pattern;
                    break;
                }
            }
        }

        // segments 0, 2 and 3 exist 9, 4 and 6 times in the table
        segments[0] = @truncate(u8, std.mem.indexOf(usize, &table, &[_]usize{9}) orelse unreachable);
        segments[2] = @truncate(u8, std.mem.indexOf(usize, &table, &[_]usize{4}) orelse unreachable);
        segments[3] = @truncate(u8, std.mem.indexOf(usize, &table, &[_]usize{6}) orelse unreachable);

        // adjust table to only unknown counts
        for (known) |k| {
            for (numbers[k].?) |n| {
                table[n] -= 1;
            }
        }

        // { _, 4, _, _, 6, 5, 6 }

        table[segments[0].?] = 100;
        table[segments[2].?] = 100;
        table[segments[3].?] = 100;

        std.io.getStdOut().writer().print("{d}\n", .{table}) catch unreachable;

        segments[1] = @truncate(u8, std.mem.indexOf(usize, &table, &[_]usize{4}) orelse unreachable);
        segments[5] = @truncate(u8, std.mem.indexOf(usize, &table, &[_]usize{5}) orelse unreachable);

        // (0) 1 (2) (3) 4 (5) (6) 7 8 (9)
        // 0 1 2 3 (4) 5 (6) 

        std.io.getStdOut().writer().print("{d}\n", .{segments}) catch unreachable;

        // 0 6 9 have 6 segments, since we have seg 1 we can work out which is 0 and which are 6 or 9
        for (entry.patterns) |pattern| {
            if (pattern.len != 6)
                continue;
            var unknowns: usize = 0;
            for (pattern) |p| {
                if (segments[p] == null)
                    unknowns += 1;
            }
            if (unknowns == 2) {
                numbers[0] = pattern;
                std.io.getStdOut().writer().print("found number 0 repr: {d}\n", .{pattern}) catch unreachable;
            }
        }

        std.io.getStdOut().writer().print("when found zero repr: {d}\n", .{numbers}) catch unreachable;

        std.io.getStdOut().writer().print("before setting seg 4 repr: {d}\n", .{segments}) catch unreachable;

        // remove from in work table and set left bottom segment
        for (numbers[0].?) |n| {
            if (segments[n] == null) { // not found at any index, not the index itself
                
                segments[4] = n;
                std.io.getStdOut().writer().print("found segment 4 repr: {d}\n", .{segments}) catch unreachable;
            }
                
            table[n] -= 1;
        }

        // 0 1 (2) (3) 4 5 (6) 7 8
        // 0 1 2 3 4 5 (6) 
        var set: [7]bool = .{ false } ** 7; 
        for (segments) |s, i| {
            if (s != null) {
                set[i] = true;
            }
        }
        var notSet = std.mem.indexOf(bool, &set, &[_]bool{false}) orelse @panic("everthing is set lmao");
        segments[6] = @truncate(u8, notSet);

        std.io.getStdOut().writer().print("found all segments: {d}\n", .{segments}) catch unreachable;

        // all segments are now know, calculate 2, 3 and 6

        numbers[2] = calculateNumber(5, segments, [5]usize{0, 1, 2, 3, 6}, entry.patterns);
        numbers[3] = calculateNumber(5, segments, [5]usize{0, 1, 2, 5, 6}, entry.patterns);
        numbers[6] = calculateNumber(6, segments, [6]usize{0, 1, 1, 3, 4, 6}, entry.patterns);

        // use this to calculate based on the outputs

        var number: usize = 0;
        for (entry.outputs) |output| {
            number <<= 1;
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
    var buf: [expectedSize]u8 = .{ 0 } ** expectedSize;
    for (expectedSegments) |exp, i| {
        buf[i] = segments[exp].?;
    }

    std.sort.sort(u8, &buf, {}, comptime std.sort.asc(u8));

    std.io.getStdOut().writer().print("looking for entry {d}\n", .{buf}) catch unreachable;
    
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
