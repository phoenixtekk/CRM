# 3. Implementation — HIPAA & HITRUST Endpoint Compliance & Vulnerability Remediation (Intune + Defender) — Government (GCC High)

This implementation follows the phase model **Assess → Configure → Gate → Remediate → Evidence/Report →
Operate**, aligned to the library standard **Assess → Configure → Pilot → Validate → Expand**. Every
object is **named verbatim** using the `<Purpose> – <Scope> – <Stage>` convention and reused across
phases, scripts, and evidence. Reuse the exact names. **Every navigation path uses the `.us` GCC High
portals** — never assume a prerequisite; if a referenced object does not exist, build it per
`02-requirements.md` first.

> **Reminder:** This builds the technical enforcement and evidence layer on a sovereign tenant. It does
> not constitute HIPAA compliance or HITRUST certification on its own.

> **Before you click anything — confirm you are on GCC High.** Sign in at
> **`https://intune.microsoft.us`** (not `intune.microsoft.com`). If a bookmark or search result lands
> you on a `.com` portal, you are on the **Commercial** cloud and your GCC High objects will not appear.
> Run **`HIPAACOMPG-Discovery.ps1`** (which connects with `-Environment USGov`) to confirm the tenant is
> reachable before building.

---

## Phase 1 — Assess: map controls to enforceable settings

### Step 1 — Confirm the scope group exists (Gov Entra)

1. Open the **Microsoft Entra admin center** at **`https://entra.microsoft.us`** > **Identity** >
   **Groups** > **All groups**.
2. Search for **`HIPAA – Clinical Endpoints`**. Confirm it is a **Security** group and its (preferably
   dynamic) device membership rule resolves the in-scope clinical Windows endpoints.
3. If it does not exist, create it per `02-requirements.md` R5 (or run **`HIPAACOMPG-Set-ScopeTargeting.ps1`**)
   before proceeding. Every object below targets this group.

### Step 2 — Build the control-to-policy mapping

Create the mapping artifact that ties each in-scope safeguard to the object that will enforce it, the
evidence source, and the owner. Store it in the evidence repository (R11). Use this structure (named
objects are created in later phases):

| HIPAA Security Rule safeguard | HITRUST CSF area | Enforcing object (named) | Evidence source | Owner |
|---|---|---|---|---|
| Encryption & decryption — §164.312(a)(2)(iv) | 06 Configuration / 19 Data Protection | `Encryption – Clinical Endpoints – Baseline` (BitLocker) | Intune disk-encryption report; `HIPAACOMPG-Report.ps1` | (R10) |
| Automatic logoff — §164.312(a)(2)(iii) | 01 Access Control | `Lock – Clinical Endpoints – Baseline` (inactivity lock/timeout) | Compliance + config report | (R10) |
| Protection from malicious software — §164.308(a)(5)(ii)(B) | 09 Endpoint Protection | `Antivirus – Clinical Endpoints – Baseline` (Defender AV) | Defender AV health; compliance report | (R10) |
| Integrity / network safeguards — §164.312(c)(1) | 09 Network Protection | `Firewall – Clinical Endpoints – Baseline` (Windows Firewall) | Config report | (R10) |
| Security updates / patch — §164.308(a)(1)(ii)(B) | 10 Vulnerability Mgmt | `Patch – Clinical Endpoints – Baseline` (Update ring; min OS build) | Compliance report; Defender TVM | (R10) |
| Access control / unique user ID — §164.312(a)(2)(i) | 01 Access Control | `Access – Clinical Endpoints – Baseline` (account/sign-in controls) | Config report | (R10) |
| Vulnerability exposure management | 10 Vulnerability Mgmt | Defender TVM + `Vulnerability – Clinical Endpoints – Remediation` | Defender exposure score; `HIPAACOMPG-Report.ps1` | (R10) |
| Access enforcement at sign-in | 01 Access Control | `Require Compliance – Clinical Endpoints – Gate` (Conditional Access) | CA sign-in logs | (R10) |

> The mapping is the audit spine. Keep it current as objects are created and renamed.

---

## Phase 2 — Configure: compliance policy and configuration baselines

The **compliance policy measures** the safeguards; the **configuration baselines enforce** them. Build
both, in `intune.microsoft.us`. You may scaffold the compliance policy + CA gate first with
**`HIPAACOMPG-Set-ScopeTargeting.ps1`**–adjacent tooling, or build by hand as below.

### Step 3 — Create the compliance policy `HIPAA Compliance – Clinical Endpoints – Policy`

1. **Intune admin center** (`https://intune.microsoft.us`) > **Devices** > **Compliance** >
   **Compliance policies** > **+ Create policy**.
