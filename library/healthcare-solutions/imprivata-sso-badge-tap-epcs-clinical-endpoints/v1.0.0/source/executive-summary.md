# Executive Summary — Imprivata SSO, Badge-Tap & EPCS Integration for Clinical Endpoints

## The challenge

On shared clinical endpoints — Workstations-On-Wheels, exam-room PCs, and nursing-station kiosks — password-based sign-on is slow, repetitive, and a known driver of clinician burnout and unsafe workarounds (shared passwords, sessions left open, sticky notes). At the same time, electronically prescribing controlled substances carries a strict regulatory burden: the DEA requires identity proofing, two-factor authentication, logical access controls, and a tamper-evident audit trail before any controlled-substance prescription can be signed. Most organizations face both problems on the same devices, with the same clinicians.

## The solution

This solution deploys and configures **Imprivata OneSign** for clinical endpoints so clinicians authenticate with a **tap of a proximity badge** instead of a password, switch users in seconds on shared workstations, single-sign-on into the **Epic EHR** and clinical web applications, and — where required — complete **EPCS** (Electronic Prescribing of Controlled Substances) two-factor signing through **Imprivata Confirm ID**. The Imprivata agent and the proximity reader drivers are delivered through **Microsoft Intune** using the standard deployment model: packaged Win32 apps, a named device group, configuration profiles, and identity integrated with Microsoft Entra ID / Active Directory.

The work follows a disciplined phase model — **Assess → Deploy Agent → Configure SSO/Badge → Enable EPCS → Pilot → Validate → Expand** — with named, reusable objects and a defined acceptance gate, so the rollout is repeatable and auditable from a pilot ward to the entire fleet.

## Business outcomes

- **Faster, safer clinician sign-on.** Badge tap-and-go and fast user switching remove the password friction that drives unsafe workarounds, while every session is correctly attributed to the clinician who tapped in.
- **One sign-on into clinical apps.** OneSign brokers credentials into Epic and clinical web apps, so clinicians authenticate once per tap rather than once per application.
- **Compliant controlled-substance signing.** Confirm ID provides the DEA-aligned two-factor workflow and supervised approval needed for EPCS, with an audit trail for review.
- **Scalable, monitored delivery.** Intune installs, targets, and reports on the agent and reader drivers, so the same deployment scales in controlled waves with continuous compliance visibility.

## Scope and governance

The solution covers the **Intune deployment, endpoint configuration, identity integration, and validation/testing**. Imprivata appliance/console policy values, license SKUs, and EPCS/DEA regulatory specifics are intentionally **not invented here** — they are governed by the organization's **Imprivata administrator and Imprivata documentation** and by **DEA EPCS regulations and the organization's compliance/pharmacy leadership**, and the documentation directs the reader to those owners at every regulated decision point. The deployment is gated by HIPAA/HITRUST change control, clinical maintenance windows, a validated test plan, and documented compliance sign-off.

## What you receive

A complete, productized package: nine implementation documents, five runnable PowerShell scripts (discovery, per-device validation, fleet reporting, safe remediation, and group provisioning), and a listing hero image — everything needed to deploy, validate, and expand Imprivata tap-and-go SSO and EPCS across shared clinical endpoints with confidence.
