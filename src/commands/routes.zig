const std = @import("std");
const Allocator = std.mem.Allocator;

/// `pidgn routes` -- list all application routes.
/// Runs the app with --routes flag, which triggers route listing mode.
pub fn run(args: []const []const u8, _: Allocator, io: std.Io) void {
    _ = args;
    const stderr_file = std.Io.File.stderr();

    var child = std.process.spawn(io, .{ .argv = &.{ "zig", "build", "run", "--", "--routes" } }) catch |err| {
        var buf: [256]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "Failed to run 'zig build run -- --routes': {}\n", .{err}) catch "Failed to run routes command.\n";
        stderr_file.writeStreamingAll(io, msg) catch {};
        return;
    };
    _ = child.wait(io) catch |err| {
        var buf: [256]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "Process error: {}\n", .{err}) catch "Process error.\n";
        stderr_file.writeStreamingAll(io, msg) catch {};
    };
}
