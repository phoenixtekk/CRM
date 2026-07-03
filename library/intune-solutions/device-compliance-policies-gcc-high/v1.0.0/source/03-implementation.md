# Implementation — Device Compliance Policies (Government / GCC High edition)

This guide is written for a **novice administrator** to follow click-by-click in the **GCC
High** portals. Every path uses the sovereign admin center **`intune.microsoft.us`** — if you
find yourself on `intune.microsoft.com`, stop: you are in the wrong cloud.

Follow the stages in order and honor the **gates**. Objects are named to the convention from
`01-solution-overview.md` and reused; do not rename them between stages.

> **Before you start**, complete the Assess exit gate in `02-requirements.md`. Run
> `DCPG-Discovery.ps1` first (read-only) to capture a baseline of what already exists — you
> will compare against it later.

---

## Stage 1 — Configure the Windows baseline compliance policy

### 1.1 Open Device compliance in the sovereign portal

1. Sign in to **`https://intune.microsoft.us/`** with your Intune Administrator account
   (you will be redirected to `login.microsoftonline.us` to authenticate).
2. In the left menu select **Devices**.
3. Select **Compliance** (Devices → **Compliance**), then the **Policies** tab.
4. Select **+ Create policy**.

### 1.2 Create the policy shell

1. **Platform:** select **Windows 10 and later**.
2. Select **Create**.
3. **Name:** `CP-Win-Baseline-GovHigh`
4. **Description:** `Windows baseline device compliance — GCC High. Owned by IT Security.`
5. Select **Next**.

### 1.3 Configure compliance settings

On the **Compliance settings** page, expand each category and set the following baseline.
These settings are the sovereign-cloud equivalents of the Commercial baseline; the
**parity caveats** are called out inline where GCC High behaves differently.

**Device Health**

| Setting | Value | GCC High caveat |
| --- | --- | --- |
| Require BitLocker | **Require** | ⚠️ **Verify for GCC High.** This depends on **Device Health Attestation (DHA)**, which Microsoft's Government Service overview lists as *planned / not yet available* in GCC High/DoD, while the Windows compliance-settings reference says DHA runs in GCC High. **Confirm on a pilot device before you rely on it** (see below). [[MS-GOV-SVC]](gcc-high-parity-notes.md) [[MS-WIN-COMPL]](gcc-high-parity-notes.md) |
| Require Secure Boot to be enabled on the device | **Require** | Same DHA dependency and caveat as BitLocker. |
| Require code integrity | **Require** | Same DHA dependency and caveat as BitLocker. |

> **DHA verification step (do this in Pilot).** Because the two Microsoft docs disagree on
> DHA availability in GCC High, treat the three Device Health settings as **unverified until
> proven on your tenant.** Assign the policy to one pilot device, wait for a sync, and check
> whether these settings report a real **Compliant/Not compliant** result rather than
> **Not applicable / Error**. If they never resolve, fall back to the **encryption** and
> **TPM** settings below (which do not require DHA) and leave the three Device Health
> settings **Not configured**. Record the outcome in your validation notes.

**Device Properties**

| Setting | Value |
| --- | --- |
| Minimum OS version | `10.0.19044.0` (Windows 10 21H2) or your organization's floor |

**System Security → Encryption**

| Setting | Value | Note |
| --- | --- | --- |
| Encryption of data storage on a device | **Require** | Checks OS-drive encryption (BitLocker) **without** the DHA attestation dependency — a safe baseline if DHA is unavailable. [[MS-WIN-COMPL]](gcc-high-parity-notes.md) |

**System Security → Device Security**

| Setting | Value |
| --- | --- |
| Firewall | **Require** |
| Trusted Platform Module (TPM) | **Require** |
| Antivirus | **Require** |
| Antispyware | **Require** |

**System Security → Defender**

| Setting | Value |
| --- | --- |
| Microsoft Defender Antimalware | **Require** |
| Real-time protection | **Require** |

**Microsoft Defender for Endpoint** *(only if MDE is onboarded in your GCC High tenant)*

| Setting | Value | GCC High note |
| --- | --- | --- |
| Require the device to be at or under the machine risk score | **Medium** | MDE **security settings management is supported in GCC High/DoD.** If MDE is not onboarded, leave this **Not configured**. [[MS-GOV-SVC]](gcc-high-parity-notes.md) |

Select **Next**.

### 1.4 Actions for noncompliance

1. The default action **Mark device noncompliant** is present with a schedule of
   **0 days** (immediate). Keep it, or set a short grace period (for example **1 day**) so
   users have time to remediate before they lose access.
