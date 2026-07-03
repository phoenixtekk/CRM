# Implementation Guide — Microsoft 365 Copilot Secure Adoption & Governance (GCC High)

This is the ordered, click-by-click implementation for a **GCC High** tenant. Every portal path uses
the **`*.us` sovereign URLs**, and every script step connects to **US Gov Graph**
(`-Environment USGov`). GCC-High-specific caveats appear **inline at the step where they matter** —
do not skip them.

Follow the deployment model with a **gate at each arrow**:
**Assess → Configure → Pilot → Validate → Expand.**

> **Before you start:** complete the Requirements Guide (R1–R11). You need Compliance Administrator,
> SharePoint Administrator, and license-assignment rights, plus the Microsoft.Graph module able to
> connect with `-Environment USGov`.

> **Availability reminder:** Copilot is GA in GCC High (Dec 2025), but feature parity lags Commercial
> and web grounding is OFF by default. Where a step depends on a capability that may not be at parity,
> it says **verify for GCC High**. See the GCC High parity notes doc for the cited detail.

---

## Phase 0 — Assess (do this before enabling Copilot for anyone)

### Step 0.1 — Run Discovery (read-only)

Get a factual picture of your oversharing exposure and governance posture **before** any user gets a
Copilot license.

1. Open PowerShell on an admin workstation with US Gov network access (R5).
2. Run:
   ```
   powershell -ExecutionPolicy Bypass -File .\COPILOTG-Discovery.ps1
   ```
   The script calls `Connect-MgGraph -Environment USGov` and enumerates (read-only): SharePoint sites
   with broad/"Everyone except external users" sharing, sites without sensitivity labels, OneDrive
   sharing posture, and current Copilot license assignments.
3. Review the CSV/console output. **Sites flagged as broadly shared are your remediation backlog** —
   these are exactly where Copilot could surface content too widely once enabled.

> **GCC High caveat:** Discovery reads via `graph.microsoft.us`. If you see empty results but no
> error, confirm you connected to **USGov**, not the default environment (see Troubleshooting T1).

### Step 0.2 — Record the baseline

Save the Discovery output as your **pre-change baseline**. You will re-run Discovery/Validation after
remediation to prove the gap closed. This is your Assess-phase gate evidence.

---

## Phase 1 — Configure the guardrails (GCC High portals)

### Step 1.1 — Create / confirm the CUI sensitivity label in Purview

1. Go to **`https://compliance.microsoft.us`** (Microsoft Purview, GCC High) → sign in.
2. Left nav: **Information protection → Labels**.
3. If your mandated CUI label (e.g. `CUI//BASIC`, per R9) does not exist, select **Create a label**
   and build it to your **organization's mandated taxonomy** — **do not invent one.**
4. Configure the label's protection to your program's requirements (encryption/marking as mandated).
5. **Information protection → Label policies → Publish labels** → publish to the pilot group
   `SG-COPILOTG-Pilot` first (not the whole tenant).

> **GCC High caveat:** Purview label and DLP feature availability can lag Commercial. If a label
> option you expect is missing, **verify for GCC High** before assuming misconfiguration.

### Step 1.2 — Create a DLP policy that respects the label

1. In `https://compliance.microsoft.us` → **Data loss prevention → Policies → Create policy**.
2. Scope it to **SharePoint sites**, **OneDrive**, and **Teams** locations.
3. Base the rule on your **CUI sensitivity label** so content marked CUI is protected consistently.
   Name it `DLP-COPILOTG-CUI`.
4. Start in **Test / simulation** mode, review matches, then enforce. Record the change (R11).

### Step 1.3 — Turn on Restricted SharePoint Search (RSS) to bound Copilot's reach

Restricted SharePoint Search limits **tenant-wide** Copilot/enterprise search to an **allow-list** of
curated sites while you remediate the rest — a fast way to shrink Copilot's blast radius during
adoption.

1. From `https://portal.office365.us` → **Admin centers → SharePoint**.
2. **Settings → Search** (or **More features → Restricted SharePoint Search** depending on tenant
   layout) → **enable Restricted SharePoint Search**.
3. Add your vetted, correctly-permissioned sites to the allow-list `Copilot Search Allowed Sites`
   (up to the documented site cap).
4. Save and record the change (R11).

> **GCC High caveat — verify for GCC High:** Restricted SharePoint Search availability and its site
> cap can differ or lag in GCC High. Confirm the feature is present in **your** SharePoint (GCC High)
> admin center before relying on it as your primary guardrail. If unavailable, fall back to
> tightening site permissions directly (Step 1.4) until RSS lands. (See parity notes doc.)

### Step 1.4 — Remediate the broadly-shared sites from Discovery

For each site flagged in Step 0.1:

