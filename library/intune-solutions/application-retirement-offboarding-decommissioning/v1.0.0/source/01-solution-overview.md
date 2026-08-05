# 1. Solution Overview — Application Retirement, Offboarding & Decommissioning (Microsoft Intune)

## What this solution is

Every organisation is good at *deploying* applications and bad at *retiring* them. Apps accumulate:
the vendor went end-of-life three years ago, two teams bought overlapping tools, a security finding
landed on a product nobody owns, or you are paying maintenance on 400 licences for software that 26
people opened last quarter. Nobody removes it, because removal feels risky and nobody owns the
decision.

This solution is the **end of the application lifecycle**: a repeatable, evidence-backed process to
retire an application from a Microsoft Intune-managed Windows fleet and prove it is gone. It covers
the decision (should this app be retired, and who says so), the impact analysis (who still uses it
and what depends on it), the communication and grace period, the **staged uninstall campaign**, the
data and licence obligations, the cleanup of everything the app leaves behind in your tenant, and
the **evidence pack** that closes the ticket.

It is a **process and campaign** discipline, not a debugging manual. When an individual device's
uninstall genuinely fails at the installer level — a broken MSI cache, a hung uninstall string, a
0x80070643 — that is deep Win32 uninstall failure remediation and belongs to a dedicated
troubleshooting discipline. Here, a per-device failure is simply a **straggler**: this solution tells
you how to count them, contain them, escalate them, and stop them from blocking the campaign.

## Why retirement needs its own process

Deployment and retirement are not mirror images:

| | Deployment | Retirement |
|---|---|---|
| Failure mode | User doesn't get the app | User loses access to something, sometimes with data |
| Reversibility | Re-deploy | Often **irreversible** — local data can be destroyed |
| Who notices | The user, immediately | The user, sometimes weeks later, at the worst moment |
| Ends when | App is installed | App is gone **and** every artefact, licence, and reference is gone |
| Evidence needed | Install count | A defensible decommission record for audit, security, and finance |

A retirement done badly produces the two worst outcomes at once: a user who lost data they needed,
and an app that is still 60% installed while you have already cancelled the licence.

## How it works — the retirement pipeline

The solution runs the standard **Assess → Configure → Pilot → Validate → Expand** model, shaped for
removal:

```
Trigger  →  Decision Record  →  Impact Analysis  →  Comms + Grace Period
      →  Data Handling  →  Uninstall Wave 0 (Pilot)  →  Validate
      →  Waves 1..N (Broad)  →  Straggler Handling  →  Artefact Cleanup
      →  Licence Reclamation  →  Evidence Pack  →  Post-Retirement Monitoring
```

Each stage has an owner, an input, and an exit gate. You do not advance a wave until the previous
wave's gate passes — because unlike a deployment, you cannot un-remove an app.

### The five retirement triggers

An app enters the retirement pipeline for one of five reasons. Naming the trigger matters, because
it sets the urgency and who has to approve:

1. **End of life / end of support (EOL/EOS)** — the vendor has stopped shipping security fixes.
   Planned, date-driven; the removal deadline is the vendor's EOS date.
2. **Security risk** — an unpatchable vulnerability, a failed vendor assessment, or a compliance
   finding. Urgency is set by the security owner; grace periods shrink or vanish.
3. **Redundancy** — two or more tools do the same job after a merger, a re-org, or a platform
   standardisation. The replacement app must exist and be deployed **first**.
4. **Low utilisation** — telemetry shows the install base dwarfs the active user base. Driven by
   evidence, not opinion.
5. **Licence cost** — renewal is due and the spend is not justified. The removal must complete
   **before** the renewal date, or you pay for another term.

### How Intune actually removes an application

This is the mechanic the whole campaign rests on, and it is widely misunderstood:

- Intune apps carry an **assignment intent**: **Required**, **Available for enrolled devices**,
  or **Uninstall**. The **Uninstall** intent is what removes software.
- For a **Win32 app**, the Uninstall intent causes the Intune Management Extension (IME) to run the
  app's stored **uninstall command line** — the one recorded when the app was created. If that
  command is wrong, missing, or interactive, the uninstall fails. The command is executed on the
  device; Intune does not "know how" to remove software on its own.
- For **line-of-business (MSI/LOB)** apps, Intune calls the MSI uninstall for the recorded product
  code.
- For **Microsoft Store apps**, the Uninstall intent removes the package for the targeted scope
  (device or user, depending on how it was published).
- **Intents conflict, and the strongest wins in a defined order.** If a device is in *both* a group
  assigned **Required** and a group assigned **Uninstall**, the app stays installed — **Required
  wins**. This is the single most common reason a retirement campaign appears to do nothing. You
  must **remove the old Required assignment**, not merely add an Uninstall assignment on top.
- **Deleting the app object from Intune does NOT uninstall it from devices.** It only stops Intune
  managing it, and it destroys your ability to target the app for removal or to report on it.
  Deleting the app is the **last** step of the campaign, never the first.