2. Select **+ Add** → **Send email to end user**.
3. Select **Create a notification** (this becomes `MT-Compliance-Noncompliant-GovHigh`):
   - **Name:** `MT-Compliance-Noncompliant-GovHigh`
   - **Subject:** `Action required: your device is not compliant`
   - **Message:** a short note telling the user to open **Company Portal** and follow the
     remediation steps. Avoid any Commercial `*.com` links — Company Portal on GCC High is
     `portal.manage.microsoft.us`.
   - Save the notification, then select it as the action's template.
4. Schedule the email (for example, send **1 day** after noncompliance).
5. Select **Next**.

### 1.5 Assignments — pilot only

1. Under **Included groups**, select **Add groups** and choose **`SG-Compliance-Pilot`**
   (from R6). **Do not** assign to All devices/All users yet.
2. Leave **Excluded groups** empty for now.
3. Select **Next**.

### 1.6 Review and create

1. Review every setting on the **Review + create** page.
2. Select **Create**. The policy `CP-Win-Baseline-GovHigh` now appears in the list.

> **Gate — Configure complete when:** `CP-Win-Baseline-GovHigh` exists, targets only
> `SG-Compliance-Pilot`, and `MT-Compliance-Noncompliant-GovHigh` is attached as a
> noncompliance action. Run `DCPG-Validation.ps1` to confirm the policy exists and is
> pilot-scoped before moving on.

---

## Stage 2 — Pilot

1. Ensure at least one enrolled Windows device belongs to a user in `SG-Compliance-Pilot`.
2. On that device, force a sync: **Settings → Accounts → Access work or school →** your
   account **→ Info → Sync**; or run the Intune device action **Sync** from
   `intune.microsoft.us` → **Devices → All devices →** the device → **Sync**.
3. Wait for evaluation (allow up to a few hours for first evaluation; DHA-based settings only
   settle **after a reboot** because they are measured at boot time).
   [[MS-WIN-COMPL]](gcc-high-parity-notes.md)
4. **Perform the DHA verification step from 1.3** and record whether the three Device Health
   settings resolve to a real result on your GCC High tenant.

> **Gate — Pilot complete when:** the pilot device shows an explicit **Compliant** or
> **Not compliant** result for the policy (not perpetually *In progress*), and you have a
> recorded answer on DHA behavior. Change nothing else during pilot.

---

## Stage 3 — Add the Conditional Access gate

A compliance policy only labels devices; **Conditional Access** enforces the label. Create
the gate scoped to the **same pilot group** first.

1. Go to **`entra.microsoft.us`** (or `portal.azure.us` → Microsoft Entra ID) →
   **Protection → Conditional Access → Policies → + New policy**.
2. **Name:** `CA-Require-Compliant-GovHigh`
3. **Users:** include **`SG-Compliance-Pilot`** only. **Exclude** at least one
   break-glass/emergency-access admin account.
4. **Target resources:** start with a single test app (for example **Office 365 SharePoint
   Online**), not "All cloud apps", during pilot.
5. **Grant:** **Grant access → Require device to be marked as compliant.**
6. **Enable policy:** set to **Report-only** first, review sign-in logs, then switch to
   **On** once the pilot behaves as expected.
7. Select **Create**.

> **Gate — CA validated when:** a compliant pilot device reaches the test app and a
> deliberately noncompliant pilot device is blocked, verified in **Entra → Sign-in logs**.
> See `05-testing.md`. Keep a break-glass account excluded at all times.

---

## Stage 4 — Expand in waves

1. Build or grow target groups with `DCPG-Set-ScopeTargeting.ps1` (defaults to **-WhatIf** —
   review the plan, then re-run with `-Commit` to apply).
2. Widen the **assignment** of `CP-Win-Baseline-GovHigh` from `SG-Compliance-Pilot` to the
   next wave group, then the next, watching the compliance report between waves.
3. Widen `CA-Require-Compliant-GovHigh` in step with the compliance policy — never enforce
   Conditional Access on a population the compliance policy has not yet reached.
4. Only after the fleet is stable, broaden the CA target resources toward **All cloud apps**
   (still excluding break-glass accounts).

> **Gate — Expand safely when:** each wave's compliance rate is acceptable before the next
> wave begins, and CA enforcement never leads the compliance rollout.

---

## Re-runnable proof

At any point, run the read-only scripts to prove the tenant matches this design:

- `DCPG-Discovery.ps1` — inventory of compliance policies, assignments, and actions.
- `DCPG-Validation.ps1` — pass/fail check that the named objects exist and are scoped right.
- `DCPG-Report.ps1` — per-device compliance rollup for a status report.

All three connect with **`-Environment USGov`** and make **no changes**.
