---
title: agents-config Obsidian CLI Playbook
tags:
  - agents-config
  - obsidian
  - retrieval
  - performance
status: active
---

# Obsidian CLI Playbook

## Purpose

Use this as the default, fastest path for setup/config retrieval in `agents-config`.

Legacy markdown-only setup flow is deprecated for retrieval-heavy tasks. Prefer the Obsidian-first pipeline below.

Canonical term mapping:
- `the brain` = this `agents-config` repository (local clone + remote canonical) with the Obsidian retrieval layer defined here.

## Fast Path (Required)

1. Refresh index:

```bash
bash ./scripts/obsidian_index_refresh.sh \
  --repo-root /Users/khizar/Documents/GitHub/agents-config \
  --vault /Users/khizar/Documents/GitHub
```

2. Query ranked context:

```bash
bash ./scripts/obsidian_fast_context.sh \
  --repo-root /Users/khizar/Documents/GitHub/agents-config \
  --vault /Users/khizar/Documents/GitHub \
  --query "last_config_sync_date" \
  --engine hybrid \
  --refresh auto \
  --mode context
```

3. For low-token runs, use paths mode:

```bash
bash ./scripts/obsidian_fast_context.sh \
  --repo-root /Users/khizar/Documents/GitHub/agents-config \
  --vault /Users/khizar/Documents/GitHub \
  --query "setup instructions" \
  --engine auto \
  --mode paths
```

## Command Cookbook

### Base-only search

```bash
bash ./scripts/obsidian_fast_context.sh \
  --vault /Users/khizar/Documents/GitHub \
  --query "Review guidelines" \
  --engine base \
  --mode json
```

### FTS-only search

```bash
bash ./scripts/obsidian_fast_context.sh \
  --query "AGENT_NOTES*.md" \
  --engine fts \
  --refresh auto \
  --mode json
```

### Force rebuild

```bash
bash ./scripts/obsidian_fast_context.sh \
  --query "obsidian_fast_context.sh" \
  --engine hybrid \
  --refresh force \
  --mode json
```

## Benchmarks

Run repeatable local benchmark:

```bash
bash ./scripts/benchmark_obsidian_fast_context.sh \
  --repo-root /Users/khizar/Documents/GitHub/agents-config \
  --vault /Users/khizar/Documents/GitHub \
  --engine auto \
  --refresh auto \
  --runs 7
```

Target goals:
- Warm p95 under 120ms
- Cold index build under 15s for current workspace scale

## Troubleshooting

### `obsidian` command not found

1. Install/enable Obsidian CLI from official docs: [Obsidian CLI](https://help.obsidian.md/cli)
2. Re-open terminal and verify:

```bash
obsidian --help
```

### Base query returns no files

Check the Base:
- `![[agents-config-index.base]]`
- Ensure view `Agent Fast Path` exists.

### FTS database missing

Run:

```bash
bash ./scripts/obsidian_index_refresh.sh --force-full
```

## Linked Assets

- Base: `![[agents-config-index.base]]`
- Canvas: `![[agents-config-flow.canvas]]`
- Query script: `[[../scripts/obsidian_fast_context.sh]]`
- Index script: `[[../scripts/obsidian_index_refresh.sh]]`
- Benchmark script: `[[../scripts/benchmark_obsidian_fast_context.sh]]`
