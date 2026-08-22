---
name: masonite-permission-development
description: Build and work with the tenant-scoped RBAC permission system in this Masonite app — roles, permissions, pivot tables, the `permission:slug` middleware, `User.can()`, and seeding the permission catalog.
license: MIT
metadata:
  author: Jorge Thomas
---

# Masonite Permission Development

This skill documents the RBAC pattern used in this application. It is a custom, tenant-scoped roles/permissions system built on Masonite ORM models — not a package.

## Core Concepts

- **Users have Roles, Roles have Permissions. Apps check Permissions (not Roles).**
- Direct permission checks against the catalog are the norm; roles are the grouping layer.
- The `User` model exposes `can(slug)` for every authorization decision. `is_owner` bypasses all checks.
- **Tenant-scoping is mandatory**: roles belong to a tenant (`tenant_id`), and every role query must be scoped to the current user's tenant.

## Models

The four tables and their pivots (see `databases/migrations/2026_08_05_000001_create_rbac_tables.py`):

- `roles` — `name`, `slug`, `tenant_id`; unique on `["tenant_id", "slug"]`.
- `permissions` — global catalog; `slug` (unique) + `name`.
- `permission_role` — pivot: `role_id` ↔ `permission_id`.
- `role_user` — pivot: `user_id` ↔ `role_id`.

Relationships live on the models:

```python
class User(Model, Authenticates, Notifiable):
    @belongs_to_many(
        local_foreign_key="user_id", other_foreign_key="role_id", table="role_user"
    )
    def roles(self):
        from app.models.Role import Role

        return Role

    def can(self, slug: str) -> bool:
        if self.is_owner:
            return True
        return slug in self.permission_slugs()

    def permission_slugs(self) -> set[str]:
        return {p.slug for role in self.roles for p in role.permissions}
```

`Role` mirrors this with `permissions` (`table="permission_role"`) and `permission_slugs()`.

## Authorization Checks

Always use `user.can(slug)` — it honors the `is_owner` bypass:

```python
if not user.can("users.manage"):
    return response.redirect(name="dashboard")
```

Never check `is_owner` or role names ad hoc in controllers when `can()` is the established pattern.

## Route Middleware

Gate routes with `permission:<slug>` (alias registered in `app/Kernel.py` as `"permission": [PermissionMiddleware]`):

```python
Route.get("/users", "UserController@index").middleware(
    "auth", "permission:users.manage"
)
```

`PermissionMiddleware` redirects anonymous users to `login` and unauthorized users to `dashboard`. The `auth` middleware should precede `permission` so the user exists before `request.user()` is used.

## Permission Catalog

The catalog lives in `app/utils/rbac.py` as `PERMISSIONS = [(slug, name), ...]`. Current entries:

- `users.manage` — "Manage users"
- `roles.manage` — "Manage roles"

When a new permission is needed, add it to `PERMISSIONS` so `sync_permission_catalog()` picks it up (idempotent).

## Seeding

`app/utils/rbac.py` provides idempotent bootstrap helpers used by migrations and the register flow:

- `sync_permission_catalog()` — `first_or_create` any missing permissions.
- `ensure_roles(tenant_id)` — creates the standard `admin` / `user` roles for a tenant; the `admin` role gets every catalog permission.
- `seed_app_basics()` — provisions permissions, a default tenant, roles, and the owner on migrate.

Use `first_or_create` for roles/permissions so seeding is safe to re-run. For pivot rows, insert via the query builder with `table("permission_role").create({...})` after checking for duplicates.

## Managing Roles and Permissions

The reference implementation is `app/controllers/RoleController.py`:

- Every role query is scoped: `Role.where("tenant_id", user.tenant_id)`.
- `_grantable_permissions(user)` returns permissions the user is allowed to grant (owner sees all; others see only what they themselves hold).
- `_sync_permissions(request, user, role)` replaces a role's pivot rows, skipping slugs the user may not grant — never let a user escalate beyond their own permissions.
- Uniqueness of `slug` is enforced per tenant (`where("slug", slug).first()`), plus the DB unique constraint.

## Tenant Isolation

Roles and the `role_user` pivots are tenant-scoped; `permissions` is a shared global catalog. When editing/deleting a role, re-verify ownership:

```python
role = Role.where("id", role_id).where("tenant_id", request.user().tenant_id).first()
```

## Testing

`tests/TestCase.py` provides `make_role(tenant, name, permissions)` which creates a role and its pivot rows. Write tests for: owner bypass, non-owner denial, tenant isolation, and escalation attempts (non-owner granting a permission they don't hold must be rejected).
