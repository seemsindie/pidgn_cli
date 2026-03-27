# pidgn_cli

Command-line tool for the pidgn web framework.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Zig](https://img.shields.io/badge/Zig-0.16.0-orange.svg)](https://ziglang.org/)

Project scaffolding, code generation, development server, database migrations, and more. A single binary that handles the full development workflow for pidgn applications.

## Installation

### Shell installer (macOS and Linux)

```bash
curl -fsSL https://pidgn.dev/install.sh | sh
```

Install a specific version:

```bash
PIDGN_VERSION=v0.1.0 curl -fsSL https://pidgn.dev/install.sh | sh
```

### Homebrew (macOS)

```bash
brew tap seemsindie/pidgn
brew install pidgn
```

### Download from GitHub Releases

Pre-built binaries for macOS (arm64, x86_64) and Linux (x86_64, aarch64) are available on the [Releases](https://github.com/seemsindie/pidgn_cli/releases) page.

### Build from source

```bash
cd pidgn_cli
zig build
# Binary at zig-out/bin/pidgn
```

## Commands

### `pidgn new <name>`

Create a new pidgn project with full directory structure.

```bash
pidgn new my_app
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

### `pidgn server` (alias: `pidgn s`)

Start a development server with auto-reload on file changes.

```bash
pidgn server
# Building...
# Server running. Watching for changes... (Ctrl+C to stop)
```

### `pidgn gen controller <Name>`

Generate a RESTful controller with index, show, create, update, and delete actions.

```bash
pidgn gen controller Users
# Created: src/controllers/users.zig
```

### `pidgn gen model <Name> [field:type ...]`

Generate a database model schema and migration file.

```bash
pidgn gen model Post title:string body:text user_id:integer published:boolean
# Created: src/post.zig
# Created: priv/migrations/001_create_post.zig
```

Supported types: `string`, `text`, `integer`/`int`, `float`/`real`, `boolean`/`bool`

### `pidgn gen channel <Name>`

Generate a WebSocket channel for real-time communication.

```bash
pidgn gen channel Chat
# Created: src/channels/chat.zig
```

### `pidgn migrate`

Run database migrations.

```bash
pidgn migrate            # Run pending migrations
pidgn migrate rollback   # Rollback last migration
pidgn migrate status     # Show migration status
```

### `pidgn routes`

List all application routes.

```bash
pidgn routes
```

### `pidgn swagger`

Export the OpenAPI specification.

```bash
pidgn swagger > api.json
```

### `pidgn test`

Run project tests.

```bash
pidgn test
```

### `pidgn deps`

List workspace dependencies.

```bash
pidgn deps
```

### `pidgn assets`

Manage the frontend asset pipeline using Bun.

```bash
pidgn assets setup           # Generate starter assets (app.js, app.css, bunfig.toml)
pidgn assets setup --ssr     # Also generate SSR worker and example component
pidgn assets build           # Bundle, minify, and fingerprint assets
pidgn assets watch           # Watch and rebuild on changes
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

### `pidgn version`

Show version.

```bash
pidgn version    # 0.1.0
```

## Workflow Example

```bash
pidgn new blog
cd blog
pidgn gen model Post title:string content:text published:boolean
pidgn gen controller Posts
pidgn gen channel Comments
pidgn assets setup
pidgn migrate
pidgn server
```

## Documentation

Full documentation available at [docs.pidgn.dev](https://docs.pidgn.dev) under the CLI section.

## Ecosystem

| Package | Description |
|---------|-------------|
| [pidgn.zig](https://github.com/seemsindie/pidgn) | Core web framework |
| [pidgn_db](https://github.com/seemsindie/pidgn_db) | Database ORM (SQLite + PostgreSQL) |
| [pidgn_jobs](https://github.com/seemsindie/pidgn_jobs) | Background job processing |
| [pidgn_mailer](https://github.com/seemsindie/pidgn_mailer) | Email sending |
| [pidgn_template](https://github.com/seemsindie/pidgn_template) | Template engine |
| [pidgn_cli](https://github.com/seemsindie/pidgn_cli) | CLI tooling |

## Requirements

- Zig 0.16.0-dev.2535+b5bd49460 or later

## License

MIT License -- Copyright (c) 2026 Ivan Stamenkovic
