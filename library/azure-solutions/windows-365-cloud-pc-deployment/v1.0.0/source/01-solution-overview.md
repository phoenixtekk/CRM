# 1. Solution Overview — Windows 365 Cloud PC Deployment & Management

## What Windows 365 is
Windows 365 is Microsoft's cloud service that gives each user a dedicated, always-on **Cloud PC** — a
personal Windows 10/11 desktop running in Microsoft's cloud and streamed to any device through a
browser or the Windows App. This solution uses **Windows 365 Enterprise**, which is managed through
**Microsoft Intune**: Cloud PCs are built by a **provisioning policy**, join your tenant, and are then
governed by the same Intune compliance, configuration, and app policies as your physical fleet.

> Windows 365 Enterprise (Intune-managed, what this solution uses) is different from Windows 365
> Business (a lightweight, self-service SKU capped at ~300 seats with no Intune-driven provisioning).
> Everything below assumes **Enterprise**.

## How it works
1. A **provisioning policy** defines how Cloud PCs are built — the join type, the network, the image,
   and the language/region — and is **assigned to a user group**. Every member of that group is
   automatically provisioned a Cloud PC (one per license).
2. The Cloud PC **joins your tenant** — either **Microsoft Entra join** (cloud-only) or **Microsoft
   Entra hybrid join** (line-of-sight to on-prem Active Directory), per the policy.
3. Networking is one of two models: the **Microsoft-hosted network** (Microsoft owns the plumbing,
   zero Azure footprint — the simplest path) or an **Azure Network Connection (ANC)** that routes
   Cloud PC traffic through *your* Azure virtual network (needed for hybrid join or on-prem reach).
4. The Cloud PC is built from an **image** — a Microsoft **gallery image** (Windows + Microsoft 365
   Apps, ready to go) or a **custom image** you capture in Azure with your baseline pre-installed.
5. Once provisioned, the Cloud PC **enrolls in Intune automatically** and receives your compliance,
   configuration, and app-deployment policies — managed identically to a physical device.
6. Users connect from **windows365.microsoft.com**, the **Windows App**, or an RDP client; access is
   secured with **Conditional Access**.

## What you can control
- **Who gets a Cloud PC** — by assigning the provisioning policy to a user group (license-gated).
- **Join type** — Microsoft Entra join or Microsoft Entra hybrid join.
- **Network** — Microsoft-hosted network or your own Azure Network Connection.
- **Image** — gallery or custom; updated centrally and re-used across policies.
- **Size / SKU** — vCPU / RAM / storage per license (e.g. 2vCPU/8GB/128GB), changeable via **resize**.
- **Management** — full Intune compliance, configuration, security baselines, and app deployment.
- **Lifecycle** — **reprovision** (rebuild to a clean image), **resize**, **restart**, and grace-period
  cleanup when a license is removed.

## Benefits
- **Desktop in minutes** — provisioned by policy on group membership; no laptop to ship or image.
- **Managed like metal** — the same Intune policies and reports cover Cloud PCs and physical devices.
- **Secure by default** — tenant-joined, Conditional Access-gated, compliance-enforced.
- **Reach anywhere** — any device with a browser or the Windows App becomes a corporate desktop.
- **Predictable cost** — a fixed per-user license instead of hardware procurement and refresh.

## Limitations (be honest with buyers)
- Each Cloud PC needs a **Windows 365 Enterprise license** *plus* the user holding **Intune + Entra
  ID P1** (the eligibility prerequisites) — license math is per user, not per device pool.
- **Hybrid join** and on-prem resource access require an **Azure Network Connection** (your Azure vNet,
  with the associated Azure cost and network design) — the Microsoft-hosted network cannot reach on-prem.
- A Cloud PC is **dedicated and personal** (one user); Windows 365 is not a pooled/multi-session
  service (that is Azure Virtual Desktop).
- **Custom images** are captured and stored in Azure and must be maintained (patched/re-captured) over time.
- GPU and very high-end workloads have limited SKU options; size to the workload.

## The standard deployment model
> **Configure licensing + groups → create the network connection → prepare the image → create the
> provisioning policy → assign to users → apply Intune management + security → validate on a pilot →
> expand to production.** Model: **Assess → Configure → Pilot → Validate → Expand**, with a pilot gate
> before production. This is the repeatable way to deliver Cloud PCs at scale.
