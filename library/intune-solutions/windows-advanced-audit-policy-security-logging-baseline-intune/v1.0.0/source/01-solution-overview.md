# 1. Solution Overview — Windows Advanced Audit Policy & Security Event Logging Baseline (Intune)

## What this solution is
This solution configures the full **Windows Advanced Audit Policy Configuration** on **Windows 10/11**
endpoints managed by **Microsoft Intune**, using a single **Settings Catalog** configuration profile.
Once deployed, every domain- and Entra-joined Windows device writes a **consistent, security-relevant
audit trail** to the local **Security** event log — sign-ins, account and group changes, process
creation (with the full command line), removable-storage use, privilege use, and audit/policy changes
— aligned to the **CIS Benchmark / Microsoft security baseline** recommendations for what to audit and
whether to capture **Success**, **Failure**, or both.

Windows has two layers of auditing. The legacy **basic audit policy** (nine broad categories) and the
modern **Advanced Audit Policy Configuration** (~60 fine-grained subcategories). Modern security
baselines are written entirely against the **advanced** subcategories, because they let you turn on
exactly the events you need without the noise of a whole category. This solution deploys the advanced
subcategories via Intune and — critically — sets the switch that makes Windows honor them.

> **The one switch everything depends on.** Windows only applies the advanced subcategory settings when
> **"Audit: Force audit policy subcategory settings (Windows Vista or later) to override audit policy
> category settings"** is **Enabled** (the registry value `SCENoApplyLegacyAuditPolicy = 1`). Modern
> Windows defaults this on, but a leftover basic-audit GPO, an image, or a third-party tool can flip it
> off — silently discarding every subcategory setting you push. This solution sets it **explicitly** so
> the baseline is deterministic, and the validation scripts check it.

## What this solution is (and is not)
- **It IS** the audit-policy **configuration baseline** — which subcategories to audit, at what
  Success/Failure level, plus command-line process auditing and a right-sized Security log — deployed
  and validated via Intune, pilot-first and reversible.
- **It is NOT** a broad security-configuration baseline. If you want the full CIS/STIG hardening baseline
  (hundreds of settings across firewall, BitLocker, account policy, etc.), that is a **separate, broader
  product** — this one is the focused *audit* slice and complements it without duplication.
- **It is NOT** log forwarding to a SIEM. This solution makes each endpoint **generate and retain** the
  right events locally. **Getting those logs off the box into Microsoft Sentinel** (Azure Monitor Agent
  + Data Collection Rules, Windows Security Events connector) is handled by the separate
  **Entra ID & Intune Audit Telemetry to Microsoft Sentinel** solution — cross-reference it, don't
  rebuild it here. Endpoint auditing is the *source*; forwarding is the *transport*.

## How it works, step by step
1. **One Settings Catalog profile carries the baseline.** A single Windows Settings Catalog
   configuration profile named **`Win Audit Policy - Baseline - Pilot`** contains all ~24 audit
   subcategory settings, the "force subcategory" override, command-line process auditing, and the
   Security-log maximum size.
2. **Intune delivers it to enrolled devices.** The profile is assigned to a **pilot** Entra security
   group (`Win Audit Policy - Pilot Devices`), then widened in waves.
3. **Windows applies the advanced subcategories.** With the force-subcategory override enabled, each
   device begins writing the specified Success/Failure events to the **Security** log.
4. **Events accumulate with room to breathe.** The Security log maximum size is raised so higher-volume
   subcategories (Process Creation, File Share) don't roll over and lose evidence within hours.
5. **Validate, then expand.** Read-only scripts confirm the profile is present, correctly scoped, and
   applied; then the baseline widens to the rest of the fleet.

## What the baseline audits (and why)
The baseline turns on the subcategories that detect the attacker behaviors defenders actually hunt for:

- **Account Logon / Logon-Logoff** — who authenticated, from where, failed sign-ins, lockouts, and the
  privileged/special logons that indicate admin activity or token theft.
- **Account & Security Group Management** — creation, deletion, and privilege changes to accounts and
  groups (a classic persistence and privilege-escalation signal).
- **Detailed Tracking → Process Creation with command line** — every process launch *with its full
  command line* (Event ID 4688). This is one of the single most valuable detections for
  living-off-the-land attacks (PowerShell, `rundll32`, `mshta`, etc.).
- **Object Access → File Share / Removable Storage** — access to shares and USB storage, for
  data-exfiltration and insider investigations.
- **Privilege Use, Policy Change, System** — use of sensitive privileges, tampering with audit/policy,
  and security-subsystem state changes.

The exact **Success/Failure** recommendation per subcategory is given in the Implementation Guide and
is cited to the **CIS Benchmark / Microsoft security baseline**.

## The event-volume trade-off (be honest with yourself)
More auditing means more events, more disk, and more to forward. Two subcategories are notably
high-volume:

- **Detailed Tracking → Process Creation** — on a busy workstation this is the loudest single source.
  It is also the most useful; keep it **Success**, size the log accordingly, and forward it.
- **Object Access → File Share / Detailed File Share / Filtering Platform Connection** — file-share and
  network-connection auditing can be very chatty on file servers and heavily networked hosts.

The baseline is tuned for **workstations**; the Implementation Guide flags where to dial specific
subcategories down (or up) for **servers** and for high-volume environments, and points you to the
forwarding solution so volume is a SIEM-ingestion decision, not a reason to stop auditing.

## Benefits
- **A consistent, baseline-aligned audit trail** on every Windows endpoint — no more per-machine drift
  in what is (or isn't) being logged.
- **Detection-ready by default** — command-line process auditing and the logon/account/privilege events
  that SOC playbooks and SIEM rules expect.
- **Deterministic** — the force-subcategory override is set explicitly, so the baseline can't be
  silently voided by a legacy audit setting.
- **No re-enrollment, fully reversible** — it deploys a configuration profile only; unassigning it
  cleanly reverts the device to its prior audit state.
- **Right-sized retention** — a larger Security log so evidence survives long enough to be collected or
  forwarded.

## Limitations (be honest with buyers)
- **Endpoint auditing only.** This makes devices *generate and keep* events; it does **not** forward
  them to a SIEM (see the Sentinel forwarding solution).
- **Windows 10/11 enrolled devices.** It targets Intune-managed Windows 10/11; it is not a macOS/iOS or
  a Linux capability, and it is not a Group Policy deliverable (though the same subcategories map 1:1 to
  GPO if you also manage domain controllers that way).
- **Settings-Catalog setting IDs can change.** The setting definition names below reflect current
  Microsoft documentation — **verify them in your tenant** before fleet rollout rather than assuming.
- **Volume is real.** High-value subcategories are high-volume; size logs and plan SIEM ingest
  accordingly.

## The standard deployment model
This solution uses **one** repeatable model across our catalog:

> **Windows 10/11 endpoints receive the Advanced Audit Policy baseline (CIS / Microsoft-aligned
> Success/Failure subcategories + command-line process auditing + a right-sized Security log) as a
> single Intune Settings Catalog profile, with the force-subcategory override set explicitly, deployed
> pilot-first and reversible.**

Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**
