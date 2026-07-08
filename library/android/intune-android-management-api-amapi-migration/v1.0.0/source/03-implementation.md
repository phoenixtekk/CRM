# Implementation

This is the ordered **AMAPI migration** procedure: **Assess → Design → Configure → Pilot →
Validate → Expand**, with explicit pass/fail gates and a documented rollback at each production
phase. It is **pilot-first** because AMAPI-migration and enrollment-model changes are high-impact
and **may affect existing devices**.

> **Standing rule for the whole procedure.** Every step that depends on the AMAPI rollout —
> sequence, enrollment-method options, web/account-driven availability, and especially **whether a
> device re-enrolls** — is a **"verify against current Microsoft guidance / your tenant"** gate.
> Do not communicate an end-user outcome you have not observed in the pilot and confirmed in
> Microsoft's current documentation. This procedure names the *artifacts and order*; it does **not**
> assert Microsoft's timeline or re-enrollment behavior.

> **Naming convention** (`AMAPIMIG – <Model> – <Stage>`), reused in Testing and the scripts:
> - Wave groups: **`AMAPIMIG – WorkProfile – Pilot`** → **`… – Wave1`** → **`… – Prod`** (and per
>   model: `FullyManaged`, `CorpWorkProfile`, `Dedicated`).
> - CSV plan: **`AMAPIMIG-WavePlan.csv`**.

---

## Phase 0 — Assess (read-only; change nothing)

**Step 0.1 — Confirm the binding is healthy (R1).** Run `AMAPIMIG-Config.ps1 -HealthSummary`. It
reports the managed Google Play binding state (`bindStatus`, `lastAppSyncDateTime`) and connection
model. If the binding is degraded, **stop** and repair it first.

**Step 0.2 — Inventory the estate (R2).** Run `AMAPIMIG-Assess-AndroidEstate.ps1`. It returns
Android devices grouped by `deviceEnrollmentType` (work profile / fully managed / corp work
profile / dedicated-COSU), `managementAgent`, `ownerType`, `osVersion`, `manufacturer`, and last
check-in — a per-model population count and a stale-device list.

> **On telling "legacy Play EMM" from "AMAPI" per device.** There is **no single documented Graph
> property** that cleanly labels a device "managed under AMAPI" vs "legacy Play EMM." The
> assessment reports what Graph exposes and the **tenant-level** binding/migration signals; the
> authoritative legacy-vs-AMAPI status is what **Microsoft surfaces in the admin center / current
> guidance**. **Verify the migration status there — do not infer it from an invented property.**

**Step 0.3 — Read the current AMAPI guidance (R3).** Review Microsoft's current Android Management
API / "What's new" documentation and the tenant **Message center**. Write down: what has moved,
what is pending, and any **required admin action**.

**Gate 0 (pass/fail):** Binding healthy **and** the team can state, in writing, the current AMAPI
status and any required action. Do not design waves until both are true.

---

## Phase 1 — Design (plan the wave; decide the enrollment path)

**Step 1.1 — Generate the wave plan.** Run `AMAPIMIG-New-MigrationWavePlan.ps1` (read-only by
default). It buckets the assessed devices into **Pilot → Wave1 → Wave2 → Prod** cohorts per
enrollment model, applying your criteria (model, ownership, OS floor, staleness), and writes
`AMAPIMIG-WavePlan.csv`. Least-risk models/cohorts go first; dedicated/COSU and BYOD work-profile
(highest user visibility) are staged deliberately.

**Step 1.2 — Check web/account-driven enrollment readiness (R5).** Run
`AMAPIMIG-Test-WebEnrollmentReadiness.ps1`. It confirms the binding, enrollment profiles, and
prerequisite signals, then **prompts you to confirm the method's availability for each enrollment
model against current Microsoft guidance**. Decide per model whether the wave adopts
web/account-driven enrollment or the currently-supported method.

**Step 1.3 — Draft the per-model impact statement (R4).** For each model, record the **expected**
end-user outcome (no change / re-consent / re-enrollment / work-profile reset) as a **hypothesis to
be proven in Pilot** — explicitly marked "unverified" until Phase Pilot confirms it.

