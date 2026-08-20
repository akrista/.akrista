---
name: rockery-idea
description: Capture half-baked concepts, brainstorms, and rough thoughts for a Quartz/Obsidian digital garden. Use whenever the user says "capture an idea", "brainstorm", "idea note", "half-baked thought", "rough concept", "think out loud about", or wants to record an in-progress thought, hypothesis, or creative spark. Also use when the user has a raw concept that needs a home before it becomes a full topic or project. Do NOT use for daily notes, topics, projects, or tasks — those have their own skills.
license: MIT
metadata:
  author: Jorge Thomas
---

Capture idea notes — half-baked concepts, brainstorms, and rough thoughts that don't yet warrant a full topic or project doc. You are generating a complete, production-ready markdown file in the established Rockery style.

## Content routing

Determine privacy:

- **Public**: `content/ideas/<slug>.md` — for half-baked concepts you're comfortable sharing
- **Private**: `content/private/ideas/<slug>.md` — for personal brainstorms or sensitive concepts

Default to **private** when in doubt about sensitivity. If the idea references company names, people, or anything non-public, route to private.

Create the directory path if it doesn't exist.

Filename: lowercase with hyphens (e.g., `gamified-flashcards.md`, `obsidian-dashboard-concept.md`). Keep slugs short and descriptive.

## YAML frontmatter

```yaml
---
title: <Idea Title>
date: <YYYY-MM-DD>
tags:
  - ideas
  - <tag>
  - <tag>
---
```

Guidelines:
- **title**: A descriptive title for the idea. Use title case. Can be more creative or speculative than a topic title.
- **date**: Today's date in YYYY-MM-DD format
- **tags**: Include `ideas` as the first tag, plus 1-3 topic tags. All lowercase hyphenated. All tags and categories must be pluralized.


## Body style

Ideas are intentionally less structured than topics. They capture thinking-in-progress. Use whatever format best suits the idea, but prefer one of these patterns depending on the idea's maturity:

### For more concrete ideas (close to actionable)

A lightweight structure with sections helps organize thoughts:

```markdown
## Concept

Brief description of the idea in 1-3 sentences.

## Why it's interesting

Why does this idea have potential? What problem does it solve or what curiosity does it explore?

## Open questions

- What's unclear or unknown?
- What would need to be true for this to work?

## Next steps (optional)

- [ ] Research X
- [ ] Try building prototype Y
```

### For raw, loosely-formed ideas

Free-form is fine — a bullet list, a paragraph, even a single question. Examples of valid formats:

- A list of questions about a topic
- A rough sketch of a system or flow
- A comparison between two approaches
- A "what if" thought experiment
- Links to references with brief commentary

### Conventions that still apply

- Use **Obsidian wikilinks** to connect to relevant topics, daily notes, or other ideas
- Use **Obsidian callouts** where they add emphasis: `> [!question]` for open questions, `> [!idea]` for the core insight
- Use code blocks with language tags for technical sketches
- No emojis
- No hard line wrapping

## Privacy & data sanitization

Use generic placeholders for any sensitive references:
- Companies/clients → "Client A", "External Client 1"
- People → "Collaborator A"
- Programs/projects → "Program X", "Internal Project 2"

## Evolving an idea

Ideas are the seed stage. A user may later ask to promote an idea into a topic or project — that's handled by those respective skills. This skill is only for the initial capture.
