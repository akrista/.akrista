---
name: rockery-project
description: Create long-form project documentation for a Quartz/Obsidian digital garden. Use whenever the user says "create a project doc", "start a project note", "document this project", "project overview", "project documentation", or wants to write long-form documentation about a project they're working on. Also use when the user describes a substantial piece of work that needs structured documentation over time — this is for sustained projects, not single sessions. Do NOT use for daily notes, topics, ideas, or tasks — those have their own skills.
license: MIT
metadata:
  author: Jorge Thomas
---

Create long-form project documentation for the Rockery digital garden. Projects are sustained, structured documentation that evolves over time — not single-session notes. You are generating a complete, production-ready markdown file with the correct directory structure.

## Content routing

Determine privacy:

- **Public**: `content/projects/<project-name>/` — for open-source or public-facing projects
- **Private**: `content/private/projects/<project-name>/` — for internal or sensitive projects

Default to **public** unless the project involves proprietary technology, company work, or anything that shouldn't be public.

Create the project directory (both the `{project-name}/` subdirectory and the file within it). Each project gets its own subdirectory to hold multiple files as the project grows.

The primary file is `content/projects/<project-name>/index.md`. Additional files can be added as `content/projects/<project-name>/<section>.md` for larger projects.

Project names: lowercase with hyphens (e.g., `home-server-setup`, `obsidian-plugin`, `dotfiles-management`).

## YAML frontmatter

For the primary project `index.md`:

```yaml
---
title: <Project Title>
date: <YYYY-MM-DD>
tags:
  - projects
  - <tag>
  - <tag>
---
```

Guidelines:
- **title**: The project name in title case. Example: `Home Server Setup`
- **date**: Today's date (project start date). Add `updated: <date>` when you make significant changes later.
- **tags**: Include `projects` as the first tag, plus 2-4 topic tags. All lowercase hyphenated. All tags and categories must be pluralized.
- **Properties**: Standardize and reuse YAML property keys across project templates. Keep them compact and composable (e.g. `start` or `end` instead of `start_date` / `end_date`, and use list type properties for fields that could contain multiple values).


## Body structure

Projects evolve, so this is a starting structure. Adapt it to the project's needs.

### Overview

1-3 paragraphs describing the project: what it is, why you're doing it, and what success looks like.

### Goals

Bullet list of concrete goals. Use `- [ ]` checkboxes for goals that aren't yet complete:

```markdown
## Goals

- [ ] Set up reverse proxy with Caddy
- [ ] Configure automatic backups
- [ ] Deploy monitoring dashboard
```

### Architecture / Design (optional)

For technical projects, describe the architecture. Use diagrams (described textually), code blocks, or bullet lists.

### Progress log

A reverse-chronological log of significant updates. Each entry is a date heading with brief notes:

```markdown
## Progress

### 2026-06-21

- Initial server provisioning complete
- Nginx config in progress
- SSL certificates requested via Let's Encrypt
```

### Related

Wikilinks to relevant topics, daily notes, and other projects. This is important for graph connectivity.

```markdown
## Related

- [[nginx]] — reverse proxy configuration
- [[systemd]] — service management
- [[ufw]] — firewall setup
```

### Additional files (for larger projects)

If a project has many subsections, create additional files in the same directory:
- `content/projects/<name>/setup.md` — detailed setup instructions
- `content/projects/<name>/reference.md` — configuration reference
- `content/projects/<name>/journal.md` — ongoing development journal

## Conventions

- Use **Obsidian wikilinks** extensively to connect to topic notes and other projects
- Use **Obsidian callouts** where helpful: `> [!info]` for context, `> [!warning]` for caveats, `> [!todo]` for next actions
- Use code blocks with language tags for config files and commands
- Tables for structured data
- No emojis
- No hard line wrapping

## Privacy & data sanitization

CRITICAL: Never place sensitive data in public projects. Use generic placeholders:
- Server IPs/hostnames → generic references (e.g., "the production server")
- Credentials → never include; use placeholders like `<your-api-key>`
- Company/client names → "Client A", "External Client 1"
- People → "Collaborator A"
