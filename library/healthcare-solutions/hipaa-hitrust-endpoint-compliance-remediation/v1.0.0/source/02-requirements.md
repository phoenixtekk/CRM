# 2. Requirements — HIPAA & HITRUST Endpoint Compliance & Vulnerability Remediation (Intune + Defender)

Each requirement follows the house pattern: **Description / Why / Verify / Implement-if-missing**. Never assume a prerequisite is already in place — verify it, and provision it if it is not.

---

## R1 — Microsoft Intune licensing and MDM authority

- **Description:** A Microsoft Intune plan (Intune Plan 1, included in Microsoft 365 E3/E5, Business Premium, or equivalent) with Intune set as the MDM authority.
- **Why:** Device compliance policies and configuration baselines are Intune features; without an Intune license assigned to the operators and enrolling users, no policy can be authored or applied.
- **Verify:** Sign in to the **Microsoft Intune admin center** (`https://intune.microsoft.com`) > **Tenant administration** > **Tenant status** and confirm the tenant is active. Check **Users** > (a pilot user) > **Licenses** for an Intune-bearing SKU.
- **Implement if missing:** Acquire Intune licensing (or a bundle that includes it) in the **Microsoft 365 admin center** > **Billing** > **Purchase services**, then assign licenses to operators and to the clinical endpoint users.

## R2 — Microsoft Entra ID P1 (for Conditional Access)

- **Description:** Microsoft Entra ID P1 (or P2 / a bundle that includes it) for every user whose access will be gated.
- **Why:** The compliance gate in this solution is a **Conditional Access** policy, which requires Entra ID P1. Without it, you can measure compliance but cannot *enforce* it at sign-in.
- **Verify:** **Microsoft Entra admin center** (`https://entra.microsoft.com`) > **Identity** > **Overview** > **Licenses**; and confirm Conditional Access is available under **Protection** > **Conditional Access**.
- **Implement if missing:** Acquire Entra ID P1 (or M365 E3/E5/Business Premium, which include it) and assign it to the gated population.

## R3 — Microsoft Defender for Endpoint + Defender Vulnerability Management

- **Description:** Microsoft Defender for Endpoint (Plan 2, e.g. via M365 E5 / E5 Security) which includes **Defender Vulnerability Management (TVM)** core capabilities; or the **Defender Vulnerability Management add-on** for premium capabilities.
- **Why:** The remediation phase relies on Defender TVM exposure scoring, security recommendations, and the remediation/exception workflow. These are not available without Defender for Endpoint onboarding and entitlement.
- **Verify:** **Microsoft Defender portal** (`https://security.microsoft.com`) > **Settings** > **Endpoints** > **Licenses**; and confirm **Vulnerability management** appears in the left navigation.
- **Implement if missing:** Acquire Defender for Endpoint P2 (or E5 Security) and, if premium TVM features are needed, the **Defender Vulnerability Management** add-on.

## R4 — Defender for Endpoint onboarding of clinical endpoints

- **Description:** Clinical Windows endpoints onboarded to Defender for Endpoint so they report sensor data and TVM exposure.
- **Why:** A device that is not onboarded contributes no vulnerability data and cannot be remediated through TVM; it is invisible to the exposure score.
- **Verify:** **Defender portal** > **Assets** > **Devices** and confirm the clinical endpoints are listed with **Onboarding status = Onboarded** and **Sensor health = Active**.
- **Implement if missing:** In **Intune admin center** > **Endpoint security** > **Microsoft Defender for Endpoint**, enable the connector and turn on **Allow Microsoft Defender for Endpoint to enforce Endpoint Security Configurations**; deploy the onboarding configuration to the clinical endpoint group (R5).

## R5 — The clinical endpoint group `HIPAA – Clinical Endpoints`

- **Description:** A Microsoft Entra security group named **`HIPAA – Clinical Endpoints`** containing every Windows device in scope for HIPAA/HITRUST endpoint enforcement (dynamic membership preferred).
- **Why:** Every policy, baseline, onboarding profile, and the Conditional Access gate target this single named group. A consistent, accurate scope is the difference between "all clinical devices are enforced" and a silent gap. Use one group, named verbatim, so assignment is unambiguous and auditable.
- **Verify:** **Entra admin center** > **Groups** > search **`HIPAA – Clinical Endpoints`**; confirm it exists, its membership rule, and that expected devices are members.
- **Implement if missing:** **Entra admin center** > **Groups** > **New group** > Type **Security**, Name **`HIPAA – Clinical Endpoints`**. For dynamic device membership use a rule such as `(device.deviceOSType -eq "Windows") and (device.deviceCategory -eq "Clinical")` (or a naming-convention rule that matches your asset standard). Document the rule with the control owner (R10).

## R6 — BitLocker-capable devices (TPM)

