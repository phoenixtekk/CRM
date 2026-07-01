# Executive Summary — Windows 365 Cloud PC Deployment & Management (Microsoft Intune)

Contractors, BYOD staff, and offshore teams need a corporate Windows desktop, but shipping and
managing a physical laptop for each one is slow, expensive, and hard to secure. **Windows 365**
gives every user a dedicated, always-on Windows desktop streamed from the cloud — joined to your
tenant, secured by the same Intune policies as your physical fleet, and reachable from any device.

This is a complete, **deploy-it-today** package for standing up Windows 365 Enterprise Cloud PCs
with Microsoft Intune, written for an administrator with no prior Cloud PC experience. It turns a
pile of one-off Cloud PCs into a repeatable, governed deployment: provisioning policies that build
desktops by group membership, a controlled image, a network connection you understand, and Intune
configuration, compliance, and security applied to Cloud PCs exactly as they are to laptops.

## What you get
- A plain-language **Solution Overview** of Windows 365 Enterprise — the provisioning-policy model,
  Azure Network Connection (ANC) vs. the Microsoft-hosted network, gallery vs. custom images, and
  how Cloud PCs are managed like physical devices in Intune.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite (licensing,
  Intune, Entra, networking, image, group design, Conditional Access).
- An **Implementation Guide** of precise, click-by-click steps in the required order — licensing and
  groups, the network connection, the image, the provisioning policy, user assignment, Intune
  management of Cloud PCs, securing access, then pilot, validate, and expand.
- Five **PowerShell scripts** for tenant-readiness discovery, Cloud PC health validation, a fleet and
  license-utilization report, safe remediation (reprovision/resize helpers), and a provisioning-target
  group builder.
- **Testing** and **Troubleshooting** guides for a confident rollout.

## What this delivers
A **policy-driven Cloud PC service**: a named provisioning policy that builds a dedicated Windows
desktop for every member of a target group, on a network connection of your choosing, from a known
image, secured by Conditional Access and managed by the same Intune compliance and configuration
profiles as your physical endpoints — proven on a pilot before you scale.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand** — with a pilot gate before production.

## Outcome
Every eligible user with a dedicated, always-on Windows Cloud PC — provisioned by policy, secured and
managed in Intune alongside physical devices, reachable from anywhere — deployable by a single
administrator and validated before fleet rollout.
