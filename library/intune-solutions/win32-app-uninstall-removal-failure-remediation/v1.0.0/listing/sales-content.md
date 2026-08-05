# Win32 App Uninstall & Removal Failure Remediation (Microsoft Intune) — Sales Content

## The hook

**Make the uninstall actually uninstall — and prove the app is gone.**

You told Intune to remove a Win32 app and it did not come off. The console says *Uninstall failed*,
or *1605*, or it sits at *Pending* — or, worse, it reports the app as removed while it is plainly
still on hundreds of machines. So the team retries, re-syncs, re-assigns, and finally deletes the app
object to "force" it — stranding the software on every device that had not yet processed the removal.

Removal is **not installation in reverse**. Intune's Uninstall intent has its own delivery path, its
own exit codes, and its own failure modes — and almost every one of them is invisible in the console.

## Run it yourself — simpler, cheaper, and proven

You do **not** need a consultant. This is the field-tested method as self-guided, click-by-click
documentation a competent admin can follow end to end, backed by ready-to-run PowerShell.

- **Simpler** — exact ordered steps with full navigation paths (*Intune admin center > Apps > All
  apps > <app> > Properties > Program > Uninstall command*); every group, filter, and evidence folder
  is named and reused through testing and troubleshooting.
- **Cheaper** — one fixed price instead of an open meter; comparable consulting runs well into the
  thousands per day. Reusable on every app you ever retire.
- **Tested** — a pilot-first method (Assess → Configure → Pilot → Validate → Expand) with four
  explicit removal gates: gone from the device, uninstall returned success, Intune agrees, and it
  *stays* gone.

## What's inside

- **Solution Overview** — how Intune processes an Uninstall intent: intent reconciliation (Required
  beats Uninstall), detection-gated removal on both ends, exit-code mapping, and install context
  (SYSTEM vs user, HKLM vs HKCU).
- **Requirements Guide** — Intune roles, Graph scopes, device + IME-log access, and the packaging
  record, each with how to verify it — plus the US Government (GCC High / DoD) targeting note.
- **Diagnostic Playbook** — Step 0 fact-finding plus **nine removal-failure branches (A–I)**:
  assignment intent conflict, detection-said-gone, detection loop, stale ProductCode (1605), wrong
  command/switches (1603), per-user vs per-machine context, app-in-use (1618) and reboot codes
  (3010/1641), supersedence removal, and reporting/lifecycle — each with symptom → why → exact fix →
  re-validate.
- **5 PowerShell scripts** — on-device uninstall-readiness discovery (real ProductCode + uninstall
  string + cache + running processes), an assignment-conflict detector, a fleet uninstall-status
  reporter, an IME log parser, and a guarded remediation (default preview) that corrects the
  uninstall command, generates a ProductCode-resolving wrapper, or re-syncs failed devices.
- **Testing & Troubleshooting Guides** with the four pass/fail removal gates, plus Best Practices for
  authoring uninstall commands, detection rules, and unambiguous intents.

## The repeatable way

Every solution follows the same repeatable shape, so each removal campaign feels familiar and
low-risk — buy once, reuse the playbook for the next app retirement and the next project.

## The bottom line

Every failed Win32 uninstall traced to its real cause — intent conflict, detection, ProductCode
drift, command switches, install context, app-in-use, supersedence, or reporting — and fixed, with a
repeatable method and scripts you keep and reuse.

## Pricing

| Tier | Price |
|---|---|
| Commercial | $2,495.00 |
| Non-Profit (40% off, verified) | $1,497.00 |
| Government (15% off, verified) | $2,120.75 |

Delivered as a Word document and PDF, plus all PowerShell scripts, in a single ZIP — yours to keep and
reuse across unlimited devices.
