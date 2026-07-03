# Best Practices — Hybrid Identity (Government / GCC High)

These practices are specific to running hybrid identity on a **GCC High** tenant. General identity
hygiene still applies; the emphasis here is on the sovereign-cloud differences that cause the most
avoidable incidents.

## Sovereign-cloud discipline

- **Bookmark the `*.us` portals and use only them.** `entra.microsoft.us`, `portal.azure.us`,
  `portal.office365.us`, `security.microsoft.us`, `compliance.microsoft.us` /`purview.microsoft.us`,
  and sign-in at `login.microsoftonline.us`. A Commercial bookmark is the #1 cause of "I configured
  it but nothing changed" in GCC High.
- **Always pass `-Environment USGov`** (or `USGovDoD`) to `Connect-MgGraph`. Bake it into every
  script and runbook so no one ever silently hits Commercial `graph.microsoft.com`.
- **Confirm cloud selection before the first sync**, not after. Verify `*.windows.net` is open (auto
  detection) or `AzureInstance=4` is set with the Custom install path
  ([Sync service instances](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/reference-connect-instances#microsoft-azure-government)).

## Endpoint & network hygiene

- **Pull the GCC High endpoint list from the web service, not a copied table.** The authoritative,
  monthly-updated source is `https://endpoints.office.com/endpoints/USGOVGCCHigh`. New URLs/IPs are
  published 30 days ahead — subscribe to the change log.
- **Open the Gov sync URLs explicitly:** `*.microsoftonline.us`, `*.gov.us.microsoftonline.com`,
  `*.windows.net`, `graph.microsoft.us`, `*.auth.microsoft.us`, plus CRLs
  ([GCC High endpoints](https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints)).
- **Don't assume ExpressRoute covers a feature.** Some Gov features (e.g. certain compliance export
  paths) depend on Azure Blob Storage and need separate connectivity — verify per feature.

## Identity-plane safety

- **Two cloud-only break-glass accounts** on `<yourtenant>.onmicrosoft.us`, excluded from CA/MFA,
  credentials stored offline, sign-ins monitored. Test them (T8) on a schedule.
- **Stage every change**: pilot OU/group first, then group-based waves. Never flip the whole
  directory into sync at once.
- **Respect the deletion threshold.** If an export stages a large delete, do not confirm it —
  investigate filtering first (T6).
- **Prefer Password Hash Sync as the default** sign-in method for resilience; it survives on-prem
  outages better than PTA/Federation. Choose PTA/Federation only for a hard requirement, and always
  run **two** agents / AD FS nodes for failover.

## Feature-parity awareness

- **Design around the Gov gaps** (see `gcc-high-parity-notes.md`): **My Staff** and **Entra threat
  intelligence** risk detection are not available; **HR-driven provisioning** is partial; Enterprise
  State Roaming shared-device sign-out is not available
  ([feature availability](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability)).
- **Flag "verify for GCC High" items in your own runbook** and validate them in a lab tenant before
  production — Gov feature rollout can lag Commercial.

## Operations & documentation

- **Run `HYBIDG-Report.ps1` on a schedule** and after every change; keep the output with your change
  record.
- **Keep Connect Health on** (available in Azure for US Government) for continuous sync/agent
  visibility.
- **Record exact object names** (`OU=HybridPilot`, `sg-HybridIdentity-InScope`, `SVR-ENTRACONNECT01`,
  the two break-glass UPNs) in your runbook so scripts and troubleshooting stay unambiguous.
- **Patch the Connect host and agents** on a cadence; keep Entra Connect current so cloud
  auto-detection and Gov endpoint changes are supported.

---
The deployment model (all solutions): Assess → Configure → Pilot → Validate → Expand.
