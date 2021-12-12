const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var caves = try loadCaves(contents, allocator);
    defer {
        var it = caves.valueIterator();
        while (it.next()) |v|
            v.deinit();
        caves.deinit();
    }

    var p1: usize = try part1(caves, allocator);
    var p2: usize = try part2(caves, allocator);

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 12, p1, p2, duration);

    return duration;
}

fn isSmallCave(cave: []u8) bool {
    return !isLargeCave(cave);
}

fn isLargeCave(cave: []u8) bool {
    for (cave) |c| {
        if (c < 'A' or c > 'Z')
            return false;
    }

    return true;
}

const SearchState = struct {
    current: []const u8,
    history: std.ArrayList([]const u8),
};

const HistoryContext = struct {
    pub fn hash(_: @This(), val: [][]const u8) u64 {
        var res = std.hash.Wyhash.init(0);
        for (val) |v| {
            res.update(v);
        }
        return res.final();
    }

    pub fn eql(_: @This(), a: [][]const u8, b: [][]const u8) bool {
        if (a.len != b.len)
            return false;
        if (a.ptr == b.ptr)
            return true;
        for (a) |val, i| {
            if (!std.mem.eql(u8, val, b[i]))
                return false;
        }
        return true;
    }
};

fn part1(caves: std.StringHashMap(std.ArrayList([]u8)), allocator: *std.mem.Allocator) !usize {
    var solutions = std.HashMap([][]const u8, void, HistoryContext, 80).init(allocator);
    defer {
        var it = solutions.keyIterator();
        while (it.next()) |v|
            allocator.free(v.*);
        solutions.deinit();
    }

    var stack = std.ArrayList(SearchState).init(allocator);
    defer {
        for (stack.items) |i|
            i.history.deinit();
        stack.deinit();
    }
    var start = "start";
    try stack.append(SearchState{ .current = start, .history = std.ArrayList([]const u8).init(allocator) });
    while (stack.popOrNull()) |_state| {
        var state = _state;
        defer state.history.deinit();

        var connected = caves.get(state.current) orelse unreachable;
        for (connected.items) |option| {
            if (std.mem.eql(u8, "end", option)) {
                var solutionHistory = try allocator.alloc([]const u8, state.history.items.len + 2);
                errdefer allocator.free(solutionHistory);
                std.mem.copy([]const u8, solutionHistory, state.history.items);
                solutionHistory[solutionHistory.len - 2] = state.current;
                solutionHistory[solutionHistory.len - 1] = option;
                try solutions.put(solutionHistory, .{});
                continue;
            }

            var small = isSmallCave(option);
            var legal = if (small) block: {
                for (state.history.items) |h| {
                    if (std.mem.eql(u8, h, option))
                        break :block false;
                }

                break :block true;
            } else true;

            if (legal) {
                var newState = SearchState{ .current = option, .history = std.ArrayList([]const u8).init(allocator) };
                errdefer newState.history.deinit();
                try newState.history.appendSlice(state.history.items);
                try newState.history.append(state.current);
                try stack.append(newState);
            }
        }
    }

    return solutions.count();
}


const SearchState2 = struct {
    current: []const u8,
    history: std.ArrayList([]const u8),
    seenBefore: ?[]const u8
};

fn part2(caves: std.StringHashMap(std.ArrayList([]u8)), allocator: *std.mem.Allocator) !usize {
    var solutions = std.HashMap([][]const u8, void, HistoryContext, 80).init(allocator);
    defer {
        var it = solutions.keyIterator();
        while (it.next()) |v|
            allocator.free(v.*);
        solutions.deinit();
    }

    var stack = std.ArrayList(SearchState2).init(allocator);
    defer {
        for (stack.items) |i|
            i.history.deinit();
        stack.deinit();
    }
    var start = "start";
    try stack.append(SearchState2{ .current = start, .history = std.ArrayList([]const u8).init(allocator), .seenBefore = null });
    while (stack.popOrNull()) |_state| {
        var state = _state;
        defer state.history.deinit();

        var connected = caves.get(state.current) orelse unreachable;
        for (connected.items) |option| {
            if (std.mem.eql(u8, "start", option))
                continue;

            var seenBefore = state.seenBefore;

            if (std.mem.eql(u8, "end", option)) {
                var solutionHistory = try allocator.alloc([]const u8, state.history.items.len + 2);
                errdefer allocator.free(solutionHistory);
                std.mem.copy([]const u8, solutionHistory, state.history.items);
                solutionHistory[solutionHistory.len - 2] = state.current;
                solutionHistory[solutionHistory.len - 1] = option;
                try solutions.put(solutionHistory, .{});
                continue;
            }
            
            var legal = if (isSmallCave(option)) block: {
                for (state.history.items) |h| {
                    if (std.mem.eql(u8, h, option)) {
                        if (state.seenBefore != null)  {
                            break :block false;
                        } else {
                            seenBefore = h;
                        }
                    }
                }

                break :block true;
            } else true;

            if (legal) {
                var newState = SearchState2{ .current = option, .history = std.ArrayList([]const u8).init(allocator), .seenBefore = seenBefore };
                errdefer newState.history.deinit();
                try newState.history.appendSlice(state.history.items);
                try newState.history.append(state.current);
                try stack.append(newState);
            }
        }
    }

    return solutions.count();
}

fn loadCaves(contents: []u8, allocator: *std.mem.Allocator) !std.StringHashMap(std.ArrayList([]u8)) {
    var result = std.StringHashMap(std.ArrayList([]u8)).init(allocator);
    errdefer {
        var it = result.valueIterator();
        while (it.next()) |v|
            v.*.deinit();
        result.deinit();
    }

    var ind: usize = 0;
    while (ind < contents.len) {
        var hyphen = std.mem.indexOf(u8, contents[ind..], "-") orelse unreachable;
        var newline = std.mem.indexOf(u8, contents[ind..], "\n") orelse unreachable;

        var a = contents[ind .. ind + hyphen];
        var b = contents[ind + hyphen + 1 .. ind + newline];

        var aEntry = try result.getOrPut(a);
        if (!aEntry.found_existing)
            aEntry.value_ptr.* = std.ArrayList([]u8).init(allocator);
        try aEntry.value_ptr.*.append(b);

        var bEntry = try result.getOrPut(b);
        if (!bEntry.found_existing)
            bEntry.value_ptr.* = std.ArrayList([]u8).init(allocator);
        try bEntry.value_ptr.*.append(a);

        ind += newline + 1;
    }

    return result;
}
