# 8. Deliverables Summary

Everything in this package, and how it fits together. The documents are the method; the scripts turn
the method into read-only evidence and a guarded fix.

## Documents
- **Executive Summary** — why a "Succeeded" Wi-Fi profile leaves the device unchanged, and what this
  solution does about it.
- **1. Solution Overview** — how a Wi-Fi change travels to the saved network, why an in-place edit
  stalls, and how Meraki fits.
- **2. Requirements Guide** — roles, Graph access, per-platform device access, the certificate
  dependency, and the Meraki footprint — each with verify / implement-if-missing. Plus the naming
  convention used everywhere.
- **3. Diagnostic Playbook** — Step 0 (establish the facts) and labelled branches:
  - **A** — modified profile not updating the existing SSID in place (**the crux**).
  - **B** — proxy wrong / wrong field / hostname-vs-URL.
  - **C** — duplicate or conflicting Wi-Fi profiles.
  - **D** — Cisco Meraki dashboard or Systems Manager overriding the client settings.
  - **E** — reports Succeeded but device unchanged (delivery vs application).
  - **F** — platform-specific quirks (Windows / iOS / Android).
- **5. Testing & Validation** — pass/fail gates that prove the change **applied on a device**, not
  just that Intune reported it.
- **6. Troubleshooting** — getting the method, scripts, and access itself working.
- **7. Best Practices** — how to stop it recurring.

## PowerShell scripts (read-only by default; cloud-aware)
All Graph scripts accept `-Environment Global|USGov|USGovDoD` and connect with the matching sovereign
endpoint. Read-only unless you explicitly run the remediation helper without `-WhatIf`.

- **`WIFIDX-Preflight.ps1`** — verify the Graph SDK, sign-in, scopes, and environment before you start.
- **`WIFIDX-Get-WifiProfiles.ps1`** — export every Intune Wi-Fi configuration profile, its
  assignments, and its proxy settings; group by SSID and **flag duplicates/conflicts**.
- **`WIFIDX-Validate-Device.ps1`** — on a Windows device, read the live saved network
  (`netsh wlan show profiles`) and effective proxy — the applied-state ground truth.
- **`WIFIDX-Report-ProfileState.ps1`** — reconcile **reported** (Succeeded) vs **applied** state per
  device and flag Succeeded/applied-mismatch rows.
- **`WIFIDX-Remediation.ps1`** — guarded (`-WhatIf` default) helper to build the corrected/renamed
  replacement profile and/or remove the stale saved network so the corrected profile re-adds it.

## Boundaries (what this does not cover — by design)
- **General config-profile diagnosis** (assignment, filters, sync, CSP conflicts) → the Intune Device
  Configuration & Policy Troubleshooting Toolkit.
- **802.1X certificate deployment** (SCEP/PKCS, trusted root, RADIUS) → the certificate-Wi-Fi and
  Wi-Fi deployment products.
- **Meraki console internals** → verify against current Cisco Meraki documentation.

## Delivery
Delivered as a Word document and a PDF (cover, table of contents, all sections, and a scripts
appendix), plus the five PowerShell scripts — bundled in a single downloadable package you keep and
reuse across unlimited devices.