- **Supersedence with "Uninstall previous version"** is a different mechanism — it removes an app as
  a side effect of installing a replacement. It is the right tool when retirement means *migration*
  to a successor app, and it is covered in this solution as a retirement path.
- The uninstall only happens **when the device checks in** and the IME evaluates the app workload.
  A device that never checks in never uninstalls anything. Your campaign's real completion rate is
  bounded by your fleet's check-in rate.

### Waves, not a big bang

The campaign targets **assigned Entra security groups**, one per wave, so that at any moment the
blast radius is a number you chose:

- **Wave 0 — Pilot:** 5–15 devices whose owners know it is happening and have agreed to be first.
- **Wave 1 — Early:** roughly 10% of the install base, spread across departments and device types.
- **Wave 2..N — Broad:** the remainder, in tranches you can support.
- **Retain / Exclude:** devices with a documented, time-limited exemption. This group is an
  **exclusion** on every wave assignment, and it must have an expiry date or it becomes permanent.

## Benefits

- **A decision you can defend.** Every retirement carries a written decision record with the
  trigger, the evidence, the approver, and the replacement.
- **No surprise data loss.** Data obligations are identified and satisfied *before* the destructive
  step, with an explicit go/no-go checkpoint.
- **Controlled blast radius.** Waves, exclusions, and gates mean a mistake affects ten devices, not
  ten thousand.
- **Real cost recovery.** Licences are reclaimed and reported, so the saving shows up in a budget
  line instead of being assumed.
- **A genuinely clean tenant.** Groups, assignments, scripts, app-control rules, and Conditional
  Access references are removed too — not just the app.
- **Audit-ready proof.** The evidence pack answers "is it gone?" with data, not with an opinion.

## Limitations — read these before you start

- **Removal can be irreversible and can destroy local data.** Many uninstallers delete
  `%ProgramData%` and `%LOCALAPPDATA%` content, licence activations, local databases, cached
  documents, and plug-in configurations. Some do not. You must determine which, per app, before
  Wave 0. This solution puts a hard checkpoint there.
- **Intune cannot uninstall what it did not install, unless you give it a command.** For software
  installed by SCCM/Configuration Manager, a legacy script, or a user, you must create an Intune app
  object (or a remediation) with a working uninstall command to target it.
- **You cannot force a device to check in.** Offline, decommissioned, and long-idle devices will not
  uninstall. The campaign must define what "done" means in the presence of unreachable devices.
- **Per-device uninstall failures are out of scope here.** When a specific machine's uninstall
  genuinely errors at the installer level, escalate to a Win32 uninstall failure remediation
  discipline; this solution covers detecting, counting, containing and escalating those stragglers.
- **Intune does not report "usage".** Install state is not utilisation. Real usage evidence comes
  from the vendor's admin console, licence-server logs, SSO/Entra sign-in logs for the app's
  enterprise application, or an endpoint analytics/telemetry source. This solution shows you where
  to get it; it cannot manufacture it.
- **Microsoft Store (new) app uninstall behaviour differs by publish scope** (user vs device).
  Confirm the scope before assuming an Uninstall assignment will reach the user's copy.

## The standard deployment model

**Assess → Configure → Pilot → Validate → Expand** — applied as: assess the install base and impact,
configure the wave groups and Uninstall assignments, pilot on Wave 0, validate with the testing
gates, then expand wave by wave to the whole install base, closing with cleanup and evidence.

## Government (GCC / GCC High / DoD) note

The retirement mechanics — assignment intents, the Uninstall intent, supersedence, wave targeting,
artefact cleanup — are **the same** in US Government clouds. What differs is **where you sign in and
which service endpoints you talk to**. Wherever this guide names a portal or Graph endpoint, use the
sovereign equivalent:

| Commercial | US Gov (GCC High / DoD) |
|---|---|
| `https://intune.microsoft.com` | `https://portal.azure.us` (and, where enabled, `https://intune.microsoft.us`) |
| `https://entra.microsoft.com` | `https://portal.azure.us` |
| `https://login.microsoftonline.com` | `https://login.microsoftonline.us` |
| `https://portal.manage.microsoft.com` (Company Portal web) | `https://portal.manage.microsoft.us` |
| `manage.microsoft.com` (service endpoint) | `manage.microsoft.us` |
| `https://graph.microsoft.com` | `https://graph.microsoft.us` (GCC High) · `https://dod-graph.microsoft.us` (DoD) |

For the PowerShell scripts, connect with `Connect-MgGraph -Environment USGov` (GCC High) or
`-Environment USGovDoD` (DoD) — every script in this package accepts an `-Environment` parameter for
exactly this. Feature availability in sovereign clouds can lag Commercial; where a specific control
in this guide is not present in your tenant, **verify for GCC High** against Microsoft's current US
Government service documentation before assuming it is a fault.
