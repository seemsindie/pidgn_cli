const std = @import("std");
const pidgn = @import("pidgn");
const app_config = @import("app_config");

const Router = pidgn.Router;
const Context = pidgn.Context;

fn index(ctx: *Context) !void {
    ctx.html(.ok,
        \\<!DOCTYPE html>
        \\<html>
        \\<head><title>Welcome to Pidgn</title></head>
        \\<body>
        \\  <h1>Welcome to Pidgn!</h1>
        \\  <p>Your new project is ready.</p>
        \\</body>
        \\</html>
    );
}

const App = Router.define(.{
    .middleware = &.{
        pidgn.logger,
        pidgn.healthCheck(.{}),
    },
    .routes = &.{
        Router.get("/", index),
    },
});

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var env = try pidgn.Env.init(allocator, .{});
    defer env.deinit();

    const config = pidgn.mergeWithEnv(@TypeOf(app_config.config), app_config.config, &env);

    var server = pidgn.Server.init(allocator, .{
        .host = config.host,
        .port = config.port,
    }, App.handler);

    try server.listen(io);
}
