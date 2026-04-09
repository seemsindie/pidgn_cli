const std = @import("std");
const swatcher = @import("swatcher");
const posix = @cImport({
    @cInclude("signal.h");
    @cInclude("sys/wait.h");
});
const Allocator = std.mem.Allocator;
const Io = std.Io;
const Child = std.process.Child;

var rebuild_flag = std.atomic.Value(bool).init(false);
var asset_reload_flag = std.atomic.Value(bool).init(false);

fn sourceCallback(
    _: swatcher.FsEvent,
    _: *swatcher.RawTarget,
    name: ?[*:0]const u8,
    _: ?*anyopaque,
) callconv(.c) void {
    const filename = if (name) |n| std.mem.span(n) else {
        // Directory-level event without filename — still set flag
        rebuild_flag.store(true, .release);
        return;
    };
    if (filename.len == 0) {
        rebuild_flag.store(true, .release);
        return;
    }
    if (std.mem.endsWith(u8, filename, ".zig") or
        std.mem.endsWith(u8, filename, ".pidgn"))
    {
        rebuild_flag.store(true, .release);
    }
}

fn publicCallback(
    _: swatcher.FsEvent,
    _: *swatcher.RawTarget,
    name: ?[*:0]const u8,
    _: ?*anyopaque,
) callconv(.c) void {
    const filename = if (name) |n| std.mem.span(n) else return;
    if (filename.len == 0) return;
    if (std.mem.endsWith(u8, filename, ".css") or
        std.mem.endsWith(u8, filename, ".js") or
        std.mem.endsWith(u8, filename, ".html") or
        std.mem.endsWith(u8, filename, ".svg") or
        std.mem.endsWith(u8, filename, ".png") or
        std.mem.endsWith(u8, filename, ".jpg"))
    {
        asset_reload_flag.store(true, .release);
    }
}

/// `pidgn dev` — build, run, and auto-rebuild on file changes.
pub fn run(args: []const []const u8, allocator: Allocator, io: std.Io) void {
    const stdout = std.Io.File.stdout();
    const stderr = std.Io.File.stderr();

    // Determine binary name from build.zig.zon
    var name_buf: [128]u8 = undefined;
    const binary_name = parseBinaryName(io, &name_buf) orelse {
        stderr.writeStreamingAll(io, "Not a pidgn project (build.zig.zon not found or missing .name).\nRun this command from your project root.\n") catch {};
        return;
    };

    // All args are passed through to `zig build`
    const build_args = args;

    // Initialize file watcher
    var watcher_config = std.mem.zeroes(swatcher.Config);
    watcher_config.poll_interval_ms = 50;
    watcher_config.coalesce_ms = 500;

    var watcher = swatcher.Watcher.init(allocator, watcher_config, null) catch |err| {
        var buf: [256]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "Failed to initialize file watcher: {}\n", .{err}) catch "Failed to initialize file watcher.\n";
        stderr.writeStreamingAll(io, msg) catch {};
        return;
    };
    defer watcher.deinit();

    const watch_events = swatcher.Event.modified |
        swatcher.Event.created |
        swatcher.Event.deleted |
        swatcher.Event.moved;

    // Watch src/ and config/ for source changes
    watcher.addTarget(.{
        .path = "src",
        .recursive = true,
        .events = watch_events,
        .watch_options = 0,
        .callback = &sourceCallback,
    }) catch {};

    watcher.addTarget(.{
        .path = "config",
        .recursive = true,
        .events = watch_events,
        .watch_options = 0,
        .callback = &sourceCallback,
    }) catch {};

    // Watch public/ for asset changes (may not exist in API projects)
    watcher.addTarget(.{
        .path = "public",
        .recursive = true,
        .events = watch_events,
        .watch_options = 0,
        .callback = &publicCallback,
    }) catch {};

    watcher.start() catch |err| {
        var buf: [256]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "Failed to start file watcher: {}\n", .{err}) catch "Failed to start file watcher.\n";
        stderr.writeStreamingAll(io, msg) catch {};
        return;
    };

    stdout.writeStreamingAll(io, "\n  pidgn dev\n  Watching src/, config/, public/ for changes...\n\n") catch {};

    // Initial build + spawn
    var server_child = buildAndSpawn(allocator, io, binary_name, build_args, false);

    while (true) {
        io.sleep(Io.Duration.fromMilliseconds(100), .boot) catch break;

        if (rebuild_flag.load(.acquire)) {
            rebuild_flag.store(false, .release);
            asset_reload_flag.store(false, .release);
            stdout.writeStreamingAll(io, "\n  Change detected, rebuilding...\n") catch {};
            killChild(&server_child, io);
            server_child = buildAndSpawn(allocator, io, binary_name, build_args, false);
        }

        if (asset_reload_flag.load(.acquire)) {
            asset_reload_flag.store(false, .release);
            stdout.writeStreamingAll(io, "\n  Asset change detected, restarting...\n") catch {};
            killChild(&server_child, io);
            server_child = buildAndSpawn(allocator, io, binary_name, build_args, true);
        }
    }

    killChild(&server_child, io);
}

