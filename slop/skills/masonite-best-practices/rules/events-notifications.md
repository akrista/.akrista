# Events and Notifications

## Events

The `EventProvider` provides a pub/sub mechanism for decoupling code paths.

- Publish meaningful domain changes, not internal implementation steps.
- Keep listeners small and single-purpose. Registration style (container binding vs. decorator) should match the repo's existing convention.
- A listener that can fail (mail, HTTP) should not take down the caller; catch, log, and continue per the repo's pattern.
- Don't publish an event that has no listener yet — YAGNI. Add events when a second consumer appears.

## Notifications

Masonite notifications (`NotificationProvider` + `Notifiable` mixin on the model) handle multi-channel user-facing messages.

- Put the notification class in `app/notifications` following the repo's naming (mirroring `app/mailables`).
- The `Notifiable` mixin gives models notification methods; use them instead of reaching into the notification store manually.
- For password reset / email verification flows, prefer the framework's built-in auth mechanisms (see `app/utils` and `AuthController`) over re-implementing them.

## Idempotency

Notification/event side effects can be delivered more than once. Design handlers to be idempotent (see `rules/queue-jobs.md`).

## When Not To

- Don't use events for plain method calls — a direct call is clearer.
- Don't use notifications for log-only behavior; that's logging (see `rules/error-handling.md`).
