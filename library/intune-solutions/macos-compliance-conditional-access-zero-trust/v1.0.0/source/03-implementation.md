# 3. Implementation Guide — macOS Compliance & Conditional Access for Zero-Trust Access

Follow these steps **in order**. You work in two consoles:
- **Intune admin center** — `https://intune.microsoft.com` (the macOS compliance policy).
- **Microsoft Entra admin center** — `https://entra.microsoft.com` → **Protection → Conditional
  Access** (the CA policy).

> **Model:** Build compliance → create the CA policy in **Report-only** on the pilot → review →
> enable → expand. **Never** point a new device-based CA policy straight at all users.

Objects you will create and reuse by name:
`macOS - Zero-Trust Compliance` (compliance policy) · `CA - macOS - Require Compliant Device`
(CA policy) · `macOS-ZeroTrust-Pilot` (pilot group) · `macOS-ZeroTrust-Exclusions` (optional).

---

## Step 1 — Confirm the pilot group exists
1. Entra → **Groups**. Confirm **`macOS-ZeroTrust-Pilot`** exists (from Requirements 2.6). If not,
   **New group → Security →** name it `macOS-ZeroTrust-Pilot` → add the pilot Macs/users → **Create**.
2. *(Optional)* Create **`macOS-ZeroTrust-Exclusions`** the same way for any service/exception accounts
   you will exclude from the CA policy alongside your break-glass accounts.

## Step 2 — (Optional) Confirm the Defender connector for the machine-risk signal
1. Intune → **Endpoint security → Microsoft Defender for Endpoint**.
2. Confirm **Connection status: Enabled** and **Connect macOS devices … to Microsoft Defender for
   Endpoint** is **On**.
3. If Defender on macOS is not in place yet, **skip the machine-risk rule** in Step 3.6 and add it
   later — the other three signals still deliver a strong Zero-Trust gate.

## Step 3 — Create the macOS compliance policy `macOS - Zero-Trust Compliance`
1. Intune → **Devices → Compliance** (Compliance policies) → **+ Create policy**.
2. **Platform:** **macOS**. Click **Create**.
3. **Name:** `macOS - Zero-Trust Compliance`. **Description:** *Zero-Trust device health for Macs —
   encryption, OS, firewall, Defender risk.* → **Next**.
4. **Compliance settings → Device Health / System Security:**
   - **Firewall** → **Require** (or **Enable** — the label may read *Firewall* under System Security).
     *Flag: exact grouping of the firewall setting can vary by Intune version; if you don't see it
     under Device Health, look under **System Security**.*
5. **Encryption:**
   - **Require encryption of data storage on device** → **Require** (this is FileVault on macOS).
6. **System Security → Operating system version:**
   - **Minimum OS version** → set a floor your fleet can meet (e.g. a current supported major
     release). *Flag: choose a version verified reachable via `MACCA-Discovery.ps1` — too high a
     floor blocks healthy Macs.*
7. **Microsoft Defender for Endpoint (machine risk)** — *only if Step 2 connector is On:*
   - **Require the device to be at or under the machine-risk score** → choose **Medium** (blocks
     High risk) to start; you can tighten to **Low** later.
8. **Actions for noncompliance** → keep the default **Mark device noncompliant** but set it to a
   **grace period** (e.g. *Immediately* for pilot, then a few days for production — see Best
   Practices) so users get a warning window before being blocked. Optionally add **Send email to end
   user**. → **Next**.
9. **Scope tags** → default → **Next**.
10. **Assignments → Included groups → Add groups →** select **`macOS-ZeroTrust-Pilot`**. → **Next**.
11. **Review + create** → **Create**. The policy `macOS - Zero-Trust Compliance` now evaluates the
    pilot Macs.

## Step 4 — Let compliance evaluate, then confirm signals
1. Give the pilot Macs time to sync (Company Portal → **check status**, or wait for the sync cycle).
2. Intune → **Devices → Compliance → `macOS - Zero-Trust Compliance` → Device status** — confirm pilot
   Macs report **Compliant** (or see exactly which signal fails).
3. Run **`MACCA-Validation.ps1`** to confirm the pilot Macs are **Compliant** and Entra-registered —
   the two facts the CA policy depends on.

## Step 5 — Create the Conditional Access policy in Report-only
1. Entra → **Protection → Conditional Access → + Create new policy**.
2. **Name:** `CA - macOS - Require Compliant Device`.
3. **Users:** **Include → Select users and groups →** `macOS-ZeroTrust-Pilot`.
   **Exclude →** your **break-glass** accounts (and `macOS-ZeroTrust-Exclusions` if used). *Never omit
   the break-glass exclusion.*
4. **Target resources:** **Cloud apps →** select **Office 365** (start here; broaden later).
5. **Conditions → Device platforms → Configure = Yes → Include → Select device platforms → macOS.**
   This scopes the policy to Macs so it never affects Windows/mobile sign-ins.
6. **Grant:** **Grant access → Require device to be marked as compliant.** Leave **Require all the
   selected controls** selected. **Select**.
7. **Enable policy:** **Report-only**. Click **Create**.

## Step 6 — Review Report-only impact
1. Have pilot users sign in normally from their Macs for a day or two.
2. Entra → **Monitoring → Sign-in logs →** open a pilot sign-in → **Report-only** tab — confirm
   `CA - macOS - Require Compliant Device` shows a result (*would apply / satisfied / would block*).
3. Run **`MACCA-Report.ps1`** to summarize, per Mac, the **compliance state** and the **would-be
   access decision**. Resolve any unexpected would-blocks (usually a failing signal — see
   Troubleshooting).

## Step 7 — Prove a non-compliant Mac would be blocked
1. On a **pilot test Mac**, deliberately fail one signal (e.g. turn FileVault off on a spare test
   device, or let it drop below the OS floor). Wait for Intune to mark it **Not compliant**.
2. Sign in from that Mac and check the **Report-only** tab — the policy should read **would block**.
3. Confirm with **`MACCA-Report.ps1`** that the non-compliant Mac maps to a **deny** decision.
   *(Re-enable the signal afterward so the test Mac returns to Compliant.)*

## Step 8 — Enable enforcement
1. Re-run **`MACCA-Validation.ps1`** and confirm **break-glass accounts are excluded** from
   `CA - macOS - Require Compliant Device`.
2. Edit the CA policy → **Enable policy → On** → **Save**.
3. Verify pilot users on compliant Macs still work, and that the earlier non-compliant test Mac is now
   actually **blocked** (not just "would block").

## Step 9 — Expand to all Macs
1. Broaden the **compliance policy** assignment (Step 3.10) from `macOS-ZeroTrust-Pilot` to your
   all-Macs group, in waves. Use **`MACCA-Set-ScopeTargeting.ps1`** (default `-WhatIf`) to preview the
   membership change before applying it.
2. Broaden the **CA policy** **Users** (Step 5.3) to the all-Macs group, keeping break-glass/exclusion
   accounts excluded. Optionally widen **Target resources** from Office 365 to **All cloud apps**.
3. Monitor each wave with **`MACCA-Report.ps1`**; keep the grace period generous until the fleet
   settles (Best Practices).

---
### Order of operations
`Pilot group → (Defender connector) → Compliance policy → evaluate → CA policy (Report-only) →
review → prove non-compliant blocked → enable On → expand in waves`
