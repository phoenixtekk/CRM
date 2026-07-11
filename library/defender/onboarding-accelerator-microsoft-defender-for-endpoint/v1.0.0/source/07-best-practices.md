# 7. Best Practices — Onboarding Accelerator: Microsoft Defender for Endpoint

Field-proven guidance for keeping the Defender for Endpoint deployment protective, operable, and low-risk.

## Onboard in rings, never all at once
- Onboard `MDE Device Group – Pilot Ring – Pilot` first — a representative Windows/macOS/Linux mix — validate, then expand in waves. Sequencing catches platform-specific issues before they hit the fleet.
- Onboard **every** platform in scope; a Linux or macOS fleet left un-onboarded is a blind spot.

## Bring ASR and block mode up audit-first
- Always run **ASR** in `MDE ASR Rules – Pilot Ring – Audit` first, review what it *would* block (`MDEONB-Report.ps1 -Section ASR`), add exclusions for legitimate line-of-business behavior, then promote to `MDE ASR Rules – Pilot Ring – Block`. An ASR rule enforced blind can break a business app.
- Promote block mode and ASR ring-by-ring, validating each ring clean before the next.

## Enforce tamper protection early
- Turn on **tamper protection** so an attacker (or a well-meaning misconfiguration) cannot disable the protection stack. It is one of the highest-value, lowest-friction controls.

## Structure device groups and RBAC deliberately
- Use **device groups** to scope AIR automation levels and analyst access; keep the pilot at **Semi — require approval**. Grant least privilege via `MDE Security Reader – Tenant – Prod` and `MDE Security Operator – Tenant – Prod` — only responders get response permissions.
- **Live response** is powerful (remote shell to a device) — restrict who can run it and gate it per policy.

## Keep automated response approval-gated until trusted
- Leave **AIR** at **Semi — require approval** during the pilot and early expansion. Raising automation is the SOC/security team's decision, made only after coverage and detections are proven.

## Work TVM exposure as a trend
- Capture the **exposure baseline** (`MDEONB-Report.ps1 -SaveBaseline`), triage the highest-impact vulnerabilities first, and track the delta each cycle. Re-baseline after each expansion so the trend reflects real coverage.

## Mind platform and licensing differences
- **macOS/Linux** onboard through platform-specific channels and have feature differences from Windows; **web content filtering, TVM, and some features need P2**. Before relying on a capability, **verify current platform support and plan requirements in your tenant.**

## Where to go next
Once MDE is onboarded and validated, natural next steps in the catalog:
- The **Defender for Endpoint Integration** solution for deeper Intune-connector configuration, and the **macOS Onboarding via Intune** solution for a macOS-specific rollout — cross-reference rather than re-do.
- The **Microsoft Defender XDR — Unified Onboarding** accelerator to correlate MDE with Identity, Office 365, and Cloud Apps.
- The **Onboarding Accelerator — Microsoft Defender for Cloud Apps** — MDE's discovery feed powers Cloud Discovery.
- The **SOC onboarding — Sentinel + Defender XDR** and **advanced KQL threat-hunting** solutions to hunt endpoint attacks in a SIEM.
