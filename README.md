# Bee Claude Workspace

Standard Claude CLI workspace for all Bee machines (Hive VPS).

## Structure

- `projects/` — Cloned repos and active project work
- `scripts/` — Reusable automation scripts
- `temp/` — Scratch space, safe to clean
- `logs/` — Claude CLI and script logs

## Usage

```bash
# Run Claude CLI with full permissions
bee-claude -p "your prompt here"

# Or use directly
claude --dangerously-skip-permissions -p "your prompt here"
```

## Owner

Yonatan Perlin (DaCoderMan) — jonathanperlin@gmail.com
