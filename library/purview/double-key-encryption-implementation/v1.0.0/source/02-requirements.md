# 2. Requirements Guide — Double Key Encryption (DKE) Implementation, Microsoft Purview

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` (licensing,
least-privilege roles, the S&C PowerShell / Graph toolchain, in-scope data, stakeholders, and a pilot
scope with change control) — this guide adds the DKE-specific prerequisites.

## 2.1 Microsoft 365 / Purview licensing for DKE
**Description:** Licensing that includes Microsoft Purview Information Protection with **Double Key
Encryption** — DKE requires the advanced information-protection plan (**Microsoft 365 E5** or the
**E5 Compliance / Information Protection and Governance** add-on).
**Why:** DKE is a premium, plan-gated capability; the **Use Double Key Encryption** option will not
appear on a sensitivity label without the required plan.
**Verify:** Microsoft 365 admin center → **Billing → Licenses**; confirm the DKE option is available
when configuring a label's encryption in the Purview portal. Run `IPDKE-Discovery.ps1`. **Verify your
licensing/tenant** against Microsoft's current DKE documentation.
**Implement:** Assign/purchase the required plan before starting.

## 2.2 Roles for labels, the app registration, and the group
**Description:** Least-privilege roles across the three areas this solution touches:
**Compliance Administrator** or **Information Protection Admin** (create and publish the DKE label);
**Application Administrator** + **Cloud Application Administrator** (register the DKE service app and
grant admin consent — Global Administrator only where consent requires it); **Groups Administrator**
(create the pilot/reader groups).
**Why:** DKE spans Purview labeling, Entra ID app registration/consent, and group management; each
needs its matching role.
**Verify:** Purview portal → **Settings → Roles and scopes**; Entra admin center → **Roles and
admins**. Confirm membership.
**Implement:** Assign the least-privilege roles under change control; reserve Global Administrator for
the consent step only if required.

## 2.3 A host you control for the DKE key service
**Description:** Hosting **you** own and control on which to deploy the DKE key service — for example
an **Azure App Service** web app or an **on-premises / IIS** server — reachable over **HTTPS** by the
clients that will open DKE content, with a valid TLS certificate and a DNS name (for example
`dke.contoso.com`).
**Why:** The customer-held key must live on infrastructure you control; the whole security benefit
depends on this service being separate from — and not decryptable by — Microsoft. Clients must reach
it to open content.
**Verify:** The host exists, resolves in DNS, and serves HTTPS with a trusted certificate; the
network path from client machines is open.
**Implement:** Provision the host and certificate; decide the hosting region to satisfy any
sovereignty requirement (a compliance/legal decision — see Requirement 2.7).

## 2.4 .NET build/deploy toolchain for the DKE service
**Description:** A workstation with the **.NET SDK** and **Git** to obtain, configure, and build the
Microsoft-published open-source DKE key service, plus the means to publish it to the host in 2.3.
**Why:** The DKE service is deployed from Microsoft's open-source reference implementation, which you
configure (appsettings) and build before publishing.
**Verify:** `dotnet --info` and `git --version` succeed on the build workstation.
**Implement:** Install the current .NET SDK and Git; obtain the Microsoft DKE service source. **Follow
Microsoft's current DKE deployment documentation for exact versions and steps.**

## 2.5 Supported client platform for applying DKE labels
**Description:** The users who will apply/open DKE content run a **supported client** — historically
**Microsoft 365 Apps (Office) desktop on Windows** with built-in labeling. **Verify current
platform/client support for your tenant** (web, macOS, and mobile support has been limited and is
evolving).
**Why:** DKE labels can only be applied and opened on supported clients; scoping the pilot to
unsupported clients will fail.
**Verify:** Confirm pilot users run a supported Office desktop build on Windows with built-in
labeling; check Microsoft's current DKE client-support list.
**Implement:** Provision supported clients for the pilot group; do not scope DKE to unsupported
platforms.

## 2.6 A named audience for DKE (not everyone)
**Description:** A **small, named audience** — a Microsoft Entra security group of pilot users
(`Purview - DKE Pilot Users`) and the set of people authorized to read the double-keyed content
(`SG - DKE Ultra Confidential Readers`) — reflecting that DKE is for the **most sensitive** data, not
the whole organization.
**Why:** DKE trades away cloud content services (DLP inspection, eDiscovery content search, Copilot);
applying it broadly would break routine workflows. It belongs on a narrow, high-value scope.
**Verify:** Entra → **Groups**; the pilot and reader groups exist. Run
`IPDKE-Scope-And-ServiceHealth.ps1`.
**Implement:** Create the groups (the helper script can create the pilot group) and agree the audience
with data owners.

## 2.7 Data owners, compliance & legal determination
**Description:** Named **data owners** and engagement with **compliance, records, privacy, and legal**
stakeholders who decide **which** data must be double-keyed and confirm any **sovereignty / regulatory**
driver (including the required hosting region for the key service).
**Why:** "Which data is sensitive enough for DKE" and any regulatory/sovereignty applicability are
business and legal determinations, not IT defaults; the hosting region may be legally constrained.
**Verify:** A named owner and a documented determination exist for the data to be double-keyed and the
key-service region.
**Implement:** Identify owners; capture the determination and the region requirement before
configuring (see the vendor boundary — determinations are deferred to these functions).

## 2.8 Change control and a documented rollback
**Description:** A documented **change-control / rollback** process for publishing the DKE label and
for the key-service configuration.
**Why:** DKE changes how sensitive content is protected and depends on a service you run; a pilot gate
and a rollback are mandatory.
**Verify:** A change ticket exists with an approver, the pilot scope, and a rollback (unpublish the
label policy; the label stays but is applied to no one).
**Implement:** Record the change, name the pilot scope, define the rollback, and get approval before
publishing beyond the pilot.

---
## Checklist
- [ ] Microsoft 365 / Purview licensing includes DKE (E5 / E5 Compliance) — `IPDKE-Discovery.ps1`
- [ ] Roles: Compliance Administrator / Information Protection Admin; Application + Cloud Application Administrator; Groups Administrator
- [ ] A host you control for the DKE key service (HTTPS, TLS cert, DNS, client reachability)
- [ ] .NET SDK + Git build/deploy toolchain for the DKE service
- [ ] Supported client platform for pilot users (verify current DKE client support)
- [ ] Named audience groups created — `Purview - DKE Pilot Users`, `SG - DKE Ultra Confidential Readers` — `IPDKE-Scope-And-ServiceHealth.ps1`
- [ ] Data owners named; compliance/legal determination + hosting-region requirement captured
- [ ] Change control + documented rollback (unpublish the label policy)
