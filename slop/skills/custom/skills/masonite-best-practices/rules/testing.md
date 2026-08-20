# Testing Best Practices (pytest)

Tests live in `tests/` and run with `pytest`. The repo's `tests/TestCase.py` extends `masonite.tests.TestCase` and sets up the app, wipes tables between tests, and provides factories.

## Structure

- Each feature area gets its own test module (`test_auth.py`, `test_roles.py`, `test_users.py`).
- Extend the shared `TestCase` and use its helpers (`make_tenant`, `make_user`, `make_role`, `login_as`) instead of repeating setup.

## Style

```python
def test_non_owner_cannot_manage_roles(self):
    self.login_as(self.make_user(owner=False))
    response = self.get("/roles")
    self.assertEqual(response.status, "302")  # redirected, not rendered
```

## What to Test

- Happy paths and every user-reachable error path (see `rules/error-handling.md`): invalid input, missing record, unauthorized access.
- Authorization: a user without the permission must be redirected/denied.
- Tenant isolation: one tenant's data must never leak into another's queries.

## Isolation

- The base `TestCase` wipes tables and flushes the throttle cache between tests. Don't rely on ordering between tests.
- Don't hit real external services or SMTP. Fake HTTP (see `rules/http-client.md`) and assert on mailables without sending.

## Run Narrow First

Run the changed module's tests first, then the full suite, then `ruff check` and `ruff format --check` to match the project's lint gate.
