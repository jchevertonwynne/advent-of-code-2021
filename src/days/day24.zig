const std = @import("std");

const util = @import("../util.zig");

const contents = @embedFile("../../files/24.txt");

pub fn run(_contents: []u8, out: anytype, allocator: std.mem.Allocator) !i128 {
    _ = _contents;
    _ = allocator;

    var start = std.time.nanoTimestamp();

    const instructions = comptime loadInstructions();

    for (instructions) |i|
        std.debug.print("{}\n", .{i});

    var p1: isize = part1(instructions);
    var p2: usize = 0;

    std.debug.print("{}\n", .{try runMachine(11111111111111, instructions)});

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 1, p1, p2, duration);

    return duration;
}

fn part1(comptime instructions: [252]Instruction) isize {
    var threads: [10]std.Thread = undefined;
    var range: isize = 100_000_000_000_000;
    var step: isize  = 100_000_000;
    var res: isize = 0;
    var mutex = std.Thread.Mutex.AtomicMutex{};
    while (res == 0) : (range -= step * 10) {
        var offset: isize = 0;
        for (threads) |*t| {
            t.* = std.Thread.spawn(.{}, runRange, .{range - offset - step, range - offset, instructions, &mutex, &res}) catch unreachable;
            offset += step;
        }
        for (threads) |*t| {
            t.join();
        }
    }
    return res;
}

fn runRange(start: isize, end: isize, comptime instructions: [252]Instruction, found: *std.Thread.Mutex.AtomicMutex, val: *isize) void {
    std.debug.print("{} {}\n", .{start, std.time.milliTimestamp()});
    defer std.debug.print("{} {}\n", .{start, std.time.milliTimestamp()});
    var i = start;
    while (i < end) : (i += 1) {
        var res = runMachine(i, instructions) catch false;
        if (res) {
            found.lock();
            if (val.* < i)
                val.* = i;
            found.unlock();
        }
    }
}

fn runMachine(number: isize, comptime instructions: [252]Instruction) !bool {
    var stack = try std.BoundedArray(isize, 14).init(0);
    var _n = number;
    while (_n > 0) {
        var unit = @mod(_n, 10);
        if (unit == 0)
            return false;

        try stack.append(unit);
        _n = @divFloor(_n, 10);
    }
    if (stack.slice().len != 14)
        return false;

    var state = [4]isize { 0, 0, 0, 0};
    
    for (instructions) |instruction, i| {
        switch (instruction) {
            .input => |register| {
                state[register] = stack.pop();
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
        std.debug.print("{} {d}\n", .{i, state});
    }

    return state['z' - 'w'] == 0;
}

fn loadInstructions() [252]Instruction {
    @setEvalBranchQuota(1000000);
    var instructions: [252]Instruction = undefined;

    var ind: usize = 0;
    var instructionIndex: usize = 0;
    while (instructionIndex < 252) : (instructionIndex += 1) {
        const instruction = contents[ind .. ind + 3];
        if (std.mem.eql(u8, instruction, "inp")) {
            instructions[instructionIndex] = Instruction{ .input = contents[ind + 4] - 'w' };
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
            instructions[instructionIndex] = newInstruction;
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
            instructions[instructionIndex] = newInstruction;
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
            instructions[instructionIndex] = newInstruction;
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
            instructions[instructionIndex] = newInstruction;
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
            instructions[instructionIndex] = newInstruction;
        } else {
            @compileError("could not find a valid instruction");
            // @compileError("please provide a valid file");
        }
    }

    return instructions;
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
