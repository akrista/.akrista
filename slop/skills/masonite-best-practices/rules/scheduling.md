# Scheduling Best Practices

Masonite's `ScheduleProvider` registers recurring tasks. Scheduled jobs are the correct home for periodic maintenance, digests, and cleanup.

## Define Schedules

Add tasks in the schedule registration (the repo's `ScheduleProvider` / `config` area). Use the framework's interval syntax, matching the existing pattern:

```python
from masonite.scheduling import Schedule

schedule = container.make("schedule")
schedule.command("your:command")  # run a craft command
schedule.call(job_fn, ...)  # run a callable
schedule.command("your:command").daily()  # with a cadence
```

## Idempotency and Overlap

- Scheduled tasks must be safe to run twice — the same guardrails as jobs (see `rules/queue-jobs.md`).
- Prevent overlapping runs where a long task could still be running when the next tick fires; add a lock/flag the repo already uses or a documented skip.

## Keep Them Short and Observable

- Each scheduled task does one thing and logs its outcome with enough context to debug.
- Cron (external) and `craft schedule:work` (process) are both valid; use whichever the deployment already runs. Don't double-schedule the same task through both.

## Not for User-Initiated Work

User actions go through routes/jobs, not the scheduler. Scheduling is for unattended, recurring work only.
