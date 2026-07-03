# Best Practices — Intune Custom Compliance & Configuration Items (Scripted), Government (GCC High) Edition

Practices that keep custom compliance reliable, auditable, and safe **on a GCC High tenant**. The sovereign-cloud items are the ones commercial runbooks miss.

## Sovereign-cloud discipline (GCC High)

- **Bookmark the `*.us` portals and delete the `.com` ones.** `intune.microsoft.us`, `entra.microsoft.us`, `portal.azure.us`, `portal.office365.us`, `security.microsoft.us`. A single commercial bookmark is how a government admin ends up making changes in the wrong (or no) cloud. ([Intune US Gov endpoints](https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints))
- **Every script call uses `-Environment USGov`.** Bake it into the scripts (this solution does) and verify `(Get-MgContext).Environment` is `USGov` before trusting any output. The default connection silently targets commercial and returns nothing for your tenant. ([Connect-MgGraph](https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.authentication/connect-mggraph))
- **Do API recon with PowerShell, not Graph Explorer.** Graph Explorer isn't supported for `graph.microsoft.us`. ([Graph national clouds](https://learn.microsoft.com/en-us/graph/deployments))
- **Never SSL-inspect `*.manage.microsoft.us`.** Microsoft doesn't support it; breaking TLS there causes silent compliance failures. Exempt these hosts in the proxy and document the exemption. ([Intune US Gov endpoints](https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints))
- **Verify feature parity before you rely on anything new.** Government clouds can trail commercial. Confirm the specific custom-compliance/Conditional-Access behavior is live in *your* GCC High tenant rather than assuming commercial docs apply (see `gcc-high-parity-notes.md`).
- **Keep help links government-appropriate.** `MoreInfoUrl` in the JSON and any operator docs should point to internal/US Gov resources users can actually reach.

## Discovery script hygiene

- **Return compressed single-line JSON** — the last line must be `ConvertTo-Json -Compress`. Multi-line output fails grading. ([Create discovery scripts](https://learn.microsoft.com/en-us/intune/intune-service/protect/compliance-custom-script))
- **Stay inside the limits:** script ≤ 1 MB, output ≤ 1 MB, Windows runtime ≤ 10 minutes. Discover only what you grade — don't dump the whole machine.
- **Run as System unless you need user context.** Only enable "run using logged-on credentials" when the setting is genuinely per-user.
- **Choose the right host bitness.** Enable the 64-bit host when your cmdlets/registry paths are 64-bit-only, to avoid WOW6432 redirection surprises.
- **Make discovery read-only.** A discovery script should observe, never change state. Keep enforcement/remediation in a separate, explicitly-gated path.
- **Intune won't lint your script.** Test on representative hardware/OS builds before upload — Intune validates neither syntax nor logic.

## JSON rules design

- **Match keys exactly (case-sensitive)** between script output and `SettingName`. A case difference is a silent failure.
- **Pick the correct `DataType` and `Operator`.** `Version` for version strings (so `GreaterEquals` compares correctly), `Boolean` for true/false, `Int64` for counts. A `String` compare on a version is a classic false pass.
- **Write remediation strings for the end user.** The `RemediationStrings` Title/Description are what the person sees in Company Portal — make them actionable and route them to the government service desk, not a commercial URL.
- **One script, one policy.** Each discovery script binds to exactly one compliance policy and vice-versa — name and scope accordingly.

## Naming, scope, and change control

- **Reuse the `CUSTCOMPG-*` names** consistently across portal objects, JSON, and scripts so the solution is auditable.
- **Apply the `CUSTCOMPG` scope tag to the policy** (the *script* upload workflow doesn't support scope tags; the admin needs the **Default** scope tag to manage scripts). ([Create discovery scripts](https://learn.microsoft.com/en-us/intune/intune-service/protect/compliance-custom-script))
- **Version the script + JSON in source control.** Treat them as code; review changes before republishing.

## Rollout safety

- **Follow Assess → Configure → Pilot → Validate → Expand** with the gates. Never skip Pilot on a government tenant.
- **Start noncompliance actions soft.** Mark-noncompliant + notify with a grace period first; add Conditional Access only after a clean validation window — and test CA with a pilot account so a bad rule can't lock out the fleet.
- **Default to `-WhatIf`.** The remediation and scope-targeting scripts preview by default; only disable `-WhatIf` after reviewing the preview.
- **Expand in waves,** not all at once, watching the report between waves.

## Operations

- **Schedule `CUSTCOMPG-Report.ps1`** for periodic snapshots; investigate any rise in "no result" devices (usually the TLS-inspection symptom).
- **Least privilege.** Read-only scopes for day-to-day reporting; request write scopes only when applying a change.
- **Document the proxy exemptions and endpoint allowlist** so the next operator doesn't re-break TLS on `*.manage.microsoft.us`.
