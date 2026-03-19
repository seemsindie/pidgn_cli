# zzz_cli

Command-line tool for the zzz web framework.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Zig](https://img.shields.io/badge/Zig-0.16.0-orange.svg)](https://ziglang.org/)

Project scaffolding, code generation, development server, database migrations, and more. A single binary that handles the full development workflow for zzz applications.

## Installation

### Shell installer (macOS and Linux)

```bash
curl -fsSL https://zzz.indielab.link/install.sh | sh
```

Install a specific version:

```bash
ZZZ_VERSION=v0.1.0 curl -fsSL https://zzz.indielab.link/install.sh | sh
```

### Homebrew (macOS)

```bash
brew tap seemsindie/zzz
brew install zzz
```

### Download from GitHub Releases

Pre-built binaries for macOS (arm64, x86_64) and Linux (x86_64, aarch64) are available on the [Releases](https://github.com/seemsindie/zzz_cli/releases) page.

### Build from source

```bash
cd zzz_cli
zig build
# Binary at zig-out/bin/zzz
```

## Commands

### `zzz new <name>`

Create a new zzz project with full directory structure.

```bash
zzz new my_app
cd my_app
zig build run
# Server running on http://127.0.0.1:4000
```

Creates:
```
my_app/
  build.zig
  build.zig.zon
  .gitignore
  src/
    main.zig
    controllers/
  templates/
  public/
    css/style.css
    js/app.js
```

### `zzz server` (alias: `zzz s`)

Start a development server with auto-reload on file changes.

```bash
zzz server
# Building...
# Server running. Watching for changes... (Ctrl+C to stop)
```

### `zzz gen controller <Name>`

Generate a RESTful controller with index, show, create, update, and delete actions.

```bash
zzz gen controller Users
# Created: src/controllers/users.zig
```

### `zzz gen model <Name> [field:type ...]`

Generate a database model schema and migration file.

```bash
zzz gen model Post title:string body:text user_id:integer published:boolean
# Created: src/post.zig
# Created: priv/migrations/001_create_post.zig
```

Supported types: `string`, `text`, `integer`/`int`, `float`/`real`, `boolean`/`bool`

### `zzz gen channel <Name>`

Generate a WebSocket channel for real-time communication.

```bash
zzz gen channel Chat
# Created: src/channels/chat.zig
```

### `zzz migrate`

Run database migrations.

```bash
zzz migrate            # Run pending migrations
zzz migrate rollback   # Rollback last migration
zzz migrate status     # Show migration status
```

### `zzz routes`

List all application routes.

```bash
zzz routes
```

### `zzz swagger`

Export the OpenAPI specification.

```bash
zzz swagger > api.json
```

### `zzz test`

Run project tests.

```bash
zzz test
```

### `zzz deps`

List workspace dependencies.

```bash
zzz deps
```

### `zzz assets`

Manage the frontend asset pipeline using Bun.

```bash
zzz assets setup           # Generate starter assets (app.js, app.css, bunfig.toml)
zzz assets setup --ssr     # Also generate SSR worker and example component
zzz assets build           # Bundle, minify, and fingerprint assets
zzz assets watch           # Watch and rebuild on changes
```

Creates:
```
assets/
  app.js                   # JavaScript entry point
  app.css                  # Stylesheet
public/assets/
  app-<hash>.js            # Fingerprinted output
  app-<hash>.css
  assets-manifest.json     # Original → fingerprinted name mapping
```

### `zzz version`

Show version.

```bash
zzz version    # 0.1.0
```

## Workflow Example

```bash
zzz new blog
cd blog
zzz gen model Post title:string content:text published:boolean
zzz gen controller Posts
zzz gen channel Comments
zzz assets setup
zzz migrate
zzz server
```

## Documentation

Full documentation available at [docs.zzz.indielab.link](https://docs.zzz.indielab.link) under the CLI section.

## Ecosystem

| Package | Description |
|---------|-------------|
| [zzz.zig](https://github.com/seemsindie/zzz.zig) | Core web framework |
| [zzz_db](https://github.com/seemsindie/zzz_db) | Database ORM (SQLite + PostgreSQL) |
| [zzz_jobs](https://github.com/seemsindie/zzz_jobs) | Background job processing |
| [zzz_mailer](https://github.com/seemsindie/zzz_mailer) | Email sending |
| [zzz_template](https://github.com/seemsindie/zzz_template) | Template engine |
| [zzz_cli](https://github.com/seemsindie/zzz_cli) | CLI tooling |

## Requirements

- Zig 0.16.0-dev.2535+b5bd49460 or later

## License

MIT License -- Copyright (c) 2026 Ivan Stamenkovic
