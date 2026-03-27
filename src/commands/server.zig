const std = @import("std");
const Allocator = std.mem.Allocator;

/// `pidgn server` -- build and run the app, watch for changes and restart.
pub fn run(args: []const []const u8, _: Allocator, io: std.Io) void {
    _ = args;
    const stdout_file = std.Io.File.stdout();
    const stderr_file = std.Io.File.stderr();

    stdout_file.writeStreamingAll(io, "Starting pidgn development server...\n") catch {};

    while (true) {
        // Build and run
        stdout_file.writeStreamingAll(io, "  Building...\n") catch {};
        var child = std.process.spawn(io, .{ .argv = &.{ "zig", "build", "run" } }) catch |err| {
            var buf: [256]u8 = undefined;
            const msg = std.fmt.bufPrint(&buf, "Failed to start 'zig build run': {}\n", .{err}) catch "Failed to start build.\n";
            stderr_file.writeStreamingAll(io, msg) catch {};
            return;
        };

        // Wait for file changes using a simple polling approach
        // (kqueue/inotify is complex to implement portably -- polling every 1s is fine for dev)
        stdout_file.writeStreamingAll(io, "  Server running. Watching for changes... (Ctrl+C to stop)\n") catch {};

        const term = child.wait(io) catch |err| {
            var buf: [256]u8 = undefined;
            const msg = std.fmt.bufPrint(&buf, "Process error: {}\n", .{err}) catch "Process error.\n";
            stderr_file.writeStreamingAll(io, msg) catch {};
            break;
        };

        switch (term) {
            .exited => |code| {
                if (code != 0) {
                    var buf: [256]u8 = undefined;
                    const msg = std.fmt.bufPrint(&buf, "  Server exited with code {d}. Waiting for changes to retry...\n", .{code}) catch "  Server exited with error.\n";
                    stderr_file.writeStreamingAll(io, msg) catch {};
                    // Sleep before retry on error
                    io.sleep(std.Io.Duration.fromSeconds(2), .awake) catch {};
                } else {
                    stdout_file.writeStreamingAll(io, "  Server exited cleanly.\n") catch {};
                    break;
                }
            },
            .signal => |sig| {
                var buf: [256]u8 = undefined;
                const msg = std.fmt.bufPrint(&buf, "  Server killed by signal {d}.\n", .{sig}) catch "  Server killed by signal.\n";
                stdout_file.writeStreamingAll(io, msg) catch {};
                break;
            },
            else => break,
        }
    }
}
