# Migrations Best Practices

Masonite ORM migrations are Python files in `databases/migrations/`. They are the single source of truth for schema.

## Structure

One migration class per concern, named by timestamp prefix so they apply in order:

```python
from masoniteorm.migrations import Migration


class CreateRbacTables(Migration):
    def up(self):
        with self.schema.create("roles") as table:
            table.integer("id", length=11)
            table._last_column.set_as_primary()
            table.string("name", length=120)
            table.string("slug", length=60)
            table.unsigned_integer("tenant_id")
            table.foreign("tenant_id").references("id").on("tenants").on_delete(
                "cascade"
            )
            table.unique(["tenant_id", "slug"])
            table.timestamps()

    def down(self):
        self.schema.drop_table("roles")
```

## Rules

- Use the `craft migration` command (`craft migration create_xxx_table`) so the timestamp prefix is consistent. Follow whatever the repo already does.
- Every table gets a primary key. Masonite ORM convention: `table.integer("id", length=11)` then `table._last_column.set_as_primary()`.
- Foreign keys get `on_delete` semantics. Use `"cascade"` for ownership (tenant, user) and keep child rows' references consistent.
- Add `unique()` constraints for dedupe keys — they also create useful indexes (`["tenant_id", "slug"]`).
- Add `.unique()` or `.index()` on any column you filter or order by (see `rules/db-performance.md`).
- `table.timestamps()` adds `created_at`/`updated_at`; keep it unless there's a reason not to.
- `down()` must be the exact inverse of `up()` — drop tables in reverse dependency order (children first).

## Data Migrations

Keep structural migrations and data provisioning separate. A data migration can call a shared bootstrap helper so seeders and the register flow reuse the same logic:

```python
from app.utils.rbac import seed_app_basics


class SeedAppBasics(Migration):
    def up(self):
        seed_app_basics()

    def down(self):
        pass  # data-only; nothing structural to roll back
```

## Never Edit a Migrated Schema by Hand

Change schema only through a new migration. Existing migrations are history.
