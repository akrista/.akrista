---
name: tiger-style
description: "TigerBeetle-derived coding discipline for safety-critical code. Applies universal engineering principles (Safety > Performance > DX) to any language. Use when writing new code that demands correctness, or reviewing code for safety, performance, and maintainability gaps."
license: MIT
metadata:
  author: tigerbeetle
---

# TigerStyle

A coding discipline adapted from TigerBeetle, optimized for **Safety > Performance > Developer Experience** — in that order. The principles are language-agnostic. Every rule serves one of these three priorities.

> "The design is not just what it looks like and feels like. The design is how it works." — Steve Jobs

## Consistency First

Before applying any rule, check what the codebase already does. If the project uses `camelCase` consistently, don't introduce `snake_case` — that's a different convention, and consistency beats any single rule. These rules are defaults for when no pattern exists yet, not overrides.

## Quick Reference

| # | Category | Priority | Key Rules |

|---|----------|----------|-----------|
| 1 | **Assertions** → `rules/safety.md#assertions` | Safety | Min 2 per function, pair on read/write paths, split compound, assert both positive and negative space |
| 2 | **Control flow** → `rules/safety.md#control-flow` | Safety | No recursion, bounded loops, every `if` has `else`, split compound conditions, state invariants positively |
| 3 | **Memory** → `rules/safety.md#memory` | Safety | Bounded allocation, no dynamic allocation on hot paths, group alloc/dealloc, no buffer bleeds |
| 4 | **Types & bounds** → `rules/safety.md#types-and-bounds` | Safety | Explicit-sized types, put a limit on everything, compile-time sanity checks |
| 5 | **Error handling** → `rules/safety.md#error-handling` | Safety | Every error handled or propagated, never silently swallowed |
| 6 | **Function shape** → `rules/safety.md#function-size` | Safety | Max 70 lines per function, push `if`s up and `for`s down |
| 7 | **Design-time perf** → `rules/performance.md#design-time-thinking` | Performance | Back-of-envelope sketches before coding, optimize slowest resource first |
| 8 | **Batching** → `rules/performance.md#batching` | Performance | Amortize overhead, separate control plane from data plane |
| 9 | **CPU predictability** → `rules/performance.md#cpu-predictability` | Performance | Extract hot loops, minimize branching in hot paths, be explicit |
| 10 | **Naming** → `rules/dx.md#naming` | DX | Get nouns and verbs right, no abbreviations, units last, semantic richness |
| 11 | **Formatting** → `rules/dx.md#formatting` | DX | Hard column limit, use the project's formatter, comments are sentences explaining why |
| 12 | **Bug prevention** → `rules/dx.md#bug-prevention` | DX | Off-by-one awareness, explicit rounding, options structs for same-typed params, variables close to use |
| 13 | **Dependencies** → `rules/dx.md#dependencies` | DX | Minimal dependencies, standardize on one toolchain |
| 14 | **Commit messages** → `rules/dx.md#commit-messages` | DX | Explain why, not just what. Store rationale in git history |

## How to Apply

1. Load this skill when writing or reviewing code that demands correctness.
2. Identify the relevant rule sections for the code type (e.g., new function → §1, §2, §6; review → §1–§14).
3. Read the detailed rule file(s) for language-agnostic guidance and examples.
4. Validate against `rules/checklist.md` before submitting.
5. Fix CRITICAL violations first (safety risks), then MAJOR (maintainability), then MINOR (style).

## When Not to Use

- Prototypes or throwaway code where speed of exploration matters more than correctness
- Code that intentionally trades safety for flexibility (e.g., dynamic configuration loaders)
- When the codebase already has a well-established, consistently applied set of conventions that contradict a rule — consistency wins

## Severity Definitions

| Severity | Criteria | Examples |
|----------|----------|----------|
| **CRITICAL** | Safety risk — will cause bugs | Missing assertions, unbounded loops, unchecked errors, missing else branches |
| **MAJOR** | Maintainability risk — will cause pain | Function too long, complex control flow, vague naming, no bounds on data structures |
| **MINOR** | Style — worth fixing, won't block | Formatting drift, comment quality, minor naming improvements |

## Philosophical Context

See `references/TIGER_STYLE.md` for the full original TigerBeetle document. It explains the "why" behind every rule: simplicity and elegance, zero technical debt, and the trade-offs that shaped this discipline.
