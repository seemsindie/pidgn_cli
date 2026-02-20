const std = @import("std");
const Allocator = std.mem.Allocator;
const project_tmpl = @import("../templates/project.zig");

/// Project options parsed from CLI flags.
const ProjectOptions = struct {
    docker: bool = true,
    db: DbOption = .none,
    full: bool = false,
    api: bool = false,

    const DbOption = enum { none, sqlite, postgres };
};

/// `zzz new <name>` -- scaffold a new zzz project.
pub fn run(args: []const []const u8, _: Allocator, io: std.Io) void {
    const stdout_file = std.Io.File.stdout();
    const stderr_file = std.Io.File.stderr();

    // Parse flags and find project name
    var opts = ProjectOptions{};
    var name: ?[]const u8 = null;

    for (args) |arg| {
        if (parseFlag(arg, "docker")) |val| {
            opts.docker = std.mem.eql(u8, val, "true");
        } else if (parseFlag(arg, "db")) |val| {
            if (std.mem.eql(u8, val, "sqlite")) {
                opts.db = .sqlite;
            } else if (std.mem.eql(u8, val, "postgres") or std.mem.eql(u8, val, "pg")) {
                opts.db = .postgres;
            } else if (std.mem.eql(u8, val, "none")) {
                opts.db = .none;
            }
        } else if (std.mem.eql(u8, arg, "--full")) {
            opts.full = true;
        } else if (std.mem.eql(u8, arg, "--api")) {
            opts.api = true;
        } else if (arg.len > 0 and arg[0] != '-') {
            if (name == null) name = arg;
        }
    }

    if (name == null) {
        stderr_file.writeStreamingAll(io, "Usage: zzz new <project_name> [--docker=false] [--db=sqlite|postgres|none] [--full] [--api]\n") catch {};
        return;
    }

    const project_name = name.?;

    // Validate name
    for (project_name) |c| {
        if (!std.ascii.isAlphanumeric(c) and c != '_' and c != '-' and c != '.') {
            var err_buf: [256]u8 = undefined;
            const msg = std.fmt.bufPrint(&err_buf, "Invalid project name: '{s}'. Use only letters, numbers, underscores, hyphens, and dots.\n", .{project_name}) catch "Invalid project name.\n";
            stderr_file.writeStreamingAll(io, msg) catch {};
            return;
        }
    }

    // Create directory structure
    makeDir(project_name, io) catch |err| {
        var err_buf: [256]u8 = undefined;
        const msg = std.fmt.bufPrint(&err_buf, "Failed to create directory '{s}': {}\n", .{ project_name, err }) catch "Failed to create directory.\n";
        stderr_file.writeStreamingAll(io, msg) catch {};
        return;
    };
    makeDirPath(project_name, "src", io) catch return;
    makeDirPath(project_name, "src/controllers", io) catch return;
    makeDirPath(project_name, "config", io) catch return;

    // Skip templates/public dirs for --api mode
    if (!opts.api) {
        makeDirPath(project_name, "templates", io) catch return;
        makeDirPath(project_name, "public", io) catch return;
        makeDirPath(project_name, "public/css", io) catch return;
        makeDirPath(project_name, "public/js", io) catch return;
    }

    // Write build.zig (replace $NAME$ with actual name)
    writeTemplateWithName(project_name, "build.zig", project_tmpl.build_zig, io) catch return;

    // Write build.zig.zon
    var zon_buf: [2048]u8 = undefined;
    if (project_tmpl.buildZigZon(project_name, &zon_buf)) |content| {
        writeFilePath(project_name, "build.zig.zon", content, io) catch return;
    }

    // Write src/main.zig (choose template based on flags)
    if (opts.full) {
        writeFilePath(project_name, "src/main.zig", project_tmpl.main_zig_full, io) catch return;
    } else if (opts.api) {
        writeFilePath(project_name, "src/main.zig", project_tmpl.main_zig_api, io) catch return;
    } else {
        writeFilePath(project_name, "src/main.zig", project_tmpl.main_zig, io) catch return;
    }

    // Write config files — choose DB-aware variants when --db is set
    if (opts.db != .none) {
        writeFilePath(project_name, "config/config.zig", project_tmpl.config_zig_db, io) catch return;
        writeFilePath(project_name, "config/dev.zig", project_tmpl.config_dev_zig_db, io) catch return;
        writeFilePath(project_name, "config/prod.zig", project_tmpl.config_prod_zig_db, io) catch return;
        writeFilePath(project_name, "config/staging.zig", project_tmpl.config_staging_zig_db, io) catch return;
    } else {
        writeFilePath(project_name, "config/config.zig", project_tmpl.config_zig, io) catch return;
        writeFilePath(project_name, "config/dev.zig", project_tmpl.config_dev_zig, io) catch return;
        writeFilePath(project_name, "config/prod.zig", project_tmpl.config_prod_zig, io) catch return;
        writeFilePath(project_name, "config/staging.zig", project_tmpl.config_staging_zig, io) catch return;
    }

    // Write .env and .env.example — include DATABASE_URL when --db is set
    if (opts.db == .postgres) {
        writeFilePath(project_name, ".env", project_tmpl.dot_env_postgres, io) catch return;
        writeFilePath(project_name, ".env.example", project_tmpl.env_example_postgres, io) catch return;
    } else if (opts.db == .sqlite) {
        writeTemplateWithName(project_name, ".env", project_tmpl.dot_env_sqlite, io) catch return;
        writeTemplateWithName(project_name, ".env.example", project_tmpl.env_example_sqlite, io) catch return;
    } else {
        writeFilePath(project_name, ".env", project_tmpl.dot_env, io) catch return;
        writeFilePath(project_name, ".env.example", project_tmpl.env_example, io) catch return;
    }

    // Write .gitignore
    writeFilePath(project_name, ".gitignore", project_tmpl.gitignore, io) catch return;

    // Write static assets (skip for --api)
    if (!opts.api) {
        writeFilePath(project_name, "public/css/style.css", project_tmpl.style_css, io) catch return;
        writeFilePath(project_name, "public/js/app.js", "// Add your JavaScript here\n", io) catch return;
    }

    // Write controller files for --full mode
    if (opts.full) {
        writeFilePath(project_name, "src/controllers/home.zig", project_tmpl.home_controller_zig, io) catch return;
        writeFilePath(project_name, "src/controllers/api.zig", project_tmpl.api_controller_zig, io) catch return;
    }

    // Write Docker files (unless --docker=false)
    if (opts.docker) {
        writeTemplateWithName(project_name, "Dockerfile", project_tmpl.dockerfile, io) catch return;
        writeFilePath(project_name, ".dockerignore", project_tmpl.dockerignore, io) catch return;

        if (opts.db == .postgres) {
            writeTemplateWithName(project_name, "docker-compose.yml", project_tmpl.docker_compose_yml_postgres, io) catch return;
        } else {
            writeFilePath(project_name, "docker-compose.yml", project_tmpl.docker_compose_yml, io) catch return;
        }
    }

    var msg_buf: [512]u8 = undefined;
    const msg = std.fmt.bufPrint(&msg_buf,
        \\
        \\  Created new zzz project: {s}
        \\
        \\  To get started:
        \\    cd {s}
        \\    zig build run
        \\
        \\  Then visit http://127.0.0.1:4000
        \\
        \\  Use -Denv= to select config environment:
        \\    zig build run -Denv=prod
        \\
    , .{ project_name, project_name }) catch "  Project created.\n";
    stdout_file.writeStreamingAll(io, msg) catch {};
}

