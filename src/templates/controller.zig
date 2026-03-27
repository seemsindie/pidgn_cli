/// Embedded template for generating a controller.

pub fn generate(name_lower: []const u8, name_upper: []const u8, buf: []u8) ?[]const u8 {
    return std.fmt.bufPrint(buf,
        \\const std = @import("std");
        \\const pidgn = @import("pidgn");
        \\const Context = pidgn.Context;
        \\const Router = pidgn.Router;
        \\
        \\// {0s} Controller
        \\
        \\pub fn index(ctx: *Context) !void {{
        \\    ctx.json(.ok, "{{\"message\":\"{1s} index\"}}");
        \\}}
        \\
        \\pub fn show(ctx: *Context) !void {{
        \\    const id = ctx.param("id") orelse "unknown";
        \\    _ = id;
        \\    ctx.json(.ok, "{{\"message\":\"{0s} show\"}}");
        \\}}
        \\
        \\pub fn create(ctx: *Context) !void {{
        \\    ctx.json(.created, "{{\"message\":\"{0s} created\"}}");
        \\}}
        \\
        \\pub fn update(ctx: *Context) !void {{
        \\    ctx.json(.ok, "{{\"message\":\"{0s} updated\"}}");
        \\}}
        \\
        \\pub fn delete_handler(ctx: *Context) !void {{
        \\    ctx.json(.ok, "{{\"message\":\"{0s} deleted\"}}");
        \\}}
        \\
        \\pub const routes = Router.resource("/{1s}", .{{
        \\    .index = index,
        \\    .show = show,
        \\    .create = create,
        \\    .update = update,
        \\    .delete_handler = delete_handler,
        \\}});
        \\
    , .{ name_upper, name_lower }) catch null;
}

const std = @import("std");
