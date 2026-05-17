---
name: claude-save-token
description: Use when the user wants to reduce token usage in Claude Code, keep answers short, or work token-efficiently.
status: 暂不满意，开发中
---

# Claude Save Token

Reduce token burn in Claude Code without lowering engineering quality. Every token spent should change a decision.

## Response Style

- Give one-sentence updates at key moments. Skip the filler.
- Report outcomes, not the process. "Fixed: X in file.py:42" is better than "Now I will try to..."
- After a series of edits, summarize in one line what changed. No per-file narrative.
- If the user asks a direct question, answer directly. No preambles or postambles.

## Tool Strategy

- **Parallelize aggressively.** Independent reads, edits, and bash calls go in a single message — not sequential.
- **Prefer Edit over Write.** Only use Write for new files or complete rewrites. Edit sends a diff, Write sends the whole file.
- **Search before reading.** Use Grep/Glob to locate, then Read only the needed slice with offset/limit.
- **Read slices, not walls.** For large files, use `offset` + `limit`. Don't read 2000 lines when you need 50.
- **Batch bash.** Chain independent commands with `&&`. Don't run `ls` then `cat` then `git status` in separate calls.
- **Set timeouts wisely.** Long builds should use `run_in_background`. Don't block the conversation on `docker build`.

## Editing Discipline

- Small, surgical edits. One change per edit when possible.
- Match existing patterns. Don't refactor unrelated code.
- No comments unless the WHY is non-obvious. Well-named code documents itself.
- No backwards-compat shims, unused vars, re-exports, or "removed" comments. Delete dead code cleanly.

## Research & Exploration

- Use Explore agent for broad searches. Don't manually grep 10 patterns sequentially.
- Use Plan agent for architecture before coding. Don't explore and plan as you go.
- Delegate independent research to background agents when safe.

## Avoid Token Sinks

- Never re-read a file you just edited — Edit/Write would have errored if the change failed.
- Don't read lockfiles, minified bundles, build artifacts, or large data files unless you need them.
- Skip reading files you already have context on from a recent Grep or previous read.
- Don't echo file contents with Bash when Read/Edit/Write tools exist.

## Don't Over-Optimize

- Read enough context to avoid regressions before editing.
- State uncertainty instead of being ambiguous to save words.
- Verify with the narrowest meaningful test. Escalate only when risk justifies it.
