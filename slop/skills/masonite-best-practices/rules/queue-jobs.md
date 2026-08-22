# Queue Jobs Best Practices

Masonite's `QueueProvider` provides background job processing. Long-running or failure-prone work (email, notifications, external APIs) belongs in jobs, not the request lifecycle.

## When to Queue

Queue anything the user doesn't need to wait for: mail, webhooks, image processing, bulk imports. Keep the request path for work that must complete before the response.

## Structure

Jobs are classes with a `handle` method (and optionally a `failed` method). Build them with `craft job`, matching the repo's existing conventions.

## Retries and Failure Handling

- Design jobs to be idempotent — a retry must not duplicate effects (guard inserts with `first_or_create`, unique constraints, or a processed-flag).
- Implement `failed()` to log or notify instead of silently swallowing.
- Keep job payloads small and serializable; pass IDs, not ORM objects.

## Queueing from Controllers

Dispatch the job and return immediately:

```python
from app.jobs.SendWelcomeMail import SendWelcomeMail

queue = container.make("queue")
queue.push(SendWelcomeMail, {"user_id": user.id})
```

Check the repo's existing dispatch pattern (queue facade vs. container) and match it.

## Running Workers

- Development: run the worker with `craft queue:work`.
- Production: a worker process per queue is required; deploy and supervise it (systemd/supervisor). A web request never runs a job.

## Testing

In tests, make the queue synchronous or assert on the dispatched job payload rather than firing real workers. See `rules/testing.md`.

## Keep Jobs Independent

A job should be able to run in isolation. If it depends on another job's side effects, that ordering must be explicit (queue + chain semantics the repo already uses), never implicit.
