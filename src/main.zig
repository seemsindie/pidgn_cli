const std = @import("std");
const new_cmd = @import("commands/new.zig");
const server_cmd = @import("commands/server.zig");
const routes_cmd = @import("commands/routes.zig");
const migrate_cmd = @import("commands/migrate.zig");
const generate_cmd = @import("commands/generate.zig");
const swagger_cmd = @import("commands/swagger.zig");
const test_cmd = @import("commands/test_cmd.zig");
const deps_cmd = @import("commands/deps.zig");
const update_cmd = @import("commands/update.zig");

const version = "0.2.0-beta.7";

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    // Collect args into a fixed buffer
    var arg_buf: [64][]const u8 = undefined;
    var arg_count: usize = 0;

    var args_iter = std.process.Args.Iterator.init(init.minimal.args);
    while (args_iter.next()) |arg| {
        if (arg_count < arg_buf.len) {
            arg_buf[arg_count] = arg;
            arg_count += 1;
        }
    }

    const args = arg_buf[0..arg_count];

    if (args.len < 2) {
        printUsage(io);
        return;
    }

    const command = args[1];
    const rest = args[2..];

    if (std.mem.eql(u8, command, "new")) {
        return new_cmd.run(rest, allocator, io);
    } else if (std.mem.eql(u8, command, "server") or std.mem.eql(u8, command, "s")) {
        return server_cmd.run(rest, allocator, io);
    } else if (std.mem.eql(u8, command, "routes")) {
        return routes_cmd.run(rest, allocator, io);
    } else if (std.mem.eql(u8, command, "migrate")) {
        return migrate_cmd.run(rest, allocator, io);
    } else if (std.mem.eql(u8, command, "gen") or std.mem.eql(u8, command, "generate")) {
        return generate_cmd.run(rest, allocator, io);
    } else if (std.mem.eql(u8, command, "swagger")) {
        return swagger_cmd.run(rest, allocator, io);
    } else if (std.mem.eql(u8, command, "test")) {
        return test_cmd.run(rest, allocator, io);
    } else if (std.mem.eql(u8, command, "deps")) {
        return deps_cmd.run(rest, allocator, io);
    } else if (std.mem.eql(u8, command, "update")) {
        return update_cmd.run(rest, allocator, io);
    } else if (std.mem.eql(u8, command, "version") or std.mem.eql(u8, command, "--version") or std.mem.eql(u8, command, "-v")) {
        printVersion(io);
    } else if (std.mem.eql(u8, command, "help") or std.mem.eql(u8, command, "--help") or std.mem.eql(u8, command, "-h")) {
        printUsage(io);
    } else {
        const stderr_file = std.Io.File.stderr();
        var buf: [256]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "Unknown command: {s}\n\n", .{command}) catch "Unknown command\n\n";
        stderr_file.writeStreamingAll(io, msg) catch {};
        printUsage(io);
    }
}

fn printVersion(io: std.Io) void {
    const stdout_file = std.Io.File.stdout();
    var buf: [64]u8 = undefined;
    const msg = std.fmt.bufPrint(&buf, "zzz v{s}\n", .{version}) catch "zzz\n";
    stdout_file.writeStreamingAll(io, msg) catch {};
}

fn printUsage(io: std.Io) void {
    const stdout_file = std.Io.File.stdout();
    stdout_file.writeStreamingAll(io,
        \\zzz - The Zig Web Framework CLI
        \\
        \\Usage: zzz <command> [options]
        \\
        \\Commands:
        \\  new <name> [options]    Create a new zzz project
        \\      --docker=false        Skip Docker file generation
        \\      --db=sqlite|postgres  Include database configuration
        \\      --full                Full project with controllers & middleware
        \\      --api                 API-only mode (no templates/static files)
        \\  server, s               Start the development server (with auto-reload)
        \\  routes                  List all application routes
        \\  gen controller <Name>   Generate a controller
        \\  gen model <Name> [fields...]  Generate a model + migration
        \\  gen channel <Name>      Generate a channel
        \\  migrate                 Run pending migrations
        \\  migrate rollback        Rollback the last migration
        \\  migrate status          Show migration status
        \\  swagger                 Export OpenAPI specification
        \\  test                    Run project tests
        \\  deps                    List workspace dependencies
        \\  update                  Update zzz CLI to the latest version
        \\  version                 Show version
        \\  help                    Show this help message
        \\
        \\Examples:
        \\  zzz new my_app
        \\  zzz server
        \\  zzz gen controller Users
        \\  zzz gen model Post title:string body:text user_id:integer
        \\  zzz migrate
        \\
    ) catch {};
}
