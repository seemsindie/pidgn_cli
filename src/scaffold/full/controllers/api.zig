const pidgn = @import("pidgn");
const Context = pidgn.Context;

pub fn status(ctx: *Context) !void {
    ctx.json(.ok, "{\"status\":\"ok\"}");
}
