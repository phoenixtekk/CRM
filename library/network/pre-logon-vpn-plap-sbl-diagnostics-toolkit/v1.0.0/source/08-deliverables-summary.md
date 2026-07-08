# Deliverables Summary

Everything included in the **Pre-Logon VPN (PLAP / Start Before Logon) Troubleshooting & Diagnostics
Toolkit**, and how each piece is used. This is a diagnostics product: a reusable, self-guided workflow
plus read-only scripts you keep and run on every pre-logon VPN incident — covering **both** Cisco Start
Before Logon (SBL/PLAP) and the Windows Always On VPN device tunnel.

## Documentation

| Document | What it gives you | When you use it |
|----------|-------------------|-----------------|
| **Solution Overview** (`01-solution-overview.md`) | The two pre-logon mechanisms, their preconditions, the five tools, and the read-only/safe constraint | Read once to understand the stack; refer back when a check mentions a precondition |
| **Requirements** (`02-requirements.md`) | The device access, admin rights, Graph/Intune read access, and vantage points to diagnose, each with Description / Why / Verify / Implement-if-missing | Before an incident — assemble access so you're not gathering it mid-outage |
| **Diagnostic Workflow** (`03-implementation.md`) | The ordered **Collect → Analyze → Remediate → Verify** workflow and the symptom → tool map | The core deliverable — start here during an incident |
| **Testing** (`05-testing.md`) | Pass/fail gates that the toolkit reports a known-good device healthy and a known-bad device's true fault, plus post-fix confirmation | To trust the tool's verdicts, and after a fix |
| **Troubleshooting** (`06-troubleshooting.md`) | The comprehensive symptom → cause → fix matrix for pre-logon VPN across both mechanisms | The heart of the product — during an incident, and for edge cases |
| **Best Practices** (`07-best-practices.md`) | Repeatable triage order, evidence collection, correct assignment scope, least-privilege access, closing the loop | To standardize triage across the team and across incidents |
| **Executive Summary** (`executive-summary.md`) | The problem, what's inside, and the value, for a decision-maker | To brief a stakeholder or justify the toolkit |
| **Global Requirements — Network** (`global-requirements-network.md`) | Category-level prerequisites shared by all Network solutions | Confirm alongside the solution-specific requirements |

## PowerShell scripts (all read-only)

| Script | What it does | Area it covers |
|--------|--------------|----------------|
| **PLAPDX-Collect-Diagnostics.ps1** | The entry-point master collector — snapshots every precondition for **both** mechanisms (OS SKU/build, join type, Secure Client version, `vpnplap64.dll` + PLAP registration, `UseStartBeforeLogon`, the device tunnel + flags, the machine cert) into one console + `-OutFile` report | Both mechanisms |
| **PLAPDX-Check-PlapSbl.ps1** | Focused SBL/PLAP checks with PASS/FAIL per precondition (module installed, DLL present, provider registered, `UseStartBeforeLogon=true`, profile present) and the exact remedy for each FAIL | SBL / PLAP |
| **PLAPDX-Check-DeviceTunnel.ps1** | Focused device-tunnel checks (SKU/join eligible, exactly one device tunnel, IKEv2, machine cert valid, AlwaysOn) with PASS/FAIL + remedy | AOVPN device tunnel |
| **PLAPDX-Check-Certificate.ps1** | Machine-certificate deep-check (present, not expired, Client Auth EKU, chains to a trusted root, private key), optional `-CaThumbprint` to confirm the expected issuing CA | Certificate (both mechanisms) |
| **PLAPDX-Check-Intune.ps1** | Read-only Graph audit — confirms the expected Intune objects exist, are assigned, and flags a device-tunnel profile mis-scoped to a **user** group | Intune objects + scoping |

Every script begins with a standard PURPOSE / HOW TO RUN / EXPECTED RESULTS header. The four
device-side scripts need **no** Graph access (run them **elevated** for full visibility); the Intune
check requires only **read** Graph scopes. None change the device, tenant, or gateway.

## What is intentionally deferred to the gateway vendor

The **VPN head-end / gateway** internals — the Cisco Secure Client profile editor and ASA/FTD config,
the RRAS / third-party IKEv2 gateway config, and which issuing CA the gateway trusts — are **deferred
to the vendor's official documentation**. The toolkit names the exact evidence to read on the gateway
side (did the attempt arrive, the rejection reason, the issuing-CA name to trust) but does not
fabricate vendor menu paths. Remediation of a device-side finding is pointed at the matching
**deployment** product; the toolkit itself stays read-only.

## How the pieces fit together

1. **Prepare** with `02-requirements.md`.
2. **Collect** with `PLAPDX-Collect-Diagnostics.ps1`, then **Analyze** with the focused `Check-*` tool
   the symptom points to (`03-implementation.md`).
3. **Remediate** in the owning plane, then **Verify** by re-running the tools and rebooting.
4. **Confirm** with `05-testing.md`; deep-dive edge cases with `06-troubleshooting.md`.
5. **Standardize** with `07-best-practices.md`.
