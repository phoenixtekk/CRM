# 5. Testing Guide — Onboarding Accelerator: Microsoft Defender for Cloud Apps

Run these checks after the pilot onboarding (Steps 2–7) and again after each expansion wave. Each test has a **pass/fail gate**; do not enforce or expand until the pilot passes. Objects are referenced by the exact names from the Implementation Guide.

## Test 1 — App connectors connected
**Procedure:** Run `MCAONB-Validate.ps1 -Check Connectors`. In `security.microsoft.com` → **Cloud apps → Connected apps → App connectors**, confirm each connector in `MDCA App Connectors – Priority SaaS – Prod` shows **Connected**.
**Pass:** Microsoft 365 (and each priority app) is connected and pulling activity.
**Fail:** A connector shows an error/disconnected — see Troubleshooting *Connector not connecting*.

## Test 2 — Cloud Discovery flowing
**Procedure:** Run `MCAONB-Validate.ps1 -Check Discovery`. In **Cloud apps → Cloud discovery → Dashboard**, confirm discovered apps and traffic appear.
**Pass:** Discovery data (apps, users, traffic) is visible from the configured source.
**Fail:** Dashboard empty — see Troubleshooting *No discovery data*.

## Test 3 — App governance and OAuth policy active
**Procedure:** Run `MCAONB-Report.ps1 -Section OAuth`. In **Cloud apps → App governance**, confirm OAuth apps are inventoried and `MDCA OAuth App Risk – Tenant – Report` is present and report-only.
**Pass:** App governance is on, OAuth apps are inventoried, and the report policy flags risky apps without revoking.
**Fail:** App governance off or no inventory — see Troubleshooting *App governance not inventorying*.

## Test 4 — Session/access policy scoped and report-only
**Procedure:** Run `MCAONB-Validate.ps1 -Check Policy`. In **Cloud apps → Policies**, confirm `MDCA Session Control – Pilot Users – Report` and `MDCA Access Control – Pilot Users – Report` exist, are **monitor/report-only**, and are scoped to `MDCA Pilot Users – Pilot Ring – Pilot`.
**Pass:** Both policies exist, are report-only, and target only the pilot users.
**Fail:** Policy missing, enforcing, or wrongly scoped — re-create per Implementation Step 5.

## Test 5 — Conditional Access App Control routes sessions
**Procedure:** As a pilot user, sign in to a targeted app; confirm the session is proxied (the MDCA session banner/URL suffix appears) per the CA policy `MDCA Session Control – Pilot Users – Report`.
**Pass:** The pilot user's session is routed through MDCA (App Control active) without blocking access.
**Fail:** Session not proxied — see Troubleshooting *App Control not proxying*.

## Test 6 — Cloud-app signal streaming
**Procedure:** Run `MCAONB-Hunt.ps1` to execute `MDCA Signal Validation – Tenant – Validate`. Confirm `CloudAppEvents` returns recent rows from the connectors/discovery.
**Pass:** `CloudAppEvents` streams recent activity.
**Fail:** Empty — see Troubleshooting *No cloud-app signal*.

## Test 7 — A monitor policy fires (no enforcement)
**Procedure:** As a pilot user, perform a benign action the monitor policy watches (e.g. a download on an unmanaged device). In **Incidents & alerts**, confirm the expected alert appears — and access is **not** blocked.
**Pass:** The monitor policy generates the alert; the pilot user is not disrupted.
**Fail:** No alert or access was blocked — re-check the policy mode/scope (Implementation Step 5).

## Test 8 — Enforcement/revoke stays approval-gated
**Procedure:** Run `MCAONB-Report.ps1 -Section Policies` and confirm no policy auto-blocks or auto-revokes during the pilot.
**Pass:** All enforcing/revoke actions require approval; nothing auto-executes on the pilot.
**Fail:** An enforcing action is live before agreed — reset to report-only and confirm with the security team.

---
### Exit gate
All eight tests pass on the pilot user group **before** you enforce any policy or expand the scope (Implementation Step 8). Re-run Tests 1, 2, 6, and 7 after each expansion wave and compare against the saved baseline.
