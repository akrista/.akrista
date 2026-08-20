# Views (Jinja2) Best Practices

Masonite renders Jinja2 templates from `templates/`. Render via the injected `View`:

```python
def index(self, request: Request, view: View):
    return view.render("app.roles.index", {"role_data": role_data, "user": user})
```

## Template Inheritance

Extend a base layout and fill blocks:

```jinja2
{% extends 'app/layout.html' %}

{% block title %}Roles - Tetra{% endblock %}

{% block app_content %}
  ...
{% endblock %}
```

## No Logic Heavy Lifting

Templates iterate and display; they do not query or compute domain logic. Pass prepared data from the controller (see `rules/db-performance.md`).

## Reuse via Partials

Extract repeated markup (nav, forms, table rows) into partial templates and include them. Match the repo's existing convention for partials.

## Expression Syntax

- `{{ expr }}` — escaped output.
- `{% if %}`, `{% for %}`, `{% block %}` — control flow.
- Filters pipe: `{{ item.permissions | join(', ') }}`.

## No Inline JS/CSS

Keep styling in the project's CSS pipeline (Tailwind, see the `tailwindcss-development` skill) and scripts in bundled JS. Pass data to JS via data attributes or a small inline payload, not ad-hoc global scripts.

## Dark Mode and Design Tokens

Match the existing layout's conventions (design system, dark mode variants) rather than inventing a parallel styling approach.
