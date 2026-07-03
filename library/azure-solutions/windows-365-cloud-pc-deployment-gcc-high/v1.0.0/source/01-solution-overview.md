# 1. Solution Overview — Windows 365 Cloud PC Deployment & Management (Government / GCC High)

## What Windows 365 Government is
Windows 365 is Microsoft's cloud service that gives each user a dedicated, always-on **Cloud PC** —
a personal Windows 10/11 desktop running in Microsoft's cloud and streamed to any device through a
browser or the Windows App. **Windows 365 Government** is the edition for US government agencies,
public entities, and contractors that qualify for the **US sovereign clouds (GCC and GCC High)**; the
Cloud PCs and underlying resources are hosted in **US government data centers** and pass the audits
required for those clouds. This solution is the **GCC High** edition — it uses **Windows 365
Enterprise (Government)** managed through **Microsoft Intune (government cloud)**: Cloud PCs are built
by a **provisioning policy**, join your tenant, and are governed by the same Intune compliance,
configuration, and app policies as your physical fleet. [What is Windows 365 Government, Microsoft
Learn.]

> Windows 365 Enterprise (Intune-managed, what this solution uses) is different from Windows 365
> Business (a lightweight, self-service SKU). Everything below assumes **Enterprise (Government)** on
> a **GCC High** tenant.

## Commercial vs GCC High — what's different
This is the section that keeps a government deployment from silently failing. **GCC High is not the
Commercial portal with a different sign-in** — the sovereign-cloud admin and end-user URLs differ,
and several Windows 365 / Intune capabilities lag or are absent. Two things to internalize:

1. **GCC ≠ GCC High.** In **GCC**, Cloud PCs run in Azure Government but the admin and end-user
   endpoints stay on the **commercial `.com`** domain. In **GCC High**, the whole experience is
   sovereign and moves to the **`.us`** domain. **This package is authored for GCC High.** [Set up
   tenants for Windows 365 Government, Microsoft Learn.]
2. **Use the `.us` portals and endpoints throughout** (full map in `gcc-high-parity-notes.md`):

   | Purpose | Commercial | **GCC High (use this)** |
   |---|---|---|
   | Sign-in (auth) | `login.microsoftonline.com` | `login.microsoftonline.us` |
   | Microsoft 365 admin | `admin.microsoft.com` | `admin.microsoft.us` |
   | Microsoft Intune admin | `intune.microsoft.com` | `intune.microsoft.us` |
   | Microsoft Entra admin | `entra.microsoft.com` | `entra.microsoft.us` |
   | Azure portal | `portal.azure.com` | `portal.azure.us` |
   | Windows 365 end-user | `windows365.microsoft.com` | `windows365.microsoft.us` |
   | Microsoft Graph | `graph.microsoft.com` | `graph.microsoft.us` (`-Environment USGov`) |

3. **Plan around the parity gaps.** In GCC High, do **not** design the deployment to depend on:
   the **Windows 365 Security baseline**, **GPU Cloud PCs**, **Windows 365 Boot / Switch / Reserve**,
   the **new Teams client / multimedia redirection**, a **W365 monitoring dashboard / system alerts**,
   **Cloud PC audit logs in Log Analytics**, **Copilot in Intune**, **cross-region DR**, or Intune's
   **Windows Autopilot, Remote Help, Windows Autopatch / update rings, or Windows Backup for
   Organizations** — none of these are available in GCC High today. Harden Cloud PCs with an ordinary
   Intune **Settings catalog** profile + compliance policy instead of the W365 baseline. Full cited
   list in `gcc-high-parity-notes.md`. [What is Windows 365 Government; Microsoft Intune Government
   Service overview, Microsoft Learn.]

Everything **else** — the provisioning-policy model, join types, network models, images, lifecycle,
and Intune management — **works the same as Commercial**. Only the portals, endpoints, and the gaps
above change.

## How it works (GCC High)
1. A **provisioning policy** defines how Cloud PCs are built — the join type, the network, the image,
   and the language/region — and is **assigned to a user group**. Every licensed member of that group
   is automatically provisioned a Cloud PC (one per license). All admin work is in the **government**
   Intune admin center at **`https://intune.microsoft.us`**.
