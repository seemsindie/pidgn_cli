const std = @import("std");
const pidgn = @import("pidgn");
const app_config = @import("app_config");

const Router = pidgn.Router;
const Context = pidgn.Context;
const home = @import("controllers/home.zig");
const api = @import("controllers/api.zig");

const App = Router.define(.{
    .middleware = &.{
        pidgn.errorHandler(.{}),
        pidgn.logger,
        pidgn.cors(.{}),
        pidgn.bodyParser,
        pidgn.session(.{}),
        pidgn.csrf(.{}),
        pidgn.staticFiles(.{}),
        pidgn.healthCheck(.{}),
    },
    .routes = &.{
        Router.get("/", home.index),
        Router.get("/api/status", api.status),
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
