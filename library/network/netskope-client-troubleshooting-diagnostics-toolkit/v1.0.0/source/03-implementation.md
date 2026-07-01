# 3. Implementation Guide — Netskope Client Troubleshooting & Diagnostics Toolkit

Follow these steps **in order**. The goal is a standing triage capability — diagnostics deployed, the
four runbooks written and named, piloted with the help desk, validated, then expanded.

> **Model:** Stand up the diagnostics, build the per-failure-class runbooks, wire collection, pilot
> with the help desk, validate against known issues, then expand. Pattern:
> **Assess → Configure → Pilot → Validate → Expand.**

## Step 1 — Assess: confirm prerequisites and baseline
1. Complete the Requirements checklist (Section 2) and the category global requirements.
2. On a representative endpoint, run `NSDIAG-Discovery.ps1` to capture the baseline client state
   (installed/services/processes), then `NSDIAG-Validation.ps1` for connectivity. Keep the output as
   the `Diagnostic Bundle – Endpoint – Collect` baseline.

## Step 2 — Stand up the diagnostics toolkit
1. Place the five scripts in a controlled location available to the help desk (a managed share, an
   Intune script package, or a remediation tool).
2. Confirm execution policy and elevation: `powershell -ExecutionPolicy Bypass -File .\NSDIAG-Discovery.ps1`.
3. Confirm Microsoft Graph reporting works once: `NSDIAG-Report.ps1` connects with
   `DeviceManagementManagedDevices.Read.All`.

## Step 3 — Build the per-failure-class runbooks
Author one runbook per class, each named with the convention and each following diagnose-then-resolve.
Reuse these names verbatim:

- `Client Triage – Steering – Diagnose` / `Client Triage – Steering – Resolve`
- `Client Triage – Authentication – Diagnose` / `Client Triage – Authentication – Resolve`
- `Client Triage – Performance – Diagnose` / `Client Triage – Performance – Resolve`
- `Client Triage – Certificate – Diagnose` / `Client Triage – Certificate – Resolve`

Each runbook's structure:
1. **Collect** the `Diagnostic Bundle – Endpoint – Collect` (`NSDIAG-Discovery.ps1` →
   `NSDIAG-Validation.ps1` → `NSDIAG-Report.ps1`).
2. **Classify** using the decision cues below.
3. **Resolve** with the safe remediation, then re-validate.
4. **Escalate** with the bundle plus the Netskope client logs (vendor-deferred path) if unresolved.

Classification cues (what the bundle shows per class):
- **Steering:** client service/process not running, or running but no steering config applied / a
  bypass present. Resolve: `NSDIAG-Remediation.ps1` restart/repair; if still wrong, re-enroll.
- **Authentication:** enrollment incomplete, identity loop, clock skew. Resolve: correct time, then
  `NSDIAG-Remediation.ps1` re-enroll; confirm device context in `NSDIAG-Report.ps1`.
- **Performance:** steering healthy but high latency / DNS delay on the validation checks. Resolve:
  per `Client Triage – Performance – Resolve` (path/inspection bypass per Netskope docs).
- **Certificate:** decryption root not trusted or TLS errors in validation. Resolve: confirm the
  decryption certificate is present/trusted (deferred to Netskope deployment docs for the cert source).

## Step 4 — Wire log/state collection
1. Make `NSDIAG-Discovery.ps1`, `NSDIAG-Validation.ps1`, and `NSDIAG-Report.ps1` runnable in one
   pass (a wrapper or a documented sequence) to produce the `Diagnostic Bundle – Endpoint – Collect`.
2. Document, from Netskope's docs, where the client's own logs live for your client version, so the
   bundle handoff is complete. `NSDIAG-Report.ps1` prints a reminder for this vendor-deferred step.

## Step 5 — Configure the pilot scope
1. Create the `Diagnostics Scope – Help Desk – Pilot` group (Entra, or `NSDIAG-Set-ScopeTargeting.ps1`).
2. Add the help-desk technicians' devices/accounts as pilot members.

## Step 6 — Pilot with the help desk
1. Have the help desk run live tickets through the four runbooks for one cycle.
2. For each ticket: collect the bundle, classify, attempt the safe remediation with `-WhatIf` first,
   then apply. Record outcomes.

## Step 7 — Validate the pilot (gate)
1. Run the Testing Guide (Section 5) — confirm discovery, validation, report, and a `-WhatIf`
   remediation behave correctly, and that each runbook resolves or cleanly escalates its class.
2. **Gate:** do not expand until the help-desk pilot passes the Testing Guide gates.

## Step 8 — Expand to the wider support org
1. Publish the toolkit and the four named runbooks to the broader support team.
2. Broaden the scope group from `Diagnostics Scope – Help Desk – Pilot` to the full support scope.
3. Re-validate each cycle with `NSDIAG-Report.ps1` (fleet device context) and keep the runbooks in
   sync with any Netskope client/console changes (re-confirm vendor-deferred paths after upgrades).

---
### Order of operations
`Assess/baseline → stand up scripts → build 4 runbooks → wire collection → pilot scope → help-desk pilot → validate (gate) → expand`
