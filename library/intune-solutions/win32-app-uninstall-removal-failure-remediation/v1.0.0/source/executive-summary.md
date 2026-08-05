# Executive Summary

## The problem

You told Microsoft Intune to remove a Win32 application, and it did not come off. The console reports
**Uninstall failed**, or a raw code like **1605**, or the device sits at **Pending** — or, worse,
Intune reports the app as **removed** while it is plainly still installed on hundreds of machines. The
team retries, re-syncs, re-assigns, and eventually deletes the app object to "force" it, which strands
the software on every device that had not yet processed the removal. Hours are burned, licences keep
being consumed, and non-compliant or unwanted software lingers on the fleet.

Removal is not installation in reverse. Intune's Uninstall intent has its own delivery path, its own
exit codes, and its own failure modes — almost all of them invisible in the console. Guessing does not
fix them.

## The solution

This is a **branch-based diagnostic playbook for the Win32 app removal path specifically**. It
explains how Intune actually processes an **Uninstall** intent — how it reconciles conflicting
intents (`Required` silently beats `Uninstall`), how **detection rules gate the removal on both ends**
(deciding whether the uninstall runs *and* whether it is judged successful), and how the Intune
Management Extension executes the uninstall command and maps its exit code. From that model it gives
you a **Step 0 fact-finding routine** and **nine labelled branches (A–I)** — intent conflict,
detection-said-gone, detection-loop, stale ProductCode (1605), wrong EXE switches (1603), per-user vs
per-machine context, app-in-use (1618), supersedence removal, and reporting/lifecycle — each with
**symptom → why → exact fix → re-validate**. Five PowerShell scripts read the real state from the
device and Microsoft Graph and make safe, gated fixes.

## What you get

- A precise **model of the Uninstall intent** — intent reconciliation, detection-gated removal,
  exit-code mapping, install context — so "uninstall failed" becomes a named cause.
- A **Diagnostic Playbook** of nine removal-failure branches with exact console navigation, registry
  paths, exit-code decoding, and the IME log lines to search for.
- **Five PowerShell scripts** — read-only on-device Discovery (real ProductCode + uninstall string +
  cache state), an assignment-conflict detector, a Graph uninstall-status Reporter, an IME
  LogParser, and a **-WhatIf**-gated Remediation that corrects the uninstall command, detection rule,
  or conflicting assignment.
- **Four removal gates** that prove the software is physically gone, that Intune agrees, and that it
  stays gone — plus **Best Practices** that stop these failures at packaging time.

## Business impact

- **Faster resolution:** removal failures traced to their real cause in minutes, not iterated on for
  days.
- **Clean fleet:** unwanted, non-compliant, or licence-costing software is actually removed and
  proven gone — not just marked gone.
- **Lower risk:** every removal is piloted and validated before the fleet; remediation is gated and
  reversible in preview.
- **Retained capability:** the method and scripts stay with your team and work for every future app
  retirement.

## Bottom line

Every failed Win32 uninstall is traced to its real cause — intent conflict, detection, ProductCode
drift, command switches, install context, app-in-use, supersedence, or reporting — and fixed, with a
repeatable method and scripts you keep, at a fraction of the cost of ad-hoc troubleshooting or outside
consulting.
