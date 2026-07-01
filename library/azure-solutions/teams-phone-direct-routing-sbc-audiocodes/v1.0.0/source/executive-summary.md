# Executive Summary — Microsoft Teams Phone Direct Routing with Session Border Controller (AudioCodes) Integration

## The outcome

Your people place and receive normal phone calls — to mobiles, landlines, and emergency services — directly from Microsoft Teams, using your own carrier and your own AudioCodes Session Border Controller (SBC). One application (Teams) replaces separate desk-phone and calling systems, while you keep full control of your telephone numbers, carrier contracts, and call routing.

## What we deliver

This solution productizes the complete **Microsoft Teams Phone Direct Routing** build with an **AudioCodes SBC**:

- **Pair the SBC** to your Microsoft tenant as a Direct Routing gateway, with healthy, monitored signaling.
- **Build the voice routing stack** — phone-number normalization, call routes, usages, and a routing policy — using clear, self-documenting, named objects.
- **Enable users** with the right licensing, calling policy, and phone numbers.
- **Pilot, validate, and expand** against explicit pass/fail quality gates, including a controlled emergency-calling check.
- **Hand over operable tooling** — five PowerShell scripts for discovery, validation, reporting, safe remediation, and configuration — so your team can run and grow the deployment with confidence.

The Microsoft side is delivered concretely and correctly. The AudioCodes device configuration is specified as a precise requirements checklist (public FQDN, public CA certificate, encrypted TLS signaling and SRTP media, SIP keep-alive) and handed to your network/voice team with vendor documentation, so nothing about the appliance is guessed.

## Why it matters

- **Cost and choice.** Keep your existing SIP trunk and negotiated rates instead of per-user calling plans, and serve regions where calling plans are unavailable.
- **Continuity and control.** Own your numbers and routing; add a second SBC for failover; interconnect existing telephony where needed.
- **Safety and compliance.** Emergency calling is designed, routed, and validated deliberately — not left to chance — because under Direct Routing that responsibility is yours.
- **Low risk.** A phased, gated rollout (Assess → Pair SBC → Configure Voice Routing → Assign Users → Pilot → Validate → Expand) with read-only discovery, dry-run-by-default changes, and documented rollback keeps a critical service safe.

## The result

Pilot users calling through your SBC on day one, an SBC that reports healthy with correct caller ID and validated emergency routing, and a repeatable, documented process to extend calling across the organization.