2. **Platform:** *Windows 10 and later*. Click **Create**.
3. **Basics:** Name = **`HIPAA Compliance – Clinical Endpoints – Policy`**; Description = "Measures
   HIPAA/HITRUST endpoint safeguards on GCC High: BitLocker, lock, Defender AV, firewall, patch
   currency, sign-in. Targets HIPAA – Clinical Endpoints." Click **Next**.
4. **Compliance settings** — expand each section and set:
   - **Device Health:** *Require BitLocker* = **Require**; *Require Secure Boot to be enabled* =
     **Require**; *Require code integrity* = **Require**.
   - **Device Properties:** *Minimum OS version* = your current supported Windows build (drives patch
     currency; update as builds advance — see R7).
   - **System Security:**
     - *Require a password to unlock mobile devices* = **Require**; *Maximum minutes of inactivity
       before password is required* = **15** (automatic logoff).
     - *Encryption of data storage on device* = **Require**; *Firewall* = **Require**.
     - *Antivirus* = **Require**; *Antispyware* = **Require**.
     - *Microsoft Defender Antimalware* = **Require**; *Real-time protection* = **Require**;
       *Microsoft Defender Antimalware security intelligence up-to-date* = **Require**.
   - **Microsoft Defender for Endpoint:** *Require the device to be at or under the machine risk score*
     = **Medium** (requires the Defender-for-GCC-High connector, R3).
5. **Actions for noncompliance:** keep *Mark device noncompliant* = **Immediately**; add *Send email to
   end user*. Click **Next**.
6. **Scope tags:** apply your scope tag if used. **Assignments:** **Included groups** > add **`HIPAA –
   Clinical Endpoints`**. Click **Next** > **Create**.

> **Verify:** **Devices** > **Compliance** > open the policy > **Device status** — devices report within
> an evaluation cycle. If none appear, confirm you are on `intune.microsoft.us` (not `.com`).

### Step 4 — Create `Encryption – Clinical Endpoints – Baseline` (BitLocker)

1. **Intune admin center** > **Endpoint security** > **Disk encryption** > **+ Create policy**.
2. **Platform** = *Windows 10 and later*; **Profile** = *BitLocker*. **Create**.
3. **Basics:** Name = **`Encryption – Clinical Endpoints – Baseline`**; Description = "Enforces BitLocker
   silent encryption for clinical endpoints (HIPAA encryption safeguard)."
4. **Configuration settings:**
   - *Enable full disk encryption for OS and fixed data drives* = **Yes**.
   - **BitLocker – Base Settings:** *Allow standard users to enable encryption during Autopilot* =
     **Yes** *(note: classic Autopilot is not available on GCC High — this setting is harmless but has no
     effect without Autopilot; standard silent encryption still applies on enrollment)*; *Configure
     client-driven recovery password rotation* = **Enabled for Azure AD-joined devices**.
   - **BitLocker – OS Drive Settings:** *Startup authentication required* = **Yes**; *Compatible TPM
     startup* = **Required**; *Recovery options* > *Save BitLocker recovery information to Microsoft
     Entra ID* = **Yes**; *Store recovery information before enabling* = **Yes**.
5. **Assignments:** add **`HIPAA – Clinical Endpoints`**. **Create**.

> **Verify:** **Endpoint security** > **Disk encryption** > the policy > encryption status; and
> **Devices** > (device) > **Recovery keys** shows escrowed keys (escrowed to the **Gov** directory).

### Step 5 — Create `Lock – Clinical Endpoints – Baseline` (automatic logoff)

1. **Intune admin center** > **Devices** > **Configuration** > **+ Create** > **New policy**.
2. **Platform** = *Windows 10 and later*; **Profile type** = *Settings catalog*. **Create**.
3. **Basics:** Name = **`Lock – Clinical Endpoints – Baseline`**; Description = "Enforces automatic screen
   lock / inactivity timeout (HIPAA automatic logoff)."
4. **Configuration settings** > **+ Add settings** > search **Device Lock** and add:
   - *Maximum Inactivity Time Lock Screen* = **15** (minutes).
   - Machine inactivity limit (Local Policies Security Options > *Interactive logon: Machine inactivity
     limit*) = **900** seconds.
   - *Require password when device returns from idle* = **Enabled**.
5. **Assignments:** add **`HIPAA – Clinical Endpoints`**. **Create**.

### Step 6 — Create `Antivirus – Clinical Endpoints – Baseline` (Defender AV)

1. **Intune admin center** > **Endpoint security** > **Antivirus** > **+ Create policy**.
2. **Platform** = *Windows 10, Windows 11, and Windows Server*; **Profile** = *Microsoft Defender
   Antivirus*. **Create**.
3. **Basics:** Name = **`Antivirus – Clinical Endpoints – Baseline`**; Description = "Enforces Microsoft
   Defender Antivirus real-time + cloud protection and signature currency (HIPAA malware protection)."
