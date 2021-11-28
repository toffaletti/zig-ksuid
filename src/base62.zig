const std = @import("std");
const t = std.testing;

pub const base62Characters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz".*;
pub const base = 62;
const zeroString = "000000000000000000000000000";
const offsetUppercase = 10;
const offsetLowercase = 36;
const stringEncodedLength = 27;

pub fn fastEncode(dest: *[27]u8, source: *const [20]u8) []const u8 {
    const srcBase = 4294967296;
    const dstBase = 62;
    std.debug.assert(source.len == 20);
    var parts = [5]u32{
        std.mem.readIntBig(u32, source[0..4]),
        std.mem.readIntBig(u32, source[4..8]),
        std.mem.readIntBig(u32, source[8..12]),
        std.mem.readIntBig(u32, source[12..16]),
        std.mem.readIntBig(u32, source[16..20]),
    };
    var n = dest.len;
    var bp: []u32 = parts[0..];
    var bq = [5]u32{ 0, 0, 0, 0, 0 };
    while (bp.len != 0) {
        var qidx: usize = 0;
        var remainder: u64 = 0;
        for (bp) |c| {
            var r: u64 = undefined;
            _ = @mulWithOverflow(u64, remainder, srcBase, &r);
            var value = @intCast(u64, c) + r;
            var digit = @divFloor(value, dstBase);
            remainder = @mod(value, dstBase);
            if (qidx != 0 or digit != 0) {
                bq[qidx] = @truncate(u32, digit);
                qidx += 1;
            }
        }
        n -= 1;
        dest[n] = base62Characters[remainder];
        bp = bq[0..qidx];
    }
    std.mem.copy(u8, dest[0..n], zeroString[0..n]);
    return dest[0..27];
}

fn base62Value(digit: u8) u8 {
    return switch (digit) {
        '0'...'9' => (digit - '0'),
        'A'...'Z' => offsetUppercase + (digit - 'A'),
        else => blk: {
            var r: u8 = undefined;
            _ = @subWithOverflow(u8, digit, 'a', &r);
            break :blk offsetLowercase + r;
        },
    };
}

pub fn fastDecode(dest: *[20]u8, source: *const [27]u8) []const u8 {
    const srcBase = 62;
    const dstBase = 4294967296;

    var parts: [27]u8 = undefined;
    var i: usize = 0;
    for (parts) |_| {
        parts[i] = base62Value(source[i]);
        i += 1;
    }
    var n = dest.len;
    var bp: []u8 = parts[0..];
    var bq: [27]u8 = undefined;
    while (bp.len > 0) {
        var qidx: usize = 0;
        var remainder: u64 = 0;

        for (bp) |c| {
            var r: u64 = undefined;
            _ = @mulWithOverflow(u64, remainder, srcBase, &r);
            var value = @intCast(u64, c) + r;
            var digit = @divFloor(value, dstBase);
            remainder = @mod(value, dstBase);
            if (qidx != 0 or digit != 0) {
                bq[qidx] = @truncate(u8, digit);
                qidx += 1;
            }
        }

        // errShortBuffer
        std.debug.assert(n >= 4);

        dest[n - 4] = @truncate(u8, remainder >> 24);
        dest[n - 3] = @truncate(u8, remainder >> 16);
        dest[n - 2] = @truncate(u8, remainder >> 8);
        dest[n - 1] = @truncate(u8, remainder);
        n -= 4;
        bp = bq[0..qidx];
    }

    var zero = [_]u8{0} ** 20;
    std.mem.copy(u8, dest[0..n], zero[0..n]);
    return dest[0..20];
}
test "base62" {
    var decoded: [20]u8 = undefined;
    _ = fastDecode(&decoded, "0ujtsYcgvSTl8PAuAdqWYSMnLOv");
    //std.debug.print("dec[{s}]\n", .{std.fmt.fmtSliceHexUpper(&decoded)});
    var outbuf: [27]u8 = undefined;
    var toEnc = try std.fmt.hexToBytes(&outbuf, "0669F7EFB5A1CD34B5F99D1154FB6853345C9735");
    var outEncBuf: [27]u8 = undefined;
    const outEnc = fastEncode(&outEncBuf, toEnc[0..20]);
    //std.debug.print("enc[{s}]\n", .{outEnc});
}
