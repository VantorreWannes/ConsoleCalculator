const std = @import("std");
const Tokenizer = @import("tokenizer.zig");
const Parser = @import("parser.zig");

pub const Number = Parser.Number;
pub const CalculateError = Tokenizer.TokenizeError || Parser.ParseError;

pub fn calculate(allocator: std.mem.Allocator, input: []const u8) CalculateError!Number {
    var tokenizer = Tokenizer.init(input);

    const tokens = try tokenizer.tokens(allocator);
    defer allocator.free(tokens);

    var parser = Parser.init(tokens);
    return parser.parse();
}

test {
    std.testing.refAllDecls(Tokenizer);
    std.testing.refAllDecls(Parser);
}
