# Deliverables Summary

Everything included in the **Cisco ISE VPN + Intune Troubleshooting & Diagnostics Toolkit**, and how each piece is used. This is a diagnostics product: a reusable, self-guided playbook plus read-only scripts you keep and run on every incident.

## Documentation

| Document | What it gives you | When you use it |
|----------|-------------------|-----------------|
| **Solution Overview** (`01-solution-overview.md`) | The full Cisco-ISE-VPN + Intune signal path and the four-layer model behind the root-cause tree | Read once to understand the stack; refer back when a branch mentions a layer |
| **Requirements** (`02-requirements.md`) | The read access, logs, and vantage points to diagnose, each with Description / Why / Verify / Implement-if-missing | Before an incident — assemble access so you're not gathering it mid-outage |
| **Diagnostic Playbook** (`03-implementation.md`) | The root-cause decision tree by symptom; each branch names the layer it isolates, the exact checks, and the typical fix | The core deliverable — start here during an incident |
| **Testing** (`05-testing.md`) | Pass/fail gates mapping one-to-one to the tree's branches, plus an end-to-end confirmation | After a fix — prove the layer cleared and the whole path is healthy |
| **Troubleshooting** (`06-troubleshooting.md`) | Deeper edge cases and the Cisco escalation evidence checklist | When a branch doesn't resolve cleanly, or the fault is inside Cisco's stack |
| **Best Practices** (`07-best-practices.md`) | Repeatable triage order, evidence collection, least-privilege access, clean escalation, closing the loop | To standardize triage across the team and across incidents |
| **Executive Summary** (`executive-summary.md`) | The problem, what's inside, and the value, for a decision-maker | To brief a stakeholder or justify the toolkit |
| **Global Requirements — Network** (`global-requirements-network.md`) | Category-level prerequisites shared by all Network solutions | Confirm alongside the solution-specific requirements |

## PowerShell scripts (all read-only)

| Script | What it does | Layer(s) it covers |
|--------|--------------|--------------------|
| **CISEDIAG-Collect.ps1** | End-to-end diagnostic collection — device certificate/VPN state plus Intune/Graph compliance state — written to a timestamped bundle | L1, L2, L4 (Intune side) |
| **CISEDIAG-Validate-Certificate.ps1** | Validates the VPN client-authentication certificate and its full chain on *this* device (private key, EKU, expiry, chain, revocation) | L1 |
| **CISEDIAG-Check-Compliance.ps1** | Reads the device's compliance/enrollment state via Graph — the same signal ISE reads through the Entra↔ISE connector | L4 (Intune side) |
| **CISEDIAG-Check-VpnClient.ps1** | Checks the Cisco Secure Client / VPN client and profile state on *this* device (service present, profile present, gateway, connection state) | L2 |
| **CISEDIAG-Report.ps1** | Consolidates the other checks into a single cross-layer pass/fail diagnostics report | L1, L2, L4 (Intune side) |

Every script begins with a standard PURPOSE / HOW TO RUN / EXPECTED RESULTS header and requires only **read** access (read-only Graph scopes on the Intune side). None change device, tenant, or ISE state.

## What is intentionally deferred to Cisco

Cisco ISE live-log navigation, EAP-TLS/RADIUS console detail, posture/authorization policy internals, and Cisco Secure Client (AnyConnect) UI / profile-editor / DART collection steps are **deferred to Cisco's official documentation**. The toolkit names the exact evidence to read on the Cisco side (the EAP-TLS failure reason, the matched authorization rule, the DART bundle) and provides the escalation checklist to hand Cisco a complete package — but does not fabricate Cisco menu paths.

## How the pieces fit together

1. **Prepare** with `02-requirements.md`.
2. **Diagnose** with `03-implementation.md`, using the scripts to snapshot evidence.
3. **Confirm** with `05-testing.md`.
4. **Escalate or refine** with `06-troubleshooting.md`.
5. **Standardize** with `07-best-practices.md`.
