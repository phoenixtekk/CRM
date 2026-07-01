# 1. Solution Overview — Intune Win32 Application Packaging & Deployment

## What the Win32 app model is
A Win32 app in Microsoft Intune is a Windows application packaged into a single `.intunewin` file
and deployed to enrolled devices by the **Intune Management Extension (IME)**. Unlike the older
line-of-business (LOB) MSI installer type, the Win32 model wraps **any** installer — MSI, EXE, or a
script — and gives you full control over the **install command**, the **uninstall command**, how
Intune **detects** whether the app is already present, the device **requirements** the app needs,
its **dependencies**, and what it **supersedes**. It is the standard, modern way to ship Windows
software through Intune.

## How it works
1. You wrap your installer and its source files into a `.intunewin` with the Microsoft **Win32
   Content Prep Tool** (`IntuneWinAppUtil.exe`). This is a one-time packaging step per app version.
2. You create a **Windows app (Win32)** in Intune, upload the `.intunewin`, and set the exact
   **install** and **uninstall** command lines, the **install behavior** (system or user), and the
   device **restart** behavior.
3. You author a **detection rule** — the test the IME runs to decide if the app is installed (an MSI
   product code, a file/version, or a registry value). Detection is what makes Intune report the
   correct state; a wrong rule is the number-one cause of "installed but shows failed" or endless
   reinstall loops.
4. You author **requirement rules** — conditions a device must meet before the app is even attempted
   (OS architecture, minimum OS version, disk space, a registry/file/script check).
5. You optionally declare **dependencies** (apps that must install first, e.g. a runtime) and
   **supersedence** (a new version that replaces — and optionally uninstalls — an older app).
6. You **assign** the app to groups. The IME downloads the content, runs the install command in the
   chosen context, then runs the detection rule and reports **Installed / Failed / Not applicable**
   back to Intune.

## Detection vs. requirement rules (the distinction that matters)
- A **requirement rule** answers "*should* this device get the app?" It gates applicability. If a
  device fails a requirement, Intune reports **Not applicable** and never installs.
- A **detection rule** answers "*is* the app already installed?" It is evaluated before install (to
  skip an already-present app) and after install (to confirm success). Detection drives reporting.

## What you can control
- **Install / uninstall command lines** and the **install context** (system vs. user).
- **Detection** by MSI product code, file existence/version/date, registry value, or a custom
  detection script.
- **Requirements:** OS architecture (x64), minimum OS build, free disk space, and custom
  file/registry/script requirement rules.
- **Dependencies** (install order, auto-install) and **supersedence** (replace/uninstall prior).
- **Assignment** as **Required**, **Available** (Company Portal), or **Uninstall**, targeted by ring.
- **Return codes** (which exit codes mean success, soft reboot, hard reboot, or retry).

## Benefits
- **Reliability** — correct detection means Intune reports the true state, not a guess.
- **Any installer** — MSI, EXE, or script all ship through one consistent model.
- **Ordered installs** — dependencies guarantee a runtime lands before the app that needs it.
- **Clean upgrades** — supersedence replaces old versions without leaving duplicates.
- **Safe rollout** — ring assignment means a bad package hits a pilot, never the whole fleet at once.

## Limitations (be honest with buyers)
- A `.intunewin` has a content size ceiling (multi-GB); very large suites may need a different approach.
- Detection and requirement rules are only as good as you author them — guesses cause false states.
- The IME must be present and healthy on the device; it installs automatically on enrolled Windows.
- Per-user installs report per logged-on user; most line-of-business apps install in **system** context.
- Supersedence is one level deep per chain step; deep upgrade chains must be modelled deliberately.

## The standard deployment model
> **Wrap the source into a `.intunewin` → create the Win32 app with correct install/uninstall
> commands → author detection and requirement rules → model dependencies and supersedence → assign
> to a pilot ring → validate → expand to broad.** This is the repeatable way:
> **Assess → Configure → Pilot → Validate → Expand.** A bad build never reaches production because
> the pilot ring is the gate.
