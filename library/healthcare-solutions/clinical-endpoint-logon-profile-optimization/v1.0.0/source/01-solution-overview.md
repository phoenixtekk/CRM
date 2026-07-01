# 1. Solution Overview — Clinical Endpoint Logon & Profile Performance Optimization (FSLogix)

## What this solution delivers

This solution cuts sign-in times and stabilizes user sessions on **shared clinical Windows endpoints** — Workstations-On-Wheels (WOWs), exam-room PCs, nursing-station kiosks — and on **Azure Virtual Desktop (AVD) session hosts** where applicable, by deploying and configuring **FSLogix profile containers** and applying **fast-logon tuning**. A clinician's Windows profile is moved out of the slow, locally-cached, copy-on-every-login model and into a **per-user VHD(X) profile container** stored on an SMB / Azure Files share; the container is **attached** at sign-in (mounted, not copied), so the profile loads in a fraction of the time and roams cleanly across every shared endpoint the clinician touches. The **FSLogix agent**, the FSLogix configuration, the profile share definition, redirections/exclusions, and the fast-logon settings are delivered to the endpoints with **Microsoft Intune** (or **Group Policy** where that is the management plane) using named, reusable objects.

The result is the experience clinical staff actually want on a shared device: walk up, sign in, and be working in seconds — with the same desktop, settings, and Office state on every WOW and exam-room PC — instead of waiting through a long first-time profile build, a temporary-profile error, or a bloated roaming-profile copy. FSLogix is the Microsoft-standard mechanism for roaming user profiles on shared and virtualized Windows; this solution applies it correctly for the clinical shared-endpoint and AVD case and **quantifies the before/after** (logon seconds, profile load time, container size).

## What problem it solves

On shared clinical endpoints, the default Windows profile model is the bottleneck. The first time a clinician signs in to a given device, Windows builds a full local profile; on roaming-profile setups the whole profile is copied over the network on every login and copied back on logout. Either way clinicians wait — often 60–120+ seconds — at the worst possible time (mid-round, mid-triage). Worse, the model produces temporary-profile errors, profile corruption, and inconsistent settings device-to-device, which drives the same unsafe workarounds (generic shared logins, never-signing-out) that the organization is trying to eliminate. This solution closes the gap:

- **Fast, consistent sign-in on shared devices** — the profile container is **attached** at logon rather than copied, so logon time drops sharply and is consistent across every endpoint.
- **A single roaming profile that follows the clinician** — one VHD(X) per user on the profile share means the same desktop, settings, and (optionally) Office/Outlook cache and search index on every shared endpoint and AVD host.
- **Stability over the copy-profile failure modes** — attaching a container avoids the temporary-profile and merge-conflict failures of mandatory/roaming profiles, and **redirections.xml exclusions** keep volatile/cache data out of the container to control bloat and corruption.
- **Fast-logon tuning on top of FSLogix** — deleting stale locally-cached profiles, trimming what runs at sign-in, and the supporting GPO/Intune settings shave additional seconds off the clinician's wait.
- **Measured, repeatable delivery** — Intune (or GPO) delivers the agent and configuration to a named device group, and the deployment is gated by a **measured baseline** so the improvement is provable, not assumed.

## Scope and boundaries

**In scope (this document):**
- Deployment of the **FSLogix agent** and FSLogix configuration to the clinical endpoints / AVD hosts via Intune (settings catalog / Win32) or Group Policy.
- Configuration of the **FSLogix Profile Container** (and, where in scope, the **Office Container**) to the named profile share, with VHD(X) sizing, container-naming, and locked-VHD/concurrent-session behavior appropriate to shared devices.
- **Profile storage** on an SMB file server or **Azure Files** share, including the share/NTFS (or Azure Files Kerberos + share) **permissions** FSLogix requires.
- **redirections.xml exclusions** and recommended FSLogix exclusion settings to control container bloat and protect against corruption.
- **Fast-logon tuning**: delete-cached-profiles behavior, sign-in optimizations, roaming-vs-local decisions, and the supporting GPO/Intune settings.
- The documented **interplay with Imprivata tap-and-go fast user switching** so FSLogix container attach/detach behaves correctly under rapid badge-driven session changes.
- Baseline measurement, pilot, validation (measure before/after), and fleet expansion, with named objects and full navigation paths.

**Out of scope / owned elsewhere — do not invent these values:**
- **The clinical applications' own profile/cache requirements** (e.g., the EHR client's local cache location and size) beyond pointing them into or out of the container correctly — confirm app-specific behavior with the application owner.
- **Imprivata appliance / OneSign computer-policy values** (tap-out lock vs. log-off behavior, session timing). These are governed by your **Imprivata administrator** and are the subject of a separate Imprivata solution. This document documents the *FSLogix-side* settings that make tap-and-go and FSLogix coexist; it does not set Imprivata policy.
- **The storage platform's own provisioning specifics** (Azure Files tier/quota/region, file-server hardware/sizing SKUs, backup/snapshot schedules). These are governed by your **storage / infrastructure team**; this document states the *requirements FSLogix imposes* on that storage and directs you to that owner for the platform values.
- **Directory and licensing entitlement** for FSLogix and Windows (see `02-requirements.md` R1) — governed by your licensing owner.

Throughout, named objects (the FSLogix config profile, the profile share, the device group, the GPO/Intune settings policy) follow the `<Purpose> – <Scope> – <Stage>` convention and are reused verbatim in later documents so the build is traceable end to end.

## Phase model

The solution follows a six-phase model, used consistently across the requirements, implementation, and testing documents:

1. **Assess (baseline logon)** — confirm prerequisites and **measure the current logon time and profile load time** on representative endpoints so the improvement is quantifiable.
2. **Configure FSLogix** — deploy the FSLogix agent and configure the Profile (and Office) Container to the named profile share, with sizing, redirections, and recommended exclusions.
3. **Tune fast logon** — apply delete-cached-profiles, sign-in optimizations, and the supporting GPO/Intune settings; reconcile FSLogix with Imprivata tap-and-go behavior.
4. **Pilot** — run a small, representative ward / set of endpoints (or AVD host pool subset) end to end.
5. **Validate (measure)** — re-measure logon and profile load against the baseline, confirm the target reduction is met, and confirm stability and fast-user-switch behavior.
6. **Expand** — roll out to the remaining clinical endpoints / AVD hosts in controlled waves.

## Audience

This solution is written for the IT team that owns endpoint and/or AVD management (Intune administrators and/or AVD/VDI engineers), in partnership with the **storage / infrastructure team** (the profile share and its permissions), the **identity team** (the directory FSLogix uses), and — where the endpoints also run Imprivata — the **Imprivata administrator** (tap-and-go interplay). Steps are written so a competent Intune/GPO administrator can execute them without prior FSLogix experience, deferring storage-platform, regulatory, and Imprivata-policy values to the named owners.

## Outcome

On completion, clinicians on the targeted shared endpoints (and AVD hosts) sign in measurably faster with a single roaming FSLogix profile that follows them across devices, sessions are stable and free of temporary-profile and corruption failures, container bloat is controlled by exclusions, and the deployment is delivered and monitored through Intune (or GPO) with a **measured before/after** that proves the logon-time reduction and a documented path to expand across the fleet.
