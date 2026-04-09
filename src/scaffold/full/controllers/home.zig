const pidgn = @import("pidgn");
const Context = pidgn.Context;

pub fn index(ctx: *Context) !void {
    ctx.html(.ok,
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <title>Welcome to Pidgn</title>
        \\  <link rel="stylesheet" href="/css/style.css">
        \\</head>
        \\<body>
        \\  <h1>Welcome to Pidgn!</h1>
        \\  <p>Your new project is ready.</p>
        \\</body>
        \\</html>
    );
}
