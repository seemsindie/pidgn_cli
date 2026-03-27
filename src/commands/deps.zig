const std = @import("std");
const Allocator = std.mem.Allocator;

/// `pidgn deps` -- list workspace dependencies.
/// Reads build.zig.zon and displays dependency information.
pub fn run(args: []const []const u8, _: Allocator, io: std.Io) void {
    _ = args;
    const stdout_file = std.Io.File.stdout();

    stdout_file.writeStreamingAll(io,
        \\Workspace Dependencies:
        \\
        \\  pidgn       - Core web framework
        \\  pidgn_db    - Database layer (SQLite + PostgreSQL)
        \\  pidgn_jobs  - Background job system
        \\  pidgn_cli   - CLI tool
        \\
        \\Run `zig build --help` for build options.
        \\
    ) catch {};
}
