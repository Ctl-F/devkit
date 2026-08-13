const std = @import("std");
const Io = std.Io;

const rndr = @import("rndr");

pub fn main(init: std.process.Init) !void {
    const GPU = rndr.GPUDevice(rndr.DummyBackend);

    var gpu = GPU.init(.{}, init.io, init.gpa);
    defer gpu.deinit();
}
