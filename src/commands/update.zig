const std = @import("std");
const Allocator = std.mem.Allocator;

/// `zzz update` -- update zzz CLI to the latest version.
/// Re-runs the install script to fetch and install the latest release.
pub fn run(args: []const []const u8, _: Allocator, io: std.Io) void {
    _ = args;
    const stdout_file = std.Io.File.stdout();

    stdout_file.writeStreamingAll(io,
        \\Updating zzz CLI...
        \\
        \\
    ) catch {};

    var child = std.process.Child.init(
        &.{ "sh", "-c", "curl -fsSL https://zzz.seemsindie.com/install.sh | sh" },
        .{ .io = io },
    );
    child.stdout = .parent;
    child.stderr = .parent;
    child.spawn(io) catch {
        stdout_file.writeStreamingAll(io,
            \\Failed to start update. Run manually:
            \\  curl -fsSL https://zzz.seemsindie.com/install.sh | sh
            \\
        ) catch {};
        return;
    };
    _ = child.wait(io) catch {};
}
