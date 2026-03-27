/// Generates .html.pidgn template content for a mailer.

pub fn generate(name_upper: []const u8, buf: []u8) ?[]const u8 {
    return std.fmt.bufPrint(buf,
        \\<!DOCTYPE html>
        \\<html>
        \\<body style="font-family: sans-serif; max-width: 600px; margin: 0 auto;">
        \\  <h1>{{{{subject}}}}</h1>
        \\  <p>{{{{greeting}}}}</p>
        \\  <p>{{{{body}}}}</p>
        \\  <p>Thanks,<br>The {0s} Team</p>
        \\</body>
        \\</html>
        \\
    , .{name_upper}) catch null;
}

const std = @import("std");
