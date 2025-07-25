const std = @import("std");
const ConsoleCalculator = @import("ConsoleCalculator");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const stdout = std.io.getStdOut();
    defer stdout.close();

    var writer = std.io.bufferedWriter(stdout.writer());
    
    if (args.len == 2) {
        const expression = args[1];
        const result = try ConsoleCalculator.calculate(allocator, expression);
        {
            const data = try std.fmt.allocPrint(allocator, "{d}", .{result.re});
            defer allocator.free(data);
            _ = try writer.write(data);
        }
        
        if (result.im < 0) {
            const data = try std.fmt.allocPrint(allocator, "{d} - {d}i", .{ result.re, -result.im });
            defer allocator.free(data);
            _ = try writer.write(data);
        }

        if (result.im > 0) {
            const data = try std.fmt.allocPrint(allocator, "{d} - {d}i", .{ result.re, -result.im });
            defer allocator.free(data);
            _ = try writer.write(data);
        }
        try writer.flush();
    }
}
