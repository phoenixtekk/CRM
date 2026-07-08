# 2. Requirements Guide — Custom DLP Policy Development (Microsoft Purview)

Verify **every** requirement before authoring a policy. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` (the six shared
requirements: compliance licensing, least-privilege Purview roles, the S&C PowerShell + Graph toolchain,
in-scope data sources, compliance/records/privacy/legal stakeholders, and a pilot scope with change
control) — those are referenced here, not repeated.

## 2.1 DLP licensing for the workloads you target
**Description:** The **DLP licensing** the target workloads require — baseline DLP for Exchange Online,
SharePoint Online, OneDrive, and Teams is broadly available; **Endpoint DLP** (devices) and advanced
classification inputs (trainable classifiers, Exact Data Match) require **Microsoft 365 E5** or the **E5
Compliance** add-on (Global Requirement 1).
**Why:** A policy that targets a workload/condition your plan doesn't license will not apply there.
**Verify:** Microsoft 365 admin center → `Billing → Licenses`; run `DLPCUSTOM-Assess-DlpEnvironment.ps1`,
which reports the DLP-relevant SKUs and whether Endpoint DLP is in scope. Confirm DLP appears in the
Purview portal (`Data loss prevention`).
**Implement:** Assign/purchase the required licensing before targeting an unlicensed workload; otherwise
scope the policy to the workloads you can license and record the rest as deferred.

## 2.2 Least-privilege DLP administration role
**Description:** An account in a least-privilege role that can author DLP — **Compliance Administrator** or
**Compliance Data Administrator**, or a **DLP Compliance Management** role group — rather than blanket
Global Administrator (Global Requirement 2).
**Why:** Purview's fine-grained role model limits exposure; DLP authoring does not require Global Admin.
**Verify:** Purview portal → `Settings → Roles & scopes → Role groups` (verify path) — confirm membership;
`Connect-IPPSSession` succeeds and `Get-DlpCompliancePolicy` returns without an authorization error.
**Implement:** Add the account to the least-privilege DLP-capable role group under change control.

## 2.3 Security & Compliance PowerShell toolchain
**Description:** A workstation with the **ExchangeOnlineManagement** module (provides `Connect-IPPSSession`
for Security & Compliance PowerShell), and a modern-auth / MFA admin account (Global Requirement 3). DLP
policy cmdlets (`*-DlpCompliancePolicy`, `*-DlpComplianceRule`) live in S&C PowerShell.
**Why:** Every script in this solution authors, validates, or reports on DLP through S&C PowerShell.
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement`; `Connect-IPPSSession` succeeds and
`Get-DlpCompliancePolicy` runs. `DLPCUSTOM-Assess-DlpEnvironment.ps1` installs a missing module and reports
connectivity.
**Implement:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; confirm modern-auth sign-in.

## 2.4 In-scope workloads (and endpoint / cloud-app onboarding, if targeted)
**Description:** The **workloads in scope** for the policy — Exchange, SharePoint, OneDrive, Teams — and,
**if** you target them, **endpoint devices onboarded to Purview** (for Endpoint DLP) and **Defender for
Cloud Apps** connected (for cloud-app DLP). Global Requirement 4.
**Why:** DLP applies per location; endpoints and cloud apps are **not** covered until onboarded/connected,
which are separate roll-outs.
**Verify:** Run `DLPCUSTOM-Scope-Health.ps1` — it confirms the M365 workloads and reports endpoint
onboarding readiness. In the portal, `Settings → Device onboarding` shows onboarded devices (verify path).
**Implement:** Target only the workloads that are ready. Endpoint onboarding and cloud-app connection are
performed in their dedicated solutions; this policy targets those locations **once they exist**.

## 2.5 The sensitive information types / classifiers the conditions need
**Description:** The **sensitive information types** (built-in or **custom**), **Exact Data Match** schemas,
**document fingerprints**, **trainable classifiers**, or **sensitivity labels** that your rule conditions
will reference — available in the tenant *before* you author the policy.
**Why:** A rule condition can only reference a SIT/label that exists; a custom identifier (e.g. your
customer-ID format) must be built first, or the rule can't detect it.
**Verify:** Run `DLPCUSTOM-Assess-DlpEnvironment.ps1` — it lists available SITs (`Get-DlpSensitiveInformationType`)
and flags whether the ones your design needs are present. Sensitivity labels via `Get-Label` (verify).
**Implement:** Build any missing custom SIT / EDM schema / fingerprint / trainable classifier in its own
solution first, then consume it here as a condition. Do **not** invent a SIT inside this policy work.

## 2.6 A documented data-protection intent (from stakeholders)
**Description:** A written **data-protection intent** from the compliance/privacy/security stakeholders
(Global Requirement 5): which data classes matter, what should happen on a match (audit / warn / block /
encrypt), which flows are approved (exceptions), and where the regulatory line is.
**Why:** DLP conditions and actions must encode enterprise policy, not technical defaults; **what is
sensitive and which regulations apply are determinations for compliance/privacy/legal**, not the engineer.
**Verify:** The intent is documented and approvers are named; each planned rule maps to a stated intent.
**Implement:** Capture the intent (data classes, desired actions, approved flows, regulatory drivers)
before authoring — record it as `Custom DLP – Sensitive Data – Design`. Escalate any determination.

## 2.7 A pilot scope, simulation mode, and change control
**Description:** A named **pilot scope** (users/sites/devices) to simulate on, confirmation that DLP
**simulation / test mode** is available (`TestWithoutNotifications` / `TestWithNotifications`), and a
**change-control** process for the move to enforcement (Global Requirement 6).
**Why:** Every Purview policy is piloted before enforcement; DLP block/encrypt actions are high-impact and
must be simulated first so they cannot break legitimate work.
**Verify:** The pilot scope is defined; a new/updated policy can be created in a test mode; a change
window/approval path exists for the enforcement cut-over.
**Implement:** Define the pilot scope and agree change control before moving any policy out of simulation.

---
## Checklist
- [ ] DLP licensing confirmed for every targeted workload (Endpoint DLP / advanced inputs need E5 / E5 Compliance)
- [ ] Least-privilege DLP admin role confirmed; Global Admin not required for authoring
- [ ] ExchangeOnlineManagement installed; `Connect-IPPSSession` + `Get-DlpCompliancePolicy` succeed
- [ ] In-scope workloads agreed; endpoints/cloud-apps onboarded **if** targeted (else deferred)
- [ ] Required SITs / labels / EDM / fingerprints exist in the tenant (or built first in their own solution)
- [ ] Data-protection intent documented and approvers named (`Custom DLP – Sensitive Data – Design`)
- [ ] Pilot scope defined; simulation/test mode available; change control agreed for enforcement