1. Tighten membership/permissions to the intended audience (remove "Everyone except external users"
   where not warranted).
2. Apply the correct **sensitivity label** at the site/library level.
3. Where you cannot immediately fix a site, **exclude it from the RSS allow-list** so Copilot cannot
   search it yet.

You can drive the safe, reviewable portion of remediation with the Remediation script (Step 1.5),
which runs **-WhatIf by default**.

### Step 1.5 — Run Remediation in preview, then apply

1. Preview only (default, no changes):
   ```
   powershell -ExecutionPolicy Bypass -File .\COPILOTG-Remediation.ps1
   ```
   It connects with `-Environment USGov` and **reports** what it *would* change (e.g. flag sites to
   remove from the allow-list, sites missing labels).
2. Review the preview against your change ticket.
3. Only when approved, re-run with the explicit apply switch the script documents in its header
   (e.g. `-Apply` / `-Confirm`), never blindly. Record results (R11).

> **Safety:** Remediation and Set-ScopeTargeting **default to -WhatIf**. Applying is an explicit,
> deliberate second run.

---

## Phase 2 — Pilot (named group only)

### Step 2.1 — Build/populate the pilot group

```
powershell -ExecutionPolicy Bypass -File .\COPILOTG-Set-ScopeTargeting.ps1
```
By default this runs **-WhatIf** and shows the membership it *would* set for `SG-COPILOTG-Pilot`.
Review, then re-run with the documented apply switch to create/populate the group.

### Step 2.2 — Assign Copilot licenses to the pilot group only

1. `https://portal.office365.us` → **Billing → Licenses → Microsoft 365 Copilot**.
2. Assign the **Microsoft 365 Copilot** add-on to members of `SG-COPILOTG-Pilot` (group-based
   licensing via Entra `https://entra.microsoft.us` → **Groups → SG-COPILOTG-Pilot → Licenses** is
   the cleaner path).
3. Confirm each pilot user also holds an **eligible base plan** (R2) — Copilot will not activate
   without it.

> **GCC High caveat:** Copilot in **Word/Excel/PowerPoint/Outlook** and **Copilot Chat (work
> grounding)** are available. **Teams meeting Copilot / Copilot in Teams chat/channels** have been
> **limited or not yet available** in GCC High — **do not promise Teams-meeting Copilot to pilot
> users until you verify it for your tenant.** (See parity notes.)

> **GCC High caveat — web grounding OFF:** pilot users get **tenant-grounded** answers by default.
> Set expectations: no live web lookups unless your org explicitly enabled web grounding and accepted
> the data-boundary tradeoff.

### Step 2.3 — Confirm Copilot activation

Have a pilot user open Word/Outlook (GCC High) and confirm the Copilot experience appears, and that
Copilot Chat only returns content the user is entitled to.

---

## Phase 3 — Validate (pass/fail gate)

### Step 3.1 — Run Validation

```
powershell -ExecutionPolicy Bypass -File .\COPILOTG-Validation.ps1
```
Connects with `-Environment USGov` and checks (read-only): RSS enabled and scoped; CUI label
published; DLP policy present and enforced; Copilot licenses only on the intended group; no
broadly-shared site remains inside the RSS allow-list. Output is **pass/fail per check.**

### Step 3.2 — Manual spot-check

As a pilot user, prompt Copilot to surface content from a site you **deliberately kept out** of the
allow-list / that the user shouldn't reach — confirm Copilot **cannot** surface it. This is the core
"no oversharing" proof.

### Step 3.3 — Produce the report

```
powershell -ExecutionPolicy Bypass -File .\COPILOTG-Report.ps1
```
Generates a consolidated **evidence report** (posture + validation results) for your change record
and leadership sign-off.

**Gate:** All Validation checks pass and the manual spot-check confirms no oversharing → proceed.
Any fail → remediate and re-validate; do **not** expand.

---

## Phase 4 — Expand (controlled waves)

1. Populate `SG-COPILOTG-Wave2` with `COPILOTG-Set-ScopeTargeting.ps1` (preview, then apply).
2. Assign Copilot licenses to Wave 2 via group-based licensing.
3. Add the next batch of **remediated, correctly-labeled** sites to the RSS allow-list.
4. Re-run **Validation** and **Report** after each wave — every wave is gated on clean results.
5. Continue until the estate is governed and Copilot is broadly, safely enabled.

> **Do not** widen the RSS allow-list faster than you remediate. The allow-list is your throttle.

---

## Post-implementation

- Re-run **Discovery** monthly (new sites/oversharing appear over time) — treat it as ongoing
  hygiene, not a one-time task.
- Re-check **GCC High feature parity** each quarter as Wave 2 capabilities land; update pilot
  expectations when Teams-meeting Copilot / web grounding / new agents become available for your
  tenant.
