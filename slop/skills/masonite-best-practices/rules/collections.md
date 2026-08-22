# Collections and Iteration Best Practices (Python)

Python idioms replace the framework "collection" abstractions you may know from other stacks.

## Favor Readable Comprehensions

Build and transform lists/dicts with comprehensions over manual loops:

```python
role_data = [
    {
        "role": role,
        "permissions": [p.name for p in role.permissions],
        "user_count": builder.table("role_user").where("role_id", role.id).count(),
    }
    for role in roles
]
```

## Use the Standard Library Before Writing Helpers

`itertools` (chain, groupby, islice), `functools` (lru_cache, reduce), `collections` (defaultdict, Counter) cover most transformation needs. Reach for them before a custom helper (see `rules/architecture.md`).

## Lazy Iteration for Large Data

Prefer generators and `yield` when materializing the whole collection is wasteful:

```python
def permission_slugs(self) -> set[str]:
    return {p.slug for role in self.roles for p in role.permissions}
```

## Dedupe with Sets

Use `set` semantics for uniqueness/containment checks (`slug in self.permission_slugs()`) instead of repeated list scans.

## Bulk Operations

For writes over many rows, prefer the ORM's bulk operations over a loop of single inserts. Check the builder for `bulk_create`-style support before writing per-row loops.

## Don't Re-implement

If the codebase already has a helper (`app/utils`), reuse it. Check before writing.
