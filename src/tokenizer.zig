const std = @import("std");
const Complex = std.math.complex.Complex(f64);
const Tokenizer = @This();

pub const Sign = enum {
    positive,
    negative,
};

pub const Operator = enum {
    add,
    subtract,
    multiply,
    divide,
    power,
};

pub const Parenthesis = enum {
    left,
    right,
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

pub const Token = union(enum) {
    operator: Operator,
    parenthesis: Parenthesis,
    function: Function,
    number: Complex,
    variable: []const u8,
};

const constant_map = std.StaticStringMap(Complex).initComptime(.{
    .{ "i", Complex.init(0, 1) },
    .{ "e", Complex.init(std.math.e, 0) },
    .{ "pi", Complex.init(std.math.pi, 0) },
    .{ "phi", Complex.init(std.math.phi, 0) },
    .{ "tau", Complex.init(std.math.tau, 0) },
});