/// Parse a `--key=value` flag. Returns the value if the flag matches, null otherwise.
fn parseFlag(arg: []const u8, comptime key: []const u8) ?[]const u8 {
    const prefix = "--" ++ key ++ "=";
    if (std.mem.startsWith(u8, arg, prefix)) {
        return arg[prefix.len..];
    }
    return null;
}

/// Write a template file, replacing all occurrences of `$NAME$` with the project name.
fn writeTemplateWithName(base: []const u8, sub_path: []const u8, tmpl: []const u8, io: std.Io) !void {
    // Simple single-pass replacement of $NAME$ occurrences
    var out_buf: [8192]u8 = undefined;
    var pos: usize = 0;
    var src: []const u8 = tmpl;

    while (std.mem.indexOf(u8, src, "$NAME$")) |idx| {
        // Copy everything before $NAME$
        if (pos + idx > out_buf.len) return error.BufferTooSmall;
        @memcpy(out_buf[pos..][0..idx], src[0..idx]);
        pos += idx;
        // Copy the project name
        if (pos + base.len > out_buf.len) return error.BufferTooSmall;
        @memcpy(out_buf[pos..][0..base.len], base);
        pos += base.len;
        // Advance past $NAME$
        src = src[idx + 6 ..];
    }
    // Copy remainder
    if (pos + src.len > out_buf.len) return error.BufferTooSmall;
    @memcpy(out_buf[pos..][0..src.len], src);
    pos += src.len;

    writeFilePath(base, sub_path, out_buf[0..pos], io) catch |err| return err;
}

fn makeDir(name: []const u8, io: std.Io) !void {
    var path_buf: [512]u8 = undefined;
    const path = std.fmt.bufPrint(&path_buf, "{s}", .{name}) catch return error.NameTooLong;
    std.Io.Dir.cwd().createDir(io, path, .default_dir) catch |err| {
        return err;
    };
}

fn makeDirPath(base: []const u8, sub: []const u8, io: std.Io) !void {
    var path_buf: [512]u8 = undefined;
    const path = std.fmt.bufPrint(&path_buf, "{s}/{s}", .{ base, sub }) catch return error.NameTooLong;
    std.Io.Dir.cwd().createDirPath(io, path) catch |err| {
        return err;
    };
}

fn writeFilePath(base: []const u8, sub_path: []const u8, content: []const u8, io: std.Io) !void {
    var path_buf: [512]u8 = undefined;
    const path = std.fmt.bufPrint(&path_buf, "{s}/{s}", .{ base, sub_path }) catch return error.NameTooLong;
    const file = std.Io.Dir.cwd().createFile(io, path, .{}) catch |err| {
        return err;
    };
    defer file.close(io);
    file.writeStreamingAll(io, content) catch |err| {
        return err;
    };
}
