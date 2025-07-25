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

test calculate {
    const allocator = std.testing.allocator;
    {
        const input = "2 + 3 * 2";
        const result = try calculate(allocator, input);
        const expected = Number.init(8, 0);
        try std.testing.expectEqual(expected, result);
    }
    {
        const input = "3*(7-2*(16)-5*-7)-3+2*4";
        const result = try calculate(allocator, input);
        const expected = Number.init(35, 0);
        try std.testing.expectEqual(expected, result);
    }
    {
        const input = "3*(2+3";
        const result = calculate(allocator, input);
        const expected = CalculateError.MissingTokens;
        try std.testing.expectError(expected, result);
    }
    {
        const input = "+1++1";
        const result = calculate(allocator, input);
        const expected = CalculateError.InvalidToken;
        try std.testing.expectError(expected, result);
    }
}

test {
    std.testing.refAllDecls(Tokenizer);
    std.testing.refAllDecls(Parser);
}
