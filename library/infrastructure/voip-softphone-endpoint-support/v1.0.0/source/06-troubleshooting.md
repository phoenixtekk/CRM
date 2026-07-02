# Troubleshooting

This guide covers problems with the **scripts and checks themselves** — not the call-quality symptoms
(those are the Diagnostic Playbook). Use it when a script errors, returns nothing, or gives a result you
don't trust.

## VOIPSUP-Discovery.ps1

**"No matching softphone/VOIP client found."**
The default filter matches common terms (softphone, voip, phone, communicator, calling, meetings). Your
client's display name may differ. Re-run with your client's name fragment:
`-ClientNameFilter your-client-name`. Confirm the expected name in **Settings → Apps → Installed apps**.

**Audio endpoints list is empty or errors.**
`Get-PnpDevice -Class AudioEndpoint` requires the PnP subsystem to be responsive. If it errors, the
Windows audio stack may be unhealthy — run **VOIPSUP-Remediation.ps1 -RestartAudio -Execute** (needs
admin) and re-run Discovery. If still empty, check Device Manager for a missing audio driver.

**CSV export fails.**
The target folder must exist and be writable. Use a path you can write to, e.g.
`-CsvPath .\voipsup-discovery.csv`, and don't have the file open in Excel while exporting.

## VOIPSUP-Validation.ps1 / VOIPSUP-Report.ps1

**"no replies from ..." / Network reachability FAIL.**
Either the target is wrong/unreachable or ICMP is blocked. Confirm the media-edge target from R3/R5 is
correct and reachable (`ping` it manually). If your environment blocks ICMP, measurement against that
target won't work — use an approved probe target that responds, and note in the escalation that
endpoint-side ICMP measurement was limited by policy.

**Latency/jitter look implausibly low or all identical.**
Some environments answer the first probe from a local cache/gateway. Increase the sample with
`-PingCount 30` (or higher) and target the actual media edge, not the default gateway.

**Every network gate FAILs but calls are fine (or vice versa).**
Your thresholds may not match your platform. The defaults are generic starting points — set
`-MaxLatencyMs`, `-MaxJitterMs`, `-MaxLossPercent` from your platform vendor's published endpoint
network guidance (R5) and re-run. Tune on the pilot before trusting fleet-wide results.

**Client version shows but "Version >= minimum" FAILs unexpectedly.**
Version parsing extracts the numeric portion of the display version. If the client uses a non-standard
version string, the comparison may misfire — verify the actual version in **Settings → Apps** and, if
needed, treat the version gate as informational for that client.

**Report shows "client not currently running" as PASS.**
That's intentional — a not-yet-started client isn't a failure. To test client health, launch the client
and place a test call, then re-run so "Process responding" is evaluated.

## VOIPSUP-Remediation.ps1

**Nothing happens / "No action selected."**
You must choose at least one action: `-RestartAudio`, `-RescanDevices`, and/or `-RestartClient`. By
design the script previews (does nothing) until you also pass `-Execute`.

**"requires local administrator rights. Skipping."**
Restarting the audio service and rescanning devices need admin. Run PowerShell **as administrator** (or
via an admin remote-support session) and re-run with `-Execute`.

**Client won't relaunch after stop.**
The script relaunches from the running process's executable path; if that path wasn't available (e.g.
the client runs from a per-user store location), relaunch the client manually. This is expected for some
packaged clients.

**Default communication device isn't changed.**
In-box Windows cmdlets do not expose setting the Default Communication Device programmatically — the
script tells you to set it in **Sound Control Panel (`mmsys.cpl`) → Playback/Recording → right-click →
Set as Default Communication Device**. This is intentional (avoids unsupported registry hacks on live
user devices).

## VOIPSUP-Set-ScopeTargeting.ps1

**"Module 'Microsoft.Graph...' is not installed."**
Install the Graph modules: `Install-Module Microsoft.Graph.Authentication -Scope CurrentUser` and
`Install-Module Microsoft.Graph.Groups -Scope CurrentUser`, then re-run.

**Graph connection or consent fails.**
The signed-in account needs the requested scopes (Group.ReadWrite.All, GroupMember.ReadWrite.All,
User.Read.All, Device.Read.All) and an admin may need to consent. Confirm the operator has **Intune
Administrator** / group-management rights (global requirement G3) and retry.

**"User not found" for a valid person.**
Pass the exact UPN (`user@your-domain`), not a display name or alias. Verify the UPN in Entra → Users.

**Members not added even though it "succeeded."**
Confirm you ran with `-Execute` — in preview mode the script only shows what *would* be added. Re-run
with `-Execute` to write the membership.

## General

**Execution policy blocks the script.**
Run via `powershell -ExecutionPolicy Bypass -File .\SCRIPT.ps1` (as shown in each script's HOW TO RUN),
or set an appropriate policy for the session with `Set-ExecutionPolicy -Scope Process Bypass`.

**Read-only vs. change scripts.**
Discovery, Validation, and Report never change the endpoint. Remediation and Set-ScopeTargeting default
to `-WhatIf` (preview) — they only make changes when you add `-Execute`. When in doubt, run without
`-Execute` first and read the planned actions.
