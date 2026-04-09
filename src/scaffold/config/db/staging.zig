const AppConfig = @import("config").AppConfig;

/// Staging defaults — production-like with verbose logging.
pub const config: AppConfig = .{
    .host = "0.0.0.0",
    .port = 8080,
    .secret_key_base = "MUST-BE-SET-VIA-ENV",
    .database_url = "MUST-BE-SET-VIA-ENV",
};
