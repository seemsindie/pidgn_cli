const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const env_name = b.option([]const u8, "env", "Environment: dev (default), prod, staging") orelse "dev";

    const pidgn_dep = b.dependency("pidgn", .{ .target = target, .optimize = optimize });
    const pidgn_mod = pidgn_dep.module("pidgn");

    // Build config path from -Denv option
    var config_path_buf: [64]u8 = undefined;
    const config_path = std.fmt.bufPrint(&config_path_buf, "config/{s}.zig", .{env_name}) catch "config/dev.zig";

    const config_mod = b.createModule(.{
        .root_source_file = b.path("config/config.zig"),
        .target = target,
    });

    const app_config_mod = b.createModule(.{
        .root_source_file = b.path(config_path),
        .target = target,
    });
    app_config_mod.addImport("config", config_mod);

    const exe = b.addExecutable(.{
        .name = "$NAME$",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "pidgn", .module = pidgn_mod },
                .{ .name = "app_config", .module = app_config_mod },
            },
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const test_step = b.step("test", "Run tests");
    const tests = b.addTest(.{ .root_module = exe.root_module });
    test_step.dependOn(&b.addRunArtifact(tests).step);
}
