# Testing & Validation — Defender for Office 365 (Plan 2): Threat Explorer, Attack Simulation & Automated Investigation

Validate the build against explicit **pass/fail gates** before expanding beyond the pilot group.
Run the two scripts and walk the manual checks. Do not proceed to **Expand** until every gate
passes. The automated gates are produced by **`DEFMDOP2-Validate.ps1`**; reporting evidence comes
from **`DEFMDOP2-Report.ps1`**, hunting from **`DEFMDOP2-Hunt.ps1`**, and readiness from
**`DEFMDOP2-Discovery.ps1`**.

Each gate lists **What good looks like / How to test / If it fails**.

---

## Gate 1 — Plan 2 is licensed and the features are present

- **What good looks like:** MDO Plan 2 is assigned to in-scope users; Explorer, Attack Simulation
  Training, Action center, and Advanced Hunting blades are all visible.
- **How to test:** Run `DEFMDOP2-Discovery.ps1`; confirm it reports the Plan 2 service plan present.
  In the portal confirm the four blades load (not just "Real-time detections").
- **If it fails:** Assign MDO Plan 2 (R1) and allow provisioning time; re-run discovery.

## Gate 2 — The prevention layer is in place (dependency)

- **What good looks like:** Anti-phishing/-malware/-spam, Safe Links, and Safe Attachments policies
  (or an enabled Preset security policy) exist.
- **How to test:** **Email & collaboration → Policies & rules → Threat policies** lists them.
- **If it fails:** Deploy the companion *Mail Hygiene* prevention solution first; this solution
  depends on its signal.

## Gate 3 — Email Advanced Hunting tables have data

- **What good looks like:** `EmailEvents` (and related email tables) return recent rows.
- **How to test:** In **Advanced hunting** run `EmailEvents | where Timestamp > ago(24h) | count`,
  or read the freshness section of `DEFMDOP2-Discovery.ps1`. Rows return.
- **If it fails:** Confirm Plan 2 provisioned and mail is flowing; email tables are Plan 2 features —
  *verify table availability in your tenant*.

## Gate 4 — The pilot simulation ran and reported

- **What good looks like:** `Sim-CredHarvest-Pilot` completed against `Grp-MDO-Pilot-Users`, with
  per-user compromise results and `Training-PhishAware-Pilot` auto-assigned to those compromised.
- **How to test:** **Attack simulation training → Simulations** shows the campaign complete with a
  report; `DEFMDOP2-Report.ps1` returns the user-risk summary.
- **If it fails:** Confirm the campaign launched (not just staged), the target group was correct, and
  training assignment was enabled (Step 1.5).

## Gate 5 — Post-delivery hunting returns results

- **What good looks like:** `Explorer-PostDelivery-Pilot` and the KQL library return who received /
  who clicked for a test or real post-delivery scenario.
- **How to test:** Run `DEFMDOP2-Hunt.ps1 -QuerySet PostDeliveryPhish`; it returns matching
  recipients/clicks. The saved Explorer view loads and filters.
- **If it fails:** Check table freshness (Gate 3), the query filters, and hunting permissions (R3).

## Gate 6 — AIR actions are **pending approval, not auto-applied**

- **What good looks like:** An AIR investigation opened, and its recommended remediation actions are
  **waiting in the Action center**, not already executed.
- **How to test:** **Actions & submissions → Action center → Pending** shows the AIR-recommended
  actions as pending. `DEFMDOP2-Validate.ps1` flags any action that was auto-applied during the
  pilot as a **FAIL**.
- **If it fails:** Set AIR back to approval-required (Step 1.2); the pilot must not auto-remediate.

## Gate 7 — Remediation preview is accurate and gated

- **What good looks like:** `DEFMDOP2-Remediate.ps1 -WhatIf` prints exactly which messages/mailboxes
  it would act on and **changes nothing**; execution requires the explicit `-Execute -Confirm` gate
  and/or Action center approval.
- **How to test:** Run the remediation script with `-WhatIf` against a hunt-result CSV; confirm no
  deletion occurred (the messages remain). Confirm the script refuses to act without the gate.
- **If it fails:** Do not run remediation until preview is correct; never run hard-delete blind.

## Gate 8 — The custom detection exists in alert-only mode

- **What good looks like:** `Detect-PostDeliveryPhish-Pilot` exists as a custom detection rule that
  **generates an alert only** (no automatic remediation) during the pilot.
- **How to test:** **Advanced hunting → Custom detection rules** lists it; its response action is
  alert-only. `DEFMDOP2-Validate.ps1` confirms.
- **If it fails:** Recreate the rule from the tuned query (Step 2.5) and set the response to
  alert-only.

## Gate 9 — Roles and audit are correct

- **What good looks like:** Only named operators can launch simulations, change AIR posture, and
  approve remediation; every approval is auditable.
- **How to test:** Review **Permissions & roles** and confirm least-privilege (R3); confirm Action
  center approvals show who approved each action.
- **If it fails:** Tighten role assignments; prefer PIM-eligible for the administrator role where
  available.

---

### Validation summary

| Gate | Check | Pass condition |
| --- | --- | --- |
| 1 | Plan 2 + features present | Plan 2 assigned; four blades visible |
| 2 | Prevention layer present | Threat policies / preset exist |
| 3 | Email tables have data | `EmailEvents` returns recent rows |
| 4 | Pilot simulation ran | `Sim-CredHarvest-Pilot` reported; training assigned |
| 5 | Hunting returns results | KQL library + `Explorer-PostDelivery-Pilot` return data |
| 6 | AIR pending, not auto-applied | Actions in Action center **Pending** |
| 7 | Remediation preview gated | `-WhatIf` changes nothing; execution requires gate |
| 8 | Custom detection alert-only | `Detect-PostDeliveryPhish-Pilot` exists, alert-only |
| 9 | Roles + audit correct | Least-privilege; approvals audited |

All nine gates pass ⇒ proceed to **Expand**. Any fail ⇒ stay in pilot and remediate the gate first.
