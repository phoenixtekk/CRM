# 7. Best Practices — HIPAA & HITRUST Endpoint Compliance & Vulnerability Remediation (Intune + Defender)

Operational guidance for running the control set well, surviving an audit, and avoiding the failure modes that turn a good baseline into a false sense of security.

> Reminder: these practices strengthen the **technical enforcement and evidence**. Compliance and certification also require organizational policy, risk analysis, training, BAAs, physical safeguards, and (for HITRUST) authorized assessment.

## Naming and traceability

- **Use the `<Purpose> – <Scope> – <Stage>` names verbatim** across Intune, Defender, the CA gate, scripts, and evidence (`Encryption – Clinical Endpoints – Baseline`, `Require Compliance – Clinical Endpoints – Gate`, etc.). Consistent names let an assessor trace control → object → evidence in seconds.
- **One scope group, named once.** Assign every object to **`HIPAA – Clinical Endpoints`**. Avoid per-policy ad hoc groups — divergent scope is the most common silent gap.
- **Keep the control mapping current.** Treat it as a living artifact; update it whenever an object is created, renamed, or retired, under change control.

## Compliance policy design

- **Measure what you enforce.** Every setting in the compliance policy must have a matching configuration baseline that enforces it. A policy that *measures* BitLocker without a baseline that *deploys* it just reports failure.
- **Advance the patch bar deliberately.** Raise *Minimum OS version* on a schedule as Windows builds progress; pair with the Update ring so devices can actually meet the bar before it rises.
- **Set a grace/action period thoughtfully.** Immediate non-compliance marking is honest for audit but can be disruptive; pair with a user notification so clinicians know how to self-remediate.
- **Use Defender machine risk as a compliance signal** (risk score condition) so an actively compromised device falls out of compliance and is gated.

## Conditional Access (the gate)

- **Always roll out in Report-only first**, review impact in sign-in logs, then enable. A misconfigured gate can lock clinicians out of the EHR.
- **Keep a tested break-glass account** excluded from all CA policies, with monitored sign-ins and a securely stored credential. Test it before you need it.
- **Scope the gate to the resources that hold ePHI** where possible, rather than all apps, to minimize collateral lockout while still protecting sensitive data.
- **Account for shared/kiosk clinical workstations** explicitly — confirm the gate behaves correctly with shared sign-in patterns.

## Vulnerability management (Defender TVM)

- **Prioritize by exposure, not count.** Close the few recommendations that drive most of the exposure score first; don't chase a long tail.
- **Close patch findings with the Update ring, config findings with baselines.** Don't remediate by hand what a policy should enforce — manual fixes drift back.
- **Govern exceptions strictly.** Every exception needs a justification, an owner approval (R10), and an expiry. Medical-device and vendor-locked software are legitimate but must be time-bound and reviewed, not permanent.
- **Watch clinical/medical devices.** Many run unpatchable embedded OSes; isolate or compensate (network segmentation) rather than silently accepting risk on the general baseline.

## Evidence and audit readiness

- **Automate evidence on a cadence.** Schedule `HIPAACOMP-Report.ps1` and `HIPAACOMP-Validation.ps1`; date-stamp output. Evidence you have to scramble to produce mid-audit looks like evidence you don't keep.
- **Retain for the look-back period.** HIPAA documentation retention is six years; keep dated exports for the full window in the access-controlled repository.
- **Never put ePHI in evidence.** Reports capture device/compliance/exposure metadata only (GR6). The evidence store must not become a new breach surface.
- **Keep baseline vs current exposure** so you can demonstrate trend (improvement) over the period, which assessors value more than a single snapshot.

## Operations and change control

- **Pilot before broad rollout.** Apply new/changed objects to a small pilot subset of `HIPAA – Clinical Endpoints` first, validate, then expand.
- **Gate changes through the owner.** Changes to compliance settings, the CA gate, and exceptions go through the change/exception process (R12) with approval and a record.
- **Reconcile baseline conflicts.** If you apply a Microsoft Security baseline alongside targeted baselines, check for and resolve conflicting settings (Intune flags conflicts in per-setting status).
- **Use Microsoft Purview Compliance Manager** as an optional aid to track improvement actions against a HIPAA/HITRUST template — but treat its score as guidance, not certification.

## Least privilege and identity hygiene

- **Scope admin roles** (Intune Administrator, Security Administrator, Conditional Access Administrator) rather than Global Administrator; make privileged roles PIM-eligible where licensed.
- **Enforce MFA for all admins** and ideally all users — credential theft remains the leading healthcare breach cause.
