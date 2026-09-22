# Universal AI Agent Guidelines

## Developer Communication & Cognitive Ergonomics

Prevent cognitive overload when explaining concepts, architectural decisions, code changes, or debugging steps:

1. **Strict quantitative limits (chunking)**: Keep explanations of complex logic, architecture, or bug analysis under 150-200 words. Focus solely on information needed immediately to understand or decide; omit historical context and pleasantries.
2. **Progressive disclosure**: If more depth is needed, provide a high-level summary of at most 3 bullets and stop. Ask which point to expand before generating additional text.
3. **Extraneous load reduction**: Use clear headings and bullets. Bold key terminology, identifiers, and file paths. Keep paragraphs to a maximum of 3 lines.
4. **Anchoring via analogies**: When introducing a complex domain concept, anchor it with one real-world analogy (such as cooking, manufacturing, or logistics) in exactly one sentence.
5. **Code presentation**: State what the code does in 1-2 sentences, output the code, and stop. Do not add explanations after the code block unless requested.

## Conventions

- Follow existing code conventions: before creating or editing a file, check sibling files for established structure, approach, and naming. Maintain consistency with existing patterns.
- Use descriptive names for variables and methods.
- Check for existing components and utilities to reuse before creating new ones.

## Verification

- Do not create verification scripts or scratch test files when the existing test suite already covers the functionality. Tests are the source of truth.

## Documentation Files

- Only create documentation files when explicitly requested.

## Replies

- Be concise. Focus on key information and omit obvious explanations.

## Design Context

- If a project defines `PRODUCT.md`, `DESIGN.md`, or `.impeccable/` at its root, inspect them before making UI decisions:
  - `PRODUCT.md` defines target users, positioning, register, anti-references, and accessibility baselines. It governs strategic and voice decisions.
  - `DESIGN.md` defines visual styling (palette, typography, elevation, component rules). It overrides `PRODUCT.md` on visual decisions.
  - `.impeccable/design.json` defines design tokens (tonal ramps, motion tokens, breakpoints) and component styling used by `impeccable live` and Stitch-compatible tooling.

## Version Control

- Ensure `.gitignore` excludes AI agent configuration and secrets: MCP configs (`.mcp.json`), local IDE and agent settings (such as `.claude/settings.local.json`), and `.env` files. Never commit credentials.
- Write commit messages describing business purpose rather than mechanical diff content (e.g., "feat: add February records for ops billing" instead of "insert into table").
- Use feature branches for schema and behavior changes. Never commit directly to `master` or `develop` on projects that follow this convention.
