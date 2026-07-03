# Executive Summary — Entra ID + ABM Managed Apple ID Auto-Provisioning (Government / GCC High)

## The bottom line

This is the **Government (GCC High)** edition of integrating Microsoft Entra ID with Apple Business
Manager (ABM) for Apple device provisioning. The single most important fact for a decision-maker:
**the Entra ⇄ ABM _federation_ and _SCIM auto-provisioning_ link does not support national clouds
(GCC High / DoD) today.** Apple's documentation states, verbatim, "Integration with national clouds
isn't currently supported," and Microsoft does not offer the ABM provisioning gallery app for the US
Government cloud.

**What this means:** a pure GCC High tenant **cannot** deliver the "sign in to Apple devices with your
Entra work account, auto-created and kept in sync by SCIM" experience the way a Commercial tenant can.
That is a **feature parity gap**, not a portal-URL difference.

**What is delivered instead — and is fully supported:** Apple device management through **Intune
Government** — ABM linked to Intune for **Automated Device Enrollment** and **User Enrollment**, with
Managed Apple IDs created through ABM's own tooling (manual, SFTP, or ABM API). This achieves the
device-management outcome government teams need, on a supported path, using the sovereign `*.us`
portals and the US Gov Microsoft Graph endpoint.

## Why this edition exists

Commercial implementation steps **silently fail** on GCC High: the admin URLs differ (`*.us`), the
tooling must be told it is US Gov (`Connect-MgGraph -Environment USGov`), the licensing is Government
SKUs, and — most importantly — the headline federation/SCIM capability is unavailable. A government
administrator following a Commercial guide would waste effort configuring a flow that cannot complete.
This edition sets expectations correctly and guides the supported path.

## What you get

- A **decision gate** that tells you, before any spend, whether your requirement is achievable on
  GCC High today or depends on the unsupported federation/SCIM link.
- Ordered, novice-friendly **Assess → Configure → Pilot → Validate → Expand** steps using the
  sovereign portals, with GCC-High caveats called out where they matter.
- **Five PowerShell scripts** (discovery, validation, reporting, safe remediation, scope targeting)
  that connect to `graph.microsoft.us` via `-Environment USGov`.
- A **cited parity reference**, **pass/fail testing gates**, and **GCC-High-specific troubleshooting**.

## The risk it removes

Deploying with Commercial assumptions on a government tenant leads to failed enrollments,
misconfigured identity, and — worst of all — stakeholders expecting a capability the sovereign cloud
does not offer. This edition delivers a **correct, supported, pilot-proven** configuration and a
**documented parity gap**, so the outcome is right the first time and no one is surprised.

_Sovereign-cloud capabilities change. The federation limitation is quoted from Apple's current
documentation; re-verify the cited Apple and Microsoft pages (see `gcc-high-parity-notes.md`) before
implementation._
