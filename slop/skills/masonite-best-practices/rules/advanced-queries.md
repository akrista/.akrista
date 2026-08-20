# Advanced Queries

Complex queries belong in the ORM, not raw SQL strings, unless the ORM cannot express the plan you need.

## Aggregates and Counts

Masonite ORM exposes aggregate methods directly on the builder:

```python
builder.table("role_user").where("role_id", role.id).count()
User.where("tenant_id", user.tenant_id).count()
builder.table("payments").sum("amount")
```

## Conditional Query Building

`when()` keeps conditionals inside the builder chain instead of building queries by string concatenation:

```python
roles = Role.where("tenant_id", user.tenant_id)
roles.when(search, lambda q: q.where("name", "like", f"%{search}%"))
```

## Relationship Existence Filters

`has()` filters by the existence of a relationship (emits an `EXISTS`-style correlated query). Prefer it over loading rows:

```python
users = User.has("roles").get()  # users that have at least one role
users = User.doesnt_have("roles").get()  # users with no roles
```

## Subqueries for Index-Friendly Lookups

When you must filter parent rows on a child condition, prefer a subquery on the primary key over a correlated re-execution:

```python
ids = builder.table("role_user").select("user_id").where("role_id", role.id)
users = User.where_in("id", ids).get()
```

## Query Logging

Debug with the connection's query log, then remove it before finishing:

```python
from config.database import DB

DB.get_connection_details()  # confirm connection
connection.get_query_log()  # list of queries run so far
```

## Verify the Plan

For slow queries, check that the index exists (see `rules/migrations.md`) and that the filtered columns are actually indexed. An index on paper that the ORM query doesn't hit is no faster.
