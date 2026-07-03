# GCC High Parity Notes — Entra ID + Apple Business Manager Managed Apple ID Auto-Provisioning

This reference records, with sources, exactly how the US sovereign cloud (GCC High) differs from
Commercial for this solution. Every claim is either cited to a Microsoft or Apple document or is
explicitly flagged **verify for GCC High** where public documentation does not confirm it. Nothing
here is invented. Read this before the implementation guide — the headline finding changes the shape
of the whole deployment.

> Terminology: "national cloud" is the umbrella Microsoft/Apple use for the US sovereign
> environments (GCC High and DoD) and 21Vianet (China). GCC High is a national cloud.

---

## Headline finding — the ABM ⇄ Entra federation link does NOT support national clouds

**Apple states, in the Apple Business / Apple Business Manager User Guide, that "Integration with
national clouds isn't currently supported."** The Entra ID federation and SCIM directory-sync
integration is built against the **Commercial** Entra OpenID Connect global service at
`login.microsoftonline.com` — not the sovereign endpoint `login.microsoftonline.us`.

- Source (Apple): *Use federated authentication with Microsoft Entra ID in Apple Business* —
  https://support.apple.com/guide/business/federated-authentication-microsoft-entra-axm8c1cac980/web
  (quote: "Integration with national clouds isn't currently supported.")
- Source (Apple): *Use federated authentication with Microsoft Entra ID in Apple Business Manager* —
  https://support.apple.com/guide/apple-business-manager/federated-authentication-microsoft-entra-axm8c1cac980/web

**What this means concretely.** A **pure GCC High tenant** (users only in the sovereign cloud, signing
in at `login.microsoftonline.us`) **cannot, today, complete the ABM Managed-Apple-ID federation +
SCIM auto-provisioning flow** the way a Commercial tenant does. The federation consent screen and the
SCIM provisioning connector expect the Commercial global endpoint. This is a **feature parity gap**,
not a portal-URL difference — it is the single most important thing to understand before quoting or
scheduling this work for a government tenant.

## Corroborating Microsoft-side gap — gallery provisioning app not offered in US Gov cloud

Microsoft's own guidance indicates the **gallery application does not support provisioning in US
Government or 21Vianet (China) clouds**, even though the underlying SCIM 2.0 APIs are generally
available in the US Gov cloud. So the "Apple Business Manager" provisioning connector you would add
from the Commercial Enterprise Applications gallery is **not the same offering** in a GCC High
Enterprise Applications blade.

- Source (Microsoft): *Apple Business Manager — user provisioning tutorial* (Entra SaaS apps) —
  https://learn.microsoft.com/en-us/entra/identity/saas-apps/apple-business-manager-provision-tutorial
- Source (Microsoft): SCIM 2.0 APIs general availability in US Gov cloud — *Microsoft Entra releases
  and announcements* — https://learn.microsoft.com/en-us/entra/fundamentals/whats-new
- Note: gallery-app provisioning not supported in US Government / 21Vianet clouds is called out in
  Microsoft provisioning documentation. **Verify for GCC High** against your tenant's live Enterprise
  Applications gallery, because gallery availability changes over time.

## What DOES work in GCC High — the supported alternative

The device-management half of the story is fully supported in GCC High. **Apple Automated Device
Enrollment (ADE, formerly DEP) and Apple User Enrollment via Apple Business Manager linked to
Microsoft Intune Government are supported in GCC High.**

- Source (Microsoft): *Microsoft Intune Government Service overview* —
  https://learn.microsoft.com/en-us/mem/intune/fundamentals/intune-govt-service-description
- Source (Microsoft): *Network endpoints for US government deployments (Intune)* —
  https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints
- Source (Microsoft): *iOS/iPadOS device enrollment guide for Microsoft Intune* —
  https://learn.microsoft.com/en-us/intune/device-enrollment/apple/guide-ios-ipados

The distinction to hold onto:

