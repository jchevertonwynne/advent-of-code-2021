const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype) !i128 {
    var start = std.time.nanoTimestamp();

    var game = Game.parse(contents);

    var p1: usize = game.play(&DeterministicDice.new());
    var p2: usize = game.playParallel(0).most();

    var duration = std.time.nanoTimestamp() - start;

    try util.writeResponse(out, 21, p1, p2, duration);

    return duration;
}

const Player = struct { score: usize, position: usize };

const Game = struct {
    players: [2]Player,

    fn parse(contents: []u8) Game {
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
                while (r < 3) : (r += 1) {
                    player.position += dice.roll();
                }
                player.position %= 10;
                player.score += player.position + 1;
                if (player.score >= 1000)
                    return dice.rolls * self.players[1 - i].score;
            }
        }
    }

    fn playParallel(_self: @This(), comptime i: usize) Wins {
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
            var player = &self.players[i];
            player.position += combination.rollSum;
            player.position %= 10;
            player.score += player.position + 1;
            if (player.score >= 21) {
                var won = (Wins{ .player1 = 1 - i, .player2 = i }).mult(combination.count);
                wins = wins.add(won);
            } else {
                var subgame = self.playParallel((i + 1) % 2).mult(combination.count);
                wins = wins.add(subgame);
            }
        }

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
        return if (wins.player1 > wins.player2)
            wins.player1
        else
            wins.player2;
    }

    fn player1() Wins {
        return Wins{ .player1 = 1, .player2 = 0 };
    }

    fn player2() Wins {
        return Wins{ .player1 = 0, .player2 = 1 };
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
