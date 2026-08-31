# TigerStyle Pre-Submit Checklist

Quick validation before committing code. Run through this after writing.

## Safety (CRITICAL)

- [ ] **Assertions**: Every function has 2+ assertions (preconditions, postconditions, invariants)
- [ ] **No recursion**: All traversals use explicit iteration with bounded stack
- [ ] **Bounded loops**: All loops have explicit upper bounds
- [ ] **Bounded allocation**: No dynamic allocation on hot paths or from untrusted input sizes
- [ ] **Errors handled**: No ignored errors — every error is propagated or explicitly handled
- [ ] **Explicit types**: Using `i32`/`u64`/`float64`, not architecture-dependent `int`/`long`

## Control Flow

- [ ] **Function size**: Every function under 70 lines
- [ ] **Simple control flow**: No complex compound conditions
- [ ] **Split conditions**: Using nested `if/else`, not `if (a and b)`
- [ ] **Positive invariants**: `if (valid)` not `if (!invalid)`
- [ ] **Every if has else**: Both branches handled or asserted explicitly
- [ ] **Braces on all blocks**: No braceless bodies (except single-line assertion guards)

## Naming

- [ ] **Consistent with project**: Follows the codebase's established naming convention
- [ ] **No abbreviations**: `message` not `msg`, `connection` not `conn`
- [ ] **Units last**: `latencyMsMax` not `maxLatency`
- [ ] **Semantic richness**: Names communicate lifetime and purpose, not just type

## Formatting

- [ ] **Column limit**: All lines within the project's hard column limit
- [ ] **Formatted**: Project's standard formatter has been run
- [ ] **Comments explain why**: No comments on self-evident code

## Bug Prevention

- [ ] **Explicit division**: Using floor/ceil/exact division, not implicit `/`
- [ ] **Off-by-one**: `index` vs `count` vs `size` distinguished
- [ ] **Named params**: Same-typed arguments use named parameters or options struct
- [ ] **Variables close to use**: No early declarations, no stale variables in scope

## Memory

- [ ] **No buffer bleeds**: Partially filled buffers are zeroed
- [ ] **Grouped alloc/dealloc**: Allocation visually paired with its deallocation

## Quick Severity Guide

| If you find... | Severity |
|----------------|----------|
| Missing assertions | CRITICAL |
| Unbounded loop | CRITICAL |
| Dynamic allocation on hot path | CRITICAL |
| Ignored error | CRITICAL |
| Function over 70 lines | MAJOR |
| Architecture-dependent types | MAJOR |
| Missing `else` branch | MAJOR |
| Buffer bleed | MAJOR |
| Implicit division (`/`) | MINOR |
| Wrong naming convention for project | MINOR |
| Line over column limit | MINOR |
| Missing units in name | MINOR |
| Variable declared too early | MINOR |
