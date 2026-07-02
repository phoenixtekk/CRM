# Solution Overview

## The problem this solves

A Win32 app you assigned in Intune sits at **"Waiting for install status,"** shows **"Not
applicable,"** or fails with a raw error code — and nobody can say whether the cause is a
**requirement rule**, a **detection rule**, a **dependency**, a **supersedence chain**, a
**download failure**, the **installer's own exit code**, or the **Enrollment Status Page (ESP)**.
People retry the install, re-sync the device, and re-create the app, hoping something sticks.

This solution replaces guessing with a **root-cause method**. It treats every app deployment as a
**pipeline** with named stages, gives you a **symptom-driven diagnostic tree** that maps each
observed symptom to the exact pipeline stage that owns it, and hands you **five PowerShell scripts**
that read the state of that pipeline directly from Microsoft Graph — so you fix the real cause the
first time.

It covers the three app types Intune delivers to Windows:

- **Win32 apps** (`.intunewin` packages delivered by the Intune Management Extension).
- **Line-of-business (LOB) apps** (a single `.msi` uploaded directly).
- **Microsoft Store apps** (new Store app type, delivered via winget).

## The app-delivery pipeline

Every app install moves through the same ordered stages. A failure at any stage stops the ones after
it, so **the first stage that fails is the root cause** — everything downstream is a symptom.

1. **Assign** — the app is targeted at a group (Required, Available, or Uninstall) and the device
   is in that group's scope. If the device is not in scope, the app never arrives.
2. **Requirement check** — the Intune Management Extension evaluates the app's **requirement rules**
   (OS version, architecture, disk space, registry/file/script checks). If a requirement is not met,
   the app reports **"Not applicable"** and never attempts to install. This is the single most
   misread state in Intune app deployment.
3. **Dependency / supersedence resolution** — if the app has **dependencies**, those must install
   first; if the app **supersedes** another app, the older app is uninstalled or updated per the
   supersedence rule. A broken link here blocks or reorders the install.
4. **Download** — the Intune Management Extension downloads the encrypted content to
   `C:\Program Files (x86)\Microsoft Intune Management Extension\Content` and decrypts it.
   Network, proxy, disk-space, or content-integrity problems fail this stage.
5. **Install** — the Management Extension runs the install command line. The installer returns an
   **exit code**; Intune maps that code to Success, Failure, Soft reboot, Hard reboot, or Retry
   based on the app's **Return codes** table.
6. **Detection** — after a "success" exit code, Intune runs the app's **detection rules**
   (MSI code, file, registry, or custom script) to confirm the app is actually present. If detection
   does not match, Intune reports the install as **failed** even though the installer succeeded —
   the classic "installs but shows failed" symptom.
7. **Report** — the device sends install status back to Intune, where it appears under the app's
   **Device install status** and **Overview** reports, and (for the ESP) gates sign-in.

## The ESP's role

The **Enrollment Status Page (ESP)** runs during Autopilot / first sign-in and can be configured to
**block device use until selected apps install**. When an app in the ESP's **"Block device use until
these required apps are installed"** list fails or times out, the user is stuck on the ESP with a
generic error. The ESP does not introduce a new failure mode — it makes an existing pipeline failure
(usually requirement, download, install, or detection) **fatal and visible at enrollment time**.
Diagnosing an ESP block therefore means diagnosing the underlying app failure, plus checking the
ESP's own **timeout**, **app selection**, and **assignment** settings.

## The diagnostic model

The method has three moves, applied in order:

1. **Locate the failing stage.** Read the reported state (Not applicable, Waiting, Failed, error
   code) and use the symptom tree in the Diagnostic Playbook to map it to one pipeline stage. Never
   fix a downstream stage before confirming the upstream ones passed.
2. **Read the evidence at that stage.** For every stage there is a definitive source of truth:
   Graph reports the requirement/install/detection state per device, and the **Intune Management
   Extension logs** on the device
   (`C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log` and
   `AppWorkload.log`) record the exact requirement result, download path, install command line,
   returned exit code, and detection result.
3. **Fix the cause, then re-validate the whole pipeline.** Correct the one stage, force a sync,
   and confirm the app walks all the way to **Detected / Installed** — not just past the stage you
   touched.

## What is in this solution

- **This overview** — the pipeline, the ESP's role, and the diagnostic model.
- **Requirements** (`02-requirements.md`) — the Intune roles, Graph read access, and device log
  access you need, each with a verify step.
- **Diagnostic Playbook** (`03-implementation.md`) — the symptom tree with exact checks per branch,
  including where to read the Management Extension logs.
- **Testing** (`05-testing.md`) — the pass/fail gates that prove an app is fixed.
- **Troubleshooting** (`06-troubleshooting.md`) — quick fixes for issues with the method and tools
  themselves.
- **Best practices** (`07-best-practices.md`) — detection-rule and phased-rollout discipline that
  prevents these failures.
- **Deliverables summary** (`08-deliverables-summary.md`) and the **executive summary**.
- **Five PowerShell scripts** — Discovery, Validation, Report, Remediation, and Set-ScopeTargeting.
