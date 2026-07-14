# 7. Best Practices — Defender for Endpoint Network Telemetry in Web Proxy / SWG Architectures

Keep the assessment trustworthy, honestly framed, and reusable.

## Keep it read-only and keep it that way
- **Run as Security Reader.** The whole assessment fits inside a read-only role; do not run it as a configuration admin "just in case." Least privilege *is* the read-only guarantee.
- **Never let the assessment become a change.** This package measures; it does not touch the SWG, the agent, the endpoints, or the tenant. If someone wants to change steering mode, that is the customer's change process, not a step here.
- **Version the read scopes.** Consent only to `ThreatHunting.Read.All`, `SecurityEvents.Read.All`, and `Organization.Read.All`. If a script ever needs more, question why.

## Make the measurement defensible
- **Document the proxy address set.** Every address that classifies a destination as "obscured" must be justified from the real config. An unexplained address in the set invalidates the finding.
- **Report a true 0% as a real result.** If a device or mode shows no obfuscation, that is a valid, valuable finding — not a failed run. Distinguish "no obfuscation" from "no data."
- **Mind the retention window.** Advanced hunting keeps a limited window (*verify current retention*). For historical or long-window analysis, use the SIEM/continuous-export copy (R9, cross-reference `WSKQL`).
- **Sample representatively, then confirm on expansion.** Pilot on `MDEPROXY Device Sample – Proxy Ring – Assess`, then confirm the sample was representative when you expand across the estate.

## Never invent Microsoft's answers
- **Keep the "Confirm with Microsoft" column open** until the advisory case returns. The measured obfuscation is yours to assert; the *feature behavior*, *XFF applicability*, *affected-table list*, and *supported topology* are **Microsoft's to confirm**.
- **Frame XFF as reasoning, not ruling.** XFF is server-side; our endpoint conclusion is well-reasoned but stays "confirm with Microsoft" until the case answers it.
- **Flag every remediation option "verify against current guidance."** SWG mode behavior is vendor- and version-specific; supported coexistence is Microsoft's determination. Present options and tradeoffs; the customer's owners decide.

## Defer the decisions that aren't technical
- **The steering tradeoff is the customer's.** Preserving endpoint telemetry may mean changing how the SWG steers or excludes traffic — trading filtering coverage for visibility. That is a **security/network/architecture decision**, deferred to those owners; the guide supplies the evidence, not the ruling.
- **Compliance and records/legal determinations** stay with the customer's compliance/legal functions.

## Operate the loop
- **Re-run after any change.** SWG mode change, connector upgrade, PAC change, or Microsoft's advisory answer — re-run Parts A–B to re-measure the delta. The assessment is a reusable instrument, not a one-shot.
- **Fold Microsoft's answer back in.** When the case returns, replace the open questions in the matrix and XFF section with the confirmed behavior, and note the case number for provenance.

## Where to go next (adjacent catalog areas)
- **Endpoint Network Connectivity Troubleshooting Toolkit** (`NETDX`) — if the question is "can the sensor *reach* the service through the proxy" (connectivity), not "is the *destination telemetry* obscured" (this solution).
- **Netskope SWG line** (`NSSWG` deployment, `NSCASB` CASB, SSL/TLS inspection, traffic steering, and the SASE/SSE blueprint) — for **deploying and operating** the gateway itself, including steering modes and exclusions.
- **Microsoft Defender for Endpoint** (`MDEFULL`) — the comprehensive MDE stand-up, tuning, enablement, and PoC.
- **Microsoft Defender XDR — Unified Onboarding** (`DEFXDR`) — cross-pillar correlation, and the place to fuse SWG destination logs with endpoint telemetry as a compensating control.
- **Advanced KQL for SecOps** (`WSKQL`) — the KQL patterns for longer-window, SIEM-side analysis of the device tables.