**Gate 1 (pass/fail):** A wave plan exists, the enrollment path per model is decided (and its
availability verified), and a draft impact statement per model is written (even if "to be
verified").

**Rollback 1:** Design artifacts only — discard the plan/CSV. No production impact.

---

## Phase 2 — Configure (prepare, don't migrate yet)

**Step 2.1 — Prepare wave groups.** Create the Assigned security groups from the plan. Either in
Entra (**Groups → New group → Security, Assigned**) or with
`AMAPIMIG-New-MigrationWavePlan.ps1 -CreateGroups` (preview) then `-CreateGroups -Commit` to create
them. Start each group **scoped to its Pilot cohort only**.

**Step 2.2 — Confirm enrollment profiles & app assignments (R6).** Verify the enrollment profiles
(device-owner profiles/tokens for dedicated & fully managed) and **managed Google Play app
assignments** that the migrated cohort will rely on are in place and target the wave groups (or
their users). Record the baseline so validation can prove "apps still deliver."

**Step 2.3 — Confirm Conditional Access / compliance won't lock users out.** Review Android CA /
compliance so a re-enrollment (if it occurs) does not strand users behind a grace-less policy
during cutover.

**Gate 2 (pass/fail):** Pilot wave groups exist and are correctly scoped; enrollment profiles and
app assignments are confirmed against the wave groups; CA/compliance reviewed.

**Rollback 2:** Delete the newly created wave groups (nothing is migrated yet), revert any
assignment changes to the recorded baseline.

---

## Phase 3 — Pilot (migrate a small cohort; OBSERVE the impact)

Do this for **one model at a time**, lowest-visibility first.

**Step 3.1 — Execute the pilot migration per current guidance.** Perform the migration action
Microsoft's **current** guidance specifies for that enrollment model (an admin action in the
admin center, an enrollment-profile change, and/or device-side re-enrollment as directed).
**Follow the current documented steps — this procedure does not substitute for them.**

**Step 3.2 — Observe the real end-user experience (satisfies R4).** On the pilot devices, **watch
what actually happens**: does the device stay enrolled, re-consent, **re-enroll**, or reset the
work profile? Capture screenshots and timing. **Update the impact statement from "unverified" to
the observed, verified outcome for that model.**

**Step 3.3 — Confirm the device manages under AMAPI.** Confirm in the admin center that the pilot
device reflects the post-migration (AMAPI) management state Microsoft's current guidance describes.

**Gate 3 (pass/fail):**
- The pilot device **manages under AMAPI** (per Microsoft's current status surface), **and**
- the **end-user impact is now observed and documented** for that model, **and**
- the device is **compliant** and reachable.

Only a full pass promotes the model to production waves.

**Rollback 3 (before wide impact):** If the pilot fails or the user impact is unacceptable, **halt
that model's migration**, keep the remaining devices on the current (pre-migration) path, and
raise the finding. Because you piloted a small cohort, exposure is limited. For device-level
recovery of a failed pilot device, re-enroll it clean per current guidance and cross-reference the
**Android enrollment troubleshooting (Google account / AMAPI)** solution.

---

## Phase 4 — Validate (prove the three outcomes)

**Step 4.1 — Run the post-migration validation report.** Run
`AMAPIMIG-Get-PostMigrationValidation.ps1 -GroupName "AMAPIMIG – WorkProfile – Pilot"`. It reports,
for the cohort: device present & checking in, **compliant**, **managed-app install status** (apps
deliver), and account/ownership signals — against the Phase 2 baseline.

**Step 4.2 — Confirm accounts add and apps deliver.** Specifically confirm a managed Google Play
app **installs** on a migrated device and (where relevant) the managed Google account is present —
the two things most likely to break if the binding or enrollment regressed. See **05 — Testing**
for the exact pass/fail.

**Gate 4 (pass/fail):** For the piloted cohort — **devices manage under AMAPI, accounts add, apps
deliver, devices compliant.** All PASS before expanding.

**Rollback 4:** If validation fails after migration, follow **06 — Troubleshooting**; if
unresolved, halt further waves and escalate (Microsoft support) rather than pushing the failure to
production.

---

## Phase 5 — Expand (wave by wave)

**Step 5.1 — Promote model by model, wave by wave.** For each enrollment model that passed Pilot,
migrate **Wave1**, validate (Phase 4), then **Wave2**, then **Prod** — re-running the validation
report after each wave. Communicate the **verified** end-user impact to each wave **before** it
migrates.

**Step 5.2 — Keep tooling on hand.** Retain `AMAPIMIG-Get-PostMigrationValidation.ps1` and the
troubleshooting cross-reference for any recurrence as later waves migrate.

**Gate 5 (pass/fail):** Each wave validates (Phase 4 all PASS) before the next wave starts.

**Rollback 5:** Halt promotion; hold remaining waves on the current path. Already-migrated,
validated devices are unaffected by halting future waves.

---

## Order of operations (must not be reordered)

1. Binding healthy (R1) → 2. Estate inventoried (R2) → 3. **Current AMAPI guidance read** (R3) →
4. Wave planned + enrollment path decided (R5) → 5. **Pilot per model and OBSERVE re-enrollment /
impact** (R4) → 6. Validate (manage under AMAPI, accounts add, apps deliver) → 7. Expand wave by
wave. **Skipping the pilot-observe step and promising an end-user outcome you did not verify is the
primary failure mode this procedure prevents.**
