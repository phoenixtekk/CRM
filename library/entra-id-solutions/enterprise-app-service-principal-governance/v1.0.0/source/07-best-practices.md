# 7. Best Practices — Enterprise App & Service Principal Governance

- Restrict user consent — the single most important control. Allow user consent only for verified
  publishers and low-risk delegated permissions; never leave it on `Allow user consent for all apps`.
  This is what stops consent-phishing before a user can be tricked.
- Turn on the admin-consent workflow. Blocking user consent without a request path just drives
  shadow IT; let users request an app and have a named reviewer group approve or deny it.
- Treat application permissions as tenant-wide breach potential. Scrutinize every app holding
  application permissions (especially `*.ReadWrite.All`, `Directory.*`, `Mail.*`, full-mailbox or
  full-directory scopes); grant them only to apps that truly need them, and only by admin consent.
- Enforce least privilege. Cut every app back to the permissions it actually uses; unused permission
  is pure blast radius if the app or its secret is stolen.
- Every app needs an owner. Unowned apps are how sprawl becomes risk — assign an owner to each app so
  someone can answer for it and rotate its credentials.
- Prefer certificates over long-lived secrets. Use a certificate for app-only authentication, keep
  secret lifetimes short, and never let a credential sit with no expiry.
- Track expiry proactively. Run the report on a schedule and rotate before expiry so integrations
  never break by surprise; prune stale and surplus credentials so a leaked secret has a short life.
- Stage and preview every removal. Revoking a permission or deleting an app can break a legitimate
  integration — always run remediation in `-WhatIf` preview first, confirm with the owner, then apply
  to the reviewed apps only.
- Make it recurring, not one-time. New apps and grants appear constantly; re-run discovery and the
  report on a cadence so governance is a standing process.
- Document the estate. Record each app's owner, purpose, permissions, and credential-rotation date
  for audits and repeatability.
