/// Embedded template for generating a mailer module that uses @embedFile + zzz_template.

pub fn generate(name_lower: []const u8, name_upper: []const u8, buf: []u8) ?[]const u8 {
    return std.fmt.bufPrint(buf,
        \\const std = @import("std");
        \\const zzz_mailer = @import("zzz_mailer");
        \\const zzz_template = zzz_mailer.template;
        \\const Email = zzz_mailer.Email;
        \\const Address = zzz_mailer.Address;
        \\
        \\// {0s} Mailer (template-based)
        \\
        \\const HtmlTemplate = zzz_template.template(@embedFile("templates/{1s}.html.zzz"));
        \\const TextTemplate = zzz_template.template(@embedFile("templates/{1s}.txt.zzz"));
        \\
        \\/// Build a {0s} email using .zzz templates.
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
