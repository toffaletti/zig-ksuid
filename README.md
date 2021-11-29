# zig-ksuid
Zig implementation of [Segment.io's KSUID](https://segment.com/blog/a-brief-history-of-the-uuid/). A mostly direct port of the original Go implementation https://github.com/segmentio/ksuid.

# library usage

To generate a KSUID you must provide a `std.rand.Random`. In this example we are using the default cryptographically secure rng provided by the zig std library.

```zig
    var secret_seed: [std.rand.DefaultCsprng.secret_seed_length]u8 = undefined;
    std.crypto.random.bytes(&secret_seed);
    var rand = std.rand.DefaultCsprng.init(secret_seed);
    const k = KSUID.random(&rand.random);
    try stdout.print("{s}\n", .{k.fmt()});
```

```zig
    const k = try KSUID.parse("1srOrx2ZWZBpBUvZwXKQmoEYga2");
```

# command usage
Generate ksuid;
```
./zig-out/bin/ksuid -n 5
21ZJr2CvT4q9YneIlvRsN2EH6MH
21ZJqz7FW1eU8jMUyuyoXRx2YIK
21ZJr2kAQeAiRqznp6UHyvvuk4k
21ZJqw99HJdsL9DhYBF1XwffcVp
21ZJr0QfjoyHkAwP8PL0GGs17e9
```

Inspect a ksuid:
```
./zig-out/bin/ksuid 0ujtsYcgvSTl8PAuAdqWYSMnLOv
0ujtsYcgvSTl8PAuAdqWYSMnLOv
 2017-10-09 21:00:47 -0700 PDT
 B5A1CD34B5F99D1154FB6853345C9735
```

# test coverage
To generate a coverage report with kcov:
```
zig build test -Dcoverage
open kcov-output/index.html
```