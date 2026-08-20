# Outbound HTTP Requests

Use the installed HTTP client (the repo already depends on `requests`; prefer `httpx` only if the project adds it) for all outbound calls.

## Timeouts Always

Every call needs a timeout; a default socket timeout can hang a request forever:

```python
import requests

resp = requests.get(url, timeout=10)
resp.raise_for_status()  # don't silently continue on failure
```

## Errors Are Data

- Never swallow exceptions or ignore status codes. Handle or propagate (see `rules/error-handling.md`).
- Check `resp.ok` / `resp.raise_for_status()` before reading `.json()`.

## Retries With Backoff

For flaky external services, retry with exponential backoff. Prefer a small helper or the `requests` adapters over hand-rolled loops; keep the retry count and backoff explicit.

## Do It Out of the Request Path

External API calls belong in a job or a service invoked from one, not inline in a controller hot path (see `rules/queue-jobs.md`).

## Fake It in Tests

Tests must not hit real networks. Monkeypatch the HTTP function or inject a fake client; assert on the request the code made (method, URL, payload) and return a canned response. See `rules/testing.md`.

## Secrets in Requests

Never log URLs or bodies that carry tokens, passwords, or API keys.
