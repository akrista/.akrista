---
name: rockery-topic
description: Create deep-dive topic/reference notes for a Quartz/Obsidian digital garden. Use whenever the user says "write a topic about", "create a topic note", "deep dive on", "reference note on", "documentation for", "tutorial on", or asks to write a detailed reference about a concept, tool, or technology. Also use when the user wants a comprehensive, structured reference — think man-page style with usage, examples, flags, and related topics. Do NOT use for daily notes, ideas, projects, or tasks — those have their own skills.
license: MIT
metadata:
  author: Jorge Thomas
---

Create deep-dive topic/reference notes for the Rockery digital garden. Topics are factual, third-person reference documents structured like mini man pages. You are generating a complete, production-ready markdown file — not a template or draft.

## Content routing

Topics are organized into category subdirectories. Determine the best category:

| Category   | Path                         | Content examples                        |
| ---------- | ---------------------------- | --------------------------------------- |
| Networking | `content/topics/networking/` | tcpdump, ssh, ssh-config, netstat, ...  |
| Cloud      | `content/topics/cloud/`      | gcp-fundamentals, gcloud, erp           |
| CLI        | `content/topics/cli/`        | cp, ls, powershell                      |
| Concepts   | `content/topics/concepts/`   | megabyte, data units, theory            |
| Tools      | `content/topics/tools/`      | create-ap, software tools               |

If the topic doesn't fit an existing category and there are fewer than 3 orphan topics in `topics/`, place it flat in `content/topics/`. If a category reaches 3+ notes, suggest creating a new subdirectory. Prefer creating new categories when the topic is clearly distinct from existing ones.

Create the directory path if it doesn't exist.

Filename: lowercase with hyphens (e.g., `tcpdump.md`, `gcp-fundamentals.md`, `ssh-config.md`).

## YAML frontmatter

```yaml
---
title: <Topic Name>
date: <YYYY-MM-DD>
tags:
  - <tag>
  - <tag>
  - <tag>
---
```

Guidelines:
- **title**: The topic name itself — concise, unquoted string. Examples: `tcpdump`, `SSH Config`, `GCP Fundamentals`
- **date**: Today's date in YYYY-MM-DD format
- **tags**: 3-7 lowercase hyphenated tags. Mix broad (`linux-systems`, `networks`, `security-standards`) and specific (`packet-analyses`, `remote-accesses`). All tags and categories must be pluralized.
- **Optional Properties**: Standardize and reuse YAML property keys across topics. Keep them compact and composable (e.g. `start` or `end` instead of `start_date` / `end_date`, list types for fields that could contain multiple values).
- **Rating**: If the topic includes a personal review or rating, use a granular integer scale from 1 to 7 (`7` = Perfect, `6` = Excellent, `5` = Good, `4` = Passable, `3` = Bad, `2` = Atrocious, `1` = Evil).


## Body structure

Every topic note follows this template. Use it as a guide, not a rigid checklist — adapt sections to the specific topic.

### Opening definition

One or two sentences that define the topic in active voice. Bold the key term on first mention. Example:

"**SSH** (Secure Shell) is both a protocol and the program that implements it. Its primary purpose is remote access to a server over a secure, encrypted channel."

Or for commands:

"`tcpdump` captures and analyzes network traffic passing through a network interface in real time."

### Main sections (`##` level)

Use H2 headings for major sections. Common sections include:

- **Basic usage** — show the most common invocation with a code block
- **Common flags/options** — use a markdown table with `| Flag | Description |`
- **Examples** — show 2-4 realistic examples with ` ```bash ` or appropriate language tag
- **Key concepts** — explain what makes this topic interesting or important
- **Configuration** — if the topic has config files, show format and common options
- **Related** or **See also** — ALWAYS end with this section containing wikilinks to related topics

### Subsections (`###` level)

Use H3 headings for subsections within a major section when needed (e.g., `### Key management` under a section about SSH usage).

### Closing section

Every topic note ends with a `## Related` or `## See also` section:

```markdown
## Related

- [[netstat]] — show active connections and port statistics
- [[tcpdump]] — capture and analyze live network traffic
```

## Writing conventions

### Code blocks
- Always use a language tag: ` ```bash `, ` ```conf `, ` ```powershell `, ` ```yaml `
- Show commands with their output where illustrative
- Use `#` for comments in configuration blocks

### Tables
- Leading pipe on every row
- Dashed separator with space-padded dashes (`| ---- |`)
- Left-aligned text in all columns
- Use backticks within table cells for inline code/commands

### Wikilinks
- The first reference to a concept in the note gets a wikilink: `[[Linux]]`
- Subsequent references to the same concept are plain text
- Self-referential wikilinks are used (e.g., `[[PowerShell]]` in a PowerShell note)
- External URLs use standard markdown: `[text](url)` — these are rare, use wikilinks where possible

### Callouts
Use sparingly — only when the information needs emphasis. The existing codebase uses `> [!warning]` for security caveats and known issues. This is the right approach: callouts should be the exception, not the rule.

### Style
- Third person, factual, active voice
- No personal pronouns (no "I", "my", "we")
- No emojis (they're reserved for the homepage)
- No hard line wrapping — let lines flow naturally
- Use em dashes — for parenthetical phrases

## Privacy & data sanitization

Topic notes are always public since they're general reference material. If the user asks for a topic involving proprietary or sensitive technology, flag it and suggest routing to private ideas or private projects instead.
