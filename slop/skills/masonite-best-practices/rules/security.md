# Security Best Practices

## Authentication

- Gate routes behind the `auth` middleware in the route definition:
  ```python
  Route.get("/dashboard", "DashboardController@show").middleware("auth")
  ```
- Resolve the current user with `request.user()`. It returns `None` when unauthenticated — handle that branch explicitly.
- Store only hashed passwords via `Hash.make()`. Never log or echo a raw password.

## Authorization

- Model-level checks on the User model (`user.can(slug)`, `user.is_owner`) rather than ad-hoc role name comparisons scattered through controllers.
- Gate management routes with `permission:slug` middleware. See the `masonite-permission-development` skill.
- Always re-check authorization inside the action, not only at the route: users must not read or mutate a row they can't reach (e.g., always filter by `tenant_id`).

## Input Safety

- Validate every untrusted input at the boundary with `request.validate(...)` (see [`rules/validation.md`](validation.md)).
- Never interpolate user input into raw SQL. Use the ORM's parameter binding.

## CSRF and Sessions

- All state-changing routes go through the `web` middleware group, which includes `VerifyCsrfToken`. Do not exempt routes without a documented reason.
- Keep the session middleware on the `web` group so CSRF and flash data work.

## Secrets

- Read secrets from the environment (`os.getenv` / `.env` loaded by `LoadEnvironment`), never hardcode them.
- Keep `.env` out of version control. `.env-example` documents the keys without values.
- Add `MAIL_PASSWORD`, `APP_KEY`, and database credentials to `__hidden__`-style protections where applicable; never commit them.

## Uploads and User Content

- Validate file type and size before persisting. Store files under `storage/` and serve them through the configured filesystem driver, never by reflecting user-controlled paths.

## Dependency Scanning

- Run `uv audit` (or `pip-audit`) periodically to check for known vulnerabilities in dependencies. Automate it in CI.

## Rate Limiting

- Protect authentication and other brute-force-prone routes with the `throttle` middleware:
  ```python
  Route.post("/login", "AuthController@login").middleware("throttle:login")
  ```
