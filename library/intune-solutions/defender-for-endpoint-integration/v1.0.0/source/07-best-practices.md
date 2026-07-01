# 7. Best Practices — Microsoft Defender for Endpoint Integration

- **Enable the connector first.** Nothing onboards through Intune until the Defender↔Intune connection is On and Active.
- **Use Auto-from-connector onboarding.** Let the connector supply the onboarding blob — no manual scripts to manage at scale.
- **Pilot before fleet.** Confirm onboarding, sensor health, and portal visibility on a small group first.
- **Start the risk threshold at Medium.** It catches real risk without over-blocking; tighten to Low for sensitive scopes.
- **Layer compliance + Conditional Access.** The risk score only enforces access when wired into compliance and a CA "require compliant device" policy.
- **Don't SSL-inspect MDE traffic.** It breaks the sensor; exclude Defender URLs from inspection.
- **Watch sensor health.** Track onboarded/health/risk with `MDE-TenantReport.ps1`; chase inactive sensors.
- **Run the EDR detection test.** Validate telemetry end-to-end with Microsoft's official detection test on a pilot device.
- **Manage AV/ASR/firewall through Intune** once onboarded (companion solutions) for a single policy plane.
- **Document the risk policy.** Record the threshold and rationale for audits.
