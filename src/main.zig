const std = @import("std");
const Io = std.Io;

const rndr = @import("rndr");

pub fn main(init: std.process.Init) !void {
    _ = init;

    const a: rndr.GPUDevice.Handle = undefined;
    _ = a;
}
