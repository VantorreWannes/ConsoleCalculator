const std = @import("std");
const Complex = std.math.complex.Complex(f64);
const Tokenizer = @This();

const constant_number_map = std.StaticStringMap(Complex).initComptime(.{
    .{ "i", Complex.init(0, 1) },
    .{ "e", Complex.init(std.math.e, 0) },
    .{ "pi", Complex.init(std.math.pi, 0) },
    .{ "phi", Complex.init(std.math.phi, 0) },
    .{ "tau", Complex.init(std.math.tau, 0) },
});

pub const Operator = enum {
    add,
    subtract,
    multiply,
    divide,
    power,
};

pub const Parenthesis = enum {
    open,
    close,
};

pub const Function = enum {
    conjugate,
    real,
    imaginary,
    squareRoot,
    logarithm10,
    logarithmE,
    logarithm2,
    exponential,
    sine,
    cosine,
    tangent,
    hyperbolicSine,
    hyperbolicCosine,
    hyperbolicTangent,
    inverseSine,
    inverseCosine,
    inverseTangent,
    inverseHyperbolicSine,
    inverseHyperbolicCosine,
    inverseHyperbolicTangent,
    ceiling,
    floor,
    absolute,
    gamma,

    pub const constant_map = std.StaticStringMap(Function).initComptime(.{
        .{ "conj", .conjugate },
        .{ "conjugate", .conjugate },
        .{ "re", .real },
        .{ "im", .imaginary },
        .{ "real", .real },
        .{ "imag", .imaginary },
        .{ "sqrt", .squareRoot },
        .{ "log", .logarithm10 },
        .{ "ln", .logarithmE },
        .{ "lb", .logarithm2 },
        .{ "exp", .exponential },
        .{ "mag", .absolute },
        .{ "abs", .absolute },
        .{ "sin", .sine },
        .{ "cos", .cosine },
        .{ "tan", .tangent },
        .{ "sinh", .hyperbolicSine },
        .{ "cosh", .hyperbolicCosine },
        .{ "tanh", .hyperbolicTangent },
        .{ "asin", .inverseSine },
        .{ "acos", .inverseCosine },
        .{ "atan", .inverseTangent },
        .{ "asinh", .inverseHyperbolicSine },
        .{ "acosh", .inverseHyperbolicCosine },
        .{ "atanh", .inverseHyperbolicTangent },
        .{ "ceil", .ceiling },
        .{ "floor", .floor },
        .{ "gamma", .gamma },
    });
};

pub const Variable = []const u8;

pub const Token = union(enum) {
    equals,
    operator: Operator,
    parenthesis: Parenthesis,
    function: Function,
    number: Complex,
    variable: Variable,
};

data: []const u8,
index: usize = 0,

pub fn init(data: []const u8) Tokenizer {
    return Tokenizer{ .data = data, .index = 0 };
}

pub fn next(self: *Tokenizer) !?Token {
    while (self.index < self.data.len) {
        switch (self.data[self.index]) {
            ' ', '\t', '\r', '\n' => self.index += 1,
            else => break,
        }
    }

    if (self.index >= self.data.len) {
        return null;
    }

    return switch (self.data[self.index]) {
        '+' => {
            self.index += 1;
            return Token{ .operator = .add };
        },
        '-' => {
            self.index += 1;
            return Token{ .operator = .subtract };
        },
        '*' => {
            self.index += 1;
            return Token{ .operator = .multiply };
        },
        '/' => {
            self.index += 1;
            return Token{ .operator = .divide };
        },
        '^' => {
            self.index += 1;
            return Token{ .operator = .power };
        },
        '(' => {
            self.index += 1;
            return Token{ .parenthesis = .open };
        },
        ')' => {
            self.index += 1;
            return Token{ .parenthesis = .close };
        },
        '0'...'9', '.' => {
            const number = try self.parseNumber();
            return Token{ .number = number };
        },
        'A'...'Z', 'a'...'z', '_' => {
            const start_index = self.index;
            while (self.index < self.data.len) {
                const byte = self.data[self.index];
                switch (byte) {
                    'A'...'Z', 'a'...'z', '0'...'9', '_' => self.index += 1,
                    else => break,
                }
            }
            const variable = self.data[start_index..self.index];
            if (Function.constant_map.get(variable)) |function| {
                return Token{ .function = function };
            }
            if (constant_number_map.get(variable)) |number| {
                return Token{ .number = number };
            }
            return Token{ .variable = variable };
        },
        '=' => {
            self.index += 1;
            return Token.equals;
        },
        else => error.InvalidCharacter,
    };
}

fn parseNumber(self: *Tokenizer) !Complex {
    const start_index = self.index;
    while (self.index < self.data.len) {
        const byte = self.data[self.index];
        switch (byte) {
            '0'...'9' => self.index += 1,
            else => break,
        }
    }
    if (self.index < self.data.len and self.data[self.index] == '.') self.index += 1;
    while (self.index < self.data.len) {
        const byte = self.data[self.index];
        switch (byte) {
            '0'...'9' => self.index += 1,
            else => break,
        }
    }
    const number_text = self.data[start_index..self.index];
    const real = try std.fmt.parseFloat(f64, number_text);
    return Complex.init(real, 0);
}

test parseNumber {
    {
        const data = "0.12";
        var tokenizer = Tokenizer.init(data);
        const number = try tokenizer.parseNumber();
        try std.testing.expectEqual(number, Complex.init(0.12, 0));
    }
    {
        const data = "100";
        var tokenizer = Tokenizer.init(data);
        const number = try tokenizer.parseNumber();
        try std.testing.expectEqual(number, Complex.init(100, 0));
    }
    {
        const data = "0.";
        var tokenizer = Tokenizer.init(data);
        const number = try tokenizer.parseNumber();
        try std.testing.expectEqual(number, Complex.init(0.0, 0));
    }
}

test next {
    const data = "value = (100 / 10) - 20";
    var tokenizer = Tokenizer.init(data);
    {
        const token = try tokenizer.next();
        try std.testing.expectEqualStrings("value", token.?.variable);
    }
    {
        const token = try tokenizer.next();
        try std.testing.expectEqual(token, Token.equals);
    }
    {
        const token = try tokenizer.next();
        try std.testing.expectEqual(token, Token{.parenthesis = .open});
    }
    {
        const token = try tokenizer.next();
        try std.testing.expectEqual(token, Token{.number = Complex.init(100, 0)});
    }
    {
        const token = try tokenizer.next();
        try std.testing.expectEqual(token, Token{.operator = .divide});
    }
    {
        const token = try tokenizer.next();
        try std.testing.expectEqual(token, Token{.number = Complex.init(10, 0)});
    }
    {
        const token = try tokenizer.next();
        try std.testing.expectEqual(token, Token{.parenthesis = .close});
    }
    {
        const token = try tokenizer.next();
        try std.testing.expectEqual(token, Token{.operator = .subtract});
    }
    {
        const token = try tokenizer.next();
        try std.testing.expectEqual(token, Token{.number = Complex.init(20, 0)});
    }
}