2. The Cloud PC **joins your tenant** — either **Microsoft Entra join** (cloud-only) or **Microsoft
   Entra hybrid join** (line-of-sight to on-prem AD), per the policy.
3. Networking is one of two models: the **Microsoft-hosted network** (Microsoft owns the plumbing,
   zero Azure footprint — the simplest path, and the recommended GCC High starting point) or an
   **Azure Network Connection (ANC)** that routes Cloud PC traffic through *your* Azure Government
   virtual network (needed for hybrid join or on-prem reach). **Multi-Region Selection** (US
   Government region group) is available on the Microsoft-hosted network for resiliency. [Announcing
   Multi-Region Selection for Windows 365 in Government Community Cloud, Microsoft.]
4. The Cloud PC is built from an **image** — a Microsoft **gallery image** (Windows + Microsoft 365
   Apps, ready to go) or a **custom image** you maintain. In GCC High, **verify the current
   GCC-High-specific custom-image / ANC setup procedure** before building either — the published GCC
   Setup Tool / tenant-mapping flow is documented for GCC and Microsoft states it does **not** apply
   to GCC High. [Set up tenants for Windows 365 Government, Microsoft Learn.]
5. Once provisioned, the Cloud PC **enrolls in the government Intune instance automatically** and
   receives your compliance, configuration, and app-deployment policies — managed identically to a
   physical device.
6. Users connect from **`https://windows365.microsoft.us`**, the **Windows App**, or an RDP client;
   access is secured with **Conditional Access** in the government Entra admin center.

## What you can control
- **Who gets a Cloud PC** — by assigning the provisioning policy to a user group (license-gated).
- **Join type** — Microsoft Entra join or Microsoft Entra hybrid join.
- **Network** — Microsoft-hosted network (with US Government region group) or your own Azure
  Government Network Connection.
- **Image** — gallery or custom; updated centrally and re-used across policies.
- **Size / SKU** — vCPU / RAM / storage per license (e.g. 2vCPU/8GB/128GB), changeable via **resize**.
  (Note: **GPU SKUs are not available in GCC High.**)
- **Management** — full Intune compliance, configuration, and app deployment (build hardening from a
  Settings catalog profile, since the **W365 Security baseline is unavailable in GCC High**).
- **Lifecycle** — **reprovision** (rebuild to a clean image), **resize**, **restart**, and grace-period
  cleanup when a license is removed.

## Benefits
- **Sovereign desktop in minutes** — provisioned by policy on group membership; hosted in US
  government data centers meeting FedRAMP High / ITAR / DFARS expectations. [What is Windows 365
  Government, Microsoft.]
- **Managed like metal** — the same government Intune policies and reports cover Cloud PCs and
  physical devices.
- **Secure by default** — tenant-joined, Conditional Access-gated, compliance-enforced, on `.us`
  sovereign endpoints.
- **Reach anywhere** — any device with a browser or the Windows App becomes a corporate desktop via
  `windows365.microsoft.us`.
- **Predictable cost** — a fixed per-user license instead of hardware procurement and refresh.

## Limitations (be honest with buyers)
- Each Cloud PC needs a **Windows 365 Enterprise (Government) license** *plus* the user holding
  **Intune + Entra ID P1** (the eligibility prerequisites) — license math is per user, not per pool.
- **Hybrid join** and on-prem resource access require an **Azure Network Connection** in **Azure
  Government** (with associated Azure cost and network design) — the Microsoft-hosted network cannot
  reach on-prem.
- A Cloud PC is **dedicated and personal** (one user); Windows 365 is not a pooled/multi-session
  service (that is Azure Virtual Desktop — and AVD multi-session is itself not an Intune-managed
  feature in GCC High).
- **GCC High parity gaps** (see the section above and `gcc-high-parity-notes.md`) remove several
  Commercial conveniences — plan without them.
- **Custom images / ANC** must follow the **GCC-High-specific** procedure — **verify for GCC High**
  before relying on the GCC Setup Tool flow.

## The standard deployment model
> **Configure licensing + groups → (verify GCC-High ANC/image setup if used) → create the
> provisioning policy → assign to users → apply Intune management + security → validate on a pilot →
> expand to production.** Model: **Assess → Configure → Pilot → Validate → Expand**, with a pilot gate
> before production. This is the repeatable way to deliver Cloud PCs at scale on GCC High.
