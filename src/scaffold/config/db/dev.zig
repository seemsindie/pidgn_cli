const AppConfig = @import("config").AppConfig;

/// Development defaults.
pub const config: AppConfig = .{
    .host = "127.0.0.1",
    .port = 4000,
    .secret_key_base = "dev-secret-not-for-production",
    .database_url = "sqlite:dev.db",
};
