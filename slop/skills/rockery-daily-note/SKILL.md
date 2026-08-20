---
name: rockery-daily-note
description: Create daily notes for a Quartz/Obsidian digital garden following the Rockery daily notes protocol. Use whenever the user says "write a daily note", "capture a daily", "journal entry", "today I learned", "learning log", "daily log", "capture my day", or asks to record what they learned/worked on today. Also use when the user mentions creating a daily entry, logging progress, or documenting their day's learning — even if they don't explicitly name the file type. Do NOT use for deep-dive topics, ideas, projects, or tasks — those have their own skills.
license: MIT
metadata:
  author: Jorge Thomas
---

Create daily notes for the Rockery digital garden following the established patterns. You are generating a complete, production-ready markdown file — not a template or draft. Write in a natural journal style that captures the user's learning or work for the day.

## Content routing

Determine the path and privacy level:

- **Public**: `content/daily/{yyyy}/{mm}/{date-slug}.md` — for learning-in-public, daily exploration
- **Private**: `content/private/daily/{yyyy}/{mm}/{date-slug}.md` — for personal daily logs

Default to **public** unless the user says "private", "personal", or the content involves sensitive information. If the content could be anything private (company names, people's names, credentials), route it to private per the project's default-to-private rule.

Use today's date for `{yyyy}`, `{mm}`, and `{date-slug}` format `YYYY-MM-DD-topic-slug`. Determine the topic slug from what the user was learning or working on. Keep slugs short and descriptive (e.g., `docker-networking`, `react-hooks`, `pkb-import`).

Create the directory path if it doesn't exist.

## YAML frontmatter

Use this exact structure:

```yaml
---
title: <Descriptive title — what was accomplished>
date: <YYYY-MM-DD>
tags:
  - <topic-tag>
  - <topic-tag>
  - <topic-tag>
---
```

Guidelines for each field:
- **title**: A concise phrase describing what was done. Use title case. Can include an em dash for sub-phrases. Example: `PKB Import — Linux, GCP, and Networking references`
- **date**: Today's date in YYYY-MM-DD format
- **tags**: 3-5 lowercase hyphenated tags. Include at least one meta-tag describing the *event* (e.g., `pkb-imports`, `learnings`, `explorations`) plus topic tags. No tag appears more than once per entry. All tags and categories must be pluralized (e.g., `networks`, `cli-commands`).

## Body content

Follow the established daily note style from the existing examples. The tone is **first-person journal-style** — write as a personal log of what was done or learned.

Structure:
1. An opening paragraph that summarizes the day's work in 1-2 sentences
2. A list of bullet points, each describing one thing accomplished or learned
3. Each bullet starts with a wikilink to the relevant concept note, then a brief explanation
4. Add a second batch or follow-up section with `##` heading if there's a distinct second topic

Key conventions:
- Use **Obsidian wikilinks** (`[[Note Name]]`) for the main concept in each bullet — this is the backbone of the knowledge graph
- First reference to a concept gets a wikilink; subsequent mentions are plain text
- Include **Obsidian callouts** where natural — `> [!info]` for clarifications, `> [!warning]` for caveats, `> [!todo]` for follow-up items
- Use dashes for bullet points, not asterisks
- Keep bullets concise — one thought each
- No emojis in daily notes (they're reserved for the homepage)
- No hard line wrapping — let lines flow naturally

## Example

A well-formed daily note:

```markdown
---
title: PKB Import — Linux, GCP, and Networking references
date: 2026-06-21
tags:
  - pkb-imports
  - linux-systems
  - google-clouds
  - networks
---

Imported 7 notes from previous Obsidian vault into the PKB:

- [[ls]] — Linux file listing command
- [[cp]] — Linux copy command
- [[ssh]] — Secure Shell protocol
- [[megabyte]] — MB vs MiB data units
- [[linux-router]] — Single-command Linux router tool
- [[gcloud]] — Google Cloud CLI reference
- [[gcp-fundamentals]] — GCP Cloud Shell, VM creation, and gcloud walkthrough

All tagged and wired with wikilinks for graph traversal.

## Second batch

- [[create-ap]] — WiFi AP creation tool (hostapd wrapper)
- [[erp]] — Enterprise Resource Planning systems overview
- [[powershell]] — PowerShell commands, updates, and Windows Update
- [[netstat]] — Network statistics / port listing command
- [[tcpdump]] — Live network traffic capture and analysis
- [[ssh-config]] — OpenSSH client configuration reference
```

## Privacy & data sanitization

CRITICAL: Never place sensitive data in git-tracked locations. Use generic placeholders:
- Companies/clients → "Client A", "External Client 1"
- Programs/projects → "Program X", "Internal Project 2"
- People → "Collaborator A"

If the content requires any of these placeholders, route to private and mention to the user that you've done so.
