# Requirements

These are the **solution-specific** prerequisites for deploying/troubleshooting ADFS federation for
Microsoft 365 and/or migrating to managed cloud authentication. They build on — and do **not**
duplicate — the shared six in **`global-requirements-messaging.md`** (Microsoft 365 tenant with Exchange
Online; least-privilege admin access; EXO V3 + Graph toolchain; DNS control; hybrid Exchange & AD;
pilot scope and change control). Verify each item below before starting the implementation steps.

> **Reminder (vendor boundary).** ADFS, WAP, Microsoft Entra ID (Azure AD), Microsoft Entra Connect
> (Azure AD Connect), and the Microsoft Graph / MSOnline cmdlets are authored from Microsoft's public
> documentation. Where behavior is **version-dependent** (Windows Server / ADFS version, Entra Connect
> build, MSOnline vs Graph cmdlet availability, Commercial vs Government cloud), it is flagged **"verify
> in your tenant/version"** — never invented.

## R1. Microsoft Entra Connect (Azure AD Connect) installed and healthy

- **Description:** A running, healthy **Microsoft Entra Connect (Azure AD Connect)** server synchronising
  the on-premises AD to Microsoft Entra ID, on a **current supported build**. This is the tool that
  enables PHS, PTA, Seamless SSO, and (via its wizard) the domain conversion and Staged Rollout.
- **Why required:** Every migration action (enable PHS/PTA, Seamless SSO, Staged Rollout, convert domain)
  is performed through Entra Connect or depends on healthy directory sync. Federated sign-in also relies
  on the correct **sourceAnchor / ImmutableID** being synced.
- **How to verify:** On the Entra Connect server open the **Synchronization Service Manager** and confirm
  recent successful sync cycles; run the Entra Connect wizard and note the current sign-in method; confirm
  the build under **Add/Remove Programs**. In Entra ID, check **Microsoft Entra Connect** health.
- **How to implement if missing:** Install/upgrade Microsoft Entra Connect to a current supported build
  and confirm a healthy delta sync before making any auth change. **Verify the current supported build in
  your version.**

## R2. Global Administrator (and Hybrid Identity Administrator) access

- **Description:** **Global Administrator** access to the Microsoft 365 / Entra tenant. Domain federation
  and domain conversion (federated ↔ managed) require it; the **Hybrid Identity Administrator** role
  covers most Entra Connect / sign-in-method operations.
- **Why required:** Beyond the least-privilege Exchange roles in the global requirements, changing a
  domain's **authentication type** and configuring federation trust are tenant-level operations requiring
  Global Administrator (or Hybrid Identity Administrator where the specific action permits it).
- **How to verify:** In the Microsoft 365 admin center / Entra roles, confirm the operator holds Global
  Administrator (and, ideally, Hybrid Identity Administrator).
- **How to implement if missing:** Have an existing Global Administrator assign the role under change
  control; use PIM/just-in-time elevation where available.

## R3. ADFS farm and (if used) WAP access — for the federation/troubleshooting path

- **Description:** Administrative access to the **ADFS farm** (ADFS Management console / ADFS PowerShell
  on a federation server) and any **Web Application Proxy (WAP)** servers fronting it, plus the service
  account and the **token-signing / token-decrypting certificates**.
- **Why required:** Repairing claims rules, rolling the token-signing certificate, inspecting endpoints,
  and eventually decommissioning ADFS all require direct ADFS/WAP administrative access.
- **How to verify:** On a federation server, `Get-AdfsProperties` and `Get-AdfsCertificate` succeed;
  the ADFS Management console opens; you can reach the WAP servers. Confirm the ADFS service account.
- **How to implement if missing:** Obtain local admin on the ADFS/WAP servers and ADFS service
  administrative rights before touching the farm.

## R4. Federation state and certificate visibility

- **Description:** Ability to read the current **federation trust** between Entra ID and ADFS — the
  issuer URI, passive/metadata endpoints, and the **token-signing certificate** currently trusted by
  Entra — and the ADFS **AutoCertificateRollover** setting.
