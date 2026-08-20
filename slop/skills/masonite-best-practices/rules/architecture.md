# Architecture Best Practices

## Layered Layout

Masonite organizes by convention:

- `routes/web.py` — URL definitions.
- `app/controllers/` — HTTP entry points (thin: validate, authorize, orchestrate).
- `app/models/` — ORM models with relationships and domain helpers.
- `app/middlewares/` — request lifecycle gates (`auth`, `permission`, `tenant`).
- `app/providers/` — service providers; the app's own `AppProvider` extends the framework's registered providers from `config/providers.py`.
- `app/utils/` — shared, framework-agnostic helpers (slugify, RBAC bootstrap).
- `config/` — module-scoped configuration.
- `databases/migrations/` — schema, via Masonite ORM migrations.
- `templates/` — Jinja2 views.

## Controllers Stay Thin

A controller method: validate → authorize → query with tenant scope → render/redirect. Reused logic moves to model helpers or `app/utils`. The repo's `RoleController` is the reference shape.

## Services Over God Helpers

When logic is shared across controllers or too heavy for a model, put it in a focused module (`app/utils`) rather than a growing "helpers" file. Extract when there's real duplication or an independent unit to test — not speculatively.

## Scope by Tenant Everywhere

Multi-tenant apps must scope every query by `tenant_id` at the query site — never trust a controller to remember. Model helpers that filter for the current user (`User.permission_slugs`) keep this correct by construction.

## Dependency Injection

Use Masonite's DI: type-hint `Request`, `Response`, `View`, and other bindings in controller methods instead of reaching for globals or container lookups where the framework injects for you.

## Consistency Wins

Before adding a pattern, check whether the codebase already does it. If it does, follow it. These rules are defaults for when no pattern exists yet, not overrides.
