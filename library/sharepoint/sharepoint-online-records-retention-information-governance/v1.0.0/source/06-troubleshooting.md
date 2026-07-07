# 6. Troubleshooting

Common failure modes and resolutions, ordered roughly by where they appear in the deployment model.
Retention, application, and disposition run on **service timers** — before treating anything as
broken, confirm you have allowed for propagation (often hours to a few days).

---

## Connection & permissions

**`Connect-IPPSSession` fails or `Get-ComplianceTag` errors with access denied.**
- Cause: the account is not in a Purview role group (Records Management / Compliance Administrator), or
  the ExchangeOnlineManagement module is missing/old.
- Resolve: confirm the role group membership (Requirement 2.3), update the module
  (`Update-Module ExchangeOnlineManagement`), and reconnect. Run `Resolve-SpoRecordsScope.ps1` to
  pre-flight module and connection health.

**`Connect-PnPOnline` fails or `Set-PnPLabel` is denied.**
- Cause: no SharePoint admin/site rights, or the PnP Entra app registration isn't consented for the
  auth mode you're using.
- Resolve: confirm SharePoint Administrator or site rights, register/consent the PnP app where required
  (category Requirement 3), and reconnect with `-Interactive`.

**Government cloud: portal or connect endpoint not found.**
- Cause: Commercial URLs/endpoints used in a GCC/GCC High/DoD tenant.
- Resolve: use the Government endpoints (portal `*.office365.us` and the matching S&C/PnP connection
  parameters) — **verify the exact paths for your cloud**; do not assume Commercial paths apply.

---

## Labels & policies

**A published label does not appear for owners to apply.**
- Cause: propagation delay, or the label policy is unpublished/disabled, or the site isn't in the
  policy's scope.
- Resolve: confirm `Label Policy – Owner-Publish – Pilot` is enabled and scoped to the pilot site; wait
  for propagation (can take up to a day); re-check `Get-RetentionCompliancePolicy`.

**`New-ComplianceTag` fails or a feature (auto-apply / adaptive scope / regulatory) is unavailable.**
- Cause: the tenant is not licensed for that plan-dependent feature.
- Resolve: confirm the compliance licensing (Requirement 2.1) — **verify the entitlement in your
  tenant**; if unlicensed, redesign to a feature the tenant has (e.g. default library label instead of
  auto-apply) or acquire the plan.

**A default library label was set but existing items are not labeled.**
- Cause: `-SyncToItems` not used, or propagation still in progress, or per-item labels already present
  take precedence.
- Resolve: set the default with `Set-PnPLabel -SyncToItems $true`; allow propagation; check individual
  items in the library's label column after the timer runs.

**Effective retention on content is not what the schedule says.**
- Cause: retention **precedence** — another policy/label is interacting (retention beats deletion;
  longest wins; explicit beats policy; shortest deletion wins).
- Resolve: enumerate every policy/label touching the content (`Get-RetentionCompliancePolicy`,
  `Get-ComplianceTag`), reason through precedence, and validate the **effective** outcome (Test 9).
  Align with the broader Purview program owners if the conflict is with a program-owned policy.

---

## Records declaration

**Applying a record label does not lock the item (still editable/deletable).**
- Cause: the label is not actually a record label (`IsRecordLabel` false), or propagation is
  incomplete.
- Resolve: `Get-ComplianceTag -Identity "<label>"` and confirm `IsRecordLabel = True` (set it with
  `Set-SpoRecordsDisposition.ps1`); wait for propagation; re-test the edit/delete block (Test 3).

**A regulatory-record label was applied by mistake.**
- Cause: `-Regulatory $true` set without sign-off — this is **irreversible**.
- Resolve: there is **no rollback** for a regulatory record; the content is locked for its full
  retention. Prevent recurrence — the `Set-SpoRecordsDisposition.ps1` helper refuses `-Regulatory`
  without `-ConfirmRegulatory`, and regulatory records require records/legal sign-off (Requirement 2.7,
  Test 4).

---

## Disposition review

**Expired items never appear in the disposition queue.**
- Cause: the label has no reviewers (`ReviewerEmail` empty, so disposal is automatic), retention hasn't
  actually elapsed yet, or propagation is pending.
- Resolve: confirm the label carries reviewers (`Get-ComplianceTag`); confirm the retention trigger and
  duration mean the item is genuinely past due; allow the disposition timer to run. Use a short-duration
  test label to exercise the flow (Test 7).

**Reviewers cannot see the disposition queue.**
- Cause: the reviewer accounts are not in the **Disposition Management** role group.
- Resolve: add them (Requirement 2.3 / Implementation 3b); `Set-SpoRecordsDisposition.ps1` validates
  reviewer membership and warns when an account is missing.

**A disposition was approved by mistake and content was deleted.**
- Cause: an approved permanent disposal executed.
- Resolve: a **completed disposition cannot be undone**. Recover from backup/retention grace only if
  still within any applicable window, and tighten reviewer training and the review stage. This is why
  high-value categories use review (not auto-disposal) and change control gates the pilot.

---

## Reporting & scope

**`Get-SpoRecordsComplianceReport.ps1` shows pending disposition as `n/a`.**
- Cause: the disposition-count cmdlet isn't available in the tenant/session (plan- or module-dependent).
- Resolve: read pending disposition from **Purview → Records management → Disposition** in the portal;
  the coverage and record-label figures in the report are still valid — **verify disposition counts in
  your tenant**.

**Assessment/report shows a library as `(unable to read)` for its label.**
- Cause: insufficient rights on that library, or a transient PnP error.
- Resolve: confirm rights on the specific site/library and re-run; the scripts continue past a single
  library error so one failure doesn't abort the whole run.
