const std = @import("std");
const t = std.testing;
const base62 = @import("./base62.zig");

const KSUID = struct {
    const Self = @This();
    pub const epochStamp: u64 = 1400000000;

    data: [20]u8 = [_]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },

    pub fn timestamp(self: *const Self) u64 {
        return @as(u64, self.rawTimestamp()) + epochStamp;
    }

    pub fn rawTimestamp(self: *const Self) u32 {
        return std.mem.readInt(u32, self.data[0..4], std.builtin.Endian.Big);
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
};

const Nil = KSUID{};

pub fn New() KSUID {
    return Nil;
}

test "new" {
    const a = New();
    try t.expectEqual(Nil, a);
    try t.expectEqual(@as(u32, 0), a.rawTimestamp());
    try t.expectEqual([_]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, a.payload().*);
}

test "parse" {
    const a = try KSUID.parse("1srOrx2ZWZBpBUvZwXKQmoEYga2");
    std.debug.print("payload[{s}]\n", .{std.fmt.fmtSliceHexUpper(a.payload())});
    try t.expectEqual(@as(u64, 1621627443), a.timestamp());
    var buf: [16]u8 = undefined;
    const expected = try std.fmt.hexToBytes(&buf, "E1933E37F275708763ADC7745AF5E7F2");
    try t.expectEqualSlices(u8, expected, a.payload());
}

test "format" {
    var buf: [20]u8 = undefined;
    _ = try std.fmt.hexToBytes(&buf, "0669F7EFB5A1CD34B5F99D1154FB6853345C9735");
    const a = KSUID{ .data = buf };
    var fmtbuf: [27]u8 = undefined;
    try t.expectEqualSlices(u8, "0ujtsYcgvSTl8PAuAdqWYSMnLOv", a.format(&fmtbuf));
}
