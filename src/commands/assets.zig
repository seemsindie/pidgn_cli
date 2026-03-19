const std = @import("std");
const Allocator = std.mem.Allocator;

extern "c" fn system(command: [*:0]const u8) c_int;

pub fn run(args: []const []const u8, allocator: Allocator, io: std.Io) !void {
    const stdout = std.Io.File.stdout();

    if (args.len == 0) {
        printUsage(io);
        return;
    }

    const subcmd = args[0];

    if (std.mem.eql(u8, subcmd, "setup")) {
        try setup(allocator, io, args[1..]);
    } else if (std.mem.eql(u8, subcmd, "build")) {
        try build(allocator, io);
    } else if (std.mem.eql(u8, subcmd, "watch")) {
        try watch(allocator, io);
    } else {
        stdout.writeStreamingAll(io, "Unknown assets subcommand: ") catch {};
        stdout.writeStreamingAll(io, subcmd) catch {};
        stdout.writeStreamingAll(io, "\n\n") catch {};
        printUsage(io);
    }
}

fn setup(allocator: Allocator, io: std.Io, args: []const []const u8) !void {
    const stdout = std.Io.File.stdout();
    var with_ssr = false;
    for (args) |arg| {
        if (std.mem.eql(u8, arg, "--ssr")) with_ssr = true;
    }

    // Create directory structure
    makeDirIfNotExists("assets");
    makeDirIfNotExists("public");
    makeDirIfNotExists("public/assets");

    // Write starter files
    writeFileIfNotExists("assets/app.js", app_js_content);
    writeFileIfNotExists("assets/app.css", app_css_content);
    writeFileIfNotExists("bunfig.toml", bunfig_content);

    if (with_ssr) {
        writeFileIfNotExists("package.json", package_json_ssr_content);
    } else {
        writeFileIfNotExists("package.json", package_json_content);
    }

    stdout.writeStreamingAll(io, "Created assets/ directory structure\n") catch {};
    stdout.writeStreamingAll(io, "  assets/app.js\n") catch {};
    stdout.writeStreamingAll(io, "  assets/app.css\n") catch {};
    stdout.writeStreamingAll(io, "  bunfig.toml\n") catch {};
    stdout.writeStreamingAll(io, "  package.json\n") catch {};

    if (with_ssr) {
        makeDirIfNotExists("assets/components");
        writeFileIfNotExists("assets/ssr-worker.js", ssr_worker_content);
        writeFileIfNotExists("assets/components/App.jsx", app_component_content);
        stdout.writeStreamingAll(io, "  assets/ssr-worker.js\n") catch {};
        stdout.writeStreamingAll(io, "  assets/components/App.jsx\n") catch {};
    }

    stdout.writeStreamingAll(io, "\nInstalling dependencies...\n") catch {};
    const install_result = runProcess(allocator, &.{ "bun", "install" });
    if (install_result) |exit_code| {
        if (exit_code == 0) {
            stdout.writeStreamingAll(io, "Dependencies installed.\n") catch {};
        } else {
            stdout.writeStreamingAll(io, "Failed to run bun install. Run 'bun install' manually.\n") catch {};
        }
    } else |_| {
        stdout.writeStreamingAll(io, "Failed to run bun install. Run 'bun install' manually.\n") catch {};
    }

    stdout.writeStreamingAll(io, "\nRun 'zzz assets build' to compile assets.\n") catch {};
    stdout.writeStreamingAll(io, "Don't forget to add node_modules/ to .gitignore\n") catch {};
}

fn build(allocator: Allocator, io: std.Io) !void {
    const stdout = std.Io.File.stdout();

    stdout.writeStreamingAll(io, "Building assets...\n") catch {};

    // Build JS
    const js_result = runProcess(allocator, &.{ "bun", "build", "assets/app.js", "--outdir", "public/assets", "--minify" });
    if (js_result) |exit_code| {
        if (exit_code != 0) {
            stdout.writeStreamingAll(io, "JS build failed\n") catch {};
            return;
        }
    } else |_| {
        stdout.writeStreamingAll(io, "Failed to run bun. Is bun installed?\n") catch {};
        return;
    }

    // Build CSS (copy for now — Bun handles CSS via JS imports or we can use a separate step)
    copyFile("assets/app.css", "public/assets/app.css");

    // Generate asset manifest with fingerprints
    generateManifest(allocator, io);

    stdout.writeStreamingAll(io, "Assets built to public/assets/\n") catch {};
}

fn watch(allocator: Allocator, io: std.Io) !void {
    const stdout = std.Io.File.stdout();

    stdout.writeStreamingAll(io, "Watching assets for changes...\n") catch {};
    stdout.writeStreamingAll(io, "Press Ctrl+C to stop.\n") catch {};

    const result = runProcess(allocator, &.{ "bun", "build", "assets/app.js", "--outdir", "public/assets", "--watch" });
    if (result) |exit_code| {
        _ = exit_code;
    } else |_| {
        stdout.writeStreamingAll(io, "Failed to run bun. Is bun installed?\n") catch {};
    }
}

