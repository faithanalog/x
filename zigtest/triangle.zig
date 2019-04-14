const std = @import("std");

// 97x27

/// Dark -> Light color to text
const colorMap = " ,:!=+%#$";
const fbWidth = 97;
const fbHeight = 26;

var fb: [fbWidth * fbHeight]f32 = undefined;

const Vec2 = struct {
    x: f32,
    y: f32,
};

const Tri = struct {
    v0: Vec2,
    v1: Vec2,
    v2: Vec2,
    c0: f32,
    c1: f32,
    c2: f32,
};

// Counter-clockwise
fn edgeFunction(a: Vec2, b: Vec2, c: Vec2) f32 {
    return (c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x);
    // return (a.x - b.x) * (c.y - a.y) - (a.y - b.y) * (c.x - a.x);
}

fn renderTri(t: Tri) void {
    const area = edgeFunction(t.v0, t.v1, t.v2);

    var y: usize = 0;
    while (y < fbHeight) {
        var x: usize = 0;
        while (x < fbWidth) {
            const p = Vec2{ .x = @intToFloat(f32, x), .y = @intToFloat(f32, y) };
            const w0 = edgeFunction(t.v1, t.v2, p);
            const w1 = edgeFunction(t.v2, t.v0, p);
            const w2 = edgeFunction(t.v0, t.v1, p);
            std.debug.warn("({}, {}): {}, {}, {}\n", x, y, w0, w1, w2);
            if (w0 >= 0 and w1 >= 0 and w2 >= 0) {
                const c0 = t.c0 * (w0 / area);
                const c1 = t.c1 * (w1 / area);
                const c2 = t.c2 * (w2 / area);
                fb[(fbHeight - y - 1) * fbWidth + x] = c0 + c1 + c2;
            }
            x = x + 1;
        }
        y = y + 1;
    }
}

fn clearFramebuffer() !void {
    for (fb) |*x, i| {
        x.* = 0;
    }
}

pub fn main() !void {
    const tri = Tri{
        .v0 = Vec2{
            .x = 80,
            .y = 24,
        },
        .c0 = 1,

        .v1 = Vec2{
            .x = 60,
            .y = 3,
        },
        .c1 = 0.8,

        .v2 = Vec2{
            .x = 4,
            .y = 17,
        },
        .c2 = 0,
    };

    renderTri(tri);

    var fbChars: [fbWidth * fbHeight * 10]u8 = undefined;
    var fbNum: usize = 0;

    var buf: [8]u8 = undefined;

    var bright = true;

    // Reset
    const init = "\x1B[0m\x1B[1;37m";
    const reset = "\x1B[0m";
    const makeDark = "\x1B[21m";
    const makeBright = "\x1B[1m";
    for (init) |b, i| fbChars[fbNum + i] = b;
    fbNum = fbNum + init.len;

    for (fb) |*x, pixi| {
        const colzz = std.math.floor(x.* * @intToFloat(f32, colorMap.len * 2));
        const colus = @floatToInt(usize, colzz);
        const colClamped = std.math.min(std.math.max(0, colus), (colorMap.len * 2) - 1);

        if (colClamped < colorMap.len) {
            if (bright) {
                for (makeDark) |b, i| fbChars[fbNum + i] = b;
                fbNum = fbNum + makeDark.len;
                bright = false;
            }
        } else {
            if (!bright) {
                for (makeBright) |b, i| fbChars[fbNum + i] = b;
                fbNum = fbNum + makeBright.len;
                bright = true;
            }
        }

        fbChars[fbNum] = colorMap[colClamped >> 1];
        fbNum = fbNum + 1;

        if (pixi % fbWidth == 0) {
            fbChars[fbNum] = '\n';
            fbNum = fbNum + 1;
        }
    }

    fbChars[fbNum] = '\n';
    fbNum = fbNum + 1;

    for (reset) |b, i| fbChars[fbNum + i] = b;
    fbNum = fbNum + reset.len;

    const stdout_file = try std.io.getStdOut();
    try stdout_file.write(fbChars[0..fbNum]);
}
