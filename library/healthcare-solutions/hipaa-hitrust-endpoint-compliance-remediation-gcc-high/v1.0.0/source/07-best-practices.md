# 7. Best Practices — HIPAA & HITRUST Endpoint Compliance & Vulnerability Remediation (Intune + Defender) — Government (GCC High)

Operational guidance for running the control set well on a sovereign tenant, surviving an audit, and
avoiding the failure modes that turn a good baseline into a false sense of security.

> Reminder: these practices strengthen the **technical enforcement and evidence**. Compliance and
> certification also require organizational policy, risk analysis, training, BAAs, physical safeguards,
> and (for HITRUST) authorized assessment.

## Sovereign-cloud hygiene (GCC High first principles)

- **Bookmark the `.us` portals and delete the `.com` ones.** Every admin surface is `.us`
  (`intune.microsoft.us`, `entra.microsoft.us`, `security.microsoft.us`, `compliance.microsoft.us`,
  `portal.office365.us`, `portal.azure.us`). A stray `.com` bookmark is the single most common way to
  "lose" your tenant.
- **Every script connects with `-Environment USGov`.** Confirm the connection banner shows
  **Environment: USGov** before you trust any output. A missing `-Environment USGov` silently reaches
  Commercial and returns nothing — which looks exactly like "no devices / no evidence."
- **Keep the evidence store inside the Gov boundary.** Retain compliance/exposure evidence in the GCC
  High tenant (R11), not a Commercial SharePoint or a personal share.
- **Verify features before you depend on them.** Government rollout trails Commercial. For any dashboard,
  report, connector, or update policy you plan to rely on, confirm it in your `.us` tenant first and
  treat anything unconfirmed as absent (see `gcc-high-parity-notes.md`).

## Naming and traceability

- **Use the `<Purpose> – <Scope> – <Stage>` names verbatim** across Intune, Defender, the CA gate,
  scripts, and evidence. Consistent names let an assessor trace control → object → evidence in seconds.
- **One scope group, named once.** Assign every object to **`HIPAA – Clinical Endpoints`**. Divergent
  scope is the most common silent gap.
- **Keep the control mapping current** — a living artifact updated whenever an object is created,
  renamed, or retired, under change control.

## Compliance policy design

- **Measure what you enforce.** Every setting in the compliance policy must have a matching configuration
  baseline that enforces it. A policy that *measures* BitLocker without a baseline that *deploys* it just
  reports failure.
- **Advance the patch bar deliberately.** Raise *Minimum OS version* on a schedule as Windows builds
  progress; pair with the **Update ring** (`Patch – Clinical Endpoints – Baseline`) so devices can meet
  the bar before it rises. On GCC High the ring is your patch mechanism — the newer update *policies* are
  not yet available.
- **Use Defender machine risk as a compliance signal** so an actively compromised device falls out of
  compliance and is gated (the Intune ↔ Defender connector works on GCC High).

## Conditional Access (the gate)

- **Always roll out in Report-only first**, review impact in `entra.microsoft.us` sign-in logs, then
  enable. A misconfigured gate can lock clinicians out of the EHR.
- **Keep a tested break-glass account** excluded from all CA policies, with monitored sign-ins and a
  securely stored credential. Test it before you need it.
- **Scope the gate to the resources that hold ePHI** where possible, to minimize collateral lockout.
- **Account for shared/kiosk clinical workstations** explicitly — confirm the gate behaves correctly with
  shared sign-in patterns.

## Vulnerability management (Defender TVM on GCC High)

- **Prioritize by exposure, not count.** Close the few recommendations that drive most of the exposure
  score first; don't chase a long tail.
- **Close patch findings with the Update ring, config findings with baselines.** Don't remediate by hand
  what a policy should enforce — manual fixes drift back.
- **Govern exceptions strictly.** Every exception needs a justification, an owner approval (R10), and an
  expiry. Medical-device and vendor-locked software are legitimate but must be time-bound and reviewed.
- **Work around the two Gov-unavailable DVM functions.** **Report inaccuracy** and **Request CVE
  support** do not exist in Gov — capture any recommendation-accuracy concern or CVE-coverage gap in your
  **own** change record (R12) and escalate through Microsoft support, rather than expecting the portal
  button.
- **Watch clinical/medical devices.** Many run unpatchable embedded OSes; isolate or compensate (network
  segmentation) rather than silently accepting risk on the general baseline.

## Evidence and audit readiness

- **Automate evidence on a cadence.** Schedule **`HIPAACOMPG-Report.ps1`** and
  **`HIPAACOMPG-Validation.ps1`** (both `-Environment USGov`); date-stamp output.
- **Retain for the look-back period.** HIPAA documentation retention is six years; keep dated exports in
  the sovereign, access-controlled repository.
- **Never put ePHI in evidence.** Reports capture device/compliance/exposure metadata only (GR6). The
  evidence store must not become a new breach surface.
- **Keep baseline vs current exposure** to demonstrate trend over the period — assessors value trend over
  a single snapshot. Note in your evidence where a Gov Secure Score recommendation differs from
  Commercial (an expected parity gap, not a finding).

## Operations and change control

- **Pilot before broad rollout.** Apply new/changed objects to a small pilot subset of `HIPAA – Clinical
  Endpoints` first, validate with the scripts, then expand in waves.
- **Gate changes through the owner.** Changes to compliance settings, the CA gate, and exceptions go
  through the change/exception process (R12) with approval and a record.
- **Reconcile baseline conflicts.** If you apply a Microsoft Security baseline alongside targeted
  baselines, resolve conflicts (Intune flags them in per-setting status); confirm the baseline version is
  present on your GCC High tenant first.
- **Use Microsoft Purview Compliance Manager** (`compliance.microsoft.us`) as an optional aid to track
  improvement actions against a HIPAA/HITRUST template — treat its score as guidance, not certification,
  and confirm the template is available in your Gov tenant.

## Least privilege and identity hygiene

- **Scope admin roles** (Intune Administrator, Security Administrator, Conditional Access Administrator)
  in `entra.microsoft.us` rather than Global Administrator; make privileged roles PIM-eligible where
  licensed.
- **Enforce MFA for all admins** (and ideally all users) via `login.microsoftonline.us` — credential
  theft remains the leading healthcare breach cause.
