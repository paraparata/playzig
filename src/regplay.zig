const std = @import("std");
const math = std.math;
const fs = std.fs;

const fourcc = [4]i8;
const sample_t = u8;
const SAMPLE_MAX = 8000;

const RiffHdr = extern struct {
    id: fourcc,
    size: u32,
    type: fourcc,
};

const FmtCheck = extern struct {
    id: fourcc,
    size: u32,
    fmt_tag: u16,
    channels: u16,
    samples_per_sec: u32,
    bytes_per_sec: u32,
    block_align: u16,
    bits_per_sample: u16,
};

const DataHdr = extern struct {
    id: fourcc,
    size: u32,
};

const WavHdr = extern struct {
    riff: RiffHdr,
    fmt: FmtCheck,
    data: DataHdr,
};

const DURATION = 5;
const SR = 44100;
const NCHANNELS = 1;
const NSAMPLES: comptime_int = NCHANNELS * DURATION * SR;

fn castStringLiteral(input: *const [4:0]u8) fourcc {
    var output: fourcc = undefined;
    for (input, 0..) |char, index| {
        output[index] = @intCast(char);
    }
    return output;
}

pub fn create() !void {
    const file = try fs.cwd().createFile("./output.wav", .{});
    defer file.close();

    // /* FMT chunk */
    const fmt = FmtCheck{
        .id = castStringLiteral("fmt "),
        .size = 16,
        .fmt_tag = 1,
        .channels = NCHANNELS,
        .samples_per_sec = SR,
        .bytes_per_sec = NCHANNELS * SR * @sizeOf(sample_t),
        .block_align = NCHANNELS * @sizeOf(sample_t),
        .bits_per_sample = 8 * @sizeOf(sample_t),
    };

    // /* DATA header */
    const data = DataHdr{
        .id = castStringLiteral("data"),
        .size = NSAMPLES * @sizeOf(sample_t),
    };

    const hdr = WavHdr{
        .riff = RiffHdr{
            .id = castStringLiteral("RIFF"),
            .size = 36 + NSAMPLES * @sizeOf(sample_t),
            .type = castStringLiteral("WAVE"),
        },
        .fmt = fmt,
        .data = data,
    };

    // write header
    var writer = file.writer();
    _ = try writer.writeStruct(hdr);

    // assign buffer
    var i: usize = 0;
    while (i < NSAMPLES) : (i += 1) {
        // const iI: f32 = @floatFromInt(i);
        // const calc: f32 = SAMPLE_MAX * math.sin(2 * math.phi * 440 * (iI / SR));
        const val: sample_t = @intCast(i * 5 & i >> 7 | i * 3 & i >> 10);
        try writer.writeInt(sample_t, val, .little);
    }

    // _ = try writer.writeAll(buf[0..NSAMPLES]);
    // if (buf.len % 2 == 1) {
    //     const nil = 0;
    //     _ = try writer.writeInt(comptime_int, nil);
    // }
}
