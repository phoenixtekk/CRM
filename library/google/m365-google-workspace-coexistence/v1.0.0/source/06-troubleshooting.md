# 6. Troubleshooting — Microsoft 365 ↔ Google Workspace Coexistence

Symptom → likely cause → fix, organized by pillar. Reuse the named objects from
`03-implementation.md`. When a fix requires a change, prefer `GWCOEX-Remediation.ps1` (default
`-WhatIf`) so you can review before applying. Always re-run the matching `05-testing.md` row after a fix.

---

## Mail routing / split delivery

### Mail to a valid recipient on the *other* platform bounces (NDR: recipient not found)
- **Cause:** the shared domain is still **Authoritative** on the receiving platform, so it rejects
  recipients it doesn't host instead of relaying.
- **Fix:** on Exchange, set `contoso.com` Accepted Domain to **Internal relay**; on Google, ensure the
  **`Coexistence – Split Delivery`** routing rule is enabled and targets **`Coexistence – M365 Host`**.
  Verify the outbound path (`Coexistence – EXO→Google Connector` / the Google host) exists and is on.

### Relayed mail loops or bounces with "too many hops"
- **Cause:** *both* platforms are relaying the same domain to each other with no authoritative owner for
  a nonexistent address — the message ping-pongs.
- **Fix:** confirm exactly **one MX-primary** (R4). A message for a truly nonexistent recipient must
  bounce cleanly on the MX-primary; it should not be relayed onward. Re-check the split-delivery scope
  so only *unknown-locally* recipients relay.

### Relayed mail is marked spam or fails authentication at the far platform
- **Cause:** **SPF** doesn't authorize both senders, or **DKIM** isn't signing on the relaying platform.
- **Fix:** publish one SPF TXT with `include:_spf.google.com include:spf.protection.outlook.com`; enable
  a **separate DKIM selector** per platform. Audit SPF for the **10-lookup limit**. Keep **DMARC** at a
  monitoring policy until both align.

### Some pilot users route, others NDR
- **Cause:** the relay/split-delivery rule is scoped to the pilot but the failing user isn't in
  **`Coexistence – Pilot Members`** (or the connector transport rule excludes them).
- **Fix:** confirm scope with `GWCOEX-Set-ScopeTargeting.ps1` (default `-WhatIf`); add the user or widen
  the scope, then re-test.

### Relayed mail is delivered in cleartext / TLS warnings
- **Cause:** the connector or Google host isn't requiring TLS.
- **Fix:** enable **Require TLS** on `Coexistence – EXO→Google Connector` and the Google host
  `Coexistence – M365 Host`.

---

## Free/busy calendar interop

### Google user sees an Exchange user as blank / "no information"
- **Cause:** the **Exchange endpoint** or **`svc-interop-gcal@contoso.com`** role account is
  misconfigured, or the endpoint is unreachable.
- **Fix:** in **Calendar Interop management**, re-check the endpoint (Graph app credentials or the EWS
  URL `https://outlook.office365.com/EWS/Exchange.asmx`) and role account. Confirm the endpoint answers
  on **443** with a valid public-CA cert; if inbound is filtered, allowlist Google's Interop egress
  ranges.

### Outlook user sees a Google user as blank
- **Cause:** the **Google role account `svc-interop-exo@contoso.com`** isn't set in Interop, is
  Calendar-disabled, or the Exchange-side org availability sharing isn't pointed at Google.
- **Fix:** confirm the Google role account is a standard, Calendar-enabled user set in Interop; verify
  the Exchange organization availability/sharing configuration references it.

### Availability resolves but no event titles/locations
- **Cause:** detail level is **availability-only** (the default).
- **Fix:** enable **Show event details** in Interop (Google→Exchange) and raise the Exchange calendar
  detail level (e.g. `Set-MailboxCalendarFolder <user>:\Calendar -DetailLevel LimitedDetails`) where
  policy allows. Event-level privacy is still respected.

### Interop works for some users, not others
- **Cause:** the target user has a conflicting personal Google account on the domain, an Exchange
  mailbox issue, or isn't in scope yet.
- **Fix:** ensure interop-target users have no conflicting personal Google account and a healthy mailbox;
  confirm they're in the current scope.

### Endpoint type "Microsoft 365 (Graph API)" not available
- **Cause:** the Graph-API endpoint option is **preview/rolling-out** in your tenant.
- **Fix:** **verify in your tenant**; if unavailable, use the legacy **EWS** endpoint with modern-auth
  where supported, and revisit when Graph is offered.

---

## Directory sync

### A user on the other platform doesn't appear in the address book/GAL
- **Cause:** the cross-platform representation is missing — no Google **shared contact** for an M365-only
  user, or no Exchange **mail contact / mail user** for a Google-only user.
- **Fix:** confirm GCDS provisions shared contacts for M365-only recipients and that EXO mail contacts
  exist for Google-only recipients (create via `GWCOEX-Remediation.ps1`, default `-WhatIf`). Confirm the
  user is in the **`Coexistence – Synced`** OU/group.

### GCDS simulate-sync proposes mass deletions
- **Cause:** an over-broad or wrong **search rule / base DN**, so GCDS thinks synced objects should be
  removed.
- **Fix:** **do not run the real sync.** Correct the LDAP search rules / base DN to the intended
  **`Coexistence – Synced`** scope; re-**Simulate** until **Proposed changes** are as expected.

### Directory in Google is stale / out of date
- **Cause:** GCDS isn't scheduled, or its last run failed.
- **Fix:** confirm GCDS is scheduled on its interval and the last run succeeded; check the GCDS logs and
  LDAP connectivity (389/636).

### Duplicate or conflicting entries appear
- **Cause:** two systems are authoring the same user (the GAL diverges).
- **Fix:** enforce a **single source of truth**; ensure only one provisioning path writes each user, and
  that shared contacts/mail contacts are only used for the *other* platform's recipients.

---

## Cross-cutting

### `GWCOEX-*.ps1` fails to connect
- **Cause:** the Graph SDK / Exchange Online module isn't installed, or consent/scopes are missing.
- **Fix:** `Install-Module Microsoft.Graph`, `Install-Module ExchangeOnlineManagement`; sign in with an
  admin that can consent to the required read scopes (see each script's header). Discovery/Validation/
  Report are read-only.

### A remediation applied the wrong change
- **Cause:** `-Apply` was run without reviewing the `-WhatIf` plan.
- **Fix:** revert using the Phase 1 baseline (accepted-domain type, connector state, DNS). Re-run the
  script in default `-WhatIf` mode, review, then `-Apply`.

> After every fix, re-run the corresponding **`05-testing.md`** check and, before declaring resolution,
> re-run `GWCOEX-Report.ps1` to confirm coverage didn't regress elsewhere.