fn generateManifest(allocator: Allocator, io: std.Io) void {
    const stdout = std.Io.File.stdout();
    _ = allocator;

    // Read app.js output and compute a simple hash for fingerprinting
    const js_hash = hashFile("public/assets/app.js");
    const css_hash = hashFile("public/assets/app.css");

    // Write manifest
    var manifest_buf: [1024]u8 = undefined;
    const manifest = std.fmt.bufPrint(&manifest_buf,
        \\{{
        \\  "app.js": "app-{x:0>8}.js",
        \\  "app.css": "app-{x:0>8}.css"
        \\}}
        \\
    , .{ js_hash, css_hash }) catch return;

    writeFileAlways("public/assets/assets-manifest.json", manifest);

    // Create fingerprinted copies
    var js_name_buf: [64]u8 = undefined;
    const js_name = std.fmt.bufPrint(&js_name_buf, "public/assets/app-{x:0>8}.js", .{js_hash}) catch return;
    copyFile("public/assets/app.js", js_name);

    var css_name_buf: [64]u8 = undefined;
    const css_name = std.fmt.bufPrint(&css_name_buf, "public/assets/app-{x:0>8}.css", .{css_hash}) catch return;
    copyFile("public/assets/app.css", css_name);

    stdout.writeStreamingAll(io, "Generated assets-manifest.json\n") catch {};
}

fn hashFile(path: []const u8) u32 {
    const c = std.c;

    // Create null-terminated path
    var path_buf: [256]u8 = undefined;
    if (path.len >= path_buf.len) return 0;
    @memcpy(path_buf[0..path.len], path);
    path_buf[path.len] = 0;

    const fd = c.open(@ptrCast(path_buf[0..path.len :0]), .{}, @as(c.mode_t, 0));
    if (fd < 0) return 0;
    defer _ = c.close(fd);

    var hash: u32 = 0x811c9dc5; // FNV-1a offset basis
    var buf: [4096]u8 = undefined;
    while (true) {
        const n = c.read(fd, &buf, buf.len);
        if (n <= 0) break;
        const bytes_read: usize = @intCast(n);
        for (buf[0..bytes_read]) |byte| {
            hash ^= byte;
            hash *%= 0x01000193;
        }
    }
    return hash;
}

fn runProcess(allocator: Allocator, argv: []const []const u8) !u8 {
    _ = allocator;
    // Use std.c to spawn process via system()
    // Build command string
    var cmd_buf: [1024]u8 = undefined;
    var pos: usize = 0;
    for (argv, 0..) |arg, i| {
        if (i > 0) {
            cmd_buf[pos] = ' ';
            pos += 1;
        }
        if (pos + arg.len >= cmd_buf.len) return error.CommandTooLong;
        @memcpy(cmd_buf[pos..][0..arg.len], arg);
        pos += arg.len;
    }
    cmd_buf[pos] = 0;

    const ret = system(@ptrCast(cmd_buf[0..pos :0]));
    return @intCast(@as(u32, @bitCast(ret)) >> 8);
}

fn makeDirIfNotExists(path: []const u8) void {
    const c = std.c;
    var buf: [256]u8 = undefined;
    if (path.len >= buf.len) return;
    @memcpy(buf[0..path.len], path);
    buf[path.len] = 0;
    _ = c.mkdir(@ptrCast(buf[0..path.len :0]), 0o755);
}

fn writeFileIfNotExists(path: []const u8, content: []const u8) void {
    const c = std.c;
    var buf: [256]u8 = undefined;
    if (path.len >= buf.len) return;
    @memcpy(buf[0..path.len], path);
    buf[path.len] = 0;

    // Try to open for reading first — if it exists, skip
    const fd_check = c.open(@ptrCast(buf[0..path.len :0]), .{}, @as(c.mode_t, 0));
    if (fd_check >= 0) {
        _ = c.close(fd_check);
        return; // File exists, don't overwrite
    }

    writeFileAlways(path, content);
}

fn writeFileAlways(path: []const u8, content: []const u8) void {
    const c = std.c;
    var buf: [256]u8 = undefined;
    if (path.len >= buf.len) return;
    @memcpy(buf[0..path.len], path);
    buf[path.len] = 0;

    const fd = c.open(@ptrCast(buf[0..path.len :0]), .{ .ACCMODE = .WRONLY, .CREAT = true, .TRUNC = true }, @as(c.mode_t, 0o644));
    if (fd < 0) return;
    defer _ = c.close(fd);

    var written: usize = 0;
    while (written < content.len) {
        const n = c.write(fd, content[written..].ptr, content.len - written);
        if (n <= 0) break;
        written += @intCast(n);
    }
}

