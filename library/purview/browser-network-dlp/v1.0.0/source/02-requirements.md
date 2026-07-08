# 2. Requirements Guide — Browser & Network DLP (Microsoft Purview)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` (the six
shared requirements: compliance licensing, least-privilege Purview roles, the S&C PowerShell + Graph
toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders, and a pilot scope with
change control) — those are referenced here, not repeated.

## 2.1 Endpoint DLP licensing (browser & network DLP is plan-gated)
**Description:** A confirmed compliance plan that includes **Endpoint DLP** — **Microsoft 365 E5**, the
**E5 Compliance** add-on, or **E5 Information Protection & Governance**. Browser and domain restrictions
are an Endpoint DLP capability (Global Requirement 1).
**Why:** Without the right plan the **Devices** location and the browser/domain restriction settings are
not available; the policy cannot be enforced.
**Verify:** M365 admin center → `Billing → Licenses` shows the E5/compliance SKU; run
`DLPBROWSER-Discovery.ps1` — it reads `subscribedSkus` via Graph and flags whether an Endpoint
DLP–bearing SKU is present. Confirm **Data Loss Prevention → Endpoint DLP settings** is visible in the
Purview portal (verify path).
**Implement:** Assign/purchase the required licensing before configuring. Where it is not licensed,
record browser & network DLP as out-of-scope rather than attempting to enable it.

## 2.2 Least-privilege DLP admin access (not blanket Global Admin)
**Description:** An account in **Compliance Administrator** or **Compliance Data Administrator** (to
author DLP policies and Endpoint DLP settings), per Global Requirement 2. **DLP Compliance Management**
role is included in those groups.
**Why:** DLP policy authoring and Endpoint DLP settings require the matching Purview role; over-granting
Global Administrator undermines least privilege.
**Verify:** Purview portal → `Settings → Roles & scopes → Role groups` (verify path) — confirm membership
in Compliance Administrator / Compliance Data Administrator; `Connect-IPPSSession` succeeds and
`Get-DlpCompliancePolicy` returns without an authorization error.
**Implement:** Add the account to the least-privilege compliance role group under change control.

## 2.3 Security & Compliance PowerShell + Microsoft Graph toolchain
**Description:** A workstation with the **ExchangeOnlineManagement** module (`Connect-IPPSSession` for
Security & Compliance PowerShell, which hosts the `*-DlpCompliancePolicy` / `*-DlpComplianceRule` and
`Search-UnifiedAuditLog` cmdlets) and the **Microsoft Graph PowerShell SDK**, with a modern-auth/MFA
admin account (Global Requirement 3).
**Why:** Assessment, policy authoring/validation, and reporting run through these.
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement, Microsoft.Graph.Authentication`;
`Connect-IPPSSession` and `Connect-MgGraph` both succeed. `DLPBROWSER-Discovery.ps1` installs
missing modules and reports connectivity.
**Implement:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser` and
`Install-Module Microsoft.Graph -Scope CurrentUser`; confirm modern-auth sign-in.

## 2.4 Graph permission scopes (read-only for assessment)
**Description:** Delegated Graph scopes for the read-only assessment/health scripts:
`Organization.Read.All` (licensing), `Directory.Read.All`, and
`DeviceManagementManagedDevices.Read.All` (managed-device / endpoint readiness signal). No write scopes
are required.
**Why:** The readiness and device-health scripts read licensing and managed-device data through Graph;
keeping to read scopes matches the safe-by-default posture.
**Verify:** Run `DLPBROWSER-ScopeHealth.ps1` (read-only) — it connects with the read scopes and
reports if consent is missing.
**Implement:** Consent at first `Connect-MgGraph`; if admin consent is required, a Global Administrator
approves the scopes once in Entra (`Identity → Applications → Enterprise applications`).

