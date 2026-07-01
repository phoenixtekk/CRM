# 3. Implementation Guide — Application Control (WDAC)

Follow these steps **in order**, in the **Microsoft Intune admin center** (`https://intune.microsoft.com`).

> **Model:** App Control for Business policy trusting Windows + Store (+ managed installer + ISG),
> deployed **Audit-first**, reviewed, then **Enforced**.

## Step 1 — Create the pilot group
1. Entra → **Groups → New group** → Security → `WDAC-Pilot` → add a few pilot devices. **Create**.

## Step 2 — Create the App Control policy (Audit mode)
1. Intune → **Endpoint security → Application control** (App Control for Business) → **Create Policy**.
   *(If not present in your tenant, use **Devices → Configuration → Create → Settings catalog** and search **"App Control" / "Application Control"**.)*
2. **Platform:** Windows. **Profile:** **App Control for Business**. **Create**.
3. **Name:** `WDAC - Audit (Pilot)`. **Next**.

## Step 3 — Configure trust and mode
On **Configuration settings**:
1. **Application control code integrity policies** = **Enable**.
2. **Trust mode** / built-in policy = **Trust Windows components and Store apps**.
3. **Also trust apps with good reputation (ISG)** = **Enable** (recommended).
4. **Trust apps from managed installers** = **Enable** (so Intune-deployed apps are allowed).
5. **Enforcement** = **Audit only** for now.
Click **Next**.

## Step 4 — Assign and run the audit
1. **Assignments → Add groups →** `WDAC-Pilot`. **Next → Create**.
2. Let pilot devices run normally for **2+ weeks**, exercising all line-of-business apps.

## Step 5 — Review Code Integrity audit events
1. On pilot devices run **`WDAC-AuditReport.ps1`** (reads Code Integrity audit events 3076).
2. Identify legitimate apps that *would* have been blocked.

## Step 6 — Add trust for legitimate apps
1. Preferred: **deploy those apps via Intune** so the **managed installer** trust covers them.
2. For signed apps not from Intune, rely on **ISG** reputation or add a **supplemental/custom policy** (advanced).
3. Re-audit until the audit log is clean of legitimate blocks.

## Step 7 — Switch to Enforce
1. Duplicate the policy as `WDAC - Enforce (Pilot)` (or edit) and set **Enforcement = Enforced**. **Save**.
2. Re-validate with **`WDAC-Validation.ps1`** (confirms an enforced policy is active).
3. Confirm pilot users can run all required apps; untrusted code is blocked.

## Step 8 — Expand to production
1. Add a production group to the **Enforce** policy **Assignments**; roll out in waves.
2. Keep new apps flowing through Intune (managed installer) so they stay trusted.
3. Re-validate each wave with **`WDAC-Validation.ps1`** / **`WDAC-AuditReport.ps1`**.

> **Recovery:** if an enforced policy is too strict, **unassign** it in Intune (and run
> **`WDAC-Remediation.ps1`** to clear/refresh the local policy), then return to Audit, fix trust, re-enforce.

---
### Order of operations
`Pilot group → App Control policy (Audit) → Trust Windows/Store/ISG/managed-installer → Assign → Review audit → Add trust → Enforce → Expand`