4. **Configuration settings:** *Allow Realtime Monitoring* = **Allowed**; *Allow Cloud Protection* =
   **Allowed**; *Cloud Block Level* = **High**; *Allow Behavior Monitoring* = **Allowed**; *Submit
   Samples Consent* = **Send safe samples automatically**; *Signature Update Interval* = **4** (hours);
   *Allow Scanning Network Files* = **Allowed**; schedule a daily quick scan.
5. **Assignments:** add **`HIPAA – Clinical Endpoints`**. **Create**.

> **GCC High note:** cloud protection and signature updates flow to the **US Gov** service endpoints. If
> AV reports unhealthy or signatures stale, the usual cause is a proxy/firewall not allowing the
> **Gov/GCC/DoD** connectivity URLs (see `06-troubleshooting.md`).

### Step 7 — Create `Firewall – Clinical Endpoints – Baseline`

1. **Intune admin center** > **Endpoint security** > **Firewall** > **+ Create policy**.
2. **Platform** = *Windows 10, Windows 11, and Windows Server*; **Profile** = *Microsoft Defender
   Firewall*. **Create**.
3. **Basics:** Name = **`Firewall – Clinical Endpoints – Baseline`**; Description = "Enforces Windows
   Defender Firewall on all profiles (HIPAA network safeguard)."
4. **Configuration settings:** for **Domain**, **Private**, and **Public** profiles set *Enable Firewall*
   = **True**; *Inbound connections blocked* = **True** (default); *Outbound connections required* =
   **Allowed**.
5. **Assignments:** add **`HIPAA – Clinical Endpoints`**. **Create**.

### Step 8 — Create `Patch – Clinical Endpoints – Baseline` (Update ring) and `Access – Clinical Endpoints – Baseline`

1. **Patch (Update ring — the GCC-High-correct patch mechanism):** **Devices** > **Windows** > **Update
   rings for Windows 10 and later** > **+ Create profile**. Name = **`Patch – Clinical Endpoints –
   Baseline`**; set sensible quality/feature deferral and deadlines; **Assign** to **`HIPAA – Clinical
   Endpoints`**. **Create.**
   > **GCC High caveat:** do **not** try to use the newer **Feature updates / Quality updates / Expedite
   > updates / Driver updates** *policies* or **Autopatch** — they are **planned but not yet available**
   > on GCC High, and *feature-update reports* are absent. **Update rings work** and are what this
   > solution uses. *Verify current Gov availability before relying on any update policy.* Cited:
   > Microsoft — Intune Government Service overview.
2. **Access:** **Devices** > **Configuration** > **+ Create** > **New policy** > *Windows 10 and later* >
   *Settings catalog*. Name = **`Access – Clinical Endpoints – Baseline`**; Description = "Enforces
   account/sign-in controls (HIPAA access control / unique user ID)." Add: *Limit Local Account Use Of
   Blank Passwords To Console Logon Only* = **Enabled**; *Account Lockout Threshold* = **10**; *Minimum
   Password Length* per policy; *Interactive logon: Do not display last signed-in* = **Enabled**;
   disable built-in Guest. **Assign** to `HIPAA – Clinical Endpoints`. **Create.**

> Optionally apply a Microsoft **Security baseline** (Endpoint security > Security baselines) to `HIPAA –
> Clinical Endpoints` for breadth, after reconciling conflicts with the targeted baselines above. Confirm
> the baseline you want is present on your GCC High tenant first — some baseline versions roll out to Gov
> later than Commercial (*verify for GCC High*).

---

## Phase 3 — Gate: Conditional Access on compliance (Gov Entra)

### Step 9 — Create the Conditional Access gate `Require Compliance – Clinical Endpoints – Gate`

1. **Microsoft Entra admin center** (`https://entra.microsoft.us`) > **Protection** > **Conditional
   Access** > **Policies** > **+ New policy**.
2. **Name:** **`Require Compliance – Clinical Endpoints – Gate`**.
3. **Users:** Include the gated population (clinical staff group); **Exclude** the break-glass account
   (R8) and any service accounts.
4. **Target resources:** *Cloud apps* > **All cloud apps** (or scope to the resources holding ePHI). Note
   the app catalog reflects your **GCC High** tenant's apps.
5. **Conditions:** *Device platforms* = **Windows**.
6. **Grant:** *Grant access* > check **Require device to be marked as compliant**; set **Require all the
   selected controls**.
7. **Enable policy:** set to **Report-only** first. Click **Create**.
8. After validating impact in report-only (see `05-testing.md`), edit the policy and set **Enable
   policy** = **On**.

> **Verify:** A non-compliant clinical Windows device is blocked from the target resource; a compliant
> one is allowed. Review **Entra** (`entra.microsoft.us`) > **Monitoring** > **Sign-in logs** >
> **Conditional Access** tab.

---

## Phase 4 — Remediate: Defender Vulnerability Management workflow (Gov Defender portal)

