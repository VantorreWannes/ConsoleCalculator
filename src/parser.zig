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

// term -> power (('*' | '/') power)*
fn parseTerm(self: *Parser) ParseError!Number {
    var factor = try self.parsePower();
    while (self.index < self.tokens.len) {
        const token = self.tokens[self.index];
        if (std.meta.activeTag(token) != TokenTag.operator) break;
        switch (token.operator) {
            .multiply => {
                self.index += 1;
                const other_factor = try self.parsePower();
                factor = factor.mul(other_factor);
            },
            .divide => {
                self.index += 1;
                const other_factor = try self.parsePower();
                factor = factor.div(other_factor);
            },
            else => break,
        }
    }
    return factor;
}

// power -> factor ('^' power)?
fn parsePower(self: *Parser) ParseError!Number {
    var base = try self.parseFactor();
    if (self.index >= self.tokens.len) return base;
    const token = self.tokens[self.index];
    if (std.meta.activeTag(token) == TokenTag.operator and token.operator == .power) {
        self.index += 1;
        const exponent = try self.parsePower();
        base = std.math.complex.pow(base, exponent);
    }
    return base;
}

// factor -> NUMBER | CONSTANT | FUNCTION '(' expression ')' | '(' expression ')' | '-' factor
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
        .function => |function| {
            self.index += 1;
            {
                if (self.index >= self.tokens.len) return ParseError.MissingTokens;
                const token = self.tokens[self.index];
                if (std.meta.activeTag(token) != TokenTag.parenthesis or token.parenthesis != .open) return ParseError.MissingTokens;
            }
            self.index += 1;
            const argument = try self.parseExpression();
            {
                if (self.index >= self.tokens.len) return ParseError.MissingTokens;
                const token = self.tokens[self.index];
                if (std.meta.activeTag(token) != TokenTag.parenthesis or token.parenthesis != .close) return ParseError.MissingTokens;
            }
            self.index += 1;
            return applyFunction(function, argument);
        },
    }
}

pub fn applyFunction(function: Token.Function, number: Number) Number {
    return switch (function) {
        .absolute => Number.init(std.math.complex.abs(number), 0),
        .conjugate => std.math.complex.conj(number),
        .exponential => std.math.complex.exp(number),
        .gamma => blk: {
            const re = std.math.gamma(f64, number.re);
            const im = if (number.im == 0) 0 else std.math.gamma(f64, number.im);
            break :blk Number.init(re, im);
        },
        .ceiling => blk: {
            const re = std.math.ceil(number.re);
            const im = std.math.ceil(number.im);
            break :blk Number.init(re, im);
        },
        .floor => blk: {
            const re = std.math.floor(number.re);
            const im = std.math.floor(number.im);
            break :blk Number.init(re, im);
        },
        .real => Number.init(number.re, 0),
        .imaginary => Number.init(number.im, 0),
        .squareRoot => std.math.complex.sqrt(number),
        .logarithm10 => blk: {
            const log10 = std.math.complex.log(Number.init(10, 0));
            break :blk std.math.complex.log(number).div(log10);
        },
        .logarithm2 => blk: {
            const log2 = std.math.complex.log(Number.init(2, 0));
            break :blk std.math.complex.log(number).div(log2);
        },
        .logarithmE => std.math.complex.log(number),
        .sine => std.math.complex.sin(number),
        .cosine => std.math.complex.cos(number),
        .tangent => std.math.complex.tan(number),
        .hyperbolicSine => std.math.complex.sinh(number),
        .hyperbolicCosine => std.math.complex.cosh(number),
        .hyperbolicTangent => std.math.complex.tanh(number),
        .inverseSine => std.math.complex.asin(number),
        .inverseCosine => std.math.complex.acos(number),
        .inverseTangent => std.math.complex.atan(number),
        .inverseHyperbolicSine => std.math.complex.asinh(number),
        .inverseHyperbolicCosine => std.math.complex.acosh(number),
        .inverseHyperbolicTangent => std.math.complex.atanh(number),
    };
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

// term -> power (('*' | '/') power)*
test parseTerm {

    // term -> power
    {
        const tokens = [_]Token{Token{ .number = Token.Number.init(2, 0) }};
        var parser = Parser.init(&tokens);
        const result = try parser.parseTerm();
        const expected = Token.Number.init(2, 0);
        try std.testing.expectEqual(expected, result);
    }

    // term -> power '*' power
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

    // term -> power '/' power
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

// power -> factor ('^' power)?
test parsePower {

    // power -> factor
    {
        const tokens = [_]Token{Token{ .number = Token.Number.init(1, 0) }};
        var parser = Parser.init(&tokens);
        const result = try parser.parsePower();
        const expected = Token.Number.init(1, 0);
        try std.testing.expectEqual(expected, result);
    }

    // power -> factor '^' power
    {
        const tokens = [_]Token{
            Token{ .number = Token.Number.init(2, 0) },
            Token{ .operator = .power },
            Token{ .number = Token.Number.init(2, 0) },
        };
        var parser = Parser.init(&tokens);
        const result = try parser.parsePower();
        const expected = Token.Number.init(4, 0);
        try std.testing.expectEqual(expected, result);
    }
}

// factor -> NUMBER | CONSTANT | FUNCTION '(' expression ')' | '(' expression ')' | '-' factor
test parseFactor {

    // factor -> NUMBER
    {
        const tokens = [_]Token{Token{ .number = Token.Number.init(1, 0) }};
        var parser = Parser.init(&tokens);
        const result = try parser.parseFactor();
        const expected = Token.Number.init(1, 0);
        try std.testing.expectEqual(expected, result);
    }

    // factor -> CONSTANT
    {
        const tokens = [_]Token{Token{ .number = Token.Number.init(0, 1) }};
        var parser = Parser.init(&tokens);
        const result = try parser.parseFactor();
        const expected = Token.Number.init(0, 1);
        try std.testing.expectEqual(expected, result);
    }

    // factor -> FUNCTION '(' expression ')'
    {
        const tokens = [_]Token{ Token{ .function = .absolute }, Token{ .parenthesis = .open }, Token{ .number = Token.Number.init(-1, 0) }, Token{ .parenthesis = .close } };
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
