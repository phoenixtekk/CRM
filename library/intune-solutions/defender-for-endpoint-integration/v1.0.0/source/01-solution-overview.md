# 1. Solution Overview — Microsoft Defender for Endpoint Integration

## What this integration is
Microsoft Defender for Endpoint (MDE) is Microsoft's enterprise endpoint security platform —
next-generation antivirus, **endpoint detection and response (EDR)**, attack surface reduction,
and threat/vulnerability management. This solution connects MDE to **Microsoft Intune** so Intune
**onboards** devices to MDE automatically and consumes MDE's **device risk score** as a
compliance and Conditional Access signal.

## How it works
1. You enable the **service-to-service connection** between Intune and the Defender portal.
2. An Intune **EDR onboarding policy** carries the onboarding configuration to enrolled devices, which begin reporting to MDE.
3. MDE continuously evaluates each device and assigns a **machine risk score** (Low/Medium/High).
4. Intune **device compliance** can require a risk score at or below a threshold; a risky device becomes **Not compliant**.
5. **Conditional Access** (require compliant device) then blocks the risky device until it's remediated.

## What you can manage through the integration
- **EDR onboarding** of Windows devices via Intune (no manual onboarding scripts at scale).
- **Risk-based compliance** — fail compliance when MDE risk exceeds your threshold.
- A foundation for managing **Defender Antivirus**, **Attack Surface Reduction**, and **firewall** policy from Intune (companion solutions).

## Benefits
- **Automatic onboarding** — enrolled devices join MDE with no per-device scripting.
- **Risk-driven access** — compromised devices automatically lose access via compliance + CA.
- **Single pane** — manage endpoint security policy from Intune.
- **Faster response** — EDR detection, investigation, and automated remediation.

## Limitations (be honest with buyers)
- Requires **Defender for Endpoint licensing** (P1/P2, M365 E5/E5 Security, or Defender for Business).
- The risk-score → access flow needs the **Device Compliance** and **Conditional Access** solutions.
- Onboarding takes effect after policy sync and a device check-in to the Defender service.
- Down-level/unsupported OSes have reduced capability.

## The standard deployment model
> **Enable the connector → create the EDR onboarding policy → assign to a pilot → wire risk score
> into compliance → validate → expand.** repeatable pattern: **Assess → Configure → Pilot →
> Validate → Expand.**
