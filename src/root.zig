const std = @import("std");
const Tokenizer = @import("tokenizer.zig");
const Parser = @import("parser.zig");

test {
    std.testing.refAllDecls(Tokenizer);
    std.testing.refAllDecls(Parser);
}

