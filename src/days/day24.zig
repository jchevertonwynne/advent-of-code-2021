const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: std.mem.Allocator) !i128 {
    var start = std.time.nanoTimestamp();

    var instructions = try loadInstructions(contents, allocator);
    defer allocator.free(instructions);

    var results = try solve(instructions, allocator);
    var p1: isize = results.max;
    var p2: isize = results.min;

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 1, p1, p2, duration);

    return duration;
}

const Results = struct { min: isize, max: isize };

fn solve(instructions: []Instruction, allocator: std.mem.Allocator) !Results {
    var parts: [14][]Instruction = undefined;
    var i: usize = 0;
    while (i < 14) : (i += 1) {
        parts[i] = instructions[18 * i .. 18 * (i + 1)];
    }

    var cache: [14]std.AutoHashMap([2]isize, [2]isize) = undefined;
    for (cache) |*c| {
        c.* = std.AutoHashMap([2]isize, [2]isize).init(allocator);
    }
    defer {
        for (cache) |*c| {
            c.deinit();
        }
    }

    var result = try runPart(0, parts, [4]isize{ 0, 0, 0, 0 }, &cache);
    var min: isize = 0;
    var max: isize = 0;
    for (result.max.?) |m| {
        min <<= 1;
        min += m;
    }
    for (result.min.?) |m| {
        max <<= 1;
        max += m;
    }
    return Results{ .min = min, .max = max };
}

fn runPart(comptime index: usize, instructions: [14][]Instruction, initialState: [4]isize, cache: *[14]std.AutoHashMap([2]isize, [2]isize)) anyerror!PartResult(14 - index) {
    var result: PartResult(14 - index) = .{ .min = null, .max = null };

    var i: isize = 1;
    while (i <= 9) : (i += 1) {
        if (index < 6) {
            var depth: usize = 0;
            while (depth < index) : (depth += 1)
                std.debug.print("  ", .{});
            std.debug.print("{}\n", .{i});
        }

        var state = initialState;
        state[0] = i;

        var initStateMin = .{ state[0], state[3] };
        var entry = try cache.*[index].getOrPut(initStateMin);
        if (entry.found_existing) {
            state[0] = entry.value_ptr[0];
            state[3] = entry.value_ptr[1];
        }
        else {
            state = runMachine(instructions[index][1..], state);
            entry.value_ptr.* = .{ state[0], state[3] };
        }

        if (index == 13) {
            if (state[3] == 0) {
                if (result.min == null)
                    result.min = [1]isize{i};
                result.max = [1]isize{i};
            }
        } else {
            var subResult = try runPart(index + 1, instructions, state, cache);
            if (subResult.min) |minSubResult| {
                var x: [14 - index]isize = undefined;
                x[0] = i;
                std.mem.copy(isize, x[1..], &minSubResult);
                if (result.min == null)
                    result.min = x;
                result.max = x;
            }
            if (subResult.max) |maxSubResult| {
                var x: [14 - index]isize = undefined;
                x[0] = i;
                std.mem.copy(isize, x[1..], &maxSubResult);
                if (result.min == null)
                    result.min = x;
                result.max = x;
            }
        }
    }

    return result;
}

fn PartResult(comptime size: usize) type {
    return struct {
        max: ?[size]isize,
        min: ?[size]isize,
    };
}

fn runMachine(instructions: []Instruction, _state: [4]isize) [4]isize {
    var state = _state;

    for (instructions) |instruction| {
        switch (instruction) {
            .input => {
                @panic("please never send me for real lol");
            },
            .add => |params| {
                state[params.register] += switch (params.value) {
                    .literal => |val| val,
                    .register => |register| state[register],
                };
            },
            .mul => |params| {
                state[params.register] *= switch (params.value) {
                    .literal => |val| val,
                    .register => |register| state[register],
                };
            },
            .div => |params| {
                state[params.register] = @divTrunc(state[params.register], switch (params.value) {
                    .literal => |val| val,
                    .register => |register| state[register],
                });
            },
            .mod => |params| {
                state[params.register] = @mod(state[params.register], switch (params.value) {
                    .literal => |val| val,
                    .register => |register| state[register],
                });
            },
            .eql => |params| {
                state[params.register] = if (state[params.register] == switch (params.value) {
                    .literal => |val| val,
                    .register => |register| state[register],
                }) 1 else 0;
            },
        }
    }

    return state;
}

