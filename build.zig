const std = @import("std");

pub fn build(b: *std.Build) void {
    _ = b.addModule("zig-obj", .{
        .source_file = .{ .path = "src/main.zig" },
    });
}
