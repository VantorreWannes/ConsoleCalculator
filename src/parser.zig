const std = @import("std");
const Tokenizer = @import("tokenizer.zig");
const Token = Tokenizer.Token;
const Number = Token.Number;
const TokenTag = Tokenizer.TokenTag;
const TokenizeError = Tokenizer.TokenizeError;
const Parser = @This();

pub const ParseError = error{
    InvalidToken,
    MissingTokens,
};

tokens: []const Token,
index: usize = 0,

pub fn init(tokens: []const Token) Parser {
    return Parser{ .tokens = tokens, .index = 0 };
}

pub fn parse(self: *Parser) ParseError!Number {
    _ = self;
    return Number.init(0, 0);
}

// expression -> term (('+' | '-') term)*
pub fn parseExpression(self: *Parser) ParseError!Number {
    self.index += 1;
    return Number.init(1, 0);
}

// term -> factor (('*' | '/') factor)*
pub fn parseTerm(self: *Parser) ParseError!Number {
    _ = self;
    return Number.init(1, 0);
}

// factor -> NUMBER | '(' expression ')' | '-' factor
pub fn parseFactor(self: *Parser) ParseError!Number {
    if (self.index >= self.tokens.len) return ParseError.MissingTokens;
    switch (self.tokens[self.index]) {
        .number => |number| {
            self.index += 1;
            return number;
        },
        .parenthesis => |parenthesis| {
            if (parenthesis != .open) return ParseError.InvalidToken;
            self.index += 1;
            const expression = try self.parseExpression();
            if (self.index >= self.tokens.len) return ParseError.MissingTokens;
            const token = self.tokens[self.index];
            if (std.meta.activeTag(token) != TokenTag.parenthesis or token.parenthesis != .close) return ParseError.MissingTokens;
            self.index += 1;
            return expression;
        },
        .operator => |operator| {
            if (operator != .subtract) return ParseError.InvalidToken;
            self.index += 1;
            const factor = try self.parseFactor();
            return factor.neg();
        },
        else => return ParseError.InvalidToken,
    }
}

// factor -> NUMBER | '(' expression ')' | '-' factor
test parseFactor {

    // factor -> NUMBER
    {
        const tokens = [_]Token{Token{ .number = Token.Number.init(1, 0) }};
        var parser = Parser.init(&tokens);
        const result = try parser.parseFactor();
        const expected = Token.Number.init(1, 0);
        try std.testing.expectEqual(expected, result);
    }

    // factor -> '(' expression ')'
    {
        const tokens = [_]Token{Token{ .parenthesis = .open }};
        var parser = Parser.init(&tokens);
        const result = parser.parseFactor();
        try std.testing.expectError(ParseError.MissingTokens, result);
    }
    {
        const tokens = [_]Token{ Token{ .parenthesis = .open }, Token{ .number = Token.Number.init(1, 0) } };
        var parser = Parser.init(&tokens);
        const result = parser.parseFactor();
        try std.testing.expectError(ParseError.MissingTokens, result);
    }
    {
        const tokens = [_]Token{ Token{ .parenthesis = .open }, Token{ .number = Token.Number.init(1, 0) }, Token{ .parenthesis = .close } };
        var parser = Parser.init(&tokens);
        const result = try parser.parseFactor();
        const expected = Token.Number.init(1, 0);
        try std.testing.expectEqual(expected, result);
    }

    // factor -> '-' factor
    {
        const tokens = [_]Token{Token{.operator = .subtract}, Token{ .number = Token.Number.init(1, 0) }};
        var parser = Parser.init(&tokens);
        const result = try parser.parseFactor();
        const expected = Token.Number.init(1, 0).neg();
        try std.testing.expectEqual(expected, result);
    }
}