### Step 10 — Establish exposure baseline in Defender TVM

1. **Microsoft Defender portal** (`https://security.microsoft.us`) > **Vulnerability management** >
   **Dashboard**.
2. Record the current **Exposure score** and **Microsoft Secure Score for Devices** as the baseline
   (store in the evidence repository, R11).
   > **GCC High note:** **Secure Score is available but omits some recommendations** in Gov — so a figure
   > or recommendation you saw in Commercial may differ or be absent. Record what your Gov tenant shows;
   > do not expect Commercial-identical numbers. Cited: Microsoft — Feature parity note.
3. Filter by the device group corresponding to **`HIPAA – Clinical Endpoints`** (create/confirm a
   matching **device group** under **Settings** > **Endpoints** > **Device groups** if Defender RBAC
   device groups are used).

### Step 11 — Triage and drive `Vulnerability – Clinical Endpoints – Remediation`

1. **Vulnerability management** > **Recommendations**. Sort by impact/exposure for the clinical device
   group.
2. For each top recommendation, open it and review **Exposed devices** and **Remediation options**.
3. Click **Request remediation** to create a task titled with the prefix **`Vulnerability – Clinical
   Endpoints – Remediation`**; route it via the integrated **Intune** remediation request (the Intune ↔
   Defender connector works on GCC High) or as a tracked task; set a due date.
4. Track open tasks under **Vulnerability management** > **Remediation**. **Patch-type** recommendations
   are closed by the **Update ring** (`Patch – Clinical Endpoints – Baseline`); **configuration-type** by
   the matching baseline.

### Step 12 — Handle exceptions (GCC High specifics)

1. For a recommendation that cannot be remediated now (clinical/medical-device dependency, vendor
   constraint), open it > **Exception options** > **Create exception**; choose **justification** and
   **scope**, set an **expiry**.
2. Record the exception (justification, approver = R10, expiry) in the evidence repository per R12.
   > **GCC High caveat:** the Defender **Report inaccuracy** and **Request CVE support** functions are
   > **not available** in Gov. If a recommendation looks wrong, or a CVE you care about is not covered,
   > you **cannot** submit it from the portal — record the concern in your **own** change record (R12)
   > and follow up through your Microsoft support channel. Cited: Microsoft — DVM functionality not
   > available for GCC/GCC High/DoD.

---

## Phase 5 — Evidence / Report: produce audit-ready output (from US Gov Graph)

### Step 13 — Capture compliance and configuration evidence

1. **Intune admin center** (`https://intune.microsoft.us`) > **Devices** > **Compliance** > **`HIPAA
   Compliance – Clinical Endpoints – Policy`** > **Device status** / **Per-setting status** — export.
2. **Reports** > **Device compliance** — run **Device compliance** and **Noncompliant devices**; export
   to the evidence store (R11).
3. **Endpoint security** > **Disk encryption** — export BitLocker/encryption status as encryption proof.
4. Run **`HIPAACOMPG-Report.ps1`** (connects `-Environment USGov`) to generate a consolidated CSV
   (per-device compliance, key safeguard status, exposure context) — written to the Gov evidence
   repository.

### Step 14 — Capture vulnerability/remediation evidence

1. **Defender portal** (`https://security.microsoft.us`) > **Vulnerability management** > **Dashboard** —
   export exposure score and trend; **Recommendations** and **Remediation** — export open/closed task
   status and exceptions.
2. Compare current exposure to the Step 10 baseline to demonstrate reduction. Store all exports
   date-stamped in the evidence repository.

---

## Phase 6 — Operate: run the control set over time

### Step 15 — Operationalize the recurring loop

1. Schedule **`HIPAACOMPG-Validation.ps1`** (per-device PASS/FAIL) and **`HIPAACOMPG-Report.ps1`** on a
   cadence; deposit output in the Gov evidence store.
2. Review noncompliant devices and remediate (**`HIPAACOMPG-Remediation.ps1`** in default `-WhatIf`
   first, then `-WhatIf:$false -Confirm:$false` to apply).
3. Advance the *Minimum OS version* in the compliance policy as Windows builds progress (keeps the
   patch-currency bar current, paired with the Update ring).
4. Review TVM exceptions at expiry and reassess exposure each period; update the control mapping
   (Step 2) on any change, gated by change control (R12).
5. Re-run **`HIPAACOMPG-Discovery.ps1`** periodically to detect drift (policies present, Defender-for-Gov
   onboarding, CA gate, BitLocker state) — and to reconfirm you are still reaching the **US Gov** cloud.

> **Done means:** clinical endpoints evaluate Compliant against the enforced baselines on GCC High, the
> CA gate blocks non-compliant devices, TVM exposure trends down, and dated evidence is retained in the
> sovereign repository — all traceable through the control mapping to a named owner.
