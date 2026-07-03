# Executive Summary — Secure Mobile Access to SharePoint Online under MAM (Government / GCC High)

**White-label · Intune Solutions · US Sovereign Cloud (GCC High)**

Government staff want to open SharePoint sites and files from their phones — often on **personal
(BYO) devices** you cannot fully manage. The risk is not the reading; it is the **leaving**: a
document copied into a personal note-taking app, saved to a consumer cloud, or forwarded from an
unmanaged mail client. This solution lets people work from mobile **without enrolling the whole
device**, by wrapping SharePoint access in **Intune App Protection Policies (MAM/APP)** and gating
sign-in with **Conditional Access** so that only the approved, protected Microsoft mobile apps can
reach SharePoint Online — and corporate data cannot escape them.

This is the **Government (GCC High) edition**. A GCC High tenant is a **separate US sovereign cloud**.
It uses different admin portals (`intune.microsoft.us`, `entra.microsoft.us`, `portal.azure.us`,
`portal.office365.us`), a different sign-in endpoint (`login.microsoftonline.us`), a different
Microsoft Graph endpoint (`graph.microsoft.us`, reached in PowerShell with
`Connect-MgGraph -Environment USGov`), and SharePoint tenants on **`*.sharepoint.us`** rather than
`*.sharepoint.com`. Some capabilities also lag, are limited, or are **absent** versus Commercial.
Running Commercial steps on a GCC High tenant sends you to the wrong URLs and to features that
silently do not exist. This package delivers the solution for the sovereign cloud with the **correct
portals and endpoints** and the **Commercial-vs-GCC-High parity gaps called out** at the step where
they matter.

## What you get
- A plain-language **Solution Overview** of how MAM + Conditional Access protect mobile SharePoint
  access, including an explicit **Commercial vs GCC High — what's different** section.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite, on the `*.us`
  endpoints.
- An **Implementation Guide** of precise, click-by-click steps in the required order — on the GCC
  High portals, piloted in Report-only first, with parity caveats inline.
- Five **PowerShell scripts** (discovery, validation, reporting, safe remediation, and scope
  targeting) — all connecting to **US Gov Graph** (`-Environment USGov`).
- A **GCC High Parity Notes** reference plus **Testing** and **Troubleshooting** guides for a
  confident, lockout-free rollout.

## What this delivers
A working, enforced posture on GCC High: staff open SharePoint Online **only** in the approved
Microsoft mobile apps (**SharePoint**, **OneDrive**, **Office/Microsoft 365**, **Edge**, **Teams**,
**Outlook**), those apps carry an **App Protection Policy** (PIN, encryption, block copy/paste and
"Save As" to unmanaged locations, selective wipe), and **Conditional Access requires the app
protection policy** before SharePoint will serve data on iOS or Android — piloted in Report-only
mode before enforcement, with break-glass accounts excluded, and GCC-High-specific gaps (e.g.
SharePoint's **Graph-dependent mobile features are disabled in GCC High**) handled up front.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Secure mobile access to SharePoint Online under MAM deployed **correctly on GCC High** — right
portals, right endpoints, parity gaps handled — so staff stay productive on their phones while
corporate data cannot leak out of the managed apps, proven on a pilot before you scale.
