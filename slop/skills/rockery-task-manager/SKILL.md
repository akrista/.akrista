---
name: rockery-task-manager
description: Manage tasks with status tracking for a Quartz/Obsidian digital garden. Use whenever the user says "add a task", "create task", "new task", "show tasks", "my tasks", "what's up", "what am I working on", "task status", "mark task as done", "update task", "list tasks", "show me what I need to do", or asks about their current work, pending items, or to-do list. Also use when the user mentions tracking work, following up on something, or recording an action item. Do NOT use for daily notes, topics, ideas, or projects — those have their own skills.
license: MIT
metadata:
  author: Jorge Thomas
---

Manage tasks in the Rockery digital garden. Tasks are individual markdown files with YAML frontmatter that includes a `status` field. This skill handles creating new tasks, listing existing tasks by status, and updating task statuses.

## Content routing

- **Public**: `content/tasks/<task-slug>.md` — for open work tracking visible on the site
- **Private**: `content/private/tasks/<task-slug>.md` — for personal task management

Default to **private** — tasks are often personal. Make public if the user explicitly says so or if it's clearly something they'd track openly (e.g., "make a public task for this feature request").

## Creating tasks

### Filename

Lowercase with hyphens: `content/tasks/set-up-continuous-deployment.md` or `content/private/tasks/review-design-proposal.md`.

Create the directory path if it doesn't exist.

### YAML frontmatter

```yaml
---
title: <Task Name>
status: <status>
tags:
  - <tag>
  - <tag>
---
```

**Status field** — one of:
- `pending` — not started yet
- `active` — currently being worked on
- `done` — completed
- `blocked` — waiting on something

Default to `active` unless the user says otherwise.

**Tags**: 1-3 lowercase hyphenated tags for filtering and organization. All tags and categories must be pluralized (except hierarchical status tags like `status/pending`).

### Body (optional)

The body can be empty for simple tasks, or contain notes, checklists, or context:

```markdown
Notes about this task...

- [ ] Subtask 1
- [ ] Subtask 2

Related: [[topic-note]], [[daily-note]]
```

## Listing tasks

When the user asks "what's up", "my tasks", "show tasks", or similar:

1. Glob all `.md` files under both `content/tasks/` and `content/private/tasks/`
2. Read the `status` from YAML frontmatter of each file (exclude index.md files)
3. Group by status in this order: **active → pending → blocked** (omit done)
4. Present as a formatted list:

```
## Active

- set-up-continuous-deployment — Set up continuous deployment
- write-docker-compose — Write docker-compose config

## Pending

- review-design-proposal — Review Q3 design proposal
- update-dependencies — Update npm dependencies

## Blocked

- deploy-monitoring — Deploy monitoring dashboard (waiting on DNS)
```

Include the file path (relative to content/) so the user knows where to find each task. Use wikilinks in the display if helpful.

## Updating task status

When the user asks to update a task:

1. Find the matching task file (by name or search in frontmatter title)
2. Read it, update the `status` field in frontmatter
3. Write the file back

Status transitions should be validated — you can move freely between any status values.

## Task listing conventions

- **Group by status**: active first (what needs attention now), then pending (up next), then blocked (stuck)
- **Omit done tasks** from the listing unless the user specifically asks for completed items
- Format the filename as wikilink text for readability: `[[set-up-continuous-deployment]]` renders as the task title
- If there are no tasks in any status, report: "No tasks found. Want me to create one?"
- If there are private tasks, mention they exist but group them under a "Private" subheading rather than hiding them — the user asked to see their tasks
