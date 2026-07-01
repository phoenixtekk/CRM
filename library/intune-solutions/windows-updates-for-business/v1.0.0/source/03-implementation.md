# 3. Implementation Guide — Windows Updates for Business

Follow these steps **in order**, in the **Microsoft Intune admin center** (`https://intune.microsoft.com`).

> **Model:** A fast **Pilot** ring and a slower **Broad** ring, plus a feature update profile that
> pins the target Windows version. Pilot validates every update before the fleet gets it.

## Step 1 — Create the ring groups
1. Entra → **Groups → New group** → Security → `WUfB-Pilot` (a few representative devices). **Create**.
2. Create `WUfB-Broad` (the rest of the fleet). **Create**.

## Step 2 — Create the Pilot update ring
1. Intune → **Devices → Windows → Update rings for Windows 10 and later → Create profile**.
2. **Name:** `Update Ring - Pilot`. **Next**.
3. **Update settings:**
   - **Quality update deferral period (days):** **0**.
   - **Feature update deferral period (days):** **0**.
   - **Automatic update behavior:** Auto install and restart at a scheduled time (or at maintenance time).
   - **Active hours:** 8:00–18:00 (adjust to your org).
   - **Deadline for quality updates:** **2 days**; **feature updates:** **3 days**; **grace period:** **2 days**.
   - **User experience:** allow the user to pause = your policy.
4. **Next → Assignments → Add groups →** `WUfB-Pilot`. **Next → Create**.

## Step 3 — Create the Broad update ring
1. **Create profile** again. **Name:** `Update Ring - Broad`.
2. **Update settings:** **Quality deferral 7 days**, **Feature deferral 14 days**, deadlines as above.
3. **Assignments → Add groups →** `WUfB-Broad`. **Create**.

## Step 4 — Create the feature update profile (pin the version)
1. Intune → **Devices → Windows → Feature updates for Windows 10 and later → Create profile**.
2. **Name:** `Feature Update - Target`. **Feature update version:** select your target (e.g. **Windows 11, version 23H2**).
3. **Rollout options:** Make update available as soon as possible (or schedule a gradual rollout).
4. **Assignments → Add groups →** `WUfB-Pilot` and `WUfB-Broad`. **Create**.

## Step 5 — Configure Delivery Optimization (optional but recommended)
1. **Devices → Configuration → Create → Settings catalog →** search **Delivery Optimization**.
2. Set **Download Mode** to **HTTP blended with peering behind same NAT (1)** or **LAN (1)**; set max bandwidth as needed. Assign to all update groups. **Create**.

## Step 6 — Apply on a pilot device
1. On a pilot device, sync policy (**Settings → Accounts → Access work or school → Info → Sync**).
2. Confirm the deferral/deadline settings applied (**Settings → Windows Update → … managed by your organization**), or run **`WUFB-Validation.ps1`**.

## Step 7 — Validate the pilot
1. Run **`WUFB-Validation.ps1`** → confirms the ring policy applied (deferrals/deadlines in registry).
2. Run **`WUFB-ComplianceReport.ps1`** → confirms pilot devices' update status and OS build.
3. Let the next quality update install on the pilot and confirm a healthy result. Complete the **Testing Guide**.

## Step 8 — Expedite path (for emergencies)
1. When a zero-day quality update is released, go to **Devices → Windows → Quality updates (Expedite) → Create profile**, choose the update, set restart grace, and assign — it bypasses deferrals.

## Step 9 — Expand to production
1. The **Broad** ring already covers the fleet; confirm it's healthy after the pilot passes each cycle.
2. Move the feature update target forward only after the pilot validates the new version.
3. Re-validate each cycle with **`WUFB-ComplianceReport.ps1`** / **`WUFB-RingReport.ps1`**.

---
### Order of operations
`Ring groups → Pilot ring → Broad ring → Feature update profile → Delivery Optimization → Apply → Validate → Expedite (as needed) → Expand`
