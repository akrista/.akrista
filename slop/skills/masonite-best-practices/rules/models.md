# Model Best Practices (Masonite ORM)

Models wrap one table each. They hold relationships, casts, and domain helpers — not HTTP concerns.

## Define Fillable and Hidden Explicitly

`__fillable__` controls mass assignment; `__hidden__` keeps secrets out of serialization:

```python
class User(Model, Authenticates, Notifiable):
    __fillable__: ClassVar[list[str]] = [
        "name",
        "email",
        "password",
        "phone",
        "tenant_id",
        "is_owner",
        "verified_at",
    ]
    __hidden__: ClassVar[list[str]] = ["password", "remember_token"]
    __auth__ = "email"
```

Never put `password` (or any secret) in `__fillable__` unless the caller hashes it first.

## Relationships

Use the relationship decorators; they reference the related model lazily to avoid import cycles:

```python
@belongs_to("tenant_id", "id")
def tenant(self):
    from app.models.Tenant import Tenant

    return Tenant


@belongs_to_many(
    local_foreign_key="user_id",
    other_foreign_key="role_id",
    table="role_user",
)
def roles(self):
    from app.models.Role import Role

    return Role
```

Keep the pivot table name and both foreign keys explicit. Eager-load with `with_("roles")` to avoid N+1 (see [`rules/db-performance.md`](db-performance.md)).

## Model Scopes and Domain Helpers

Put reusable query fragments and domain logic on the model, not in controllers:

```python
def permission_slugs(self) -> set[str]:
    slugs = set()
    for role in self.roles:
        for permission in role.permissions:
            slugs.add(permission.slug)
    return slugs


def can(self, slug: str) -> bool:
    if self.is_owner:
        return True
    return slug in self.permission_slugs()
```

## Timestamps

`table.timestamps()` in the migration adds `created_at`/`updated_at`. Masonite ORM maintains them automatically.

## Model Factories vs Direct Create

For tests, create via the model with explicit attributes (see [`rules/testing.md`](testing.md)). Use `first_or_create` for idempotent seeders:

```python
role = Role.first_or_create(
    {"tenant_id": tenant_id, "slug": attrs["slug"]},
    {"name": attrs["name"], "slug": attrs["slug"], "tenant_id": tenant_id},
)
```

## Keep Raw SQL Out

Prefer the ORM and relationships over `builder.table()` or raw SQL whenever the model already describes the table. Use the query builder only for bare pivot aggregates that the relationship API can't express.
