# openclaw-pgmemory

Persistent semantic memory for [OpenClaw](https://github.com/openclaw/openclaw) agents — PostgreSQL + pgvector.

OpenClaw agents wake up fresh every session. This skill gives them a memory that persists, decays intelligently, and gets smarter the longer you use it.

## What it does

- **Writes memories** during sessions — decisions, constraints, discoveries, infrastructure facts
- **Injects context** at session start — semantic search surfaces what's relevant to the current task
- **Decays intelligently** — frequently referenced memories stay fresh; ignored ones fade; nothing is ever hard deleted
- **Works with named agents** — each OpenClaw agent ID gets its own memory namespace; sub-agents inherit and harvest back automatically
- **Migrates safely** — versioned SQL migrations with checksums; never auto-migrates; full rollback support

## Install

```bash
clawhub install pgmemory
```

## Quick start

```bash
python3 ~/.openclaw/skills/pgmemory/scripts/setup.py
```

The wizard:
1. Detects or installs Docker / PostgreSQL
2. Spins up a `pgvector/pgvector:pg17` container (or connects to existing DB)
3. Runs migrations
4. Configures your embedding provider (Voyage AI, OpenAI, or Ollama)
5. Scaffolds `AGENTS.md` additions for your OpenClaw agents
6. Writes `pgmemory.json`

## Minimal config

```json
{
  "db": { "uri": "postgresql://openclaw@localhost:5432/openclaw" },
  "embeddings": { "provider": "voyage", "api_key_env": "VOYAGE_API_KEY" },
  "agent": { "name": "main" }
}
```

Everything else uses sane defaults.

## Usage

```bash
# Write a memory
python3 scripts/write_memory.py --key "infra.db" --content "OVH DB at 10.10.0.1:5432" --importance 3 --category infrastructure

# Search memories
python3 scripts/query_memory.py "database connection"

# Check system health
python3 scripts/setup.py --doctor

# Run migrations
python3 scripts/setup.py --migrate

# Validate config
python3 scripts/setup.py --validate
```

## Named agents

Each OpenClaw agent gets its own namespace. Namespace = agent ID.

```bash
openclaw agents add code-writer
# setup.py scaffolds AGENTS.md for code-writer automatically
```

Sub-agents spawned under `code-writer` inherit its `AGENTS.md` — pgmemory context injection happens automatically.

## Memory decay

Memories don't just expire — they decay based on age, category, and how often they're accessed.

- **Decisions and constraints** decay very slowly (~700 day half-life)
- **Context and tasks** decay quickly (~7–14 days)
- **Frequently accessed** memories stay fresh regardless of age
- Faded memories move to archive — never deleted, always recoverable

## Providers

| Provider | Model | Dimensions | Notes |
|---|---|---|---|
| Voyage AI | voyage-3 | 1024 | Default, best quality |
| OpenAI | text-embedding-3-small | 1536 | Common fallback |
| Ollama | nomic-embed-text | 768 | Local, no API key |

## Requirements

- Python 3.9+
- PostgreSQL 14+ with pgvector 0.5+
- An embedding provider API key (or Ollama for local)

## License

MIT
