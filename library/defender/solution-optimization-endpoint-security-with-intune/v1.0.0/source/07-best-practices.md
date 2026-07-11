# 7. Best Practices — Solution Optimization: Endpoint Security with Microsoft Intune

Field-proven guidance for tuning an Intune endpoint-security estate so it gets **measurably better** without locking users out or breaking production.

## Always baseline before you touch anything
- Capture the **before** state (`SOPEIS-Report.ps1 -SaveBaseline` and `SOPEIS-ConflictReport.ps1`) first. Optimization you cannot measure is just change; the baseline is what makes "better" provable to leadership.
- Re-baseline after each expansion wave so the trend reflects real scope growth, not just the pilot.

## One authoritative policy per setting
- **Conflict is the number-one drift symptom.** A setting configured by two policies has an undefined effective value. Consolidate to a single authoritative `Endpoint Security – <area> – Prod` policy per setting area and remove the overlap — don't maintain parallel copies.
- Prefer folding legacy device-configuration profiles into the security baseline / endpoint-security policy rather than running both.

## Migrate baselines deliberately, keep only justified customizations
- When a new **security-baseline version** ships, create the new-version profile, carry forward only the customizations with a documented reason, and take Microsoft's new defaults otherwise. Then **retire the old baseline's assignment** so the two don't overlap (which would re-create conflict).

## Tune compliance for signal, not silence
- Reduce **false** non-compliant flags so the queue is trustworthy, but never loosen a policy so far that a real gap (encryption off, Defender unhealthy) passes. The goal is that "non-compliant" means something.
- Give users a **grace period** before a compliance action restricts access — instant blocking generates help-desk load and erodes trust.

## Treat Conditional Access as the blast radius
- Compliance state feeds Conditional Access. Always model a stricter compliance policy's impact **in report-only** (and with the What-If tool) before enforcing, and move to enforce **last** and in stages. **The enforce decision is the identity team's.**

## Expand coverage as deliberately as you tune
- A device that never received the policy is silently unprotected. Hunt for unassigned devices every cycle and fix the assignment model — but verify you didn't **double-target** a device, which re-introduces conflict.
- Use a consistent, documented group model; over-broad **exclusions** are a common hidden coverage gap.

## Keep licensing and preview facts current
- Intune requires the appropriate per-user plan; Defender-for-Endpoint settings surfaced through Intune (ASR/EDR) need **Defender for Endpoint P2**; baseline versions change. **Verify current plan requirements and availability in your tenant** before relying on a feature.

## Defer the policy decisions to the owners
- Which **compliance thresholds** are required, whether a **Conditional Access grant** should block or warn, and what **residual risk** is acceptable are the **security/identity team's** determinations. This solution delivers the controls and the before/after evidence — not the policy decision.

## Where to go next
Once the estate is tuned and the deltas are trending the right way, natural next steps in the catalog:
- The **Solution Optimization — Microsoft Defender for Endpoint** to tune the EDR/ASR side that Intune surfaces (ASR audit→block, alert noise, web filtering).
- **Microsoft Defender XDR Deployment & Unified Onboarding** to correlate endpoint, identity, email, and cloud detections.
- The **Conditional Access / Zero Trust** identity solutions for broader access-policy design beyond compliance.
- The **Security Optimization Assessment** as the recurring read-only health check that feeds the next tuning cycle.
