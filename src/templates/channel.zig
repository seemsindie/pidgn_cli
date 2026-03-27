/// Embedded template for generating a channel.

pub fn generate(name_lower: []const u8, name_upper: []const u8, buf: []u8) ?[]const u8 {
    return std.fmt.bufPrint(buf,
        \\const std = @import("std");
        \\const pidgn = @import("pidgn");
        \\const Socket = pidgn.Socket;
        \\const ChannelDef = pidgn.ChannelDef;
        \\const JoinResult = pidgn.JoinResult;
        \\
        \\// {0s} Channel
        \\
        \\fn handleJoin(socket: *Socket, topic: []const u8, _payload: []const u8) JoinResult {{
        \\    _ = socket;
        \\    _ = topic;
        \\    return .ok;
        \\}}
        \\
        \\fn handleNewMessage(socket: *Socket, topic: []const u8, _event: []const u8, payload: []const u8) void {{
        \\    socket.broadcast(topic, "new_msg", payload);
        \\}}
        \\
        \\pub const channel = ChannelDef{{
        \\    .topic_pattern = "{1s}:*",
        \\    .join = &handleJoin,
        \\    .handlers = &.{{
        \\        .{{ .event = "new_msg", .handler = &handleNewMessage }},
        \\    }},
        \\}};
        \\
    , .{ name_upper, name_lower }) catch null;
}

const std = @import("std");
