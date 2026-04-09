const pidgn = @import("pidgn");
const Context = pidgn.Context;

const LayoutTemplate = pidgn.template(@embedFile("../templates/layout.html.pidgn"));
const HomeContent = pidgn.template(@embedFile("../templates/home.html.pidgn"));

pub fn index(ctx: *Context) !void {
    try ctx.renderWithLayout(LayoutTemplate, HomeContent, .ok, .{
        .title = "Welcome to Pidgn",
    });
}
