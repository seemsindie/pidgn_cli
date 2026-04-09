/// Shared application config struct.
/// Comptime defaults come from dev.zig / prod.zig (selected by `-Denv`).
/// Runtime overrides come from `.env` + system env via `pidgn.mergeWithEnv`.
pub const AppConfig = struct {
    host: []const u8 = "127.0.0.1",
    port: u16 = 4000,
    secret_key_base: []const u8 = "change-me-in-production",
    database_url: []const u8 = "",
};
