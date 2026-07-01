# Executive Summary — Epic Hyperdrive & Hyperspace Client Deployment & Lifecycle Management with Microsoft Intune

The Epic clinical EHR client is the most important application on a clinical endpoint — and one of the
hardest to manage well at scale. It runs on shared, always-on devices used directly in patient care
(clinical workstations, workstations-on-wheels, exam-room PCs), it must stay version-coherent with the
organization's Epic environment, and a bad client build pushed to the floor is a patient-safety event,
not just an IT incident. This solution turns Epic client deployment from a manual, error-prone task
into a **repeatable, ring-based, fully auditable lifecycle** managed through **Microsoft Intune** (and
Microsoft Configuration Manager where devices are co-managed).

## What you get

- **A productized packaging and deployment method** for the Epic client — both the current
  **Hyperdrive** (Chromium / WebView2-based) and legacy **Hyperspace** — as an Intune **Win32 app**
  with **version-pinned detection**, requirement rules, and (for Hyperdrive) a **WebView2 runtime
  dependency**.
- **Ring-based rollout** using named Entra device groups (`Epic Hyperdrive – Pilot Ring`,
  `Epic Hyperdrive – Broad Ring`, `EPIC – Clinical Workstations`) so every release and upgrade is
  proven on a small, representative set of devices before reaching the clinical floor.
- **A validation gate** — documented tests plus PowerShell tooling — confirming the correct version
  installed, the client launches and loads, and **Imprivata badge-tap into Epic still works** before
  the rollout is allowed to expand.
- **A clean lifecycle** — upgrades delivered via Intune **supersedence** (the new version
  automatically uninstalls and replaces the old), and a deliberate **retire / uninstall** path so no
  stale Epic client is ever left behind on a shared device.
- **Five operational PowerShell tools** for discovery, validation, fleet reporting, safe remediation,
  and ring-group provisioning.

## Why it matters

- **Patient-safety containment:** ring-based rollout limits the blast radius of any defective client
  build to a handful of validated, non-care devices.
- **Version coherence with Epic:** version pinning and supersedence keep the entire fleet aligned to
  the exact client version the Epic environment expects, eliminating drift and coexisting-version
  problems on shared devices.
- **Auditable, compliant change:** every deploy, upgrade, and retire is change-controlled, windowed,
  reversible, and recorded — aligned to HIPAA / HITRUST expectations for a clinical setting.

## Approach

The work follows the **standard deployment model**: **Assess → Package → Pilot → Validate → Broad
Deploy → Lifecycle (update / supersede / retire)**. Epic-specific installer, version, and
configuration values are obtained from the organization's **Epic build team / Epic UserWeb** and
substituted into an otherwise exact, vendor-accurate Intune / ConfigMgr packaging and lifecycle
method — so the deployment mechanics are correct and the Epic specifics are always authoritative.
