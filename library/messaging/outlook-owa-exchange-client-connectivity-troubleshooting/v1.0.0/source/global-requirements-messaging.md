# Global Requirements — Microsoft 365 / Exchange Messaging Solutions

These requirements apply to **every** solution in the **Messaging** category (Exchange Online &
Exchange hybrid mail flow, connectors, mail hygiene, email authentication, federation, archiving,
client connectivity, and messaging support operations). They are the common foundation each solution
assumes is already in place (or stands up as part of its own Requirements section). Verify each before
starting a solution's implementation steps.

> **Vendor boundary (applies to every Messaging solution).** The **Exchange admin center (EAC)**, the
> **Microsoft 365 admin center**, **Exchange Online PowerShell (EXO V3 module)**, **Microsoft Graph**,
> and on-premises **Exchange Server / Active Directory** are authored at exact, current click-by-click
> and cmdlet detail from Microsoft's public documentation. Where a capability, default, or portal path
> is **version- or plan-dependent** (Exchange Server build/CU, EOP vs Defender for Office 365 plan,
> Exchange Online Archiving / auto-expanding archive availability, Commercial vs Government cloud), it
> is **cited or flagged "verify in your tenant/version"** — never invented. **Third-party mail hygiene,
> archiving, and signature/gateway products** are integrated at the pattern level; their internal
> consoles are deferred to the vendor's own docs. **Commercial vs Government (GCC/GCC High/DoD)** portal
> URLs and endpoints differ — where a solution's setup materially differs on a sovereign cloud, flag it
> (per the house Commercial-vs-Government rule). Automation is delivered as **PowerShell** (Exchange
> Online PowerShell / Graph) — never with hardcoded credentials or secrets in code.

## 1. Microsoft 365 tenant with Exchange Online
- **Description:** A Microsoft 365 tenant with **Exchange Online** and the appropriate licensing for the
  capability in scope (e.g. Exchange Online Plan 1/2, EOP, **Defender for Office 365** for advanced
  hygiene, Exchange Online Archiving / auto-expanding archive where required).
- **Why required:** All mail-flow, hygiene, archiving, and client configuration is performed against
  this tenant and depends on the right plan.
- **How to verify:** Sign in to the Microsoft 365 admin center; confirm the Exchange Online subscription
  and license counts under **Billing > Licenses**.
- **How to implement if missing:** Provision/assign the required licensing before starting.

## 2. Administrative access (least-privilege Exchange/365 roles)
- **Description:** Administrative access with the **least-privilege role** the solution names —
  typically **Exchange Administrator** (or specific EAC role groups such as Organization Management,
  Recipient/Records/Hygiene Management), and **Global Administrator** only where genuinely required
  (e.g. federation/ADFS, connector auth).
- **Why required:** Mail-flow, connector, hygiene, archiving, and federation changes require the
  corresponding admin role.
- **How to verify:** Confirm the role assignment in the Microsoft 365 admin center / Entra roles.
- **How to implement if missing:** Have a Global Admin assign the least-privilege role under change control.

## 3. Exchange Online PowerShell (EXO V3) + Graph toolchain
- **Description:** A workstation with the **ExchangeOnlineManagement (EXO V3)** PowerShell module and,
  where used, **Microsoft Graph PowerShell**; modern-auth / MFA-capable admin sign-in.
- **Why required:** Configuration, automation, and the provided scripts run through EXO PowerShell /
  Graph; Basic Auth is retired.
- **How to verify:** `Connect-ExchangeOnline` succeeds with the admin account; `Get-Module
  ExchangeOnlineManagement`.
- **How to implement if missing:** Install the module (`Install-Module ExchangeOnlineManagement`) and
  confirm modern-auth sign-in before running the steps.

## 4. DNS control for the mail domains
- **Description:** Ability to create/modify **DNS records** (MX, SPF (TXT), DKIM (CNAME), DMARC (TXT),
  Autodiscover, and connector/host records) for the domains in scope.
- **Why required:** Email authentication, mail routing/coexistence, connector validation, and client
  autodiscover all depend on DNS.
- **How to verify:** Confirm access to the authoritative DNS zone for each mail domain.
- **How to implement if missing:** Coordinate with whoever controls DNS; stage changes under change
  control (mail-flow and authentication changes are high-impact).

## 5. Hybrid Exchange & Active Directory (for hybrid solutions)
- **Description:** For **hybrid / on-premises** solutions, access to the on-premises **Exchange Server**
  organization (correct roles/CU), **Active Directory**, **Azure AD Connect** (directory sync), and the
  relevant network/firewall paths (e.g. for Edge/transport, hybrid connectors, autodiscover).
- **Why required:** Hybrid mail flow, Edge Transport, connectors, and federation read from and change
  the on-premises side.
- **How to verify:** Confirm on-prem Exchange admin access, AD access, and that directory sync is healthy.
- **How to implement if missing:** Obtain access and confirm the on-prem Exchange/AD/AAD-Connect health
  before making hybrid changes.

## 6. A pilot scope and change control
- **Description:** A **pilot group / accepted-domain / test mail flow** to validate on before fleet-wide
  rollout, and a **change-control** process for production changes (mail flow, connectors, DNS,
  authentication, hygiene policy are all high-impact).
- **Why required:** Every solution follows an **Assess → Design → Configure → Pilot → Validate → Expand**
  model; the pilot proves the design and change control protects production mail flow.
- **How to verify:** Confirm a named pilot scope and an approval/change window are available.
- **How to implement if missing:** Define a pilot scope and agree change control with the messaging/
  service owners before making production changes.

*The deployment model across every Messaging solution is the same: **Assess → Design → Configure →
Pilot → Validate → Expand**, with explicit pass/fail gates and a documented rollback for production
changes. Automation is delivered as **PowerShell** (Exchange Online PowerShell / Graph) — never with
hardcoded credentials or secrets in code.*