- **Why required:** The number-one federation outage is a **token-signing certificate mismatch/expiry**.
  You must be able to compare the cert ADFS is signing with against the cert Entra trusts, and know
  whether ADFS auto-rolls certificates.
- **How to verify:** `Get-MgDomainFederationConfiguration -DomainId <domain>` (Microsoft Graph) returns
  the trusted signing certificate and endpoints; on ADFS, `Get-AdfsCertificate -CertificateType
  Token-Signing` and `(Get-AdfsProperties).AutoCertificateRollover` return current values.
- **How to implement if missing:** Install the **Microsoft Graph PowerShell** module and connect with the
  required scopes (`Domain.Read.All` for read; `Domain.ReadWrite.All` to change). Ensure ADFS PowerShell
  is available on a federation server. **Legacy note:** the older `Get-MsolFederationProperty` / MSOnline
  cmdlets provide similar data but **MSOnline is deprecated — verify availability in your tenant.**

## R5. Chosen managed sign-in method decided and its prerequisites met — for the migration path

- **Description:** A decision on the target managed method — **PHS** (recommended default) or **PTA** —
  and its prerequisites: for **PTA**, **two or more PTA authentication agents** for resilience; for
  **Seamless SSO**, the requirements for the **AZUREADSSOACC** computer object and the Kerberos
  configuration (browsers must send the corporate-network endpoints the Kerberos ticket, typically via
  the intranet zone / trusted sites).
- **Why required:** The target sign-in path must be resilient and validated before you convert the
  domain. A single PTA agent is a new single point of failure; Seamless SSO silently fails to a normal
  prompt if its prerequisites aren't met.
- **How to verify:** In the Entra Connect wizard, confirm the method can be enabled; for PTA, confirm the
  number of healthy agents under **Entra ID → Connect → Pass-through authentication**; for Seamless SSO,
  confirm the `AZUREADSSOACC` object exists and the Kerberos decryption key rollover plan is understood.
- **How to implement if missing:** Enable the method in Entra Connect (Configure → Change user sign-in),
  deploy additional PTA agents, and push the Seamless SSO browser settings via Group Policy.

## R6. Microsoft Entra Conditional Access parity for any ADFS-enforced controls — for the migration path

- **Description:** An inventory of any **access-control / MFA / client-restriction rules enforced in
  ADFS** for the Microsoft 365 relying party, and an equivalent set of **Entra ID Conditional Access**
  policies to replace them **before** ADFS is removed.
- **Why required:** When authentication moves to the cloud, ADFS-side access rules (e.g. block extranet,
  require MFA for certain groups, device checks) stop applying. Without Conditional Access parity you
  **silently lose** those controls at conversion.
- **How to verify:** Review the ADFS Microsoft 365 relying-party trust's **Access Control Policy** /
  issuance authorization rules and any third-party MFA adapter; confirm matching Entra ID Conditional
  Access policies exist (in report-only first).
- **How to implement if missing:** Author the equivalent Conditional Access policies (requires Entra ID
  P1/P2 — **verify your licensing**), test them in **report-only** mode, and enable them before
  converting the domain.

## R7. Pilot user group and a maintenance/change window

- **Description:** A named **pilot user group** (a handful of representative, low-risk users — ideally the
  implementers) for **Staged Rollout**, and an agreed **change window** with rollback authority for the
  domain conversion and ADFS decommission.
- **Why required:** Auth changes are high-impact. Staged Rollout validates the target path on the pilot
  group first; the domain conversion and decommission are done in a controlled window with rollback ready.
- **How to verify:** Confirm the pilot group membership and that a change window with communicated
  rollback is approved.
- **How to implement if missing:** Create the pilot group, define the Staged Rollout wave
  (`Staged Rollout – Pilot – Wave1`), and schedule the change window with the service owner. (This
  extends the shared "pilot scope and change control" requirement with the specifics for auth cut-over.)
