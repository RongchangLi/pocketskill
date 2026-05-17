---
name: codex-token-saving
description: Use when the user asks Codex to save tokens, reduce context usage, keep answers concise, or work in a token-efficient way.
---

# Codex Token Saving

Use this skill when the user wants Codex to reduce token usage without lowering engineering quality.

## Core Principle

Spend tokens only on information that changes the next decision. Be concise, but do not skip context that is necessary for correctness, safety, or verification.

## Working Rules

- Clarify only when a missing choice would materially change the outcome. Otherwise make a reasonable assumption and state it briefly.
- Search before reading. Prefer `rg`, `rg --files`, targeted `find`, and narrow path filters over opening broad directories or whole files.
- Read slices, not dumps. Use `sed -n`, `nl -ba`, `head`, `tail`, `jq`, or focused log ranges to inspect only relevant sections.
- Avoid ingesting generated or bulky files unless they are directly relevant: lockfiles, minified bundles, build artifacts, long traces, notebooks, and large data files.
- Keep progress updates short and only when useful. Do not repeat the same status or restate the full problem.
- Prefer small, direct edits that match existing patterns. Avoid broad refactors, speculative abstractions, and unrelated cleanup.
- Verify with the narrowest meaningful command first. Escalate to broader test suites only when the touched behavior or risk justifies it.
- In the final answer, report the outcome, changed files, and verification in a compact form. Omit detailed command logs unless the user asked for them.

## Tool Discipline

- Batch independent file reads with parallel tool calls when available.
- Set output limits on commands that may be verbose.
- Stop or narrow commands that start returning irrelevant output.
- For web or documentation lookup, browse only when current or source-specific information is required, then rely on primary sources and cite only what matters.

## Conversation Discipline

- Preserve useful state through short summaries rather than re-reading the same files.
- After compaction or a long pause, resume from the latest concrete goal instead of replaying the whole history.
- When the user asks for a plan, keep it decision-oriented and short.
- When the user asks for code, implement rather than producing long speculative explanations.

## Do Not Over-Optimize

- Do not skip required browsing when the answer depends on current facts.
- Do not edit code before reading enough surrounding context to avoid regressions.
- Do not hide uncertainty; state the assumption or remaining risk briefly.
- Do not sacrifice test quality when the change affects shared behavior, public APIs, data migrations, security, billing, or user-visible workflows.
