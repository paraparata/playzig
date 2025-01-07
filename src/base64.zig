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
    _table: *const [64]u8,

    pub fn init() Base64 {
        const upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        const lower = "abcdefghijklmnopqrstuvwxyz";
        const numbers_symb = "0123456789+/";
        return Base64{ ._table = upper ++ lower ++ numbers_symb };
    }

    pub fn charAt(self: Base64, i: u8) u8 {
        return self._table[i];
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
};

test "test base64" {
    const base64 = Base64.init();
    var memBuf: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&memBuf);
    const allocator = fba.allocator();

    const encoded = try base64.encode(allocator, "saha");
    try testing.expectEqual("c2FoYQo=", encoded);
}
