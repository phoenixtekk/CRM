# Global Requirements — Azure Solutions — Microsoft 365 Exchange Online Tenant-to-Tenant Migration (1:1 Domains)

These are the baseline requirements common to **every** solution in the Azure Solutions category. They are generic to the category and are **not** Exchange-specific — the Exchange tenant-to-tenant requirements are listed separately in `02-requirements.md`. Satisfy both sets before beginning implementation.

Each requirement follows the same structure: **Description / Why required / How to verify / How to implement if missing.**

---

## G1 — A Microsoft 365 / Microsoft Entra tenant

**Description.** An active Microsoft cloud tenant (Microsoft Entra ID directory, the identity backbone for all Microsoft 365 and Azure services) for each environment the solution touches.

**Why required.** Every Azure Solutions deliverable operates against one or more Microsoft tenants; the tenant is the root container for identities, licensing, policies, and services.

**How to verify.** Sign in to the **Microsoft Entra admin center** (https://entra.microsoft.com) → **Overview** and confirm the tenant name, tenant ID, and primary domain.

**How to implement if missing.** Provision a Microsoft 365 tenant via https://www.microsoft.com/microsoft-365 (or an Azure subscription via https://portal.azure.com) and record the tenant ID.

---

## G2 — Sufficient administrative roles

**Description.** A named operator account holding the least-privilege administrative roles required by the specific solution (commonly Global Administrator, or a scoped combination such as Exchange Administrator, Security Administrator, Application Administrator, or Privileged Role Administrator).

**Why required.** Configuration, policy, and service changes require directory administrative rights. Using scoped roles where possible limits blast radius.

**How to verify.** In **Microsoft Entra admin center** → **Identity → Roles & admins → Roles**, confirm the operator's role assignments. Prefer **Privileged Identity Management (PIM)** eligible assignments where available.

**How to implement if missing.** Have an existing Global Administrator assign the required role under **Roles & admins → (role) → Add assignments**, ideally as a PIM-eligible (time-bound) assignment.

---

## G3 — Licensing baseline

**Description.** The Microsoft 365 / Entra / Azure licenses and service plans the solution depends on, assigned to the in-scope users or groups.

**Why required.** Most workloads (Exchange Online, Entra ID P1/P2, Defender, Intune, etc.) are gated behind specific service plans; features silently fail or are unavailable without them.

**How to verify.** In the **Microsoft 365 admin center** (https://admin.microsoft.com) → **Billing → Licenses**, confirm owned quantities; in **Users → Active users**, confirm assignment.

**How to implement if missing.** Acquire licenses via **Billing → Purchase services** and assign them directly or via group-based licensing.

---

## G4 — Network connectivity to Microsoft 365 / Azure service endpoints

**Description.** Reliable outbound connectivity from operator workstations and any in-scope systems to the relevant Microsoft 365 and Azure service URLs and IP ranges, through any corporate proxy/firewall.

**Why required.** Admin portals, PowerShell modules, Microsoft Graph, and migration/data services all require access to Microsoft's published endpoints; blocked endpoints cause authentication and operation failures.

**How to verify.** From an operator workstation, confirm you can reach https://admin.microsoft.com, https://entra.microsoft.com, and connect with Exchange Online PowerShell / Microsoft Graph PowerShell without proxy errors. Reference Microsoft's published **Office 365 URLs and IP address ranges**.

**How to implement if missing.** Allow-list the required Microsoft 365/Azure endpoints on the proxy/firewall per Microsoft's published ranges; if using PowerShell, ensure TLS 1.2+ and module access through the proxy.

---

## G5 — Change control and a defined maintenance window

**Description.** An approved change request and a scheduled maintenance/cutover window for any change that affects production identities, mail flow, DNS, or user-facing services.

**Why required.** Azure Solutions changes can affect authentication, mail, and access for the whole organization. Change control provides approval, communication, scheduling, and a rollback decision point.

**How to verify.** Confirm an approved change record exists with a defined window, a named change owner, a communication plan, and documented rollback criteria.

**How to implement if missing.** Raise a change request in the organization's change-management process; schedule the window during low-impact hours and notify stakeholders and the service desk in advance.

---

## G6 — Backup, export, and rollback posture

**Description.** A documented rollback plan and, where applicable, an exported snapshot of pre-change configuration and data (current DNS records, current policy/config exports, data backups) sufficient to recover if the change must be reversed.

**Why required.** Some Azure Solutions actions are disruptive or hard to reverse (DNS cutover, domain moves, policy changes). A captured baseline and a rollback plan protect against data loss and prolonged outage.

**How to verify.** Confirm a pre-change export/backup exists (for this solution: current MX/Autodiscover/SPF/DKIM/DMARC records, mailbox inventory, and permission exports) and that the rollback steps are written down and understood.

**How to implement if missing.** Before making changes, export current DNS records and relevant configuration, run the discovery scripts to capture a data/inventory baseline, and write the rollback procedure into the change record.

---

## Global requirements summary

| ID | Requirement |
|----|-------------|
| G1 | Microsoft 365 / Entra tenant |
| G2 | Sufficient administrative roles (least privilege, PIM where possible) |
| G3 | Licensing baseline for the workload |
| G4 | Network connectivity to Microsoft 365 / Azure endpoints |
| G5 | Change control + defined maintenance window |
| G6 | Backup / export / rollback posture |
