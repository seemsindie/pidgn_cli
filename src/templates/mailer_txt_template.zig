/// Generates .txt.pidgn template content for a mailer.

pub fn generate(name_upper: []const u8, buf: []u8) ?[]const u8 {
    return std.fmt.bufPrint(buf,
        \\{{{{subject}}}}
        \\
        \\{{{{greeting}}}}
        \\
        \\{{{{body}}}}
        \\
        \\Thanks,
        \\The {0s} Team
        \\
    , .{name_upper}) catch null;
}

const std = @import("std");
