# 7. Best Practices — Microsoft Defender XDR Deployment & Unified Onboarding

Field-proven guidance for keeping the unified XDR deployment clean, correlated, and low-risk.

## Onboard in rings, never all at once
- Always onboard a **pilot ring** first — a few devices (`MDE Onboarding – Pilot Ring – Pilot`), one or two domain controllers, and a pilot user group (`XDR Pilot Users – Pilot Ring – Pilot`) — validate, then expand in waves.
- Sequence the pillars but let signal accumulate: onboard Endpoint and the Identity sensor first (they take longest), then activate Office 365 and Cloud Apps, which are portal-side toggles.

## Keep automated response approval-gated until trusted
- Leave **AIR** at **Semi — require approval** during the pilot and early expansion. Move toward higher automation only after correlation and coverage are proven — and that decision belongs to the SOC/security team, not the deployment.
- Never let a response playbook auto-isolate a device or auto-disable a user before the org has agreed the guardrails.

## Prefer one unified role model
- Adopt **unified RBAC** and retire per-pillar permissions so analysts have one consistent role (reader / operator / admin) across Endpoint, Identity, Office, and Cloud Apps. This removes the "who can see what in which console" confusion that fragments a SOC.
- Grant least privilege: read-only analysts get `XDR Security Reader – Tenant – Prod`; only responders get `XDR Security Operator – Tenant – Prod`.

## Treat Secure Score as a trend, not a target
- Capture a **baseline** with `DEFXDRG-Report.ps1 -SaveBaseline` and work the highest-impact recommendations first. Track the delta each cycle rather than chasing a single number.
- Re-baseline after each expansion wave so the trend reflects real coverage growth.

## Let correlation and tables warm up
- After onboarding, allow time before judging correlation — advanced-hunting tables (`DeviceInfo`, `IdentityInfo`, `EmailEvents`, `CloudAppEvents`) populate over hours, not seconds. Use `DEFXDRG-Hunt.ps1` to confirm each pillar is streaming before expecting multi-pillar incidents.

## Protect the Identity sensors
- Domain-controller sensors are security-critical infrastructure. Keep them healthy, patched, and monitored; a silent sensor blinds MDI. Use the DSA (gMSA) per current guidance and review sensor health on a cadence.

## Keep licensing and preview facts current (GCC High/DoD lag commercial)
- Each pillar and feature is **license-gated** (MDE P1/P2, MDI, MDO P1/P2, MDCA). Before enabling a feature, **verify current availability and plan requirements in your tenant** — do not assume a feature is included.
- **In GCC High/DoD, availability itself lags or differs from commercial.** Whether a pillar, connector, unified-RBAC capability, preview, or AI/Copilot feature exists in your Government cloud — and which advanced-hunting tables it populates — **must be verified against current Microsoft Government documentation** for your specific cloud (GCC High vs DoD IL5). Never assume commercial parity. See `gcc-high-parity-notes.md`.

## Defer the security decisions to the owners
- Automated-response guardrails, incident-response runbooks, and which recommendations are "must-fix" are **the security/SOC team's** determinations. This solution delivers the technical onboarding and validation; the operating decisions stay with the customer.

## Where to go next
Once the XDR suite is onboarded and correlating, natural next steps in the catalog:
- **Defender for Office 365 (P2) — Threat Explorer, Attack Simulation & AIR** to go deep on the email pillar.
- **Microsoft Defender for Cloud — CSPM & Secure Score Remediation** to extend posture management to cloud workloads.
- The **Sentinel** SOC/XDR integration solution to stream this correlated XDR into a SIEM for long-term hunting and SOAR.
- **Entra ID governance / Conditional Access** solutions to harden the identity layer that MDI protects.