- **Description:** Clinical endpoints with a TPM (1.2/2.0) and UEFI firmware capable of BitLocker full-disk encryption.
- **Why:** Encryption-at-rest is the single most leveraged HIPAA technical safeguard for lost/stolen devices (it is an addressable specification and the practical basis for the breach-notification safe harbor). If hardware cannot do BitLocker, the encryption control cannot be enforced.
- **Verify:** On a sample device run `manage-bde -status` (look for a usable TPM and encryptable volume), or check **Intune admin center** > **Devices** > (device) > **Hardware** for TPM presence; review **Endpoint security** > **Disk encryption** reporting.
- **Implement if missing:** Enable/clear the TPM and enable UEFI Secure Boot in firmware; replace hardware that lacks a TPM. Then deploy the BitLocker configuration in the configuration baseline (see implementation).

## R7 — Patch / update currency mechanism

- **Description:** A managed update mechanism — **Windows Update for Business** rings (Intune) or equivalent — keeping clinical endpoints on a supported, current build.
- **Why:** The compliance policy measures minimum OS build / patch currency; without a managed update flow, devices drift out of compliance and accumulate TVM vulnerabilities that cannot be closed by patching.
- **Verify:** **Intune admin center** > **Devices** > **Windows** > **Update rings for Windows 10 and later** (or **Feature/Quality update policies**) and confirm a ring targets `HIPAA – Clinical Endpoints`.
- **Implement if missing:** Create an **Update ring** assigned to `HIPAA – Clinical Endpoints` with appropriate deferral/deadline settings, and verify devices report a current build.

## R8 — Conditional Access readiness (break-glass + report-only)

- **Description:** A break-glass (emergency access) account excluded from all Conditional Access, and the ability to deploy a policy in **Report-only** mode first.
- **Why:** A compliance gate that blocks non-compliant devices can lock out administrators if misconfigured. A break-glass account and a report-only rollout prevent a self-inflicted outage and let you measure impact before enforcing.
- **Verify:** **Entra admin center** > **Protection** > **Conditional Access** — confirm a cloud-only break-glass account exists and is excluded from policies; confirm report-only mode is available.
- **Implement if missing:** Create a cloud-only emergency access account with a long, stored credential, exclude it from all CA policies, and monitor its sign-ins. Plan to roll the gate out in **Report-only** before **On**.

## R9 — Control mapping document and evidence ownership

- **Description:** A maintained mapping that ties each in-scope HIPAA Security Rule safeguard and HITRUST CSF control to the named Intune/Defender object that enforces it and the named owner accountable for it.
- **Why:** Assessors do not accept "Intune is configured" — they trace a specific control to a specific enforcement and an accountable owner. The mapping is the spine of the audit narrative and is referenced by every later phase.
- **Verify:** Confirm a current mapping artifact exists (the implementation produces the structure) and that each row names a safeguard, an enforcing object, an evidence source, and an owner.
- **Implement if missing:** Build the mapping in the Assess phase of the implementation; store it in the evidence repository (R11) and review it at each change (R12).

## R10 — Named control owner / accountable role

- **Description:** A designated owner (security/compliance lead) accountable for the endpoint control set, exceptions, and evidence.
- **Why:** HIPAA requires assigned security responsibility; HITRUST control maturity is graded partly on defined accountability. Unowned controls drift and exceptions accumulate silently.
- **Verify:** Confirm the owner is named in the control mapping (R9) and that exception approvals route to that role.
- **Implement if missing:** Assign the role formally, record it in the mapping, and route the exception and change processes (R12) through it.

## R11 — Evidence store / repository

- **Description:** A defined, access-controlled location to retain generated evidence (compliance exports, configuration proof, TVM exposure/remediation reports) for the required retention period.
- **Why:** Evidence that is not retained cannot be produced for an audit covering a past period. HIPAA documentation retention is six years; HITRUST assessments review a defined look-back window.
- **Verify:** Confirm a repository exists (e.g. a restricted SharePoint/document library or secured file share) with access limited to the owner and assessors, and a retention setting applied.
- **Implement if missing:** Provision a restricted repository, apply retention, and point the reporting script output (`HIPAACOMP-Report.ps1`) at it.

## R12 — Change control and exception process

- **Description:** A lightweight change-control and exception process for the compliance baseline, the CA gate, and TVM remediation deferrals.
- **Why:** Auditors expect that control changes and risk-accepted exceptions are reviewed, approved by the owner, time-bound, and documented — not made ad hoc.
- **Verify:** Confirm a process exists for proposing/approving changes to the named objects and for recording TVM exceptions with justification, approver, and expiry.
- **Implement if missing:** Adopt a simple approval workflow (ticket or change record) gated by the owner (R10); record exceptions in Defender TVM with a documented business justification and review date, mirrored in the evidence store.

---

> See **`source/global-requirements-healthcare-solutions.md`** for category-wide requirements common to all Healthcare Solutions (tenant, roles, network, data-handling). The requirements above are specific to this solution.
