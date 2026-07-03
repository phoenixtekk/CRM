# 7. Best Practices — Enterprise App & Service Principal Governance (Government / GCC High)

- Always confirm the sovereign cloud first. Sign in at `entra.microsoft.us` and connect Graph with
  `-Environment USGov`. A single Commercial-endpoint call against a GCC High tenant fails silently or
  authenticates the wrong tenant — verify `(Get-MgContext).Environment` is `USGov` before you act.
- Restrict user consent — the single most important control. Allow user consent only for verified
  publishers and low-risk delegated permissions; never leave it on `Allow user consent for all apps`.
  This is what stops consent-phishing before a user can be tricked.
- Turn on the admin-consent workflow. Blocking user consent without a request path just drives
  shadow IT; let users request an app and have a named reviewer group approve or deny it.
- Treat application permissions as tenant-wide breach potential. Scrutinize every app holding
  application permissions (especially `*.ReadWrite.All`, `Directory.*`, `Mail.*`, full-mailbox or
  full-directory scopes); grant them only to apps that truly need them, and only by admin consent.
  On a CUI/ITAR tenant this blast radius is controlled-data exposure — hold the line harder.
- Enforce least privilege. Cut every app back to the permissions it actually uses; unused permission
  is pure blast radius if the app or its secret is stolen.
- Every app needs an owner. Unowned apps are how sprawl becomes risk — assign an owner to each app so
  someone can answer for it and rotate its credentials.
- Prefer certificates over long-lived secrets. Use a certificate for app-only authentication, keep
  secret lifetimes short, and never let a credential sit with no expiry — a leaked long-lived secret
  on a sovereign tenant is a data-spill risk.
- Track expiry proactively. Run the report on a schedule and rotate before expiry so integrations
  never break by surprise; prune stale and surplus credentials so a leaked secret has a short life.
- Stage and preview every removal. Revoking a permission or deleting an app can break a legitimate
  integration — always run remediation in `-WhatIf` preview first, confirm with the owner, then apply
  to the reviewed apps only.
- Do not depend on features that are not in GCC High. Microsoft Entra threat intelligence risk
  detection is not available, and Graph Explorer is not supported — use the over-permission report
  and the PowerShell scripts. Check `gcc-high-parity-notes.md` before building any step on an
  adjacent feature.
- Make it recurring, not one-time. New apps and grants appear constantly; re-run discovery and the
  report on a cadence so governance is a standing process.
- Document the estate. Record each app's owner, purpose, permissions, and credential-rotation date
  for audits and repeatability — GCC High tenants are frequently audited (CMMC/ITAR), and this
  record is your evidence.
