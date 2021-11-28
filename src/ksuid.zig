const std = @import("std");
const t = std.testing;
const base62 = @import("./base62.zig");
const Nil = KSUID{};

const KSUID = struct {
    const Self = @This();
    pub const epochStamp: i64 = 1400000000;

    data: [20]u8 = [_]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },

    pub fn random(rand: *std.rand.Random) KSUID {
        // Get a calendar timestamp, in seconds, relative to UTC 1970-01-01.
        return randomWithTimestamp(rand, std.time.timestamp());
    }

    pub fn randomWithTimestamp(rand: *std.rand.Random, unixTimestamp: i64) KSUID {
        var k = KSUID{};
        rand.bytes(k.data[4..]);
        const ts = @intCast(u32, unixTimestamp - epochStamp);
        std.mem.writeIntBig(u32, k.data[0..4], ts);
        return k;
    }

    pub fn timestamp(self: *const Self) i64 {
        return @intCast(i64, self.rawTimestamp()) + epochStamp;
    }

    pub fn rawTimestamp(self: *const Self) u32 {
        return std.mem.readIntBig(u32, self.data[0..4]);
    }

    pub fn payload(self: *const Self) *const [16]u8 {
        return self.data[4..];
    }

    pub fn parse(data: []const u8) !KSUID {
        var k = KSUID{};
        _ = base62.fastDecode(&k.data, data[0..27]);
        return k;
    }

    pub fn format(self: *const Self, dest: *[27]u8) []const u8 {
        return base62.fastEncode(dest, &self.data);
    }

    pub fn fmt(self: *const Self) std.fmt.Formatter(formatKSUID) {
        return .{.data = self};
    }
};

pub fn formatKSUID(
    ksuid: *const KSUID,
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    var buf: [27]u8 = undefined;
    _ = ksuid.format(&buf);
    try writer.writeAll(&buf);
}

test "new" {
    const a = KSUID{};
    try t.expectEqual(Nil, a);
    try t.expectEqual(@as(u32, 0), a.rawTimestamp());
    try t.expectEqual([_]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, a.payload().*);
}

test "parse" {
    const a = try KSUID.parse("1srOrx2ZWZBpBUvZwXKQmoEYga2");
    //std.debug.print("payload[{s}]\n", .{std.fmt.fmtSliceHexUpper(a.payload())});
    try t.expectEqual(@as(i64, 1621627443), a.timestamp());
    var buf: [16]u8 = undefined;
    const expected = try std.fmt.hexToBytes(&buf, "E1933E37F275708763ADC7745AF5E7F2");
    try t.expectEqualSlices(u8, expected, a.payload());
}

test "format" {
    var buf: [20]u8 = undefined;
    _ = try std.fmt.hexToBytes(&buf, "0669F7EFB5A1CD34B5F99D1154FB6853345C9735");
    var fmtbuf: [27]u8 = undefined;
    {
        const a = KSUID{ .data = buf };
        try t.expectEqualSlices(u8, "0ujtsYcgvSTl8PAuAdqWYSMnLOv", a.format(&fmtbuf));
    }
    // min
    {
        const a = KSUID{};
        try t.expectEqualSlices(u8, "000000000000000000000000000", a.format(&fmtbuf));
    }
    // max
    {
        const a = KSUID{ .data = [_]u8{0xff} ** 20 };
        try t.expectEqualSlices(u8, "aWgEPTl1tmebfsQzFP4bxwgy80V", a.format(&fmtbuf));
    }
}

test "formatter" {
    const a = KSUID{};
    var fmtbuf: [27]u8 = undefined;
    _ = try std.fmt.bufPrint(&fmtbuf, "{s}", .{a.fmt()});
    try t.expectEqualSlices(u8, "000000000000000000000000000", &fmtbuf);
}

test "random" {
    var prng = std.rand.DefaultPrng.init(0);
    const a = KSUID.random(&prng.random);
    var fmtbuf: [27]u8 = undefined;
    //std.debug.print("random[{s}]\n", .{a.format(&fmtbuf)});
    try t.expect(a.timestamp() != 0);
    //std.debug.print("payload[{s}]\n", .{std.fmt.fmtSliceHexUpper(a.payload())});
    var buf: [16]u8 = undefined;
    const expected = try std.fmt.hexToBytes(&buf, "A333D71CA4469950FA4B93B167568800");
    try t.expectEqualSlices(u8, &buf, a.payload());
}
