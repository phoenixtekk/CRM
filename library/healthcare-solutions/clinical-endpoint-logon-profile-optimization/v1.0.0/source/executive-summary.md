# Executive Summary — Clinical Endpoint Logon & Profile Performance Optimization (FSLogix)

## The challenge

On shared clinical endpoints — Workstations-On-Wheels, exam-room PCs, and nursing-station kiosks — and on virtual desktops, clinicians lose time at every sign-in. The default Windows profile model builds a full local profile on first use of each device, or copies a roaming profile over the network on every login, so clinicians routinely wait 60–120+ seconds at the worst possible moment in care. The same model produces temporary-profile errors, profile corruption, and settings that differ device-to-device — friction that drives the unsafe workarounds (generic shared logins, never signing out) the organization is trying to eliminate. On a busy ward, seconds-per-login multiplied across thousands of daily sign-ins is a measurable drain on clinical time.

## The solution

This solution deploys and configures **FSLogix profile containers** — the Microsoft-standard mechanism for roaming profiles on shared and virtual Windows — and applies **fast-logon tuning** so clinicians sign in measurably faster with one profile that follows them everywhere. Each clinician's profile lives in a per-user **VHD(X) container** on an SMB or **Azure Files** profile share; the container is **attached** at sign-in (mounted, not copied), so logon time drops sharply and stays consistent across every shared endpoint and **Azure Virtual Desktop** host. **Redirections and exclusions** keep volatile caches out of the container to control bloat and corruption, and fast-logon settings (deleting stale cached profiles, trimming sign-in work) shave off additional seconds. The FSLogix agent and configuration are delivered through **Microsoft Intune** (or Group Policy) using named, reusable objects.

The work follows a disciplined phase model — **Assess (baseline logon) → Configure FSLogix → Tune fast logon → Pilot → Validate (measure) → Expand** — anchored by a **measured baseline** so the improvement is proven, not assumed, and gated by a defined acceptance test before fleet rollout.

## Business outcomes

- **Faster, consistent clinician sign-in.** Attaching a profile container instead of copying it cuts logon time against a measured baseline and keeps it consistent across every shared device and virtual desktop.
- **One roaming profile that follows the clinician.** A single container per clinician means the same desktop, settings, and Office/EHR state on every WOW, exam-room PC, and AVD host — no more device-to-device inconsistency.
- **Fewer profile failures.** Attaching a container avoids the temporary-profile, corruption, and merge-conflict failures of roaming/mandatory profiles, and exclusions keep containers small and stable.
- **Proven, monitored delivery.** Intune (or GPO) installs, targets, and reports on the agent and configuration; the deployment ships with a measured before/after and continuous coverage reporting, expanding in controlled waves.

## Scope and governance

The solution covers the **FSLogix deployment, endpoint/AVD configuration, fast-logon tuning, profile-share requirements, and measured validation**. Storage-platform values (share path, storage account, tier, quota, backup), FSLogix/Windows licensing entitlement, and Imprivata appliance policy are intentionally **not invented here** — they are governed by the organization's **storage/infrastructure team**, **licensing owner**, and **Imprivata administrator** (a separate solution), and the documentation directs the reader to those owners at every decision point. The deployment is gated by HIPAA/HITRUST change control, clinical maintenance windows, a measured baseline, a validated test plan, and documented change/compliance sign-off.

## What you receive

A complete, productized package: nine implementation documents, five runnable PowerShell scripts (inventory/discovery, per-device validation, fleet logon-time-and-size reporting, safe remediation, and baseline capture), and a listing hero image — everything needed to baseline, deploy, prove, and expand FSLogix logon and profile optimization across shared clinical endpoints and AVD with confidence.