| Capability | Commercial | GCC High |
| --- | --- | --- |
| ABM ⇄ Entra **federation** (sign in to Apple with work credentials) | Supported | **Not supported** (national clouds excluded — Apple) |
| ABM ⇄ Entra **SCIM auto-provisioning** of Managed Apple IDs | Supported (gallery app) | **Not supported / verify** (gallery app not offered in US Gov) |
| ABM ⇄ Intune **ADE / User Enrollment** (MDM token, device push) | Supported | **Supported** (Intune Government) |
| Managed Apple IDs created **manually or via ABM SFTP/API** | Supported | Supported (ABM is not a sovereign service; independent of Entra cloud) |

> ABM itself is a single global Apple service — it is **not** a US-sovereign product and has no `.us`
> equivalent. The sovereign constraint lives entirely on the **Entra federation/SCIM link into ABM**,
> which is what this solution's title covers. That link is the part that is gated in GCC High.

## Sovereign endpoint map (use these, not the Commercial URLs)

For every step that is supported in GCC High, use the sovereign admin portals and Graph endpoints.
These URL mappings are documented by Microsoft.

| Purpose | Commercial | GCC High (use this) |
| --- | --- | --- |
| Entra admin center | entra.microsoft.com | entra.microsoft.us |
| Azure portal | portal.azure.com | portal.azure.us |
| Microsoft 365 admin | admin.microsoft.com | portal.office365.us |
| Intune / Endpoint admin | intune.microsoft.com / endpoint.microsoft.com | endpoint.microsoft.us |
| Defender portal | security.microsoft.com | security.microsoft.us |
| Purview / Compliance | compliance.microsoft.com | compliance.microsoft.us |
| Sign-in authority | login.microsoftonline.com | login.microsoftonline.us |
| Microsoft Graph | graph.microsoft.com | graph.microsoft.us |

- Source (Microsoft): *Microsoft Graph national cloud deployments* —
  https://learn.microsoft.com/en-us/graph/deployments
- Source (Microsoft): *Connect-MgGraph* reference (the `-Environment USGov` parameter maps to
  `graph.microsoft.us`) —
  https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.authentication/connect-mggraph

## PowerShell / Microsoft Graph in GCC High

All scripts in this solution connect to the **US Gov** Graph endpoint. In the Microsoft Graph
PowerShell SDK this is done with `Connect-MgGraph -Environment USGov`, which targets
`graph.microsoft.us`. Omitting `-Environment USGov` silently authenticates against the Commercial
endpoint and fails for a GCC High tenant with what looks like an auth error.

- Source (Microsoft): *Connect-MgGraph* —
  https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.authentication/connect-mggraph

## Items flagged "verify for GCC High" (not confirmed in public docs at authoring time)

1. Whether Apple has added, or will add, national-cloud support for Entra federation/SCIM after this
   document's date — Apple's wording is "isn't *currently* supported," which implies it may change.
   **Re-check the Apple federated-authentication page before quoting the work.**
2. Whether an **"Apple Business Manager" provisioning gallery app** appears in your specific GCC High
   Enterprise Applications gallery — availability varies by tenant and changes over time. Confirm
   live in `entra.microsoft.us`.
3. Whether a **hybrid identity** design (a companion Commercial/GCC tenant used only for the ABM
   federation, with GCC High used for everything else) is permitted under your organization's
   compliance boundary (CMMC/ITAR/DFARS). This is an **architecture and compliance decision**, not a
   documented Microsoft feature — treat it as an option to evaluate with your security team, not a
   supported Microsoft path.

## Bottom line for a government reader

- If your requirement is **"sign in to Apple devices with GCC High work credentials via Entra
  federation, auto-provisioned by SCIM"** — that specific path is **not supported today** by Apple
  for national clouds. Do not attempt to force the Commercial flow against `login.microsoftonline.us`;
  it will not complete.
- If your requirement is **"manage Apple devices with Intune Government using ABM ADE/User
  Enrollment, with Managed Apple IDs provisioned by ABM's own tooling"** — that **is** supported in
  GCC High and is the path this solution guides you through, with the federation/SCIM step called out
  as a Commercial-only capability to evaluate separately.

_Sources are Microsoft Learn and Apple Support pages current as of the authoring date; sovereign-cloud
capabilities change — re-verify the cited pages before implementation._
