# 7. Best Practices — Microsoft Defender for Endpoint Integration (Government / GCC High)

Operating guidance for running the Intune ↔ MDE integration on a **GCC High** tenant. These build on
the implementation and testing guides and assume you have passed the pilot gates.

## Stay on the sovereign portals — always
- **Bookmark the `.us` portals** and delete Commercial bookmarks from admin workstations:
  `security.microsoft.us`, `intune.microsoft.us`, `entra.microsoft.us`, `portal.azure.us`,
  `portal.office365.us`, `login.microsoftonline.us`. A single stray `.com` bookmark is the #1 cause
  of "I don't see the tenant / the feature is missing" confusion on GCC High.
- **Standardize automation on US Gov Graph.** Every script connects with **`-Environment USGov`**;
  never let a runbook default to the Commercial cloud. The included `MDEG-*` scripts do this for you.
- **Use the correct MDE API base URI** in any custom tooling:
  `api-gov.securitycenter.microsoft.us` (GCC High/DoD) or `api-gcc.securitycenter.microsoft.us`
  (GCC) — never the public `api.securitycenter.microsoft.com`.

## Onboarding hygiene
- **Prefer "Auto from connector"** for the EDR onboarding package so devices always register to the
  **US Government** environment. Avoid manually pasted onboarding blobs, which are easy to source
  from the wrong (Commercial) cloud.
- **Patch downlevel devices before onboarding.** Some downlevel Windows 10 builds need a specific KB
  deployed *first* so the sensor points at the Gov environment; onboarding before patching can
  register the device to the wrong environment. Cited: Microsoft — Endpoint versions.
- **For MMA-based downlevel servers,** always choose **Azure US Government** as the Azure Cloud (or
  `OPINSIGHTS_WORKSPACE_AZURE_CLOUD_TYPE=1`). Prefer the modern unified solution where possible.

## Connectivity
- **Use the streamlined Gov/GCC/DoD URL list** where supported to keep the proxy/firewall allow-list
  small; fall back to the standard Gov/GCC/DoD list when a device needs the full set. Never mix in
  the Commercial URL list. Cited: Microsoft — Required connectivity settings.
- **Re-check connectivity after network changes.** A new proxy rule that drops `*.microsoft.us` will
  silently break sensor check-in; `MDEG-Validation.ps1` surfaces stale/unhealthy sensors early.

## Rollout discipline (Assess → Configure → Pilot → Validate → Expand)
- **One population at a time.** Assign onboarding and `CP-Windows-MDE-Risk` to `SG-MDE-Pilot`, then
  to `SG-MDE-Prod-Wave1`, then subsequent waves — re-validating each wave.
- **Start Conditional Access in Report-only.** Observe who *would* be blocked before enforcing
  `CA-Require-Compliant-MDE`, so a misconfigured risk threshold cannot lock users out.
- **Choose the risk threshold deliberately.** Start at **Medium**; move to **Low** only for
  high-assurance scopes after you understand the noise profile in your environment.

## Know your parity — and playbook the gaps
- **Verify feature availability in *your* tenant, not from Commercial docs.** GCC High/DoD lag
  Commercial in parts of analytics, reporting, and integration; some features are absent
  (e.g. **Microsoft Threat Experts**, **enterprise IoT security**), and **Microsoft Secure Score**
  omits some recommendations. Cited: Microsoft — Feature parity with commercial.
- **Write a manual playbook for each gap you depend on.** Where automated investigation/response or a
  reporting surface is unavailable, document the manual detection→triage→response steps your SOC will
  run instead, and **flag "verify for GCC High/DoD"** on any capability you have not personally
  confirmed present.
- **Re-check parity periodically.** US Gov availability changes over time; a feature absent today may
  reach GA later. Revisit `gcc-high-parity-notes.md` against the live Microsoft page each quarter.

## Least privilege & separation
- Operate day-to-day with **Endpoint Security Manager** (Intune) rather than Global Administrator.
- Keep **Conditional Access Administrator** separate and use it deliberately; CA changes affect
  access tenant-wide.
- Apply **scope tags** (`MDEG-Set-ScopeTargeting.ps1`) so regional/mission admins only see their
  own devices and policies.

## Change safety
- **Run remediation with `-WhatIf` first.** `MDEG-Remediation.ps1` and `MDEG-Set-ScopeTargeting.ps1`
  default to `-WhatIf`; review the planned changes, then re-run intentionally to apply.
- **Keep evidence.** Save `MDEG-Report.ps1` output per wave as your onboarding/compliance record for
  audit (CMMC/DoD programs frequently ask for it).

*Sources: Microsoft Learn — "Microsoft Defender for Endpoint for US Government customers"; Intune ↔
Defender integration pages. Verify GCC High / DoD specifics in your tenant.*
