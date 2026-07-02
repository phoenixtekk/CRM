# 1. Solution Overview — Intune Custom Compliance & Configuration Items (Scripted)

## What custom compliance is
Intune custom compliance lets you evaluate device state that the built-in compliance settings can't
reach — a registry value, a running service, an installed app version, a security control specific to
your organization. It works by pairing two artifacts:
1. A PowerShell **detection script** that runs on the device and returns a small JSON payload of the
   values it discovered.
2. A **JSON rule file** that tells Intune how to judge those values (operators, thresholds) and what
   remediation message to show the user when a value fails.

You upload the detection script under `Devices → Compliance → Scripts`, then reference it in a
custom compliance policy created under `Devices → Compliance → Create policy` (custom compliance).
Intune runs the script, reads the returned settings, applies the JSON rule, and marks the device
compliant or noncompliant on those custom settings — alongside the built-in rules.

## Scripted configuration items
Some device state must be **set**, not just measured. Where the configuration templates and the
built-in compliance UI can't express a setting, use **scripted configuration items** — custom
settings authored in the settings catalog under `Devices → Configuration`. These push the exact
registry value, policy, or OMA-URI you need, so the device reaches the state your custom compliance
rule then verifies. Together they form a measure-and-set pair: the config item makes the device
correct; custom compliance proves it.

## How it works
1. You author a detection script that outputs a JSON object of named settings (for example a
   registry value or an app version).
2. You author a JSON rule file that maps each setting to an operator and value, with a per-rule
   remediation message and severity.
3. You upload the detection script (`Devices → Compliance → Scripts`) and create a custom compliance
   policy that references it and imports the JSON rule.
4. You assign the policy to a pilot group; Intune runs the script on each device and evaluates the
   rule.
5. Non-matching settings mark the device noncompliant on the custom rule; the user sees your
   remediation message.
6. A Conditional Access policy that requires a compliant device then gates access — so a failed
   custom check can block access, not just report.

## What you can control
- Any device-side value a PowerShell script can read (registry, WMI/CIM, file/app version, service
  state, certificate presence) evaluated with your own operators and thresholds.
- Per-rule remediation messages, severity, and the JSON discovery/rule mapping.
- Scripted configuration items for settings the templates can't reach.
- How custom compliance participates in overall device compliance and Conditional Access.

## Benefits
- **Reach** — measure and enforce controls the built-in settings can't express.
- **Precision** — your own operators, thresholds, and messages per rule.
- **Enforcement** — custom results feed device compliance and Conditional Access, not just reports.
- **Repeatability** — a documented author → upload → assign → validate model reused for every check.

## Limitations (be honest with buyers)
- Detection scripts run in **64-bit PowerShell** on the device and must emit valid JSON matching the
  rule file; a script or JSON error surfaces as an error state, not a pass.
- Custom compliance evaluates **Windows** devices; other platforms use their own compliance settings.
- The device must be enrolled and healthy for the script to run and report.
- Scripts should be **signed** (or execution policy allowed) per your standards; treat detection
  scripts as code you review and control.

## The standard deployment model
> **Author the detection script + JSON rule → add scripted config items → upload + create the custom
> compliance policy → assign to a pilot → validate evaluation and the Conditional Access effect →
> expand.** repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**
