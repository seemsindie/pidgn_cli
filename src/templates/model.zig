/// Embedded templates for generating a model schema and migration.

pub fn generateSchema(name_lower: []const u8, name_upper: []const u8, fields_zig: []const u8, buf: []u8) ?[]const u8 {
    return std.fmt.bufPrint(buf,
        \\const schema = @import("pidgn_db").Schema;
        \\
        \\/// {0s} schema definition.
        \\pub const {0s} = struct {{
        \\    id: i64,
        \\{1s}    inserted_at: i64 = 0,
        \\    updated_at: i64 = 0,
        \\
        \\    pub const Meta = schema.define(@This(), .{{
        \\        .table = "{2s}",
        \\        .primary_key = "id",
        \\        .timestamps = true,
        \\    }});
        \\}};
        \\
    , .{ name_upper, fields_zig, name_lower }) catch null;
}

pub fn generateMigration(table_name: []const u8, columns_sql: []const u8, buf: []u8) ?[]const u8 {
    return std.fmt.bufPrint(buf,
        \\const MigrationContext = @import("pidgn_db").MigrationContext;
        \\
        \\pub fn up(ctx: *MigrationContext) !void {{
        \\    try ctx.createTable("{0s}", &.{{
        \\        .{{ .name = "id", .col_type = .integer, .primary_key = true, .auto_increment = true }},
        \\{1s}        .{{ .name = "inserted_at", .col_type = .bigint, .nullable = false }},
        \\        .{{ .name = "updated_at", .col_type = .bigint, .nullable = false }},
        \\    }});
        \\}}
        \\
        \\pub fn down(ctx: *MigrationContext) !void {{
        \\    try ctx.dropTable("{0s}");
        \\}}
        \\
    , .{ table_name, columns_sql }) catch null;
}

/// Map a CLI type string to a Zig type string.
pub fn zigType(type_str: []const u8) []const u8 {
    if (std.mem.eql(u8, type_str, "string") or std.mem.eql(u8, type_str, "text")) return "[]const u8";
    if (std.mem.eql(u8, type_str, "integer") or std.mem.eql(u8, type_str, "int")) return "i64";
    if (std.mem.eql(u8, type_str, "float") or std.mem.eql(u8, type_str, "real")) return "f64";
    if (std.mem.eql(u8, type_str, "boolean") or std.mem.eql(u8, type_str, "bool")) return "bool";
    return "[]const u8"; // default to text
}

/// Map a CLI type string to a SQL column type string.
pub fn sqlColumnType(type_str: []const u8) []const u8 {
    if (std.mem.eql(u8, type_str, "string") or std.mem.eql(u8, type_str, "text")) return ".text";
    if (std.mem.eql(u8, type_str, "integer") or std.mem.eql(u8, type_str, "int")) return ".bigint";
    if (std.mem.eql(u8, type_str, "float") or std.mem.eql(u8, type_str, "real")) return ".real";
    if (std.mem.eql(u8, type_str, "boolean") or std.mem.eql(u8, type_str, "bool")) return ".boolean";
    return ".text";
}

const std = @import("std");