fn loadInstructions(contents: []u8, allocator: std.mem.Allocator) ![]Instruction {
    var instructions = std.ArrayList(Instruction).init(allocator);
    errdefer instructions.deinit();

    var ind: usize = 0;
    while (ind < contents.len) {
        const instruction = contents[ind .. ind + 3];
        if (std.mem.eql(u8, instruction, "inp")) {
            try instructions.append(Instruction{ .input = contents[ind + 4] - 'w' });
            ind += 6;
        } else if (std.mem.eql(u8, instruction, "add")) {
            var newInstruction = Instruction{ .add = Params{ .register = contents[ind + 4] - 'w', .value = undefined } };
            if ('w' <= contents[ind + 6] and contents[ind + 6] <= 'z') {
                newInstruction.add.value = Value{ .register = contents[ind + 6] - 'w' };
                ind += 8;
            } else {
                var size: usize = undefined;
                var val: isize = undefined;
                util.toSignedInt(isize, contents[ind + 6 ..], &val, &size);
                newInstruction.add.value = Value{ .literal = val };
                ind += 6 + size + 1;
            }
            try instructions.append(newInstruction);
        } else if (std.mem.eql(u8, instruction, "mul")) {
            var newInstruction = Instruction{ .mul = Params{ .register = contents[ind + 4] - 'w', .value = undefined } };
            if ('w' <= contents[ind + 6] and contents[ind + 6] <= 'z') {
                newInstruction.mul.value = Value{ .register = contents[ind + 6] - 'w' };
                ind += 8;
            } else {
                var size: usize = undefined;
                var val: isize = undefined;
                util.toSignedInt(isize, contents[ind + 6 ..], &val, &size);
                newInstruction.mul.value = Value{ .literal = val };
                ind += 6 + size + 1;
            }
            try instructions.append(newInstruction);
        } else if (std.mem.eql(u8, instruction, "div")) {
            var newInstruction = Instruction{ .div = Params{ .register = contents[ind + 4] - 'w', .value = undefined } };
            if ('w' <= contents[ind + 6] and contents[ind + 6] <= 'z') {
                newInstruction.div.value = Value{ .register = contents[ind + 6] - 'w' };
                ind += 8;
            } else {
                var size: usize = undefined;
                var val: isize = undefined;
                util.toSignedInt(isize, contents[ind + 6 ..], &val, &size);
                newInstruction.div.value = Value{ .literal = val };
                ind += 6 + size + 1;
            }
            try instructions.append(newInstruction);
        } else if (std.mem.eql(u8, instruction, "mod")) {
            var newInstruction = Instruction{ .mod = Params{ .register = contents[ind + 4] - 'w', .value = undefined } };
            if ('w' <= contents[ind + 6] and contents[ind + 6] <= 'z') {
                newInstruction.mod.value = Value{ .register = contents[ind + 6] - 'w' };
                ind += 8;
            } else {
                var size: usize = undefined;
                var val: isize = undefined;
                util.toSignedInt(isize, contents[ind + 6 ..], &val, &size);
                newInstruction.mod.value = Value{ .literal = val };
                ind += 6 + size + 1;
            }
            try instructions.append(newInstruction);
        } else if (std.mem.eql(u8, instruction, "eql")) {
            var newInstruction = Instruction{ .eql = Params{ .register = contents[ind + 4] - 'w', .value = undefined } };
            if ('w' <= contents[ind + 6] and contents[ind + 6] <= 'z') {
                newInstruction.eql.value = Value{ .register = contents[ind + 6] - 'w' };
                ind += 8;
            } else {
                var size: usize = undefined;
                var val: isize = undefined;
                util.toSignedInt(isize, contents[ind + 6 ..], &val, &size);
                newInstruction.eql.value = Value{ .literal = val };
                ind += 6 + size + 1;
            }
            try instructions.append(newInstruction);
        } else {
            unreachable;
        }
    }

    return instructions.toOwnedSlice();
}

const Instruction = union(enum) {
    input: u8,
    add: Params,
    mul: Params,
    div: Params,
    mod: Params,
    eql: Params,
};

const Params = struct {
    register: u8,
    value: Value,
};

const Value = union(enum) {
    literal: isize,
    register: u8,
};
