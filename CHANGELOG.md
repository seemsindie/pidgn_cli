# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-03-19

### Added
- `zzz assets setup` - generate starter asset files (JS, CSS, bunfig.toml)
- `zzz assets setup --ssr` - generate SSR worker script and example React component
- `zzz assets build` - bundle, minify, and fingerprint assets via Bun
- `zzz assets watch` - watch mode for asset rebuilding

## [0.1.0] - 2026-02-16

### Added
- `zzz new` - project scaffolding with full directory structure
- `zzz server` - development server with auto-reload
- `zzz gen controller` - RESTful controller generation
- `zzz gen model` - database model and migration generation
- `zzz gen channel` - WebSocket channel generation
- `zzz migrate` - database migration management (up, rollback, status)
- `zzz routes` - list application routes
- `zzz swagger` - export OpenAPI specification
- `zzz test` - run project tests
- `zzz deps` - list workspace dependencies
