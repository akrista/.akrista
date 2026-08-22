# Python Style Best Practices

Consistency with the codebase beats any single style rule. The repo uses `ruff` for lint and format; `pyproject.toml` holds the config.

## Naming Conventions

- Modules/files: `snake_case.py` normally, but Masonite conventions use PascalCase filenames for classes in `app/` (e.g. `RoleController.py`). Follow what the repo already does.
- Functions, variables, methods: `snake_case`.
- Classes, constants: `PascalCase` / `UPPER_SNAKE_CASE`.
- Private helpers: leading underscore (`_find`, `_sync_permissions`).

## Type Hints

Annotate signatures with types and `ClassVar` for class attributes:

```python
from typing import ClassVar


class User(Model, Authenticates, Notifiable):
    __fillable__: ClassVar[list[str]] = ["name", "email", "password"]


def permission_slugs(self) -> set[str]: ...
```

## Docstrings

Module-level docstrings describe the module's purpose (the repo uses them on every model/controller). One-line docstrings for non-obvious methods. No comments that restate the code.

## Prefer Python Idioms Over Helpers

Use comprehensions, `set`/`dict` operations, and the standard library before introducing custom helpers (see `rules/collections.md`). Check `app/utils` for existing helpers before writing new ones.

## File Boundaries

- Controllers: HTTP concerns only, thin.
- Models: data + domain helpers.
- Reusable logic: `app/utils` modules (the repo has `slugify`, `rbac` there).
- Keep one cohesive responsibility per file.

## Formatting and Lint

Run before finishing:

```bash
ruff check .
ruff format --check .
```

`ruff format` is the repo's formatter — don't hand-format to fight it. The lint gate includes the `N999` exception already configured in `pyproject.toml`.
