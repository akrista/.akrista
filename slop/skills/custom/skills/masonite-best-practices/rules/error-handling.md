# Error Handling Best Practices

## Exceptions Are the Contract

Let exceptions propagate unless you can recover meaningfully. Never `except Exception: pass` — a swallowed error hides the exact bug you'll chase at 3am. If a failure is expected (best-effort cleanup, optional third-party call), catch the narrow exception and log it.

## Narrow Excepts

Catch the specific exception you expect, not `Exception`:

```python
try:
    role_id = int(request.param("id"))
except (TypeError, ValueError):
    return None
```

## Log with Context

Include the discriminating values (ids, tenant, operation) in the log line so you can reproduce the failure:

```python
logger.error("failed to sync permissions for role %s (tenant %s)", role_id, tenant_id)
```

Log via the configured logger (Masonite `LoggingProvider`) — print is not production logging.

## HTTP Error Responses

Handle known failure modes at the controller boundary with a redirect or error response, not a raw traceback. Match the repo's existing pattern (`response.redirect(...).with_errors(...)`, `response.status(404)`).

## Validate Before You Touch the Database

Most "errors" are bad input, not system failures. Validate first (see `rules/validation.md`), then do work, then handle genuine exceptions around the work itself.

## Tests Cover Error Paths

Every error branch a user can hit needs a test: wrong input, missing record, unauthorized access. See `rules/testing.md`.
