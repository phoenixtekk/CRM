# 7. Best Practices — Office & PDF Rights Protection (RMS/IRM)

Field-tested practices for making **persistent, label-based protection** actually protect — without
locking users out of their own content or breaking legitimate sharing. These complement the
Implementation and Testing guides.

## Designing usage rights (grant the least that works)
- **Right people, right rights — not just "encrypted".** Encryption alone is blunt; the value is in
  **usage rights**. Grant **Viewer** (view only) where content should not be printed/copied/edited, and
  **Co-Author** where collaboration is needed. Start narrow; widen only on evidence.
- **Template vs user-defined, on purpose.** Use **assigned (template)** rights for known audiences
  (all employees, a named group) so the grant is consistent and auditable; use **user-defined** (Do Not
  Forward / Encrypt-Only) for ad-hoc protection where the user knows the recipients. Don't force
  user-defined for content that always has the same audience.
- **Beware AuthenticatedUsers vs a named group.** `AuthenticatedUsers` grants *every authenticated org
  user* — appropriate for "all employees", wrong for board/M&A content. For restricted labels, grant a
  **named group** and confirm with Test 4 that the wrong recipient is denied.
- **Externals need an identity and an intent.** Sharing protected content externally requires the
  recipient to authenticate. Decide deliberately whether a label allows external addresses; **verify the
  current external-sharing/one-time-passcode options for your tenant**.

## Rollout discipline (encryption is not simulatable — so pilot is everything)
- **There is no service-side simulation for label encryption.** The setting takes effect the moment a
  file is labeled. The **pilot ring is your only safety net** — configure encryption on the labels,
  publish **only** to `RMSPolicy – Pilot – Ring1`, validate, then publish to `RMSPolicy – Broad –
  AllUsers`.
- **`-WhatIf` before every commit.** Every provided config action previews with `-WhatIf` and changes
  nothing until `-Commit`. Read the preview — a wrong rights definition can lock people out.
- **Test the denial, not just the access.** The most important test is that the **wrong** recipient is
  **denied** (Test 4). "It opens for me" proves nothing about whether protection is real.

## Recovery, revocation, and continuity (non-negotiable)
- **Configure super-users before broad publish.** Encrypted content is **unrecoverable** without a
  super-user. Enable the super-user feature and set `grp-rms-superusers@contoso.com` **before** any label
  is published broadly (Step 2). Keep the group tiny and audited — a super-user can read everything.
- **Plan for the departing-employee / lost-key case.** Content encrypted to an individual who leaves, or
  a mis-scoped grant, is only recoverable via super-user — confirm the recovery path works (Test 8)
  before you rely on it.
- **Know the revocation path.** For content that must be taken down, confirm the current revocation/
  document-tracking tooling for your tenant (`Get-AipServiceDocumentLog` and related) — **verify current
  tooling**, it evolves.
- **Legal hold / eDiscovery of encrypted content is a legal determination.** eDiscovery can index and
  process protected content when configured, but *how* encrypted content is preserved and produced is a
  **legal/records decision** — this solution provides the super-user recovery method, not the decision.

## Office and PDF specifics
- **Cover the PDF gap deliberately.** Protecting Office files but not their PDF exports is a common quiet
  leak. Confirm labeled/protected **PDF** handling is enabled and that users' readers honor it (Test 7);
  where reader support is uncertain, **standardize on a supported reader** (e.g. Microsoft Edge).
- **Offline access is a trade-off.** A long offline-access window is convenient but means a revoked/
  expired grant keeps working offline until the license lapses. Set offline days to match the label's
  sensitivity (shorter for the most restricted label).
- **Content expiry where the data has a shelf life.** For time-sensitive content, set content expiry so
  access lapses automatically — but confirm super-user recovery still works after expiry.

## Avoiding drift and conflicts
- **Encryption lives on the label, publish lives on the policy.** Changing *who* gets a label is a
  policy change; changing *how it protects* is a label change. Keep that distinction clear so an
  expansion never silently alters a grant.
- **Retire the pilot cleanly.** After broad rollout, ensure no protection label is left published **only**
  to the pilot policy, or (worse) a label configured but never published. `IPRMS-Readiness.ps1` flags this.
- **Re-baseline periodically.** Run `IPRMS-Discovery.ps1` / `IPRMS-Report.ps1` on a cadence to catch RMS
  deactivation, a dropped super-user group, IRM disabled, or a label's protection changed unexpectedly.

## Security & safety hygiene
- **No credentials in code.** All scripts authenticate interactively via `Connect-IPPSSession` /
  `Connect-AipService`; never embed secrets. Store exported evidence securely — it describes your
  protection posture.
- **Read-only or `-WhatIf` by default.** Discovery/validation/reporting/readiness scripts are read-only;
  the protection script defaults to `-WhatIf` and requires `-Commit` for any write. Keep it that way.
- **Verify licensing/tenant/reader support before relying on a capability.** Label encryption, PDF
  protection, and external sharing are plan-/tenant-dependent and the portal evolves — flag, don't assume.
