# 3. Implementation — HIPAA & HITRUST Endpoint Compliance & Vulnerability Remediation (Intune + Defender)

This implementation follows the phase model **Assess → Configure → Gate → Remediate → Evidence/Report → Operate**. Every object is **named verbatim** using the `<Purpose> – <Scope> – <Stage>` convention and reused across phases, scripts, and evidence. Reuse the exact names. Full navigation paths are given for every step; never assume a prerequisite — if a referenced object does not exist, build it per `02-requirements.md` first.

> **Reminder:** This builds the technical enforcement and evidence layer. It does not constitute HIPAA compliance or HITRUST certification on its own.

---

## Phase 1 — Assess: map controls to enforceable settings

### Step 1 — Confirm the scope group exists

1. Open the **Microsoft Entra admin center** (`https://entra.microsoft.com`) > **Identity** > **Groups** > **All groups**.
2. Search for **`HIPAA – Clinical Endpoints`**. Confirm it exists, is a **Security** group, and its (preferably dynamic) device membership rule resolves the in-scope clinical Windows endpoints.
3. If it does not exist, create it per `02-requirements.md` R5 before proceeding. Every object below targets this group.

### Step 2 — Build the control-to-policy mapping

Create the mapping artifact that ties each in-scope safeguard to the object that will enforce it, the evidence source, and the owner. Store it in the evidence repository (R11). Use this structure (the named objects are created in later phases):

| HIPAA Security Rule safeguard | HITRUST CSF area | Enforcing object (named) | Evidence source | Owner |
|---|---|---|---|---|
| Encryption & decryption — §164.312(a)(2)(iv) | 06 Configuration / 19 Data Protection | `Encryption – Clinical Endpoints – Baseline` (BitLocker) | Intune disk-encryption report; `HIPAACOMP-Report.ps1` | (R10) |
| Automatic logoff — §164.312(a)(2)(iii) | 01 Access Control | `Lock – Clinical Endpoints – Baseline` (inactivity lock/timeout) | Compliance + config report | (R10) |
| Protection from malicious software — §164.308(a)(5)(ii)(B) | 09 Endpoint Protection | `Antivirus – Clinical Endpoints – Baseline` (Defender AV) | Defender AV health; compliance report | (R10) |
| Integrity / network safeguards — §164.312(c)(1) | 09 Network Protection | `Firewall – Clinical Endpoints – Baseline` (Windows Firewall) | Config report | (R10) |
| Security updates / patch — §164.308(a)(1)(ii)(B) | 10 Vulnerability Mgmt | `Patch – Clinical Endpoints – Baseline` (min OS build) + Update ring | Compliance report; Defender TVM | (R10) |
| Access control / unique user ID — §164.312(a)(2)(i) | 01 Access Control | `Access – Clinical Endpoints – Baseline` (account/sign-in controls) | Config report | (R10) |
| Vulnerability exposure management | 10 Vulnerability Mgmt | Defender TVM + `Vulnerability – Clinical Endpoints – Remediation` | Defender exposure score; `HIPAACOMP-Report.ps1` | (R10) |
| Access enforcement at sign-in | 01 Access Control | `Require Compliance – Clinical Endpoints – Gate` (Conditional Access) | CA sign-in logs | (R10) |

> The mapping is the audit spine. Each later step names the object referenced in this table; keep the table current as objects are created and renamed.

---

## Phase 2 — Configure: compliance policy and configuration baselines

The **compliance policy measures** the safeguards; the **configuration baselines enforce** them. Build both.

### Step 3 — Create the compliance policy `HIPAA Compliance – Clinical Endpoints – Policy`

