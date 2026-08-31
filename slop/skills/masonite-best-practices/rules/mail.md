# Mail Best Practices

Masonite's `MailProvider` sends email via the configured driver. Mailables in `app/mailables` build message content.

## Structure

Each email is a `Mailable` subclass in `app/mailables` (the repo already has `VerifyEmailMailable`, `PasswordResetMailable`). Follow that existing shape.

## Build Content in the Mailable

Template rendering and payload assembly belong in the mailable, not the controller:

```python
class VerifyEmailMailable(Mailable):
    def __init__(self, user, token):
        self.user = user
        self.token = token

    def build(self):
        return (
            self.to(self.user.email)
            .subject("Verify your email")
            .from_("no-reply@example.com")
            .template("emails.verify", {"user": self.user, "token": self.token})
        )
```

## Send

```python
from masonite.facades import Mail

Mail().send(VerifyEmailMailable(user, token))
```

Match the repo's existing access pattern for sending.

## When to Send

- Auth emails (verification, reset) send inside the request flow only when fast enough; otherwise dispatch through a job (see `rules/queue-jobs.md`).
- Never put secrets in the subject or log message bodies.

## Testing

Assert on what would be sent without delivering: check the mailable's recipient/subject/template data. Do not hit a real SMTP server in tests.
