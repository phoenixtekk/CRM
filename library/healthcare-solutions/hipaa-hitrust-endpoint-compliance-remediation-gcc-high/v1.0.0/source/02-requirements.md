# 2. Requirements — HIPAA & HITRUST Endpoint Compliance & Vulnerability Remediation (Intune + Defender) — Government (GCC High)

Each requirement follows the house pattern: **Description / Why / Verify / Implement-if-missing**. Never
assume a prerequisite is already in place — verify it, and provision it if it is not. **Every Verify
step uses the `.us` portals** and the **US Gov Graph** — a `.com` portal or a Graph session without
`-Environment USGov` will show the wrong (or an empty) tenant. See `gcc-high-parity-notes.md` for the
cited portal/endpoint/licensing tables.

---

## R1 — GCC High tenant and Intune (government cloud) MDM authority

- **Description:** An active **Microsoft 365 GCC High** tenant with **Microsoft Intune** (government
  cloud instance) set as the MDM authority.
- **Why:** Compliance policies and configuration baselines are Intune features. On GCC High the Intune
  service is the physically separate **government cloud** (IL4/IL5) — not the Commercial instance — so
  you must administer it from `intune.microsoft.us`. (Note: for *Intune*, "GCC" means Commercial;
  "GCC High"/"DoD" is the government cloud. Cited: Microsoft — Intune Government Service overview.)
- **Verify:** Sign in to the **Microsoft Intune admin center** at **`https://intune.microsoft.us`** >
  **Tenant administration** > **Tenant status** and confirm the tenant is active. Confirm the sign-in
  authority is `login.microsoftonline.us`.
- **Implement if missing:** Provision/activate the GCC High tenant and Intune government licensing;
  confirm operators can reach `intune.microsoft.us`.

## R2 — US Government licensing (Intune + Entra ID P1/P2 + Defender for Endpoint P2)

- **Description:** US-Gov SKUs that provide Intune, Entra ID P1 (Conditional Access), and Defender for
  Endpoint **Plan 2** (which includes **Defender Vulnerability Management core**) — e.g. **Microsoft
  365 E5 for GCC High** / **Microsoft 365 G5 Security for GCC High** / **Microsoft Defender for
  Endpoint for GCC High**. (**G3 includes Defender for Endpoint Plan 1** only.)
- **Why:** DVM (the remediation phase) and the machine-risk compliance signal require **Defender for
  Endpoint Plan 2**; the Conditional Access gate requires **Entra ID P1**. Commercial SKU names do not
  apply on GCC High — use the Gov SKUs.
- **Verify:** **Defender portal** (`https://security.microsoft.us`) > **Settings** > **Endpoints** >
  **Licenses**; and **Entra admin center** (`https://entra.microsoft.us`) > **Identity** >
  **Overview** > **Licenses**. Confirm an Intune-bearing SKU on a pilot user.
- **Implement if missing:** Acquire the matching **GCC High** SKUs (see the licensing table in
  `gcc-high-parity-notes.md`) and assign to operators and clinical endpoint users.

## R3 — Defender for Endpoint (GCC High) onboarding of clinical endpoints

- **Description:** Clinical Windows endpoints onboarded to **Defender for Endpoint for GCC High** so
  they report sensor data and TVM exposure, using the **US Gov** onboarding/telemetry endpoints.
- **Why:** A device that is not onboarded contributes no vulnerability data and cannot be remediated
  through TVM; it is invisible to the exposure score. On GCC High the device must reach the **Gov/GCC/DoD
  connectivity URLs**, not the Commercial MDE endpoints — the number-one cause of "onboarded but no
  data" is a device pointed at the Commercial cloud.
- **Verify:** **Defender portal** (`https://security.microsoft.us`) > **Assets** > **Devices** and
  confirm the clinical endpoints show **Onboarding status = Onboarded** and **Sensor health = Active**.
- **Implement if missing:** In **Intune admin center** (`https://intune.microsoft.us`) > **Endpoint
  security** > **Microsoft Defender for Endpoint**, confirm the connector shows **Connected** and turn
  on **Allow Microsoft Defender for Endpoint to enforce Endpoint Security Configurations**; deploy the
  onboarding (EDR) policy to **`HIPAA – Clinical Endpoints`** (R5). Allow the **Gov/GCC/DoD** URL lists
  through proxies/firewalls (use the **streamlined** list where supported — *Preview, verify for GCC
  High*). For downlevel/MMA devices choose **Azure US Government** (or set
  `OPINSIGHTS_WORKSPACE_AZURE_CLOUD_TYPE=1`) and deploy the required KB **before** onboarding. Cited:
  Microsoft — Required connectivity settings (Gov/GCC/DoD).

