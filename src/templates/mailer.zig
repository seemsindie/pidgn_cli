/// Embedded template for generating a mailer module.

pub fn generate(name_lower: []const u8, name_upper: []const u8, buf: []u8) ?[]const u8 {
    return std.fmt.bufPrint(buf,
        \\const std = @import("std");
        \\const pidgn_mailer = @import("pidgn_mailer");
        \\const Email = pidgn_mailer.Email;
        \\const Address = pidgn_mailer.Address;
        \\
        \\// {0s} Mailer
        \\
        \\/// Build a {0s} email.
        \\pub fn build(to: Address, data: anytype) Email {{
        \\    _ = data;
        \\    return Email{{
        \\        .from = .{{ .email = "noreply@example.com", .name = "My App" }},
        \\        .to = &.{{to}},
        \\        .subject = "{0s}",
        \\        .text_body = textBody(),
        \\        .html_body = htmlBody(),
        \\    }};
        \\}}
        \\
        \\/// Plain-text body template for {0s} emails.
        \\fn textBody() []const u8 {{
        \\    return
        \\        \\Hi,
        \\        \\
        \\        \\This is the {1s} email.
        \\        \\
        \\        \\Thanks,
        \\        \\The Team
        \\    ;
        \\}}
        \\
        \\/// HTML body template for {0s} emails.
        \\fn htmlBody() []const u8 {{
        \\    return
        \\        \\<!DOCTYPE html>
        \\        \\<html>
        \\        \\<body style="font-family: sans-serif; max-width: 600px; margin: 0 auto;">
        \\        \\  <h1>{0s}</h1>
        \\        \\  <p>Hi,</p>
        \\        \\  <p>This is the {1s} email.</p>
        \\        \\  <p>Thanks,<br>The Team</p>
        \\        \\</body>
        \\        \\</html>
        \\    ;
        \\}}
        \\
    , .{ name_upper, name_lower }) catch null;
}

const std = @import("std");
