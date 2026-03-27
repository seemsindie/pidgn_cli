const std = @import("std");
const Allocator = std.mem.Allocator;

/// `pidgn migrate` -- run pending migrations.
/// `pidgn migrate rollback` -- rollback the last migration.
/// `pidgn migrate status` -- show migration status.
pub fn run(args: []const []const u8, _: Allocator, io: std.Io) void {
    const stdout_file = std.Io.File.stdout();
    const stderr_file = std.Io.File.stderr();

    const sub_command: []const u8 = if (args.len > 0) args[0] else "up";

    if (std.mem.eql(u8, sub_command, "up") or args.len == 0) {
        stdout_file.writeStreamingAll(io, "Running migrations...\n") catch {};
        runZigBuild(&.{ "zig", "build", "run", "--", "--migrate" }, io, stderr_file);
    } else if (std.mem.eql(u8, sub_command, "rollback")) {
        stdout_file.writeStreamingAll(io, "Rolling back last migration...\n") catch {};
        runZigBuild(&.{ "zig", "build", "run", "--", "--migrate-rollback" }, io, stderr_file);
    } else if (std.mem.eql(u8, sub_command, "status")) {
        stdout_file.writeStreamingAll(io, "Migration status:\n") catch {};
        runZigBuild(&.{ "zig", "build", "run", "--", "--migrate-status" }, io, stderr_file);
    } else {
        var buf: [256]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "Unknown migrate subcommand: {s}\n", .{sub_command}) catch "Unknown migrate subcommand.\n";
        stderr_file.writeStreamingAll(io, msg) catch {};
        stderr_file.writeStreamingAll(io, "Usage: pidgn migrate [up|rollback|status]\n") catch {};
    }
}

fn runZigBuild(argv: []const []const u8, io: std.Io, stderr_file: std.Io.File) void {
    var child = std.process.spawn(io, .{ .argv = argv }) catch |err| {
        var buf: [256]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "Failed to run command: {}\n", .{err}) catch "Failed to run command.\n";
        stderr_file.writeStreamingAll(io, msg) catch {};
        return;
    };
    _ = child.wait(io) catch |err| {
        var buf: [256]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "Process error: {}\n", .{err}) catch "Process error.\n";
        stderr_file.writeStreamingAll(io, msg) catch {};
    };
}