## R4 — Administrative roles with least privilege (in the Gov portals)

- **Description:** Operators hold scoped roles — **Intune Administrator**, **Security Administrator**,
  **Conditional Access Administrator** — assigned in `entra.microsoft.us`, rather than Global
  Administrator for day-to-day work.
- **Why:** HIPAA and HITRUST expect least-privilege access and separation of duties; over-privileged
  admin accounts are a top audit finding and breach vector. Roles must be assigned in the **Gov** Entra
  portal to take effect on the Gov tenant.
- **Verify:** **Entra admin center** (`https://entra.microsoft.us`) > **Roles & admins** — review
  assignments; confirm Global Administrator is limited and, where Entra ID P2 is available, PIM-eligible.
- **Implement if missing:** Assign scoped roles; make privileged roles **eligible** via Privileged
  Identity Management with approval and time limits where licensed.

## R5 — The clinical endpoint group `HIPAA – Clinical Endpoints`

- **Description:** A Microsoft Entra security group named **`HIPAA – Clinical Endpoints`** (created in
  `entra.microsoft.us`) containing every Windows device in scope for HIPAA/HITRUST endpoint enforcement
  (dynamic membership preferred).
- **Why:** Every policy, baseline, onboarding profile, and the Conditional Access gate target this
  single named group. A consistent, accurate scope is the difference between "all clinical devices are
  enforced" and a silent gap. Use one group, named verbatim, so assignment is unambiguous and auditable.
- **Verify:** **Entra admin center** (`https://entra.microsoft.us`) > **Groups** > search **`HIPAA –
  Clinical Endpoints`**; confirm it exists, its membership rule, and expected members.
- **Implement if missing:** **Entra admin center** > **Groups** > **New group** > Type **Security**,
  Name **`HIPAA – Clinical Endpoints`**. For dynamic device membership use a rule such as
  `(device.deviceOSType -eq "Windows") and (device.deviceCategory -eq "Clinical")` (or a
  naming-convention rule matching your asset standard). The included **`HIPAACOMPG-Set-ScopeTargeting.ps1`**
  can create this group on the Gov tenant. Document the rule with the control owner (R10).

## R6 — BitLocker-capable devices (TPM) + Intune disk-encryption policy availability

- **Description:** Clinical endpoints with a TPM (1.2/2.0) and UEFI firmware capable of BitLocker
  full-disk encryption, managed by the Intune **Disk encryption (BitLocker)** endpoint-security policy —
  a standard MDM feature available in GCC High.
- **Why:** Encryption-at-rest is the single most leveraged HIPAA technical safeguard for lost/stolen
  devices (the practical basis for the breach-notification safe harbor). If hardware cannot do
  BitLocker, the encryption control cannot be enforced.
- **Verify:** On a sample device run `manage-bde -status` (usable TPM + encryptable volume), or check
  **Intune admin center** (`https://intune.microsoft.us`) > **Devices** > (device) > **Hardware** for
  TPM presence; review **Endpoint security** > **Disk encryption** reporting.
- **Implement if missing:** Enable/clear the TPM and enable UEFI Secure Boot in firmware; replace
  hardware that lacks a TPM. Deploy the BitLocker policy (implementation Step 4).

## R7 — Patch / update currency via **Update rings** (not update *policies* on GCC High)

- **Description:** A managed update mechanism keeping clinical endpoints on a supported, current build —
  delivered by an **Update ring for Windows 10 and later** (Windows Update for Business rings) assigned
  to `HIPAA – Clinical Endpoints`.
- **Why:** The compliance policy measures **Minimum OS version** (patch currency); without a managed
  update flow, devices drift out of compliance and accumulate TVM vulnerabilities. **GCC High caveat:**
  the newer Intune **Windows Update policies** — *feature, quality, expedite, driver updates,
  Autopatch, Delivery Optimization* — are **planned but not yet available** in GCC High, and the
  *feature-update reports* are absent. **Update rings are a standard MDM feature and do work in GCC
  High** — use them. *Verify current Gov availability of any update policy before relying on it.* Cited:
  Microsoft — Intune Government Service overview.
