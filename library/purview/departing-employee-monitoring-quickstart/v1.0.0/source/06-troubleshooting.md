# Troubleshooting — Departing-Employee Data-Theft Monitoring Quickstart

Symptom → likely cause → fix, for the failure modes you actually hit deploying and operating the
departing-user policy. Work top-down; most "it isn't working" reports are a missing **trigger** (the HR
connector), a disabled **indicator**, or a **licensing/role** gap — not a broken product. When a
capability seems absent, **verify it against your licensing/tenant** before assuming a bug (IRM is
plan-gated and the portal evolves).

---

## Insider Risk Management doesn't appear in the portal / Settings won't open

- **Cause:** Missing licence (E5 / E5 Compliance / IRM add-on) or missing IRM role.
- **Fix:** Confirm the licence in the M365 admin center (R1) and that your account is in an **Insider Risk
  Management** role group (Admins to configure). `IRMDEPART-Discovery.ps1` lists role-group membership.
  Verify capability availability against your licensing/tenant.

## The policy is On but produces NO alerts

Work these in order — this is the most common report, and for a departing-user policy the usual answer is
**the trigger never fired**:

1. **No leaver trigger.** The user is only scored after the **triggering event**. The HR connector has
   **no recent leaver record** for the user (or is stale), and you're not using the Entra
   account-deletion trigger. Check **Settings → Data connectors** for a recent successful upload; run
   `IRMDEPART-Test-HRConnector.ps1`. Confirm the user's resignation/termination date is present and
   valid.
2. **Indicator disabled.** The activity's **indicator** is off under **Settings → Policy indicators**.
   Enable the needed Office/Device family.
3. **Device not onboarded.** Device indicators (USB/print/personal-cloud) only fire from **onboarded**
   devices (R5). Check **Settings → Device onboarding** — a leaver on an un-onboarded laptop is invisible.
4. **Detection window.** The activity fell outside the policy's **activation window / past-activity**
   timeframe (Settings → Policy timeframes). For leavers, widen **past activity** so exfiltration that
   began before the resignation was recorded is still caught.
5. **User not in scope / unlicensed.** The user isn't in `SG-Departing-Pilot` or isn't licensed. Add them
   to scope (`IRMDEPART-Set-Scope.ps1`) and confirm licensing.

## HR connector shows no / stale data — departing-user detection silently stopped

- **Cause:** Upload job failing, schedule lapsed, or the source export changed shape.
- **Fix:** In **Settings → Data connectors** open the HR connector and check the last upload status/time
  (`IRMDEPART-Test-HRConnector.ps1` flags staleness). Re-run the upload; validate the CSV/API schema
  (resignation/termination dates) matches what Microsoft's connector expects. The upload credential lives
  in the **connector app**, not in any script. If you have no HR feed at all, switch the policy to the
  **Entra account-deletion** trigger (coarser — it fires as the account is removed, so you lose the
  before-last-day window — but works without a connector).

## Device indicators never fire even though the leaver copied files

- **Cause:** Device not onboarded to Purview endpoint (same onboarding as Defender for Endpoint), the
  device indicator family is off, or an unsupported OS.
- **Fix:** Confirm onboarding (**Settings → Device onboarding**), enable **Device indicators** (**Settings
  → Policy indicators**), and verify the OS is supported. `IRMDEPART-Test-HRConnector.ps1` points you to
  these checks.

## Reviewers see real names when they shouldn't (or "why is everyone anonymized?")

- **Cause:** Anonymization posture mis-set, or a role confusion about who may de-anonymize.
- **Fix:** **Settings → Privacy** must have **"Show anonymized versions of usernames"** selected (ON) —
  the default and expected posture. Analysts see the **anonymized** experience; **de-anonymization** is an
  **Investigator**-level, justified, **audited** action (Auditors can see it in the IRM audit log). If
  anonymization was turned off, re-enable it unless privacy/legal agreed an exception in writing (Gate 2).

## An account can both build the policy and unmask identities (separation broken)

- **Cause:** Someone holds a **conflicting** combination (e.g. **Admins + Investigators**), or the
  combined **Insider Risk Management** role group was assigned to an operator.
- **Fix:** Run `IRMDEPART-Discovery.ps1` — it flags conflicting combinations. In **Settings → Roles &
  scopes**, reduce each person to **one** function; remove operators from the combined **Insider Risk
  Management** group. Treat this as a governance finding, not a convenience (Gate 1).

## "Access denied" triaging alerts or opening a case

- **Cause:** Wrong role. Triage needs **Analysts**; deep case + content needs **Investigators**. Admins
  **cannot** see alert/case user activity by design.
- **Fix:** Assign the correct functional role group to the operator — without breaking separation (don't
  stack Admin + Investigator on one person).

## Alerts are overwhelming / lots of false positives in the pilot

- **Cause:** Thresholds too sensitive, no exclusions, or scope too broad for a first pilot.
- **Fix:** This is why you **pilot with a small scope first**. Tune **intelligent detection** settings,
  add file-type/domain **exclusions** (recording why), and keep scope at `SG-Departing-Pilot` until noise
  is acceptable. Set a noisy policy **Off**, tune, and re-pilot — don't expand scope to "average out" the
  noise.

## A user resigned but was never scored

- **Cause:** The leaver record didn't reach the policy, or the user isn't in scope.
- **Fix:** Confirm the HR upload succeeded and the leaver date is recent/valid
  (`IRMDEPART-Test-HRConnector.ps1`), that the user is a member of `SG-Departing-Pilot`
  (`IRMDEPART-Set-Scope.ps1 -WhatIf`), and that the activation window covers the period since the trigger
  (Testing Gate 5).

## `Get-InsiderRiskPolicy` / IRM cmdlets aren't recognized

- **Cause:** IRM authoring is **primarily portal-based**; the cmdlet surface is limited and
  tenant/version-dependent.
- **Fix:** Manage the policy in **purview.microsoft.com → Insider Risk Management → Policies**. The
  scripts here deliberately use PowerShell for **readiness, role/scope verification, and reporting** — not
  to invent an authoring path. `IRMDEPART-Set-Policy.ps1 -WhatIf` prints the exact plan to apply in the
  portal.

## `IRMDEPART-Report.ps1` returns no records

- **Cause:** Unified audit-log ingestion off, window too short, or no IRM activity yet.
- **Fix:** Enable audit ingestion (`IRMDEPART-Test-HRConnector.ps1`), widen `-DaysBack`, and remember the
  **portal Alerts/Cases dashboards are authoritative** — the CSV is a summary aid, not the source of
  truth (Gate 9).

## Connect-IPPSSession / Connect-MgGraph fails

- **Cause:** Module not installed, modern-auth/MFA blocked, or wrong account.
- **Fix:** Install **ExchangeOnlineManagement** and **Microsoft.Graph**, sign in with an **MFA-capable**
  admin, and ensure Security & Compliance PowerShell is reachable. See `global-requirements-purview.md`
  §3.

---

### When to stop and escalate to HR/legal (not troubleshoot)

- You have a **real** confirmed case of departing-employee theft and need a determination or disciplinary
  decision → that is **HR/legal's**, not an administrator's, and not a "fix" in this guide.
- You're unsure whether you may **enable monitoring** or **de-anonymize** a user → stop and get the
  **lawful-basis / privacy** decision first (R9). The technical method is here; the determination is not.
