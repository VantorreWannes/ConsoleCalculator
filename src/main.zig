const std = @import("std");
const ConsoleCalculator = @import("ConsoleCalculator");

pub fn main() !void {
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
}
