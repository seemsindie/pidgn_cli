const std = @import("std");
const Allocator = std.mem.Allocator;

/// `pidgn test` -- run project tests via `zig build test`.
pub fn run(args: []const []const u8, _: Allocator, io: std.Io) void {
    _ = args;
    const stdout_file = std.Io.File.stdout();
    const stderr_file = std.Io.File.stderr();

    stdout_file.writeStreamingAll(io, "Running tests...\n") catch {};

    var child = std.process.spawn(io, .{ .argv = &.{ "zig", "build", "test" } }) catch |err| {
        var buf: [256]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "Failed to run 'zig build test': {}\n", .{err}) catch "Failed to run tests.\n";
        stderr_file.writeStreamingAll(io, msg) catch {};
        return;
    };
    const term = child.wait(io) catch |err| {
        var buf: [256]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "Process error: {}\n", .{err}) catch "Process error.\n";
        stderr_file.writeStreamingAll(io, msg) catch {};
        return;
    };
    switch (term) {
        .exited => |code| {
            if (code == 0) {
                stdout_file.writeStreamingAll(io, "All tests passed.\n") catch {};
            } else {
                var buf: [256]u8 = undefined;
                const msg = std.fmt.bufPrint(&buf, "Tests failed with exit code {d}.\n", .{code}) catch "Tests failed.\n";
                stderr_file.writeStreamingAll(io, msg) catch {};
            }
        },
        else => {
            stderr_file.writeStreamingAll(io, "Test process terminated abnormally.\n") catch {};
        },
    }
}
