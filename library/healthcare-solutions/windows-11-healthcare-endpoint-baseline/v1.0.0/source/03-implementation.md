# 3. Implementation Guide — Windows 11 Healthcare Endpoint Baseline

Follow these steps in order, in the Microsoft Intune admin center (`https://intune.microsoft.com`).
Create every object with the exact name shown and reuse it verbatim in later steps.

> Model: Build the baseline once, assign it to a small clinical pilot, validate, then expand to the
> whole fleet. The pilot gate protects devices used for care. The repeatable way: Assess to Configure
> to Pilot to Validate to Expand.

## Objects this guide creates (names are fixed — reuse exactly)
| Object | Name |
|---|---|
| Device group (clinical pilot) | `W11 Baseline – Clinical – Pilot` |
| Device group (clinical production) | `W11 Baseline – Clinical – Production` |
| Device group (corporate pilot) | `W11 Baseline – Corporate – Pilot` |
| Device group (corporate production) | `W11 Baseline – Corporate – Production` |
| Configuration profile (device restrictions) | `W11 Device Restrictions – All – Baseline` |
| Settings catalog policy | `W11 Settings Catalog – All – Baseline` |
| Security baseline reference | `W11 Security Baseline – All – Baseline` |
| Update ring (clinical) | `W11 Update Ring – Clinical – Baseline` |
| Update ring (corporate) | `W11 Update Ring – Corporate – Baseline` |
| Power profile (clinical, always-on) | `W11 Power – Clinical – AlwaysOn` |
| Power profile (corporate, battery-saving) | `W11 Power – Corporate – BatterySaver` |

## Step 1 — Create the device groups
1. Entra, Groups, New group, Security; name `W11 Baseline – Clinical – Pilot` (a few representative
   non-production clinical devices). Create.
2. Repeat for `W11 Baseline – Clinical – Production`, `W11 Baseline – Corporate – Pilot`, and
   `W11 Baseline – Corporate – Production`.

(You can create and populate all four with `W11HC-Set-BaselineTargeting.ps1` instead.)

## Step 2 — Create the device-restrictions configuration profile
1. Intune, Devices, Configuration, Create, New policy. Platform Windows 10 and later; Profile type
   Templates; Device restrictions. Create.
2. Name `W11 Device Restrictions – All – Baseline`. Next.
3. Under Microsoft Defender Antivirus, enable real-time monitoring and cloud-delivered protection.
   Under Microsoft Defender SmartScreen, turn SmartScreen on. Under Locked screen experience and
   General, set your lock-screen and basic device controls. Next.
4. Assignments, Add groups, add `W11 Baseline – Clinical – Pilot` and `W11 Baseline – Corporate – Pilot`. Next, Create.

## Step 3 — Create the settings catalog policy
1. Intune, Devices, Configuration, Create, New policy. Platform Windows 10 and later; Profile type
   Settings catalog. Create.
2. Name `W11 Settings Catalog – All – Baseline`. Next.
3. Add settings, search the catalog, and add the fine-grained controls the restrictions template does
   not expose (for example specific Microsoft Defender, AutoPlay, and lock-screen timeout settings).
   Set each to your standard. Next.
4. Assignments, Add groups, add `W11 Baseline – Clinical – Pilot` and `W11 Baseline – Corporate – Pilot`. Next, Create.

## Step 4 — Reference the security baseline
1. Intune, Endpoint security, Security baselines, open the current Security Baseline for Windows,
   Create profile.
2. Name `W11 Security Baseline – All – Baseline`. Next.
3. Review the recommended settings; accept the defaults unless a setting conflicts with a clinical
   workflow. The security baseline is authoritative for security settings, so do not duplicate those
   in the settings catalog policy. Next.
4. Assignments, Add groups, add `W11 Baseline – Clinical – Pilot` and `W11 Baseline – Corporate – Pilot`. Next, Create.

## Step 5 — Create the update rings
1. Intune, Devices, Windows, Update rings for Windows 10 and later, Create profile.
2. Name `W11 Update Ring – Clinical – Baseline`. Set Quality update deferral 3 days, Feature update
   deferral 14 days, Automatic update behavior Auto install and restart at maintenance time, Active
   hours aligned to the clinical maintenance window. Assignments, add
   `W11 Baseline – Clinical – Pilot`. Create.
3. Create profile again. Name `W11 Update Ring – Corporate – Baseline`. Set Quality deferral 7 days,
   Feature deferral 14 days, standard active hours. Assignments, add
   `W11 Baseline – Corporate – Pilot`. Create.

## Step 6 — Create the power/display profiles
1. Intune, Devices, Configuration, Create, New policy. Platform Windows 10 and later; Profile type
   Settings catalog. Name `W11 Power – Clinical – AlwaysOn`. Add the Power settings: set
   plugged-in sleep and display-off timeouts to Never (0) so shared clinical devices stay awake on
   shift; set lid-close action to Do nothing where appropriate. Assignments, add
   `W11 Baseline – Clinical – Pilot`. Create.
2. Create another settings catalog policy. Name `W11 Power – Corporate – BatterySaver`. Set sensible
   on-battery sleep and display-off timeouts so corporate laptops conserve battery. Assignments, add
   `W11 Baseline – Corporate – Pilot`. Create.

## Step 7 — Apply on a pilot device
1. On a pilot device, sync policy (Settings, Accounts, Access work or school, Info, Sync).
2. Confirm the profiles applied (Intune device, Device configuration shows Succeeded), or run
   `W11HC-Validation.ps1`.

## Step 8 — Validate the pilot
1. Run `W11HC-Validation.ps1` on a pilot device to confirm the baseline settings are present.
2. Run `W11HC-Report.ps1` to confirm pilot devices show the baseline policies as Succeeded across the
   fleet view. Complete the Testing Guide. Do not proceed past the pilot gate until all pass.

## Step 9 — Expand to production
1. Open each object (Steps 2 through 6) and in Assignments add the matching Production group:
   clinical objects get `W11 Baseline – Clinical – Production`, corporate objects get
   `W11 Baseline – Corporate – Production`.
2. Re-validate after the next policy cycle with `W11HC-Report.ps1`; remediate any drift with
   `W11HC-Remediation.ps1`.

---
### Order of operations
`Device groups -> Device restrictions -> Settings catalog -> Security baseline -> Update rings -> Power profiles -> Apply -> Validate (pilot gate) -> Expand`
