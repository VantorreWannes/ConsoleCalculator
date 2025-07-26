//! This file acts as the main interface for the calculator library.
//! It combines the tokenizer and parser to provide a simple `calculate`
//! function that takes a string expression and returns the result.

const std = @import("std");
const Tokenizer = @import("tokenizer.zig");
const Parser = @import("parser.zig");

/// The complex number type used for calculations.
pub const Number = Parser.Number;

/// Represents errors that can occur during calculation,
/// combining tokenizer and parser errors.
pub const CalculateError = Tokenizer.TokenizeError || Parser.ParseError;

/// Calculates the result of a mathematical expression.
///
/// # Parameters
/// - `allocator`: The memory allocator to use for intermediate allocations.
/// - `input`: The string containing the mathematical expression to evaluate.
///
/// # Returns
/// The calculated result as a complex number, or an error if the
/// expression is invalid.
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
        const expression = "3*(4+5^2)/-4";
        const result = try calculate(allocator, expression);
        const expected = Number.init(-21, 0);
        try std.testing.expectApproxEqRel(expected.re, result.re, 0.1);
    }

    {
        const expression = "1+abs(-4)";
        const result = try calculate(allocator, expression);
        const expected = Number.init(5, 0);
        try std.testing.expectEqual(expected, result);
    }
}

test {
    std.testing.refAllDecls(Tokenizer);
    std.testing.refAllDecls(Parser);
}