1. Open the **Microsoft Intune admin center** (`https://intune.microsoft.com`) > **Devices** > **Compliance** > **Compliance policies** > **+ Create policy**.
2. **Platform:** *Windows 10 and later*. Click **Create**.
3. **Basics:** Name = **`HIPAA Compliance – Clinical Endpoints – Policy`**; Description = "Measures HIPAA/HITRUST endpoint safeguards: BitLocker, lock, Defender AV, firewall, patch currency, sign-in. Targets HIPAA – Clinical Endpoints." Click **Next**.
4. **Compliance settings** — expand each section and set:
   - **Device Health:** *Require BitLocker* = **Require**; *Require Secure Boot to be enabled* = **Require**; *Require code integrity* = **Require**.
   - **Device Properties:** *Minimum OS version* = your current supported Windows build (drives patch currency; update this value as builds advance — see R7).
   - **System Security:**
     - *Require a password to unlock mobile devices* = **Require**; *Maximum minutes of inactivity before password is required* = **15** (automatic logoff / screen lock).
     - *Encryption of data storage on device* = **Require**.
     - *Firewall* = **Require**.
     - *Antivirus* = **Require**; *Antispyware* = **Require**.
     - *Microsoft Defender Antimalware* = **Require**; *Defender Antimalware minimum version* = (a recent platform version); *Real-time protection* = **Require**.
     - *Microsoft Defender Antimalware security intelligence up-to-date* = **Require** (signatures current).
   - **Microsoft Defender for Endpoint:** *Require the device to be at or under the machine risk score* = **Medium** (gates on Defender's device risk; requires the Defender connector, R4).
5. **Actions for noncompliance:** keep *Mark device noncompliant* = **Immediately**; add *Send email to end user* (a customized notification) and *Remotely lock the noncompliant device* if appropriate. Click **Next**.
6. **Scope tags:** apply your scope tag if used. Click **Next**.
7. **Assignments:** **Included groups** > add **`HIPAA – Clinical Endpoints`**. Click **Next** > **Create**.

> **Verify:** **Devices** > **Compliance** > open the policy > **Device status** — devices should begin reporting within an evaluation cycle.

### Step 4 — Create the configuration baseline `Encryption – Clinical Endpoints – Baseline` (BitLocker)

1. **Intune admin center** > **Endpoint security** > **Disk encryption** > **+ Create policy**.
2. **Platform** = *Windows 10 and later*; **Profile** = *BitLocker*. Click **Create**.
3. **Basics:** Name = **`Encryption – Clinical Endpoints – Baseline`**; Description = "Enforces BitLocker silent encryption for clinical endpoints (HIPAA encryption safeguard)."
4. **Configuration settings:**
   - *Enable full disk encryption for OS and fixed data drives* = **Yes**.
   - *Require storage cards to be encrypted (mobile only)* as applicable.
   - **BitLocker – Base Settings:** *Enable storage card encryption* / *Warning for other disk encryption* = **No**; *Allow standard users to enable encryption during Autopilot* = **Yes**; *Configure client-driven recovery password rotation* = **Enabled for Azure AD-joined devices**.
   - **BitLocker – OS Drive Settings:** *Startup authentication required* = **Yes**; *Compatible TPM startup* = **Required**; *Recovery options* > *Save BitLocker recovery information to Azure AD* = **Yes**; *Store recovery information before enabling* = **Yes**.
5. **Assignments:** add **`HIPAA – Clinical Endpoints`**. **Create**.

> **Verify:** **Endpoint security** > **Disk encryption** > the policy > device/encryption status; and **Devices** > (device) > **Recovery keys** shows escrowed keys.

### Step 5 — Create the configuration baseline `Lock – Clinical Endpoints – Baseline` (automatic logoff)

1. **Intune admin center** > **Devices** > **Configuration** > **+ Create** > **New policy**.
2. **Platform** = *Windows 10 and later*; **Profile type** = *Settings catalog*. Click **Create**.
3. **Basics:** Name = **`Lock – Clinical Endpoints – Baseline`**; Description = "Enforces automatic screen lock / inactivity timeout (HIPAA automatic logoff)."
4. **Configuration settings** > **+ Add settings** > search **Device Lock** and add:
   - *Maximum Inactivity Time Lock Screen* = **15** (minutes).
   - *Allow Screen Timeout While Locked User Config* and machine inactivity limit (Local Policies Security Options > *Interactive logon: Machine inactivity limit*) = **900** seconds.
   - *Require password when device returns from idle* = **Enabled**.
5. **Assignments:** add **`HIPAA – Clinical Endpoints`**. **Create**.

### Step 6 — Create the configuration baseline `Antivirus – Clinical Endpoints – Baseline` (Defender AV)

1. **Intune admin center** > **Endpoint security** > **Antivirus** > **+ Create policy**.
2. **Platform** = *Windows 10, Windows 11, and Windows Server*; **Profile** = *Microsoft Defender Antivirus*. **Create**.
3. **Basics:** Name = **`Antivirus – Clinical Endpoints – Baseline`**; Description = "Enforces Microsoft Defender Antivirus real-time protection, cloud protection, and signature currency (HIPAA malware protection)."
4. **Configuration settings:** *Allow Realtime Monitoring* = **Allowed**; *Allow Cloud Protection* = **Allowed**; *Cloud Block Level* = **High**; *Allow Behavior Monitoring* = **Allowed**; *Submit Samples Consent* = **Send safe samples automatically**; *Signature Update Interval* = **4** (hours); *Allow Scanning Network Files* = **Allowed**; *Schedule a scan* (quick daily).
5. **Assignments:** add **`HIPAA – Clinical Endpoints`**. **Create**.

### Step 7 — Create the configuration baseline `Firewall – Clinical Endpoints – Baseline`

1. **Intune admin center** > **Endpoint security** > **Firewall** > **+ Create policy**.
2. **Platform** = *Windows 10, Windows 11, and Windows Server*; **Profile** = *Microsoft Defender Firewall*. **Create**.
3. **Basics:** Name = **`Firewall – Clinical Endpoints – Baseline`**; Description = "Enforces Windows Defender Firewall on all profiles (HIPAA network safeguard)."
4. **Configuration settings:** for **Domain**, **Private**, and **Public** profiles set *Enable Firewall* = **True**; *Inbound connections blocked* = **True** (default); *Outbound connections required* = **Allowed**; *Notify on inbound block* as desired.
5. **Assignments:** add **`HIPAA – Clinical Endpoints`**. **Create**.

### Step 8 — Create the configuration baselines `Patch – Clinical Endpoints – Baseline` and `Access – Clinical Endpoints – Baseline`

1. **Patch:** Confirm an **Update ring for Windows 10 and later** (R7) targets **`HIPAA – Clinical Endpoints`** with sensible quality/feature deferral and deadlines, named **`Patch – Clinical Endpoints – Baseline`** (rename the ring to match). Path: **Devices** > **Windows** > **Update rings for Windows 10 and later**.
2. **Access:** **Devices** > **Configuration** > **+ Create** > **New policy** > *Windows 10 and later* > *Settings catalog*. Name = **`Access – Clinical Endpoints – Baseline`**; Description = "Enforces account/sign-in controls (HIPAA access control / unique user ID)." Add settings: *Limit Local Account Use Of Blank Passwords To Console Logon Only* = **Enabled**; *Account Lockout Threshold* = **10**; *Minimum Password Length* per policy; *Interactive logon: Do not display last signed-in* = **Enabled**; disable built-in Guest. **Assign** to `HIPAA – Clinical Endpoints`. **Create**.

> Optionally apply a Microsoft **Security baseline** (Endpoint security > Security baselines > *Security Baseline for Windows*) to `HIPAA – Clinical Endpoints` for breadth, after reconciling any conflicts with the targeted baselines above.

---

## Phase 3 — Gate: Conditional Access on compliance

### Step 9 — Create the Conditional Access gate `Require Compliance – Clinical Endpoints – Gate`

1. Open the **Microsoft Entra admin center** > **Protection** > **Conditional Access** > **Policies** > **+ New policy**.
2. **Name:** **`Require Compliance – Clinical Endpoints – Gate`**.
3. **Users:** Include the gated population (e.g. clinical staff group); **Exclude** the break-glass account (R8) and any service accounts.
4. **Target resources:** *Cloud apps* > **All cloud apps** (or scope to the resources holding ePHI, e.g. SharePoint/Exchange/EHR SAML app).
5. **Conditions:** *Device platforms* = **Windows** (to scope to clinical Windows endpoints; pair with device filters if needed).
6. **Grant:** *Grant access* > check **Require device to be marked as compliant** (and, if desired, **Require Microsoft Entra hybrid joined device**). Set **Require all the selected controls**.
7. **Enable policy:** set to **Report-only** first. Click **Create**.
8. After validating impact in report-only (see `05-testing.md`), edit the policy and set **Enable policy** = **On**.

> **Verify:** A non-compliant clinical Windows device is blocked from the target resource; a compliant one is allowed. Review **Entra** > **Monitoring** > **Sign-in logs** > **Conditional Access** tab.

---

## Phase 4 — Remediate: Defender Vulnerability Management workflow

### Step 10 — Establish exposure baseline in Defender TVM

1. Open the **Microsoft Defender portal** (`https://security.microsoft.com`) > **Vulnerability management** > **Dashboard**.
2. Record the current **Exposure score** and **Microsoft Secure Score for Devices** as the baseline (store in the evidence repository, R11).
3. Filter the dashboard by the device group corresponding to **`HIPAA – Clinical Endpoints`** (create/confirm a matching **device group** under **Settings** > **Endpoints** > **Device groups** if Defender RBAC device groups are used).

### Step 11 — Triage and drive `Vulnerability – Clinical Endpoints – Remediation`

1. **Vulnerability management** > **Recommendations**. Sort by impact/exposure for the clinical device group.
2. For each top recommendation (e.g. update an out-of-date application, enable a hardening setting), open it and review **Exposed devices** and **Remediation options**.
3. Click **Request remediation** to create a remediation task named **`Vulnerability – Clinical Endpoints – Remediation`** (use this name as the task title prefix). Assign it to the owner (R10) / IT team via the integrated **Microsoft Intune** remediation request (if connected) or as a tracked task; set a due date.
4. Track open tasks under **Vulnerability management** > **Remediation**. Patch-type recommendations are closed by the Update ring (`Patch – Clinical Endpoints – Baseline`); configuration-type recommendations are closed by the corresponding baseline.

### Step 12 — Handle exceptions

1. For a recommendation that cannot be remediated now (clinical/medical-device dependency, vendor constraint), open it > **Exception options** > **Create exception**.
2. Choose **justification** (e.g. *Third-party control*, *Risk accepted*, *Planned remediation*) and **scope** (device group or global), and set an **expiry**.
3. Record the exception (justification, approver = R10, expiry) in the evidence repository per the change/exception process (R12). Review exceptions at expiry.

---

## Phase 5 — Evidence / Report: produce audit-ready output

### Step 13 — Capture compliance and configuration evidence

1. **Intune admin center** > **Devices** > **Compliance** > **`HIPAA Compliance – Clinical Endpoints – Policy`** > **Device status** / **Per-setting status** — export.
2. **Reports** > **Device compliance** > run **Device compliance** and **Noncompliant devices** reports; export to the evidence store (R11).
3. **Endpoint security** > **Disk encryption** — export BitLocker/encryption status as encryption proof.
4. Run **`HIPAACOMP-Report.ps1`** (Microsoft Graph) to generate a consolidated CSV: per-device compliance state, key safeguard status, and Defender TVM exposure — written to the evidence repository.

### Step 14 — Capture vulnerability/remediation evidence

1. **Defender portal** > **Vulnerability management** > **Dashboard** — export exposure score and trend; **Recommendations** and **Remediation** — export open/closed task status and exceptions.
2. Compare current exposure to the Step 10 baseline to demonstrate reduction over the period. Store all exports with date stamps in the evidence repository.

---

## Phase 6 — Operate: run the control set over time

### Step 15 — Operationalize the recurring loop

1. Schedule **`HIPAACOMP-Validation.ps1`** (per-device PASS/FAIL) and **`HIPAACOMP-Report.ps1`** on a recurring cadence; deposit output in the evidence store.
2. Review noncompliant devices and remediate (re-evaluate via **`HIPAACOMP-Remediation.ps1`** in `-WhatIf` first, then `-Apply` for a named device).
3. Advance the *Minimum OS version* in the compliance policy as Windows builds progress (keeps the patch-currency bar current).
4. Review TVM exceptions at expiry and reassess exposure each period; update the control mapping (Step 2) on any change, gated by change control (R12).
5. Re-run **`HIPAACOMP-Discovery.ps1`** periodically to detect drift in tenant readiness (policies present, Defender onboarding, CA gate, BitLocker state).

> **Done means:** clinical endpoints evaluate Compliant against the enforced baselines, the CA gate blocks non-compliant devices, TVM exposure trends down, and dated evidence is retained in the repository — all traceable through the control mapping to a named owner.
