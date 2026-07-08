# 6. Troubleshooting — Google Workspace ↔ Intune Third-Party EMM Integration

A symptom → likely root cause → fix playbook for the Google Workspace / Cloud Identity ↔ Intune
third-party EMM integration. Work top-down; each item names the script or console area to check.

> **Golden rule for every enrollment-impact symptom:** measure it (baseline vs current with
> `ANDROIDGW-DeviceImpact.ps1`) and **verify the interpretation against current Microsoft/Google
> guidance and your tenant**. Do **not** conclude "the integration re-enrolled the fleet" (or "it
> won't") from memory — confirm it.

---

## A. Model / binding problems

### A1 — "This account is already a managed Google Play enterprise" / domain conflict
- **Likely cause:** An **account-enterprise** binding (`ANDROIDENT`) already exists, or the same Google
  domain is bound both ways — the two models are mutually exclusive (GR 2).
- **Fix:** Run `ANDROIDGW-Discovery.ps1` and read the `ModelHint` + owner. Confirm in the Intune admin
  center which binding is present. If an account enterprise is bound but you need the Workspace
  third-party EMM model, resolve the binding deliberately under change control (verify the current,
  supported procedure with Microsoft) before enabling the Google-side integration.

### A2 — You have no Google managed domain but followed this solution
- **Likely cause:** Wrong solution — this is only for tenants with Google Workspace / Cloud Identity.
- **Fix:** Use the account-enterprise solution (`ANDROIDENT`) instead (Requirement 2.1).

### A3 — Binding shows "not bound" after completing both consoles
- **Likely cause:** The Google Admin console third-party EMM enablement or the Intune connection did not
  fully complete, or app sync has not run.
- **Fix:** Re-run `ANDROIDGW-Discovery.ps1`; if `bindStatus` is not bound, re-check the Google Admin
  console setting (super-admin) and the Intune connection flow against **current** guidance
  (Implementation Steps 5–6). Allow/trigger an app sync and re-check.

## B. Google Admin console side

### B1 — Can't find the third-party Android EMM / managed Google Play setting
- **Likely cause:** Google relocated the setting (it has lived under *Devices → Mobile & endpoints →
  Settings → Third-party integrations* and under an *Android EMM* setting).
- **Fix:** Do **not** rely on a remembered path — follow Google's **current** documentation for using
  managed Google Play with a third-party EMM / binding a managed Google domain to an EMM. Confirm the
  acting account is a **super-admin** (Requirement 2.2).

### B2 — The console generated a token/identifier but the Intune side won't accept it
- **Likely cause:** Token not captured/entered correctly, or the Intune flow expects a different step in
  the current version.
- **Fix:** Re-capture exactly what the Google console produced; follow Microsoft's current Intune
  connection flow. If the flow has changed (AMAPI transition), verify the current end-to-end procedure
  before retrying, and record the steps in the change record.

## C. Identity / account-add problems

### C1 — "Can't add a Google account" during enrollment
- **Likely cause (most common):** Endpoint reachability — managed Google Play / Google sign-in blocked
  on the device network (Requirement 2.7); or an identity mismatch (Entra UPN vs Google primary email).
- **Fix:** Confirm the required Google/Microsoft endpoints are allowed (verify the current list). Run
  `ANDROIDGW-Readiness.ps1` and resolve any identity/domain mismatch (Requirement 2.5). Retry on a known-
  good network.

### C2 — Account adds but the user resolves to the wrong identity / no apps
- **Likely cause:** Google identity ↔ Entra identity mapping is off, or the user isn't licensed/in scope.
- **Fix:** Run `ANDROIDGW-Readiness.ps1` for the user (presence + licensing) and confirm domains align.
  Confirm the user is in the pilot scope and app assignments target `MGP Pilot – Android – Stage1`.

## D. App delivery / sync

### D1 — Assigned managed Google Play apps don't install
- **Likely cause:** Failed/stale app sync, or the app isn't assigned to the device's group.
- **Fix:** Run `ANDROIDGW-Validation.ps1`: check `lastAppSyncStatus` (should be success) and that the
  app shows the expected assignment. Trigger/allow a sync; re-scope the assignment if needed.

### D2 — App sync status is failed
- **Likely cause:** Connection health degraded (binding, token, or service issue).
- **Fix:** Re-run `ANDROIDGW-Discovery.ps1` for bind state; re-verify the connection on both consoles.
  Refresh `MGP Sync Health – Android – Report` and monitor.

## E. Re-enrollment / device-impact scenarios (handle with care)

### E1 — After the cutover, some devices show a new enrolled-date
- **Likely cause:** Possible re-enrollment — **or** a benign state change. A changed enrolled-date does
  **not** by itself prove the integration re-enrolled the device.
- **Fix:** Run `ANDROIDGW-DeviceImpact.ps1 -BaselineCsv <baseline>` and review the diff. Correlate with
  the change window. **Verify against current Microsoft/Google guidance** whether the observed change is
  expected for your enrollment models. If it is unexpected and disruptive, invoke rollback
  (Implementation Step 10). Never assert cause from the diff alone.

### E2 — Devices dropped out of management after the change
- **Likely cause:** Enrollment/connection state changed in a way the devices didn't follow, or an
  identity/scope problem.
- **Fix:** Use the impact diff to list dropped devices; check their user/identity and scope. If the pilot
  shows this, **stop expanding**, roll back per current guidance, and reassess before retrying.

### E3 — Users report unexpected prompts or lost work profiles on the pilot
- **Likely cause:** The change affected existing profiles in a way your expectation didn't account for.
- **Fix:** Treat as a **Gate A failure** (Testing 05, Test 3–4): roll back, capture what users saw,
  verify expected behavior against current guidance, and only retry once the expected experience is
  confirmed.

### E4 — Dedicated/COSU or rugged (Samsung Knox/Zebra) devices behave differently from phones
- **Likely cause:** OEM/kiosk enrollment paths are the most sensitive to binding changes and are
  vendor-specific (pattern level here).
- **Fix:** Test these device classes **explicitly** in the pilot; defer OEM-console specifics to the
  vendor's current docs. Do not infer their behavior from a personal phone.

## F. Rollback

### F1 — Need to revert the integration
- **Likely cause:** A gate failed and you must return to baseline.
- **Fix:** The Google super-admin reverses the third-party EMM enablement in the Google Admin console and
  the Intune side is reverted — **verify the current, supported rollback procedure against
  Microsoft/Google guidance first**, as rollback is itself high-impact. Re-run `ANDROIDGW-DeviceImpact.ps1`
  and confirm devices return to the baseline state (Implementation Step 10).

---
### Escalation checklist before opening a vendor case
1. `ANDROIDGW-Discovery.ps1` output (bind status, owner, app-sync status) — for Microsoft.
2. `ANDROIDGW-DeviceImpact.ps1` baseline **and** post-change diff — the objective evidence of what
   changed.
3. The Google Admin console change record (what was enabled, when, by which super-admin).
4. The specific enrollment model(s) affected and whether behavior was confirmed against current guidance.
5. Whether the issue reproduces on the pilot scope only or fleet-wide.
