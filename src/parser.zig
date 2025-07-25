const std = @import("std");
const Tokenizer = @import("tokenizer.zig");
const Token = Tokenizer.Token;
const TokenTag = Tokenizer.TokenTag;
pub const Number = Token.Number;
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
    return self.parseExpression();
}

// expression -> term (('+' | '-') term)*
fn parseExpression(self: *Parser) ParseError!Number {
    var term = try self.parseTerm();
    while (self.index < self.tokens.len) {
        const token = self.tokens[self.index];
        if (std.meta.activeTag(token) != TokenTag.operator) break;
        switch (token.operator) {
            .plus => {
                self.index += 1;
                const other_term = try self.parseTerm();
                term = term.add(other_term);
            },
            .minus => {
                self.index += 1;
                const other_term = try self.parseTerm();
                term = term.sub(other_term);
            },
            else => break,
        }
    }
    return term;
}

// term -> factor (('*' | '/') factor)*
fn parseTerm(self: *Parser) ParseError!Number {
    var factor = try self.parseFactor();
    while (self.index < self.tokens.len) {
        const token = self.tokens[self.index];
        if (std.meta.activeTag(token) != TokenTag.operator) break;
        switch (token.operator) {
            .multiply => {
                self.index += 1;
                const other_factor = try self.parseFactor();
                factor = factor.mul(other_factor);
            },
            .divide => {
                self.index += 1;
                const other_factor = try self.parseFactor();
                factor = factor.div(other_factor);
            },
            else => break,
        }
    }
    return factor;
}

// factor -> NUMBER | '(' expression ')' | '-' factor
fn parseFactor(self: *Parser) ParseError!Number {
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
            if (operator != .minus) return ParseError.InvalidToken;
            self.index += 1;
            const factor = try self.parseFactor();
            return factor.neg();
        },
        else => return ParseError.InvalidToken,
    }
}

test parse {
    const tokens = [_]Token{
        Token{ .number = Token.Number.init(2, 0) },
        Token{ .operator = .plus },
        Token{ .number = Token.Number.init(3, 0) },
        Token{ .operator = .multiply },
        Token{ .number = Token.Number.init(2, 0) },
    };
    var parser = Parser.init(&tokens);
    const result = try parser.parse();
    const expected = Number.init(8, 0);
    try std.testing.expectEqual(expected, result);
}

// expression -> term (('+' | '-') term)*
test parseExpression {
    // expression -> term
    {
        const tokens = [_]Token{Token{ .number = Token.Number.init(2, 0) }};
        var parser = Parser.init(&tokens);
        const result = try parser.parseExpression();
        const expected = Token.Number.init(2, 0);
        try std.testing.expectEqual(expected, result);
    }

    // expression -> term '+' term
    {
        const tokens = [_]Token{ Token{ .number = Token.Number.init(2, 0) }, Token{ .operator = .plus } };
        var parser = Parser.init(&tokens);
        const result = parser.parseExpression();
        try std.testing.expectError(ParseError.MissingTokens, result);
    }
    {
        const tokens = [_]Token{
            Token{ .number = Token.Number.init(2, 0) },
            Token{ .operator = .plus },
            Token{ .number = Token.Number.init(2, 0) },
        };
        var parser = Parser.init(&tokens);
        const result = try parser.parseExpression();
        const expected = Token.Number.init(4, 0);
        try std.testing.expectEqual(expected, result);
    }

    // expression -> term '-' term
    {
        const tokens = [_]Token{ Token{ .number = Token.Number.init(2, 0) }, Token{ .operator = .minus } };
        var parser = Parser.init(&tokens);
        const result = parser.parseExpression();
        try std.testing.expectError(ParseError.MissingTokens, result);
    }
    {
        const tokens = [_]Token{
            Token{ .number = Token.Number.init(2, 0) },
            Token{ .operator = .minus },
            Token{ .number = Token.Number.init(2, 0) },
        };
        var parser = Parser.init(&tokens);
        const result = try parser.parseExpression();
        const expected = Token.Number.init(0, 0);
        try std.testing.expectEqual(expected, result);
    }
}

// term -> factor (('*' | '/') factor)*
test parseTerm {
    // term -> factor
    {
        const tokens = [_]Token{Token{ .number = Token.Number.init(2, 0) }};
        var parser = Parser.init(&tokens);
        const result = try parser.parseTerm();
        const expected = Token.Number.init(2, 0);
        try std.testing.expectEqual(expected, result);
    }

    // term -> factor '*' factor
    {
        const tokens = [_]Token{ Token{ .number = Token.Number.init(2, 0) }, Token{ .operator = .multiply } };
        var parser = Parser.init(&tokens);
        const result = parser.parseTerm();
        try std.testing.expectError(ParseError.MissingTokens, result);
    }
    {
        const tokens = [_]Token{
            Token{ .number = Token.Number.init(2, 0) },
            Token{ .operator = .multiply },
            Token{ .number = Token.Number.init(2, 0) },
        };
        var parser = Parser.init(&tokens);
        const result = try parser.parseTerm();
        const expected = Token.Number.init(4, 0);
        try std.testing.expectEqual(expected, result);
    }

    // term -> factor '/' factor
    {
        const tokens = [_]Token{ Token{ .number = Token.Number.init(2, 0) }, Token{ .operator = .divide } };
        var parser = Parser.init(&tokens);
        const result = parser.parseTerm();
        try std.testing.expectError(ParseError.MissingTokens, result);
    }
    {
        const tokens = [_]Token{
            Token{ .number = Token.Number.init(2, 0) },
            Token{ .operator = .divide },
            Token{ .number = Token.Number.init(2, 0) },
        };
        var parser = Parser.init(&tokens);
        const result = try parser.parseTerm();
        const expected = Token.Number.init(1, 0);
        try std.testing.expectEqual(expected, result);
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
        const tokens = [_]Token{ Token{ .operator = .minus }, Token{ .number = Token.Number.init(1, 0) } };
        var parser = Parser.init(&tokens);
        const result = try parser.parseFactor();
        const expected = Token.Number.init(1, 0).neg();
        try std.testing.expectEqual(expected, result);
    }
}
