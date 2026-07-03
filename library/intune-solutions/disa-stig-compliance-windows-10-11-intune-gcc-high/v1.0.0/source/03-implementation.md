# Implementation Guide — Government / GCC High edition

This guide walks a **novice administrator** through delivering DISA STIG alignment on Windows 10 & 11 via Intune **in the US Government cloud (GCC High / DoD)**, click-by-click, using the **sovereign `*.us` portals**. It follows the gated model **Assess → Configure → Pilot → Validate → Expand**. GCC-High/DoD caveats appear inline at the step where they matter.

> **Before you start:** finish `02-requirements.md`. You must be signed in to **`https://intune.microsoft.us`** (not `.com`) as an **Intune Administrator** in the Gov tenant, and you must have the **DISA STIG benchmark** (from `public.cyber.mil`) open in **STIG Viewer**. This solution supplies the delivery mechanism; the **rule content comes from DISA**.

---

## Phase 0 — Sign in to the right cloud (do this first)

1. Open a browser and go to **`https://intune.microsoft.us`**. Sign in; confirm the authority in the address bar is **`login.microsoftonline.us`**.
2. In a second tab, open **`https://portal.azure.us`** for Entra ID (Groups, Roles).
3. **Sanity check:** if either portal redirects you to a `.com` sign-in or "tenant not found," you are pointed at Commercial — stop and correct the URL. Everything below assumes `*.us`.

**Gate 0:** Both `intune.microsoft.us` and `portal.azure.us` load your Gov tenant, and you hold **Intune Administrator**.

---

## Phase 1 — Assess

Goal: know your fleet, your benchmark, and your gaps before changing anything.

1. **Inventory the fleet.** `intune.microsoft.us` → **Devices → All devices**. Note Windows 10 vs 11, OS builds, and enrollment state. Confirm devices check in (they use `*.manage.microsoft.us`).
2. **Run Discovery (read-only).** From the admin workstation, run `scripts\STIGG-Discovery.ps1` with **`-Environment USGov`** (GCC High) or **`-Environment USGovDoD`** (DoD). It inventories existing configuration profiles, ADMX profiles, compliance policies, security baselines, and target groups so you don't duplicate or collide with existing objects.
3. **Load the DISA benchmark.** Open the current *Microsoft Windows 11 STIG* / *Windows 10 STIG* in **STIG Viewer**. Record the **benchmark version/release date** — you will pin your policy set to it.
4. **Confirm the STIG audit baseline availability (optional, GCC High).** `intune.microsoft.us` → **Reports → Advanced Analytics** (or **Endpoint security → Security baselines**). If the **STIG** audit baseline appears, note it — it will *assess* (not enforce) devices against DISA recommendations. **If it is absent, that is expected** where Advanced Analytics isn't licensed or where the feature hasn't reached your tenant — **verify for GCC High/DoD**; you will still enforce via Settings Catalog/ADMX/custom.
5. **Map rules → mechanism.** For each STIG rule, decide the Intune delivery mechanism:
   - **Settings Catalog** (default, most rules),
   - **Administrative Templates (ADMX)** (classic policy settings), or
   - **Custom / OMA-URI** (CSP with no catalog UI yet).
   Keep this mapping in a spreadsheet keyed by DISA rule ID → Intune setting → chosen profile name.

**Gate 1:** You have a device inventory, the benchmark version recorded, a rule→mechanism map, and Discovery output showing no naming collisions.

---

## Phase 2 — Configure (build objects; assign to nobody yet)

You will build every object now but **assign to the pilot group only in Phase 3**. Reuse the object names from `01-solution-overview.md`.

### 2a. Create the target groups

1. `portal.azure.us` → **Microsoft Entra ID → Groups → New group**.
2. Type **Security**; name **`SG-STIG-Pilot-Devices`**; add 5–15 representative pilot devices. Create.
3. Repeat to create **`SG-STIG-Prod-Devices`** (leave empty for now).
   *(You can also build these with `scripts\STIGG-Set-ScopeTargeting.ps1` — it defaults to `-WhatIf`, so run once to preview, then again with `-WhatIf:$false` to apply.)*

### 2b. Build the Settings Catalog profile(s)

1. `intune.microsoft.us` → **Devices → Manage devices → Configuration** → **Create → New Policy**.
2. **Platform:** Windows 10 and later. **Profile type:** **Settings catalog**. Create.
3. Name it per convention, e.g., **`STIG-Win-SettingsCatalog-Account`**. (Split by domain — Account, Audit, Defender, etc. — so a rollback is surgical.)
4. **Add settings** → search for the CSP/ADMX settings your STIG mapping calls for, and set each value to the DISA-specified value. **Do not assign yet** — click through to **Review + create**, leaving assignments empty.
5. Repeat for each domain profile you mapped.

> **GCC High/DoD parity note:** the Settings Catalog surface is the same as Commercial, but individual settings can lag their Commercial debut in the sovereign cloud. If a setting you expect is missing, check whether it's a newer CSP not yet in Gov, and fall back to **ADMX** or **custom OMA-URI** for that rule. **Verify for GCC High/DoD.**

### 2c. Build Administrative Templates (ADMX) profile(s) as needed

1. **Configuration → Create → New Policy → Windows 10 and later → Templates → Administrative Templates**.
2. Name **`STIG-Win-ADMX-{domain}`**; set the mapped classic policy settings; **Review + create** with no assignments.

