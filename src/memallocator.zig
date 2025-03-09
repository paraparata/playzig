// how zig compiler decides where the object will be stored:
// 1. every literal is stored in global data section
// 2. every constant object whose value is known at compile-time

const std = @import("std");

fn returnAsTuple(comptime a: anytype) struct { @TypeOf(a), comptime_int } {
    const n = 1;
    return .{ a, n };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var buffer = try std.ArrayList(u8)
        .initCapacity(allocator, 8);
    defer buffer.deinit();

    try buffer.append('a');
    try buffer.append('p');
    try buffer.append('e');
    _ = buffer.orderedRemove(1);

    const x, const y = returnAsTuple('a');
    std.debug.print("{any}\n{}\n{}", .{ buffer.items, x, y });
}
