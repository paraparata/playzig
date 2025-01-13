const std = @import("std");
const testing = std.testing;

fn calcEncodeLen(input: []const u8) !usize {
    if (input.len < 3) {
        return @as(usize, 4);
    }

    const output = try std.math.divCeil(usize, input.len, 3);
    return output * 4;
}

test "test calcEncodeLen" {
    const encodeLen = calcEncodeLen("Saha");
    try testing.expectEqual(8, encodeLen);
}

fn calcDecodeLen(input: []const u8) !usize {
    if (input.len < 4) {
        return @as(usize, 3);
    }

    const output = try std.math.divFloor(usize, input.len, 4);
    return output * 3;
}

test "test calcDecodeLen" {
    const decodeLen = calcDecodeLen("Sahamaneh");
    try testing.expectEqual(6, decodeLen);
}

pub const Base64 = struct {
    char_set: *const [64]u8,

    pub fn init() Base64 {
        const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        return Base64{ .char_set = chars };
    }

    pub fn charAt(self: Base64, i: u8) u8 {
        return self.char_set[i];
    }

    pub fn encode(self: Base64, allocator: std.mem.Allocator, input: []const u8) ![]u8 {
        if (input.len == 0) {
            return "";
        }

        // input = "saha"
        // nOut  = 8
        const nOut = try calcEncodeLen(input);
        var out = try allocator.alloc(u8, nOut);
        var buf = [3]u8{ 0, 0, 0 };
        var count: u8 = 0;
        var iOut: u64 = 0;

        for (input, 0..) |_, i| {
            // buf[0] = input[0] = 's'
            buf[count] = input[i];
            count += 1;
            if (count == 3) {
                out[iOut] = self.charAt(buf[0] >> 2);
                out[iOut + 1] = self.charAt(((buf[0] & 0x03) << 4) + (buf[1] >> 4));
                out[iOut + 2] = self.charAt(((buf[1] & 0x0f) << 2) + (buf[2] >> 6));
                out[iOut + 3] = self.charAt(buf[2] & 0x3f);
                iOut += 4;
                count = 0;
            }
        }

        if (count == 1) {
            out[iOut] = self.charAt(buf[0] >> 2);
            out[iOut + 1] = self.charAt((buf[0] & 0x03) << 4);
            out[iOut + 2] = '=';
            out[iOut + 3] = '=';
        }

        if (count == 2) {
            out[iOut] = self.charAt(buf[0] >> 2);
            out[iOut + 1] = self.charAt(((buf[0] & 0x03) << 4) + (buf[1] >> 4));
            out[iOut + 2] = self.charAt((buf[1] & 0x0f) << 2);
            out[iOut + 3] = '=';
            iOut += 4;
        }

        return out;
    }

    pub fn decode(self: Base64, allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
        if (input.len == 0) {
            return "";
        }

        const nOut = try calcDecodeLen(input);
        var out = try allocator.alloc(u8, nOut);
        var buf = [4]u8{ 0, 0, 0, 0 };
        var count: u8 = 0;
        var iOut: u64 = 0;

        for (input) |char| {
            const char_index: u8 = @intCast(std.mem.indexOf(u8, self.char_set, &[1]u8{char}) orelse 64);
            buf[count] = char_index;
            count += 1;
            if (count == 4) {
                out[iOut] = (buf[0] << 2) + (buf[1] >> 4);
                if (buf[2] != 64) {
                    out[iOut + 1] = (buf[1] << 4) + (buf[2] >> 2);
                }
                if (buf[3] != 64) {
                    out[iOut + 2] = (buf[2] << 6) + buf[3];
                }
                iOut += 3;
                count = 0;
            }
        }

        const res = std.mem.trim(u8, out, "\xaa");
        return res;
    }
};

test "base64 encode" {
    const base64 = Base64.init();
    var memBuf: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&memBuf);
    const allocator = fba.allocator();

    const encoded = try base64.encode(allocator, "saha");
    try testing.expectEqualStrings("c2FoYQ==", encoded);
}

test "base64 decode" {
    const base64 = Base64.init();
    var memBuf: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&memBuf);
    const allocator = fba.allocator();

    const decoded = try base64.decode(allocator, "c2FoYQ==");
    try testing.expectEqualStrings("saha", decoded);
}

// test "std indexOf" {
//     const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
//     const str = "c2FoYQ==";
//     for (str) |char| {
//         const index: u8 = @intCast(std.mem.indexOf(u8, chars, &[1]u8{char}) orelse 64);
//         std.log.warn("{}: {}\n", .{ char, index });
//     }
//
//     try testing.expectEqual(true, true);
// }
