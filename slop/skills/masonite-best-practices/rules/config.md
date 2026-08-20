# Configuration Best Practices

## Environment-Driven Configuration

`LoadEnvironment` (booted in `app/Kernel.py`) loads `.env` into the process. Read values with `os.getenv` (or the repo's helper) with a default:

```python
def _env(name: str, default: str) -> str:
    return os.getenv(name, default)
```

- Never hardcode secrets or environment-specific values in source (see `rules/security.md`).
- Keep `.env-example` current with every new variable so a fresh checkout documents what's needed.

## Config Modules

`config/*.py` modules hold application settings (database, mail, cache, session, security). Access them through Masonite's configuration container rather than importing the module directly when the framework expects the container:

```python
from masonite.configuration import config

config("database.connections.sqlite.driver")
```

Match the repo's existing config access pattern.

## Provider Registration

Services are enabled by registering providers in `config/providers.py` and, when needed, wiring them in `app/Kernel.py`. Adding a new framework feature means registering its provider — don't hand-roll the integration if the framework ships one.

## Keep Configuration Minimal

Don't add config keys nothing reads. YAGNI — a value that never varies belongs in code, not config.
