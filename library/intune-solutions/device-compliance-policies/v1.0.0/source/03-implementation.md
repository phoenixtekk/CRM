# 3. Implementation Guide — Device Compliance Policies

Follow these steps **in order**, in the **Microsoft Intune admin center** (`https://intune.microsoft.com`).

> **Model:** A Windows compliance policy with health + password + Defender rules, actions for
> noncompliance, assigned to a pilot group — ready for Conditional Access enforcement.

## Step 1 — Set the no-policy default
1. Go to **Devices → Compliance → Compliance settings**.
2. Set **Mark devices with no compliance policy assigned as** to **Not compliant**. **Save**.

## Step 2 — Create the compliance policy
1. Go to **Devices → Compliance → Create policy**.
2. **Platform:** Windows 10 and later. Click **Create**.
3. **Name:** `Compliance - Windows - Pilot`. Click **Next**.

## Step 3 — Configure the rules
On **Compliance settings**, set:
1. **Device Health** → Require BitLocker = **Require**; Require Secure Boot = **Require**; Code integrity = **Require**.
2. **Device Properties** → Minimum OS version = your baseline (e.g. `10.0.19044`).
3. **System Security** → Require a password = **Require**; Minimum password length = **8**; Password type = **Alphanumeric** (or Device default); Encryption of data storage = **Require**.
4. **Microsoft Defender Antivirus** = **Require**; **Real-time protection** = **Require**; **Firewall** = **Require**.
5. (Optional) **Defender for Endpoint** → Require the device to be at or under machine risk score = **Medium**.
6. Click **Next**.

## Step 4 — Configure actions for noncompliance
1. On **Actions for noncompliance**, keep **Mark device noncompliant** and set schedule to **1 day** (grace period).
2. Click **Add** → **Send email to end user** → choose/create a notification → schedule **immediately**.
3. (Optional) Add **Remotely lock the noncompliant device** for higher-risk scopes. Click **Next**.

## Step 5 — Assign to the pilot group
1. On **Assignments → Included groups → Add groups →** select `Compliance-Pilot`. **Next**.

## Step 6 — Review and create
1. On **Review + create**, confirm the rules and actions. Click **Create**.

## Step 7 — (Recommended) require compliance in Conditional Access
1. Pair with the **Conditional Access Integration** solution: create a policy requiring **Require device to be marked as compliant** for the same users. Start in **Report-only** mode.

## Step 8 — Validate the pilot
1. On a pilot device, run **`DCP-Validation.ps1`** → confirms the device reports Compliant.
2. Run **`DCP-TenantReport.ps1`** → confirms compliance status across the pilot group.
3. Run **`DCP-ConflictCheck.ps1`** → flags conflicting policies. Complete the **Testing Guide**.

## Step 9 — Expand to production
1. Add a production group to the policy **Assignments**; roll out in waves.
2. Move the Conditional Access policy from **Report-only** to **On** once compliance coverage is confirmed.
3. Re-validate each wave with **`DCP-Validation.ps1`** / **`DCP-TenantReport.ps1`**.

---
### Order of operations
`No-policy default → Create policy → Rules → Actions → Assign → (CA require compliant) → Validate → Expand`