fn buildAndSpawn(allocator: Allocator, io: Io, binary_name: []const u8, extra_args: []const []const u8, skip_build: bool) ?Child {
    const stdout = std.Io.File.stdout();
    const stderr = std.Io.File.stderr();

    if (!skip_build) {
        // Build argv: "zig" "build" + extra args
        var argv_buf: [32][]const u8 = undefined;
        argv_buf[0] = "zig";
        argv_buf[1] = "build";
        const extra_count = @min(extra_args.len, argv_buf.len - 2);
        for (0..extra_count) |i| {
            argv_buf[2 + i] = extra_args[i];
        }
        const argv = argv_buf[0 .. 2 + extra_count];

        const result = std.process.run(allocator, io, .{
            .argv = argv,
        }) catch |err| {
            var buf: [256]u8 = undefined;
            const msg = std.fmt.bufPrint(&buf, "  Failed to run zig build: {}\n", .{err}) catch "  Failed to run zig build.\n";
            stderr.writeStreamingAll(io, msg) catch {};
            return null;
        };
        defer allocator.free(result.stdout);
        defer allocator.free(result.stderr);

        switch (result.term) {
            .exited => |code| if (code != 0) {
                stderr.writeStreamingAll(io, "  Build failed:\n") catch {};
                stderr.writeStreamingAll(io, result.stderr) catch {};
                stdout.writeStreamingAll(io, "\n  Waiting for changes...\n") catch {};
                return null;
            },
            else => {
                stderr.writeStreamingAll(io, "  Build terminated abnormally.\n") catch {};
                return null;
            },
        }
    }

    // Spawn the server binary
    var bin_path_buf: [256]u8 = undefined;
    const bin_path = std.fmt.bufPrint(&bin_path_buf, "./zig-out/bin/{s}", .{binary_name}) catch {
        stderr.writeStreamingAll(io, "  Binary path too long.\n") catch {};
        return null;
    };

    var child = std.process.spawn(io, .{
        .argv = &.{bin_path},
    }) catch |err| {
        var buf: [256]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "  Failed to start server: {}\n", .{err}) catch "  Failed to start server.\n";
        stderr.writeStreamingAll(io, msg) catch {};
        return null;
    };
    _ = &child;

    stdout.writeStreamingAll(io, "  Server started.\n") catch {};
    return child;
}

fn killChild(child_ptr: *?Child, _: Io) void {
    if (child_ptr.*) |*child| {
        // Use POSIX kill+waitpid directly to avoid Zig IO system blocking
        // when the server has active WebSocket connections.
        if (child.id) |pid| {
            _ = posix.kill(pid, posix.SIGKILL);
            _ = posix.waitpid(pid, null, 0);
        }
        child_ptr.* = null;
    }
}

/// Parse the binary name from build.zig.zon in the current directory.
/// Looks for `.name = .identifier` pattern.
fn parseBinaryName(io: Io, buf: []u8) ?[]const u8 {
    const result = std.process.run(std.heap.smp_allocator, io, .{
        .argv = &.{ "cat", "build.zig.zon" },
    }) catch return null;
    defer std.heap.smp_allocator.free(result.stdout);
    defer std.heap.smp_allocator.free(result.stderr);

    const content = result.stdout;

    // Find ".name = ." pattern
    const marker = ".name = .";
    const start = (std.mem.indexOf(u8, content, marker) orelse return null) + marker.len;

    // Extract identifier (alphanumeric + underscore)
    var len: usize = 0;
    while (start + len < content.len) : (len += 1) {
        const c = content[start + len];
        if (!std.ascii.isAlphanumeric(c) and c != '_') break;
    }
    if (len == 0 or len >= buf.len) return null;

    @memcpy(buf[0..len], content[start..][0..len]);
    return buf[0..len];
}
