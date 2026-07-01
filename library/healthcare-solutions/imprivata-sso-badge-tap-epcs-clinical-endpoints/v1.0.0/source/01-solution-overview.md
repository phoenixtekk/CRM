# 1. Solution Overview — Imprivata SSO, Badge-Tap & EPCS Integration for Clinical Endpoints

## What this solution delivers

This solution deploys and configures **Imprivata OneSign** across shared clinical endpoints so that clinicians authenticate with a **tap of a proximity badge** instead of typing usernames and passwords, switch between users in seconds on a shared workstation, single-sign-on into the **Epic EHR** and clinical web applications, and complete **Electronic Prescribing of Controlled Substances (EPCS)** two-factor signing where required. The Imprivata agent and the proximity card-reader drivers are delivered to the endpoints with **Microsoft Intune** using the standard deployment model — packaged Win32 apps, an Entra device group, and configuration profiles — and identity is integrated with **Microsoft Entra ID / Active Directory**.

The result is the "tap-and-go" clinical workstation experience: a clinician walks up to a Workstation-On-Wheels (WOW), exam-room PC, or nursing-station kiosk, taps their badge, and is immediately at their session inside Epic; they tap out (or another clinician taps in) and the session is locked or switched in place. Where a controlled-substance prescription must be signed, Imprivata Confirm ID drives the EPCS two-factor prompt (badge or fingerprint **plus** a second factor such as a PIN) and records the audit trail.

## What problem it solves

On shared clinical endpoints, password-based login is slow, error-prone, and a documented source of clinician burnout and workarounds (shared passwords, never-locking sessions, sticky notes). EPCS adds a regulatory burden: the DEA requires identity proofing, two-factor authentication, logical access controls, and a tamper-evident audit trail before any controlled-substance prescription can be signed electronically. This solution closes both gaps at once:

- **Speed and safety on shared devices** — badge tap-and-go and fast user switching remove the password friction that drives unsafe workarounds, while every session is attributed to the clinician who tapped in.
- **One sign-on into clinical apps** — Imprivata OneSign brokers credentials into Epic and clinical web apps so clinicians sign on once per tap, not once per application.
- **Compliant controlled-substance signing** — Imprivata Confirm ID provides the DEA-required two-factor workflow and the supervised approval / identity-proofing process for EPCS.
- **Repeatable, fleet-wide delivery** — Intune installs the agent and reader drivers, targets the right devices by group, and reports compliance, so the same deployment scales from a pilot ward to the whole organization.

## Scope and boundaries

**In scope (this document):**
- Intune packaging and deployment of the **Imprivata OneSign agent** and the **proximity reader drivers** as named Win32 apps.
- Creation of the **Entra device group `IMPRIVATA – Clinical Endpoints`** and the configuration profiles that prepare endpoints for tap-and-go and fast user switching.
- Endpoint-side configuration and identity integration with Entra ID / Active Directory.
- The endpoint-side enablement of SSO into Epic and clinical web apps, tap-and-go, fast user switching, and the EPCS two-factor experience.
- Pilot, validation, and fleet expansion, with named objects and full navigation paths.

**Out of scope / owned elsewhere — do not invent these values:**
- **Imprivata appliance and console policy values** (OneSign / Confirm ID server configuration, application profile definitions, computer policies, license SKUs, agent installer parameters specific to your version). These are governed by **your Imprivata administrator and Imprivata's customer documentation**. This document tells you *where* the endpoint integrates; your Imprivata admin supplies the policy values.
- **EPCS / DEA regulatory specifics** (identity-proofing provider, two-factor credential requirements, incident-reporting obligations, audit-retention periods). These are governed by **DEA EPCS regulations and your organization's compliance / pharmacy leadership**. This document documents the *workflow shape* accurately; your compliance team owns the regulatory configuration and sign-off.
- **Epic application-side SSO configuration** (Epic credential vaulting, Hyperdrive/Hyperspace launch settings) — coordinated with your Epic / EHR team and your Imprivata admin.

Throughout, named objects (the Win32 apps, the device group, the configuration profiles) follow the `<Purpose> – <Scope> – <Stage>` convention and are reused verbatim in later documents so the build is traceable end to end.

## Phase model

The solution follows a seven-phase model, used consistently across the requirements, implementation, and testing documents:

1. **Assess** — confirm prerequisites: Imprivata licensing and appliance reachability, Confirm ID for EPCS, reader hardware and drivers, Intune/Entra readiness, target OS, and the shared-device model.
2. **Deploy Agent** — package and deploy the Imprivata agent and reader drivers via Intune Win32 apps to the clinical device group.
3. **Configure SSO / Badge** — bind the agent to identity, enable tap-and-go badge SSO and fast user switching, and broker SSO into Epic and clinical web apps.
4. **Enable EPCS** — enable the Confirm ID two-factor enrollment and the supervised approval / identity-proofing workflow for controlled-substance signing.
5. **Pilot** — run a small, representative ward / set of endpoints end to end.
6. **Validate** — execute the test plan and meet the acceptance gate.
7. **Expand** — roll out to the remaining clinical endpoints in controlled waves.

## Audience

This solution is written for the IT team that owns endpoint management (Intune administrators), in partnership with the **Imprivata administrator** (appliance-side policy), the **Epic / EHR team** (application SSO), and the organization's **compliance / pharmacy leadership** (EPCS / DEA). Steps are written so a competent Intune administrator can execute them without prior Imprivata experience, deferring appliance-side and regulatory values to the named owners.

## Outcome

On completion, clinicians on the targeted endpoints tap a badge to sign in, switch users instantly on shared devices, single-sign-on into Epic and clinical web apps, and complete EPCS two-factor signing where required — all delivered and monitored through Intune, with a validated audit trail and a documented path to expand across the fleet.
