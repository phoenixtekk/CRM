# Troubleshooting

Post-migration troubleshooting pointers for the AMAPI migration. Match the symptom, apply the
check, and re-validate with the referenced script. For device-level enrollment failures
(especially **"can't add a Google account"**), this section deliberately **cross-references the
dedicated Android enrollment-troubleshooting (Google account / AMAPI) solution** rather than
duplicating it.

> **Verify-first still applies here.** Whether a symptom is "expected AMAPI behavior" or a genuine
> fault (e.g. a re-enrollment prompt) is **version-dependent** — confirm the correct behavior
> against **current Microsoft guidance / your tenant** before treating it as a bug.

---

## Decision tree (start at the top)

```
After the migration action, is the device present and checking in?
├─ NO — device missing / not checking in                     → §1
├─ NO — user hit "can't add a Google account"                → §2 (see enrollment-troubleshooting solution)
├─ YES but not compliant / Conditional Access blocks user    → §3
├─ YES but managed Google Play apps did not (re)install      → §4
├─ Device re-enrolled / work profile reset UNEXPECTEDLY      → §5 (verify expected behavior first)
└─ Whole cohort/app-sync looks wrong (binding)               → §6

Admin can't see/select the wave group or devices (custom RBAC) → §7
Everything checks and it still fails                            → §8 (escalate)
```

Fast triage: run `AMAPIMIG-Get-PostMigrationValidation.ps1 -GroupName "<wave group>"` and
`AMAPIMIG-Config.ps1 -HealthSummary` first — they localize most issues to a device, an app, or the
binding.

---

## §1 — Device missing / not checking in after migration

**Symptom:** A migrated device does not appear in the cohort, or `CheckInOk = False` in the
validation report.
**Checks:**
1. Confirm the migration action for that enrollment model was actually completed per **current
   Microsoft guidance** (Phase 3 / 5).
2. `AMAPIMIG-Get-PostMigrationValidation.ps1` — is `LastSync` stale? Force a device check-in and
   re-run.
3. Network reachability to Google/Microsoft endpoints (Global Requirements) — a blocked endpoint
   silently stops check-in.
**Fix:** Restore reachability / re-run the documented migration step; if the device was expected to
re-enroll, complete the re-enrollment per current guidance. Re-validate (V2).

## §2 — "Can't add a Google account" during (re-)enrollment

**Symptom:** The device-side enrollment fails at adding the managed Google account.
**Root causes (common):** blocked Google/Microsoft endpoints; a degraded managed Google Play
binding; device-side account state.
**Fix:** Confirm endpoints and the binding (`AMAPIMIG-Config.ps1 -HealthSummary`), then follow the
**Android enrollment-troubleshooting (Google account / AMAPI)** solution, which owns the detailed
symptom→cause tree for this failure. Re-validate (V5).

## §3 — Device present but non-compliant / Conditional Access blocks the user

**Symptom:** Migrated device shows non-compliant, or the user is blocked by CA after migration.
**Root cause:** A re-enrollment (where it occurs) can reset compliance grace; a CA/compliance
policy reviewed in R6 may re-evaluate.
**Fix:** Allow the compliance policy to re-evaluate / check-in; confirm the policies from R6 apply
to the migrated state. Do not disable CA blindly. Re-validate (V6).

## §4 — Managed Google Play apps did not (re)install

**Symptom:** Required managed Google Play apps are missing or `installState != installed` in the
validation report.
**Checks:**
1. `AMAPIMIG-Config.ps1 -HealthSummary` — is `lastAppSyncDateTime` recent and the binding bound? A
   stale binding is the top cause.
2. Confirm the app assignment targets the **wave group** (or the migrated users/devices), per R6.
3. Allow normal Intune sync latency before concluding failure.
**Fix:** Repair the binding / correct the assignment, force a sync, re-run
`AMAPIMIG-Get-PostMigrationValidation.ps1 -AppDisplayName "<app>"`. Re-validate (V4).

## §5 — Device re-enrolled or work profile reset **unexpectedly**

**Symptom:** A device did something the impact statement did not predict (re-enrollment prompt,
work-profile reset, or a dedicated-device reset).
**First — verify it is actually unexpected.** Re-enrollment/reset behavior is **version- and
model-dependent**. Confirm against **current Microsoft guidance** whether this is the intended
behavior for that model at the current rollout stage.
**If genuinely unexpected:** **Stop expanding that model**, update the impact statement (R4/V3),
re-communicate to affected users, and re-pilot before any further wave. On dedicated/COSU, treat
any reset as data-affecting and stage devices offline.
**Fix / recovery:** Re-enroll the affected device clean per current guidance (cross-reference the
enrollment-troubleshooting solution) and record the true behavior so later waves are communicated
correctly.

## §6 — Whole cohort / app-sync looks wrong (managed Google Play binding)

**Symptom:** App delivery fails broadly, or the connection shows unbound/stale.
**Check:** `AMAPIMIG-Config.ps1 -HealthSummary` — `bindStatus` and `lastAppSyncDateTime`.
**Fix:** Repair or re-establish the managed Google Play binding (category Global Requirements /
Android Enterprise connection solution) **before** interpreting any per-device result. A degraded
binding masquerades as many migration bugs.

## §7 — Admin can't see/select the wave group or devices (custom Intune RBAC)

**Symptom:** With custom Intune RBAC, the operating admin can't see the wave group or the migrated
devices.
**Fix:** Add the wave group to the admin's role-assignment **scope groups**, or operate with an
admin whose scope includes them (tenants on built-in roles only are unaffected).

## §8 — Everything checks and it still fails (escalation)

When binding is healthy, the estate is inventoried, the current guidance was followed, and
validation still fails:

1. Capture the exact admin-center state and error, the enrollment model, device details, and the
   `AMAPIMIG-Get-PostMigrationValidation.ps1` / `-HealthSummary` output.
2. Re-confirm the correct current behavior against Microsoft's **live** Android Management API
   guidance (the rollout may have changed since you planned).
3. **Halt the affected wave** (do not push a failing migration to production) and open a
   **Microsoft support case** with the captured evidence.

---

**Golden rule:** because the AMAPI transition is evolving, a "failure" is only a failure once you
have confirmed the correct current behavior. Verify against current Microsoft guidance, keep waves
small, and let the pilot — not an assumption — tell you what the end user experiences.
