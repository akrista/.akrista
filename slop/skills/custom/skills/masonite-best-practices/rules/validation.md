# Validation Best Practices

Masonite's `ValidationProvider` registers `request.validate()` for rule-based validation.

## Validate at the Boundary

Validate once, at the controller, before any database work. A dict of rules in, an `errors` dict out:

```python
def store(self, request: Request, response: Response):
    errors = request.validate({"name": "required"})
    if errors:
        return response.redirect("/roles/create").with_errors(errors)

    name = request.input("name")
    ...
```

## Rules Reference

Rules are pipe-separated strings, e.g. `"required|email"`, `"min:6"`, `"max:120"`, `"integer"`. Chain as needed:

```python
errors = request.validate(
    {
        "email": "required|email",
        "password": "required|min:6",
    }
)
```

## Read Input With Defaults

`request.input(name, default)` returns the default when the field is missing — use this instead of keying into the raw payload:

```python
selected = request.input("permissions", [])
if isinstance(selected, str):
    selected = [selected]
```

## Errors and Flash

Redirect back to the form with errors via `with_errors(errors)`; the `web` middleware group (`ShareErrorsInSessionMiddleware`) exposes them to the template.

## Re-validate Business Rules After Form Validation

Form rules cover shape, not domain constraints. Check uniqueness, ownership, and cross-field invariants after validation:

```python
dup = (
    Role.where("tenant_id", user.tenant_id)
    .where("slug", slug)
    .where("id", "!=", role.id)
    .first()
)
if dup:
    return response.redirect(f"/roles/{role.id}/edit").with_errors(
        {"name": "A role with this name already exists."}
    )
```

## Never Trust Client-Side Validation Alone

Client-side checks are UX, not security. Server-side `request.validate()` is the authority.
