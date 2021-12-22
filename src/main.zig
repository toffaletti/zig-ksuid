const std = @import("std");
const ksuid = @import("./ksuid.zig");
const cTime = @cImport(@cInclude("time.h"));

fn strftime(buf: []u8, fmt: [*c]const u8, ts: i64) []const u8 {
    const tm = cTime.localtime(&ts);
    var nlen = cTime.strftime(buf.ptr, buf.len, fmt, tm);
    return buf[0..nlen];
}

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();

    var count: u64 = 1;
    var i: usize = 1;
    while (i < std.os.argv.len) : (i += 1) {
        const arg = std.mem.span(std.os.argv[i]);
        if (std.mem.eql(u8, "-n", arg)) {
            i += 1;
            const count_arg = std.mem.span(std.os.argv[i]);
            count = try std.fmt.parseInt(u64, count_arg, 10);
        } else {
            count = 0;
            const k = try ksuid.KSUID.parse(arg);
            var buf: [200]u8 = undefined;
            try stdout.print("{s}\n {s}\n {s}\n", .{
                k.fmt(),
                strftime(&buf, "%Y-%m-%d %H:%M:%S %z %Z", k.timestamp()),
                std.fmt.fmtSliceHexUpper(k.payload()),
            });
        }
    }

    var secret_seed: [std.rand.DefaultCsprng.secret_seed_length]u8 = undefined;
    std.crypto.random.bytes(&secret_seed);
    var rand = std.rand.DefaultCsprng.init(secret_seed);
    while (count > 0) : (count -= 1) {
        const k = ksuid.KSUID.random(rand.random());
        try stdout.print("{s}\n", .{k.fmt()});
    }
}
