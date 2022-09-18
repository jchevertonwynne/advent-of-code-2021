const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []const u8, out: anytype) !i128 {
    var start = std.time.nanoTimestamp();

    var game = Game.parse(contents);

    var dice = DeterministicDice.new();
    var p1: usize = game.play(&dice);
    var memo = nulled([10][10][21][21]?Wins);
    var p2: usize = game.playParallel(0, &memo).most();
    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 21, p1, p2, duration);

    return duration;
}

const Player = struct { score: usize, position: usize };

const Game = struct {
    players: [2]Player,

    fn parse(contents: []const u8) Game {
        var game = Game{ .players = [2]Player{ Player{ .score = 0, .position = undefined }, Player{ .score = 0, .position = undefined } } };

        game.players[0].position = contents[28] - '1';
        game.players[1].position = contents[58] - '1';

        return game;
    }

    fn play(_self: @This(), dice: *DeterministicDice) usize {
        var self = _self;
        while (true) {
            for (self.players) |*player, i| {
                var r: usize = 0;
                while (r < 3) : (r += 1)
                    player.position += dice.roll();
                player.position %= 10;
                player.score += player.position + 1;
                if (player.score >= 1000)
                    return dice.rolls * self.players[1 - i].score;
            }
        }
    }

    fn playParallel(_self: @This(), comptime playerIndex: usize, cache: *[10][10][21][21]?Wins) Wins {
        var orderedPlayers = _self.players;
        if (playerIndex == 1)
            std.mem.swap(Player, &orderedPlayers[0], &orderedPlayers[1]);

        if (cache[orderedPlayers[0].position][orderedPlayers[1].position][orderedPlayers[0].score][orderedPlayers[1].score]) |_cacheResult| {
            var cacheResult = _cacheResult;
            if (playerIndex == 1)
                std.mem.swap(usize, &cacheResult.player1, &cacheResult.player2);
            return cacheResult;
        }

        var wins = Wins{ .player1 = 0, .player2 = 0 };

        const rollsCombination = [_]struct { rollSum: usize, count: usize }{
            .{ .rollSum = 3, .count = 1 },
            .{ .rollSum = 4, .count = 3 },
            .{ .rollSum = 5, .count = 6 },
            .{ .rollSum = 6, .count = 7 },
            .{ .rollSum = 7, .count = 6 },
            .{ .rollSum = 8, .count = 3 },
            .{ .rollSum = 9, .count = 1 },
        };

        inline for (rollsCombination) |combination| {
            var self = _self;
            var player = &self.players[playerIndex];
            player.position += combination.rollSum;
            player.position %= 10;
            player.score += player.position + 1;
            if (player.score >= 21) {
                var won = (Wins{ .player1 = 1 - playerIndex, .player2 = playerIndex }).mult(combination.count);
                wins = wins.add(won);
            } else {
                var subgame = self.playParallel((playerIndex + 1) % 2, cache).mult(combination.count);
                wins = wins.add(subgame);
            }
        }

        var orderedWins = wins;
        if (playerIndex == 1)
            std.mem.swap(usize, &orderedWins.player1, &orderedWins.player2);

        cache[orderedPlayers[0].position][orderedPlayers[1].position][orderedPlayers[0].score][orderedPlayers[1].score] = orderedWins;

        return wins;
    }
};

const Wins = struct {
    player1: usize,
    player2: usize,

    fn mult(wins: Wins, multiplier: usize) Wins {
        var p1 = wins.player1 * multiplier;
        var p2 = wins.player2 * multiplier;
        return Wins{ .player1 = p1, .player2 = p2 };
    }

    fn add(a: Wins, b: Wins) Wins {
        var p1 = a.player1 + b.player1;
        var p2 = a.player2 + b.player2;
        return Wins{ .player1 = p1, .player2 = p2 };
    }

    fn most(wins: Wins) usize {
        return std.math.max(wins.player1, wins.player2);
    }
};

const DeterministicDice = struct {
    value: usize,
    rolls: usize,

    fn roll(self: *@This()) usize {
        self.value %= 100;
        self.value += 1;
        self.rolls += 1;
        return self.value;
    }

    fn new() DeterministicDice {
        return .{ .value = 0, .rolls = 0 };
    }
};

fn nulled(comptime array: type) array {
    const arrayTypeInfo = @typeInfo(array);
    const arrayInfo = switch (arrayTypeInfo) {
        .Array => |arr| arr,
        else => @compileError("passed type must be an array"),
    };
    const childInfo = @typeInfo(arrayInfo.child);

    var res: array = undefined;
    for (res) |*item| {
        switch (childInfo) {
            .Array => item.* = nulled(arrayInfo.child),
            .Optional => item.* = null,
            else => @compileError("nested types must be optional or array"),
        }
    }

    return res;
}