- **Verify:** **Intune admin center** (`https://intune.microsoft.us`) > **Devices** > **Windows** >
  **Update rings for Windows 10 and later** and confirm a ring targets `HIPAA – Clinical Endpoints`.
- **Implement if missing:** Create an **Update ring** named **`Patch – Clinical Endpoints – Baseline`**
  with appropriate deferral/deadline settings; verify devices report a current build. Advance the
  compliance policy **Minimum OS version** on a schedule (R7 ↔ Best Practices).

## R8 — Conditional Access readiness (break-glass + report-only) in Gov Entra

- **Description:** A break-glass (emergency access) account excluded from all Conditional Access, and
  the ability to deploy the gate in **Report-only** first — all configured in `entra.microsoft.us`.
- **Why:** A compliance gate that blocks non-compliant devices can lock out administrators if
  misconfigured. A break-glass account and a report-only rollout prevent a self-inflicted outage.
- **Verify:** **Entra admin center** (`https://entra.microsoft.us`) > **Protection** > **Conditional
  Access** — confirm a cloud-only break-glass account exists and is excluded; confirm report-only mode
  is available.
- **Implement if missing:** Create a cloud-only emergency access account with a long, stored
  credential, exclude it from all CA policies, and monitor its sign-ins. Roll the gate out in
  **Report-only** before **On**.

## R9 — Control mapping document and evidence ownership

- **Description:** A maintained mapping tying each in-scope HIPAA Security Rule safeguard and HITRUST CSF
  control to the named Intune/Defender object that enforces it, the evidence source, and the owner.
- **Why:** Assessors do not accept "Intune is configured" — they trace a specific control to a specific
  enforcement and an accountable owner. The mapping is the spine of the audit narrative and is
  referenced by every later phase.
- **Verify:** Confirm a current mapping artifact exists (the implementation produces the structure) and
  that each row names a safeguard, an enforcing object, an evidence source, and an owner.
- **Implement if missing:** Build the mapping in the Assess phase; store it in the evidence repository
  (R11) and review it at each change (R12).

## R10 — Named control owner / accountable role

- **Description:** A designated owner (security/compliance lead) accountable for the endpoint control
  set, exceptions, and evidence.
- **Why:** HIPAA requires assigned security responsibility; HITRUST control maturity is graded partly on
  defined accountability. Unowned controls drift and exceptions accumulate silently.
- **Verify:** Confirm the owner is named in the control mapping (R9) and that exception approvals route
  to that role.
- **Implement if missing:** Assign the role formally, record it in the mapping, and route the exception
  and change processes (R12) through it.

## R11 — Evidence store / repository (sovereign)

- **Description:** A defined, access-controlled location — on the **GCC High** tenant (e.g. a restricted
  SharePoint/document library in `portal.office365.us` or a secured share) — to retain generated
  evidence for the required retention period.
- **Why:** Evidence that is not retained cannot be produced for an audit covering a past period. HIPAA
  documentation retention is six years; HITRUST assessments review a defined look-back window. On a
  sovereign tenant, keep the evidence store **inside the Gov boundary**.
- **Verify:** Confirm a repository exists with access limited to the owner and assessors and a retention
  setting applied.
- **Implement if missing:** Provision a restricted repository within the GCC High tenant, apply
  retention, and point the reporting script output (**`HIPAACOMPG-Report.ps1`**) at it.

## R12 — Change control and exception process

- **Description:** A lightweight change-control and exception process for the compliance baseline, the
  CA gate, and TVM remediation deferrals.
- **Why:** Auditors expect that control changes and risk-accepted exceptions are reviewed, approved by
  the owner, time-bound, and documented — not made ad hoc. **GCC High note:** the Defender **Report
  inaccuracy** and **Request CVE support** functions are **not available** in Gov, so record any
  recommendation-accuracy concern or CVE-coverage gap **in your own change record**, not via the portal.
- **Verify:** Confirm a process exists for proposing/approving changes to the named objects and for
  recording TVM exceptions with justification, approver, and expiry.
- **Implement if missing:** Adopt a simple approval workflow gated by the owner (R10); record exceptions
  in Defender TVM with a documented justification and review date, mirrored in the evidence store.

---

> See **`source/global-requirements-healthcare-solutions.md`** for category-wide requirements common to
> all Healthcare Solutions (tenant, roles, network, data-handling) — apply them using the **`.us`**
> portals on a GCC High tenant. See **`gcc-high-parity-notes.md`** for the cited portal/endpoint/
> licensing/parity tables. The requirements above are specific to this solution.
