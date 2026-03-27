const std = @import("std");
const Allocator = std.mem.Allocator;

/// `pidgn swagger` -- export OpenAPI specification.
/// Runs the app with --swagger flag to output comptime-generated OpenAPI JSON.
pub fn run(args: []const []const u8, _: Allocator, io: std.Io) void {
    _ = args;
    const stderr_file = std.Io.File.stderr();

    var child = std.process.spawn(io, .{ .argv = &.{ "zig", "build", "run", "--", "--swagger" } }) catch |err| {
        var buf: [256]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "Failed to run 'zig build run -- --swagger': {}\n", .{err}) catch "Failed to run swagger command.\n";
        stderr_file.writeStreamingAll(io, msg) catch {};
        return;
    };
    _ = child.wait(io) catch |err| {
        var buf: [256]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "Process error: {}\n", .{err}) catch "Process error.\n";
        stderr_file.writeStreamingAll(io, msg) catch {};
    };
}