## 2.5 Devices onboarded to Microsoft Purview (Endpoint DLP)
**Description:** The in-scope **Windows 10/11 and/or macOS endpoints onboarded to Purview** for Endpoint
DLP. Onboarding is separate from device management/enrollment; a device must be onboarded before Endpoint
DLP (and therefore browser DLP) can see or control it (Global Requirement 4).
**Why:** Browser & network DLP is enforced on **onboarded devices** only — an un-onboarded device is
invisible to the policy.
**Verify:** Purview portal → `Settings → Device onboarding` (verify path) shows onboarded devices; run
`DLPBROWSER-ScopeHealth.ps1` — it reports managed-device counts and onboarding readiness signals.
**Implement:** Onboard the pilot-ring devices first (portal → Device onboarding; script/GPO/Intune per
Microsoft's onboarding method). Roll out broadly only after the pilot validates.

## 2.6 Microsoft Purview browser extension + browser coverage
**Description:** The **Microsoft Purview browser extension** deployed to **Chrome** and **Firefox** on
in-scope devices, with **Microsoft Edge** relying on its **native** Endpoint DLP integration (no
extension needed). This is what lets Purview inspect browser upload activity.
**Why:** Chrome/Firefox upload activity is only visible to Endpoint DLP when the extension is present;
without it those browsers are effectively blind and should be treated via the **unallowed browsers**
control.
**Verify:** On a pilot device, confirm the extension is installed and enabled in Chrome/Firefox
(`chrome://extensions` / Firefox add-ons); `DLPBROWSER-ScopeHealth.ps1` reports the extension as a
readiness checklist item (deployment is enterprise-managed, verify in your MDM/GPO).
**Implement:** Deploy the extension via **Group Policy / Intune / enterprise browser management** per
Microsoft's guidance (Purview portal → Endpoint DLP settings references the extension). Verify the
current extension name/ID in your tenant — the portal is evolving.

## 2.7 In-scope sensitive data (labels / sensitive information types)
**Description:** The **sensitivity labels** and/or **sensitive information types (SITs)** that define
when an upload is "sensitive" and therefore in scope for the policy condition (Global Requirement 4).
**Why:** The DLP rule keys off these; without a defined condition the policy either matches nothing or
matches everything.
**Verify:** Purview portal → `Information Protection → Sensitivity labels` and
`Data classification → Sensitive info types` show the intended labels/SITs; confirm with stakeholders
which represent restrict-worthy data.
**Implement:** Reuse the label taxonomy / SITs from the Information Protection solutions; where none
exist yet, start with high-confidence built-in SITs (e.g. credit-card / national-ID types) for the pilot
and refine. **Which data warrants restriction is a compliance/security determination**, not a technical
default.

## 2.8 Destination inventory (unsanctioned & personal cloud domains)
**Description:** The list of **web destinations to restrict** — personal cloud storage and unsanctioned
file-sharing/SaaS domains — that will populate the **sensitive service domain group**
`Unsanctioned & Personal Cloud – Domain Group`.
**Why:** The domain group is what the upload restriction acts on; an incomplete list leaves egress paths
uncontrolled.
**Verify:** Review egress signals (Activity Explorer, and any Defender for Cloud Apps / proxy discovery)
to see where uploads actually go; `DLPBROWSER-Report.ps1` summarizes recent endpoint egress
from the audit log to inform the list.
**Implement:** Compile the domain list with security/stakeholders; enter it as a sensitive service domain
group in Purview portal → **Endpoint DLP settings → Browser and domain restrictions to sensitive data**
(verify path). **Which destinations are "unsanctioned" is an organizational determination.**

## 2.9 A pilot ring, simulation mode, and change control
**Description:** A small **pilot ring** (`Browser & Network DLP Pilot Ring – Stage1`) of devices/users,
confirmation that the DLP policy can run in **simulation / test mode** before enforcement, and a
**change-control** process, per Global Requirement 6.
**Why:** Browser upload blocking is high-impact; the policy must be **piloted in simulation/test** and
tuned before any Warn/Block enforcement.
**Verify:** The ring is defined; `New-DlpCompliancePolicy`/`Set-DlpCompliancePolicy` support the test
modes (`TestWithoutNotifications` / `TestWithNotifications`); a change window/approval path exists.
**Implement:** Define the ring and agree change control before enforcing anything.

---
## Checklist
- [ ] Endpoint DLP licensing confirmed (E5 / E5 Compliance / E5 IP&G) — else recorded out-of-scope
- [ ] Compliance Administrator / Compliance Data Administrator access confirmed; Global Admin not required for authoring
- [ ] ExchangeOnlineManagement + Microsoft Graph SDK installed; `Connect-IPPSSession` / `Connect-MgGraph` succeed
- [ ] Graph read scopes consented (no write scopes needed)
- [ ] In-scope devices onboarded to Purview (pilot ring first)
- [ ] Microsoft Purview browser extension deployed (Chrome/Firefox); Edge native coverage confirmed
- [ ] In-scope sensitivity labels / SITs identified as the policy condition
- [ ] Unsanctioned & personal-cloud destination list compiled for the domain group
- [ ] `Browser & Network DLP Pilot Ring – Stage1` defined; simulation/test mode confirmed; change control agreed
