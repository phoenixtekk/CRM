# Solution Overview — Azure Virtual Desktop Remote Access (Government / Azure Government · GCC High)

This is the **Government (Azure Government / GCC High) edition** of the Azure Virtual Desktop (AVD) Remote Access solution. It publishes Windows desktops and applications from session hosts running in **Azure Government** and delivers them to **Windows and macOS clients** — authored end to end for the US sovereign cloud, using the correct `*.us` admin portals, US Government service endpoints, and the identity model that a GCC High / Azure Government tenant actually supports.

The goal is a government tenant configured **correctly the first time** — not with Commercial steps that silently fail because the portal URL, the client feed URL, or a feature simply is not the same in the sovereign cloud.

> **Naming convention (used throughout):** every object you create is named `<Purpose> – <Scope> – <Stage>` and reused verbatim. Example: `AVD Host Pool – Finance – Pilot`, `AVD Workspace – Finance – Prod`, `AVD Users – Finance – Pilot`.

---

## What this solution delivers

- A **host pool**, **workspace**, and **application group** deployed in Azure Government, published to a named group of pilot users first, then expanded.
- **Session hosts** (Windows 11 / Windows 10 Enterprise multi-session, or single-session) joined per your chosen identity model (Microsoft Entra join or AD DS / Microsoft Entra Domain Services).
- **Client access from Windows App / Remote Desktop client on Windows and macOS**, subscribed to the **Azure Government feed URL** — not the Commercial one.
- **Five PowerShell scripts** — Discovery, Validation, Report, Remediation (default `-WhatIf`), and Set-ScopeTargeting — all connecting to **US Gov** Azure and Microsoft Graph endpoints (`-Environment AzureUSGovernment` / `USGov`).
- A **Commercial-vs-Azure Government parity reference** (`gcc-high-parity-notes.md`) so you know, before you start, which capabilities differ or lag in the sovereign cloud.

---

## Commercial vs Azure Government — what's different

AVD is a single product, but the sovereign cloud is **not the Commercial portal with a different sign-in**. The control plane, the admin portals, the client feed URLs, and the session-host service endpoints are all distinct. If you follow a Commercial runbook verbatim on a GCC High tenant, the most common outcome is that clients subscribe to the wrong feed, or session hosts fail agent registration because a `.us` endpoint is blocked. The table below is the short version; the fully cited detail is in `gcc-high-parity-notes.md`.

| Area | Commercial | Azure Government / GCC High |
| --- | --- | --- |
| Azure portal | `portal.azure.com` | **`portal.azure.us`** |
| Microsoft 365 / Entra admin | `admin.microsoft.com`, `entra.microsoft.com` | **`portal.office365.us`**, **`entra.microsoft.us`** |
| Sign-in / authentication endpoint | `login.microsoftonline.com` | **`login.microsoftonline.us`** |
| AVD client **feed URL** (subscribe) | `https://rdweb.wvd.microsoft.com` (or `.../api/arm/feeddiscovery`) | **`https://rdweb.wvd.azure.us`** (feed discovery: `https://rdweb.wvd.azure.us/api/arm/feeddiscovery?aadtenant=<yourdomain>`) |
| AVD **web client** | `https://client.wvd.microsoft.com/arm/webclient` | **`https://rdweb.wvd.azure.us/arm/webclient/index.html`** |
| Session-host service traffic FQDN | `*.wvd.microsoft.com` | **`*.wvd.azure.us`** |
| `ms-avd:` URI `env` value | `avdarm` | **`usgov`** |
| PowerShell / CLI environment | `AzureCloud` (default) | **`AzureUSGovernment`** (`Connect-AzAccount -Environment AzureUSGovernment`; Graph `Connect-MgGraph -Environment USGov`) |
| Feature availability | New features land here first | **Parity lags** — features release in Commercial first and arrive in Gov later, in preview, or not at all. Verify each feature for Azure Government before you rely on it. |

**The single most important takeaway:** point admins at `portal.azure.us` and point clients at `rdweb.wvd.azure.us`. Those two substitutions prevent the majority of "it works in the demo tenant but not in ours" failures.

Sources: AVD is available in sovereign clouds including Azure for US Government ([Microsoft Learn — Prerequisites](https://learn.microsoft.com/en-us/azure/virtual-desktop/prerequisites)); Gov feed/web-client and session-host FQDNs ([Required FQDNs and endpoints — Azure for US Government tab](https://learn.microsoft.com/en-us/azure/virtual-desktop/safe-url-list?tabs=azure-for-us-government)); `env=usgov` URI value ([URI schemes](https://learn.microsoft.com/en-us/azure/virtual-desktop/uri-scheme)).

---

## The deployment model — Assess → Configure → Pilot → Validate → Expand

Every step in the Implementation Guide fits this model, and each stage has an **exit gate** — you do not proceed until the gate passes.

1. **Assess** — Confirm you are on a GCC High / Azure Government tenant, the licensing entitles AVD, the `Microsoft.DesktopVirtualization` resource provider is registered, roles are in place, and the required `*.us` endpoints are reachable. *(Gate: Discovery script reports all green; requirements in `02-requirements.md` all verified.)*
2. **Configure** — Create the named host pool, workspace, and application group in `portal.azure.us`; deploy session hosts on the chosen identity model; assign the pilot user group. *(Gate: resources exist with the agreed names; session hosts show **Available**.)*
3. **Pilot** — Publish to `AVD Users – <Scope> – Pilot` only; those users subscribe to the **Gov feed URL** from Windows App / Remote Desktop client on Windows and macOS. *(Gate: every pilot user connects to a desktop and launches a published app.)*
4. **Validate** — Run the Validation and Report scripts; confirm connectivity, profile behavior, and performance against the pass/fail criteria in `05-testing.md`. *(Gate: all test cases pass; no open Sev-1/Sev-2 issues.)*
5. **Expand** — Use `AVDG-Set-ScopeTargeting.ps1` to grow the assignment group in controlled waves, re-validating after each wave. *(Gate: each wave validated before the next is added.)*

---

## Who this is for

Government, defense, and regulated organizations (and their MSPs / integrators) standing up or correcting AVD on a **GCC High or Azure Government** tenant, who need the sovereign-cloud specifics called out rather than discovered the hard way. Novice-friendly, click-to-implement, with full Azure Government navigation at every step.

## What you need before you start

See `02-requirements.md` for the full, verifiable prerequisite list (layered on the Azure Solutions global requirements in `global-requirements-azure-solutions.md`). At a glance: a GCC High / Azure Government tenant, Gov-appropriate licensing (e.g., Microsoft 365 G3/G5 or Windows Enterprise E3/E5 Gov entitlement for AVD), the correct Azure roles, `portal.azure.us` access, and the `*.us` / `*.usgovcloudapi.net` endpoints allowed through your filtering.
