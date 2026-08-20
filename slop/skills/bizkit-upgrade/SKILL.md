---
name: bizkit-upgrade
description: Selectively pull upstream improvements, features, and bug fixes from the official akrista/bizkit repository into a project bootstrapped from it. Uses the built-in Artisan command or manual git comparisons while fully preserving the developer's custom changes.
license: MIT
metadata:
  author: Jorge Thomas
---

# Bizkit Starter Kit Upgrade

When an AI assistant works on a project bootstrapped from **akrista/bizkit**, use this skill to update the local codebase to the latest upstream version safely.

## Core Directives

1. **Prioritize the Artisan Command**: Always prefer using the built-in interactive command `php artisan bizkit:upgrade` as your primary driver.
2. **Never Auto-Overwrite**: Never automatically overwrite files that have custom user logic. If a file has local changes, surface the diff and let the user decide.
3. **Behavior Preservation**: The developer's existing test suite must still pass completely after the upgrade. If a regression occurs, offer to revert.

---

## The Upgrade Workflow

### Phase 1: Preflight Verification

Before modifying anything, ensure the working environment is safe:
- Run `git status --porcelain` to verify the working tree is clean. If dirty, stop and ask the user to commit or stash.
- Ensure the `bizkit.json` version file exists in the project root to detect the currently pinned version.

### Phase 2: Run the Upgrade Tool

Execute the upgrade command in dry-run mode first to preview what has changed:
```bash
php artisan bizkit:upgrade --dry-run
```

If the preview looks correct, execute the upgrade interactively:
```bash
php artisan bizkit:upgrade
```

### Phase 3: Interactive Diff Resolution

When the command flags files as **differs** (~):
1. Review the terminal diff displayed by the command.
2. If the upstream change is a generic bugfix or enhancement that does not touch custom business logic, choose `take` to apply it.
3. If it touches custom local features, choose `keep` and note it for manual integration later if needed.

### Phase 4: Verification

After applying the updates:
- Run the local linting checks:
  ```bash
  composer run lint:check
  ```
- Run the Pest test suite to ensure no regressions were introduced:
  ```bash
  php artisan test --compact
  ```

---

## Troubleshooting & Rollback

If the upgrade introduces syntax or runtime failures that cannot be easily fixed:
- Discard all upgrade modifications and restore the previous state cleanly:
  ```bash
  git checkout .
  git clean -fd
  ```
