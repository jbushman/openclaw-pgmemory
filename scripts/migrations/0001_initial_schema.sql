-- pgmemory migration 0001
-- Initial schema: memories, session_state, archived_memories, pgmemory_migrations

-- UP

CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Core memory table
CREATE TABLE memories (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  agent           TEXT        NOT NULL,
  namespace       TEXT        NOT NULL DEFAULT 'default',
  category        TEXT        NOT NULL DEFAULT 'context',
  key             TEXT        NOT NULL,
  content         TEXT        NOT NULL,
  embedding       vector(1024),
  importance      INT         NOT NULL DEFAULT 2 CHECK (importance BETWEEN 1 AND 3),
  relevance_score FLOAT       NOT NULL DEFAULT 1.0,
  access_count    INT         NOT NULL DEFAULT 0,
  source          TEXT        NOT NULL DEFAULT 'session',
  tags            TEXT[]      DEFAULT '{}',
  expires_at      TIMESTAMPTZ,
  last_accessed   TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Unique per agent+key (latest write wins within an agent's namespace)
CREATE UNIQUE INDEX idx_memories_agent_key
  ON memories (agent, key);

-- Vector similarity search
CREATE INDEX idx_memories_embedding
  ON memories USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 100);

-- Fast lookups by agent + importance
CREATE INDEX idx_memories_agent_importance
  ON memories (agent, importance DESC);

-- Category filter
CREATE INDEX idx_memories_category
  ON memories (agent, category);

-- Expiry cleanup
CREATE INDEX idx_memories_expires_at
  ON memories (expires_at)
  WHERE expires_at IS NOT NULL;

-- Archive table (memories moved here on expiry or eviction — never hard deleted)
CREATE TABLE archived_memories (
  LIKE memories INCLUDING ALL,
  archived_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  archive_reason TEXT NOT NULL DEFAULT 'expired'
);

CREATE INDEX idx_archived_memories_agent
  ON archived_memories (agent, archived_at DESC);

-- Agent session state (one row per agent — current task, context)
CREATE TABLE session_state (
  agent        TEXT        PRIMARY KEY,
  current_task TEXT,
  summary      TEXT,
  active_jobs  TEXT[]      DEFAULT '{}',
  blocked_on   TEXT[]      DEFAULT '{}',
  metadata     JSONB       DEFAULT '{}',
  last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Migration tracking table (self-referential: this migration creates the table)
CREATE TABLE pgmemory_migrations (
  version    INT         PRIMARY KEY,
  filename   TEXT        NOT NULL,
  checksum   TEXT        NOT NULL,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER memories_updated_at
  BEFORE UPDATE ON memories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- DOWN

DROP TRIGGER IF EXISTS memories_updated_at ON memories;
DROP FUNCTION IF EXISTS update_updated_at();
DROP TABLE IF EXISTS pgmemory_migrations;
DROP TABLE IF EXISTS session_state;
DROP TABLE IF EXISTS archived_memories;
DROP TABLE IF EXISTS memories;