fn copyFile(src: []const u8, dst: []const u8) void {
    const c = std.c;

    var src_buf: [256]u8 = undefined;
    if (src.len >= src_buf.len) return;
    @memcpy(src_buf[0..src.len], src);
    src_buf[src.len] = 0;

    const src_fd = c.open(@ptrCast(src_buf[0..src.len :0]), .{}, @as(c.mode_t, 0));
    if (src_fd < 0) return;
    defer _ = c.close(src_fd);

    var dst_buf: [256]u8 = undefined;
    if (dst.len >= dst_buf.len) return;
    @memcpy(dst_buf[0..dst.len], dst);
    dst_buf[dst.len] = 0;

    const dst_fd = c.open(@ptrCast(dst_buf[0..dst.len :0]), .{ .ACCMODE = .WRONLY, .CREAT = true, .TRUNC = true }, @as(c.mode_t, 0o644));
    if (dst_fd < 0) return;
    defer _ = c.close(dst_fd);

    var buf: [8192]u8 = undefined;
    while (true) {
        const n = c.read(src_fd, &buf, buf.len);
        if (n <= 0) break;
        const bytes_read: usize = @intCast(n);
        var written: usize = 0;
        while (written < bytes_read) {
            const w = c.write(dst_fd, buf[written..].ptr, bytes_read - written);
            if (w <= 0) return;
            written += @intCast(w);
        }
    }
}

fn printUsage(io: std.Io) void {
    const stdout = std.Io.File.stdout();
    stdout.writeStreamingAll(io,
        \\Usage: zzz assets <command>
        \\
        \\Commands:
        \\  setup [--ssr]   Generate starter asset files
        \\  build           Build and fingerprint assets using Bun
        \\  watch           Watch and rebuild assets on change
        \\
    ) catch {};
}

// ── Template content ──

const app_js_content =
    \\// assets/app.js — Main JavaScript entry point
    \\// Bundled by Bun via `zzz assets build`
    \\
    \\console.log("zzz app loaded");
    \\
;

const app_css_content =
    \\/* assets/app.css — Main stylesheet */
    \\
    \\*, *::before, *::after {
    \\  box-sizing: border-box;
    \\}
    \\
    \\body {
    \\  margin: 0;
    \\  font-family: system-ui, -apple-system, sans-serif;
    \\  line-height: 1.5;
    \\}
    \\
;

const bunfig_content =
    \\[build]
    \\target = "browser"
    \\minify = true
    \\
;

const ssr_worker_content =
    \\// SSR Worker — reads JSON from stdin, renders components, writes HTML to stdout
    \\import { renderToString } from "react-dom/server";
    \\import { createElement } from "react";
    \\
    \\const components = {};
    \\
    \\// Dynamic component loader
    \\async function loadComponent(name) {
    \\  if (!components[name]) {
    \\    components[name] = (await import(`./components/${name}.jsx`)).default;
    \\  }
    \\  return components[name];
    \\}
    \\
    \\// Read stdin line by line
    \\const decoder = new TextDecoder();
    \\for await (const chunk of Bun.stdin.stream()) {
    \\  const lines = decoder.decode(chunk).split("\n").filter(Boolean);
    \\  for (const line of lines) {
    \\    try {
    \\      const { component, props } = JSON.parse(line);
    \\      const Component = await loadComponent(component);
    \\      const html = renderToString(createElement(Component, props));
    \\      process.stdout.write(html + "\n---END---\n");
    \\    } catch (err) {
    \\      process.stdout.write(`<div>SSR Error: ${err.message}</div>\n---END---\n`);
    \\    }
    \\  }
    \\}
    \\
;

const app_component_content =
    \\// Example React component for SSR
    \\export default function App({ title, message }) {
    \\  return (
    \\    <div>
    \\      <h1>{title}</h1>
    \\      <p>{message}</p>
    \\    </div>
    \\  );
    \\}
    \\
;

const package_json_content =
    \\{
    \\  "name": "app",
    \\  "private": true,
    \\  "scripts": {
    \\    "build": "bun build assets/app.js --outdir public/assets --minify",
    \\    "watch": "bun build assets/app.js --outdir public/assets --watch"
    \\  }
    \\}
    \\
;

const package_json_ssr_content =
    \\{
    \\  "name": "app",
    \\  "private": true,
    \\  "scripts": {
    \\    "build": "bun build assets/app.js --outdir public/assets --minify",
    \\    "watch": "bun build assets/app.js --outdir public/assets --watch"
    \\  },
    \\  "dependencies": {
    \\    "react": "^19.0.0",
    \\    "react-dom": "^19.0.0"
    \\  }
    \\}
    \\
;
