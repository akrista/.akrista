# Database Performance Best Practices

Query performance failures are the most common production incident. Guard against them at the ORM level, not by sprinkling indexes later.

## Watch for the N+1 Problem

Loading a model and then accessing a relationship on each row fires one query per row:

```python
# BAD: fires 1 + N queries (one per role)
for role in Role.all():
    for permission in role.permissions:
        ...
```

Eager-load the relationship once with `with_()`:

```python
# GOOD: 2 queries total (roles + one join query)
roles = Role.with_("permissions").where("tenant_id", user.tenant_id).get()
```

When you only need a count, use `with_count()` instead of loading the full relationship:

```python
roles = Role.with_count("users").get()
for role in roles:
    role.users_count  # no extra query
```

## Add Indexes at Migration Time

Index every column used in `where()`, `order_by()`, `join()`, or a foreign key. Composite indexes matter for filters that always pair up:

```python
with self.schema.create("roles") as table:
    table.unsigned_integer("tenant_id")
    table.foreign("tenant_id").references("id").on("tenants").on_delete("cascade")
    table.unique(["tenant_id", "slug"])  # composite lookup key
```

`unique()` gives you both correctness (dedupe) and an index for the paired lookup. See [`rules/migrations.md`](migrations.md).

## No Queries in Templates

Never run queries inside Jinja2 templates. Pass prepared data from the controller:

```python
# GOOD
return view.render("app.roles.index", {"role_data": role_data})
```

## Prefer the Model API Over Raw Builders

Use `Model.where(...).get()` and relationships instead of `builder.table(...)` unless you need a bare aggregate or pivot:

```python
# GOOD: model + relationship, table name derived from the model
Role.with_("permissions").get()

# When a bare pivot aggregate is the goal, the query builder is fine:
builder.table("role_user").where("role_id", role.id).count()
```

## Paginate Large Result Sets

Never load thousands of rows into memory to render one page. Use `Model.paginate()`:

```python
users = User.where("tenant_id", user.tenant_id).paginate(25, page)
```

## Lazy Iteration for Read-Only Bulk Work

For one-off scripts that process large tables, stream rows instead of materializing a list:

```python
for role in Role.where("tenant_id", tenant_id).get():
    # process one at a time
```

## Benchmarks Before and After

When touching a hot query, note query count (`connection.get_query_log()`) and confirm the fix removes the N+1, not just moves it.
