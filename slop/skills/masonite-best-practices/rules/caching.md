# Caching Best Practices

Masonite's `CacheProvider` registers the `cache` container binding. Use it for expensive, slow-changing values — never as a substitute for correct queries.

## Basic Usage

```python
cache = container.make("cache")
cache.store().put("key", value, seconds=3600)  # TTL in seconds
value = cache.store().get("key", default)  # None or default when missing
cache.store().flush()  # clear everything (tests, deploys)
```

Match the repo's existing access pattern (`container.make("cache")` vs. a facade).

## Rule of Thumb

Cache only what is demonstrably expensive: repeated identical queries, rendered fragments, external API responses, computed aggregates. Adding cache "for safety" adds invalidation bugs.

## Cache Keys

- Namespace by entity and tenant: `"user:{user_id}:roles"`, `"tenant:{tenant_id}:stats"`.
- Never build keys from unvalidated user input directly.

## Invalidation Over TTL

Prefer explicit invalidation on writes over long TTLs when the data must be fresh:

```python
cache.store().forget("user:{user_id}:roles")  # after roles change
```

A short TTL (seconds to minutes) is a safety net, not the primary mechanism.

## Memoization

For repeated pure computation inside a request, prefer Python-level memoization or module-level caching over the store — only cross-request data needs the cache service.

## Don't Cache What's Already Fast

A covered indexed lookup is fast; caching it adds a second source of truth for nothing. See `rules/db-performance.md` before reaching for the cache.
