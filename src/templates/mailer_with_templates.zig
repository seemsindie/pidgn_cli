/// Embedded template for generating a mailer module that uses @embedFile + pidgn_template.

pub fn generate(name_lower: []const u8, name_upper: []const u8, buf: []u8) ?[]const u8 {
    return std.fmt.bufPrint(buf,
        \\const std = @import("std");
        \\const pidgn_mailer = @import("pidgn_mailer");
        \\const pidgn_template = pidgn_mailer.template;
        \\const Email = pidgn_mailer.Email;
        \\const Address = pidgn_mailer.Address;
        \\
        \\// {0s} Mailer (template-based)
        \\
        \\const HtmlTemplate = pidgn_template.template(@embedFile("templates/{1s}.html.pidgn"));
        \\const TextTemplate = pidgn_template.template(@embedFile("templates/{1s}.txt.pidgn"));
        \\
        \\/// Build a {0s} email using .pidgn templates.
        \\pub fn build(allocator: std.mem.Allocator, to: Address, data: anytype) !Email {{
        \\    return Email{{
        \\        .from = .{{ .email = "noreply@example.com", .name = "My App" }},
        \\        .to = &.{{to}},
        \\        .subject = "{0s}",
        \\        .text_body = try TextTemplate.render(allocator, data),
        \\        .html_body = try HtmlTemplate.render(allocator, data),
        \\    }};
        \\}}
        \\
    , .{ name_upper, name_lower }) catch null;
}

const std = @import("std");
