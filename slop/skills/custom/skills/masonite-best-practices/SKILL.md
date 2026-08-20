---
name: masonite-best-practices
description: "Apply this skill whenever writing, reviewing, or refactoring Masonite Python code. This includes creating or modifying controllers, models, migrations, validation, jobs, scheduled commands, service providers, and Masonite ORM queries. Triggers for N+1 and query performance issues, caching strategies, authorization and security patterns, validation, error handling, queue and job configuration, route definitions, and architectural decisions. Also use for Masonite code reviews and refactoring existing Masonite code to follow best practices. Covers any task involving Masonite backend Python code patterns."
license: MIT
metadata:
  author: masonite
---

# Masonite Best Practices

Best practices for Masonite (Python), organized as an index of rule files. Each rule file teaches what to do and why. For exact API syntax, verify against the installed `masonite` / `masoniteorm` packages.

## Consistency First

Before applying any rule, check what the application already does. Masonite offers multiple valid approaches, and the best choice is the one the codebase already uses, even if another pattern would be theoretically better. Inconsistency is worse than a suboptimal pattern.

Check sibling files, related controllers, models, or tests for established patterns. If one exists, follow it. Don't introduce a second way. These rules are defaults for when no pattern exists yet, not overrides.

## How to Apply

1. Check the changed files, nearby code, project configuration, and relevant tests for established patterns. Deviate only for a correctness or security defect, and call the deviation out.
2. Map every affected concern to the rule index below. Read each mapped rule file before editing. Skip unrelated rule files.
3. Make the smallest coherent change. Keep the application's architecture and naming instead of introducing a second pattern for the same job.
4. Verify version-sensitive Masonite APIs for the installed version by inspecting the installed `masonite` and `masoniteorm` packages when in doubt.
5. Run the narrowest relevant tests first (`pytest`), then the project's linting and formatting checks (`ruff`) when the change warrants them.
6. Re-read the diff against every mapped rule before finishing.

## Rule Index

Cross-cutting changes often need more than one rule file.

| Concern | Read |
| --- | --- |
| Query count, eager loading, indexes, large datasets | [`rules/db-performance.md`](rules/db-performance.md) |
| Subqueries, aggregates, complex ordering and query plans | [`rules/advanced-queries.md`](rules/advanced-queries.md) |
| Models, relationships, scopes, casting | [`rules/models.md`](rules/models.md) |
| Authentication, authorization, input safety, secrets, uploads | [`rules/security.md`](rules/security.md) |
| Request validation rules | [`rules/validation.md`](rules/validation.md) |
| Controllers, route binding, middleware | [`rules/routing.md`](rules/routing.md) |
| Schema changes, columns, foreign keys, indexes | [`rules/migrations.md`](rules/migrations.md) |
| Jobs, retries, delays, queues | [`rules/queue-jobs.md`](rules/queue-jobs.md) |
| Cache lifetime, invalidation, locks, memoization | [`rules/caching.md`](rules/caching.md) |
| Outbound requests, retries, timeouts, fakes | [`rules/http-client.md`](rules/http-client.md) |
| Exceptions, reporting, log context | [`rules/error-handling.md`](rules/error-handling.md) |
| Events and notifications | [`rules/events-notifications.md`](rules/events-notifications.md) |
| Mailables and mail assertions | [`rules/mail.md`](rules/mail.md) |
| Scheduled tasks and overlap protection | [`rules/scheduling.md`](rules/scheduling.md) |
| Lazy iteration, generators, bulk operations | [`rules/collections.md`](rules/collections.md) |
| Jinja2 templates, components, layout inheritance | [`rules/views.md`](rules/views.md) |
| Environment values and application configuration | [`rules/config.md`](rules/config.md) |
| pytest patterns, test case base classes, fakes | [`rules/testing.md`](rules/testing.md) |
| Naming, helpers, file boundaries, Python style | [`rules/style.md`](rules/style.md) |
| Controllers, services, dependencies, application structure | [`rules/architecture.md`](rules/architecture.md) |

## Decision Rules

- Prefer framework features and existing application abstractions over new helpers or dependencies.
- Avoid speculative abstractions. Extract code when it creates a clear domain boundary, removes meaningful duplication, or makes behavior independently testable.
- Keep database access out of Jinja2 templates and prevent hidden N+1 queries across controllers, jobs, and serialization.
