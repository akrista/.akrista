# Routing, Controllers, and Middleware

## Route Definitions

Define all routes in `routes/web.py` as a `ROUTES` list:

```python
from masonite.routes import Route

ROUTES = [
    Route.get("/", "WelcomeController@show").name("welcome"),
    Route.post("/users", "UserController@store").middleware(
        "auth", "permission:users.manage"
    ),
]
```

- `"Controller@method"` binds a route to a controller method.
- `.name("...")` gives the route a reversible name.
- `.middleware(...)` applies one or more middleware aliases.

## Route Parameters

Capture URL segments with `@param`:

```python
Route.get("/roles/@id/edit", "RoleController@edit")
```

Read them with `request.param("id")`. Validate and coerce before use:

```python
try:
    role_id = int(request.param("id"))
except (TypeError, ValueError):
    return None
```

## Controllers

- Controllers inherit from `masonite.controllers.Controller` and receive `request`, `response`, and `view` via dependency injection:

```python
from masonite.controllers import Controller
from masonite.request import Request
from masonite.response import Response
from masonite.views import View


class RoleController(Controller):
    def index(self, request: Request, view: View): ...
```

- Keep controllers thin: validation, auth, and orchestration. Move reused domain logic to model helpers or service modules.
- Scope every query by the current tenant/owner: `Role.where("tenant_id", user.tenant_id)`.

## Middleware

Route middleware lives in `app/Kernel.py` under `route_middleware`, keyed by alias:

```python
route_middleware: ClassVar[dict[str, list[type]]] = {
    "web": [
        SessionMiddleware,
        LoadUserMiddleware,
        TenantContextMiddleware,
        VerifyCsrfToken,
    ],
    "auth": [AuthenticationMiddleware],
    "permission": [PermissionMiddleware],
    "throttle": [ThrottleRequestsMiddleware],
}
```

A middleware implements `before(request, response, *args)` and `after(request, response, *args)`. Return `request` to continue, or short-circuit with a response:

```python
from masonite.middleware import Middleware


class PermissionMiddleware(Middleware):
    def before(self, request, response, *args):
        user = request.user()
        if not user:
            return response.redirect(name="login")
        if user.can(args[0]):
            return request
        return response.redirect(name="dashboard")
```

- Global middleware goes in `http_middleware`.
- Group middleware (`web`) applies to every request using the route's group.

## Route Groups

When a set of routes shares middleware, apply it to each route explicitly (as above) or group them where the app's existing convention calls for it. Consistency with existing routes wins.
