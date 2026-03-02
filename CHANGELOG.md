# Changelog

## v1.0.0 — 2026-03-02

Initial release.

### Features

- **Persistent semantic memory** — PostgreSQL + pgvector backend; memories survive session compaction
- **Three scripts** — `setup.py`, `write_memory.py`, `query_memory.py`
- **Wizard** — interactive setup with Docker detection/install, DB provisioning, embedding provider config, AGENTS.md scaffolding, cron setup
- **Migrations** — versioned SQL files with checksum verification, rollback support, idempotent on existing schemas
- **Decay + reinforcement** — relevance scores decay by category/importance, boosted by access frequency; archive not delete
- **Doctor** — full system health check including dimension mismatch detection, index health, cap warnings
- **Validate** — config pre-flight, no DB connection needed
- **`--sync-agents`** — auto-scaffold pgmemory into all OpenClaw agent workspaces from `openclaw.json`
- **Harvest** — pull important findings from sub-agent namespaces into primary namespace
- **Embedding providers** — Voyage AI (default), OpenAI, Ollama (local)
- **Archive table** — expired/evicted/decayed memories move to `archived_memories`, never hard deleted; `restore_on_access` brings them back automatically
- **Sane defaults** — minimal config is 3 fields; all options configurable