### 2d. Build custom / OMA-URI profile(s) for gaps

1. **Configuration → Create → New Policy → Windows 10 and later → Templates → Custom**.
2. Name **`STIG-Win-Custom-{rule-area}`**; add each OMA-URI (name, description, OMA-URI path, data type, value) exactly per the CSP documentation for the rule. **Review + create**, no assignments.

### 2e. Build the compliance policy

1. **Devices → Manage devices → Compliance → Create policy → Windows 10 and later**.
2. Name **`STIG-Win-Compliance-Baseline`**. Add the rules you want to *gate* device compliance on (e.g., BitLocker, minimum OS build, Defender on). **Review + create**, no assignments yet.

> **GCC High/DoD parity note:** compliance policy and Conditional Access exist in the Gov cloud, but some **MTD connectors** and integrations available in Commercial may not have a GCC-High-capable vendor. When you sign in to a Gov tenant, only the connectors valid there are shown. **Verify for GCC High/DoD** before making a partner integration a compliance dependency.

### 2f. (Optional, GCC High) Instantiate the STIG audit baseline

If the **STIG** audit baseline is available (R9): **Endpoint security → Security baselines → STIG…** → **Create profile**, name it **`STIG-Win-AuditBaseline`**, accept the audit-only assessment settings, **do not assign yet**. Remember: this **reports**, it does not configure devices.

**Gate 2:** All objects exist, are named per convention, are pinned to the benchmark version, and have **no assignments**. Re-run `STIGG-Discovery.ps1` to confirm.

---

## Phase 3 — Pilot (assign to `SG-STIG-Pilot-Devices` only)

1. For **each** profile built in Phase 2, open it → **Properties → Assignments → Edit** → add **`SG-STIG-Pilot-Devices`** → **Review + save**. Assign the compliance policy and (if used) the audit baseline the same way.
   *(Or use `scripts\STIGG-Set-ScopeTargeting.ps1` to assign in bulk — preview with the default `-WhatIf`, then apply.)*
2. On pilot devices, force a sync: **Settings → Accounts → Access work or school → Info → Sync**, or `intune.microsoft.us` → device → **Sync**.
3. Wait for check-in (devices contact `*.manage.microsoft.us`). Confirm each profile shows **Succeeded** for the pilot devices under the profile's **Device status**.

**Gate 3:** Every pilot assignment shows **Succeeded** (no **Error/Conflict**) on the pilot devices, and pilot users report no functional breakage.

---

## Phase 4 — Validate (evidence before you expand)

1. **Run Validation (read-only):** `scripts\STIGG-Validation.ps1 -Environment USGov` (or `USGovDoD`). It confirms the pilot assignments match the intended object set and flags conflicts, unassigned profiles, and drift.
2. **Run Report (read-only):** `scripts\STIGG-Report.ps1 -Environment USGov` to produce a JSON/CSV evidence artifact of profile/compliance/baseline state for the pilot group. Store it per your change-control process (R10).
3. **Check the audit baseline (if used):** review the STIG audit results in Advanced Analytics for the pilot devices; note assessed-vs-target deltas. Remember these are **advisory** — enforcement is your profiles.
4. **Functional check:** verify pilot devices still perform their mission workload (sign-in, LOB apps, VPN/Tunnel, printing). STIG lockdowns can break workflows; catch it in pilot, not production.

**Gate 4:** Validation clean, Report evidence captured, audit deltas understood/accepted, no functional regressions. **Only now proceed to Expand.**

---

## Phase 5 — Expand (roll out under change control)

1. Add production devices to **`SG-STIG-Prod-Devices`** in waves (e.g., 10% → 25% → 50% → 100%). Use `STIGG-Set-ScopeTargeting.ps1` (default `-WhatIf` first) to add the prod group to each profile's assignments, or add it in the portal.
2. After **each wave**, re-run `STIGG-Validation.ps1` and `STIGG-Report.ps1`; hold the wave if errors/conflicts appear.
3. **Remediate drift** with `scripts\STIGG-Remediation.ps1` — it defaults to **`-WhatIf`**; review the planned actions, then re-run with `-WhatIf:$false` to apply only the changes you approved.
4. **Maintain against benchmark updates:** when DISA releases a new STIG benchmark version, re-open it in STIG Viewer, update your rule→setting map, revise the affected profiles, bump their benchmark-version pin, and re-pilot the delta before expanding.

**Gate 5:** 100% of `SG-STIG-Prod-Devices` reporting **Succeeded**, evidence captured per wave, and a documented benchmark-version → policy-version record.

---

## Sovereign-cloud reminders (apply throughout)

- Always operate in **`intune.microsoft.us`** / **`portal.azure.us`**; scripts always use **`-Environment USGov`** or **`-Environment USGovDoD`**.
- **Do not** rely on Commercial-only features (classic Autopilot, Windows Update feature/quality/expedite/driver policies, Remote Help, Security Copilot, Cloud PKI) — see `gcc-high-parity-notes.md` and design around the gaps. **Verify current availability for GCC High/DoD** before assuming a feature is present.
- **SSL inspection is not supported** on `*.manage.microsoft.us` — exclude it, or enrollment/check-in fails.
- STIG **rule content stays with DISA**; you deliver and validate it with Intune.
