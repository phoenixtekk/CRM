# 7. Best Practices — A Maintained NIST 800-53 Program in Microsoft Purview

Operating principles for keeping a NIST SP 800-53-aligned Purview program accurate, evidenced, and
defensible. Grounded in Microsoft's public guidance, NIST's Risk Management Framework, and the
**Assess → Design → Configure → Pilot (simulate) → Validate → Expand (enforce)** model.

## Keep the authorization boundary bright
- **Configure and evidence the control; never assert the authorization.** Whether the system is authorized
  to operate, the boundary, residual-risk acceptance, and control applicability are **AO/security/legal**
  decisions. Every artifact you produce is *input to* that decision, not the decision — say so in the package.
- **Map coverage honestly.** Purview implements a **subset** of 800-53 (mostly AU, AC, SC, MP, SI, and CA/RA
  visibility). Physical, personnel, awareness, and much of IR are organizational. Mark deferred families
  **deferred** in `NIST 800-53 – Control-to-Purview – Map` — overstating coverage fails an assessment.

## Evidence is an artifact, not an assertion
- For every Purview-covered control, attach a **concrete artifact** to its Compliance Manager improvement
  action: a policy export, an audit-config snapshot, a published-label list, a DLP-rule definition. "We have
  a policy" is not evidence; the policy object and its configuration are.
- Keep evidence **current between assessments** — a control that drifted since the last export is a finding.
  The scheduled Discovery→Validate→Report chain keeps the package live, not stale.

## Configure audit before you need it
- **Audit is not retroactive** (AU family). Enable unified audit logging and the AU retention policy **now**,
  so the accountability evidence exists across the assessment window. Every deferred day is permanently
  missing evidence.
- Set audit **retention by event class** to the compliance/records requirement — don't rely on the default,
  and don't invent the duration. Verify accepted `RetentionDuration` values and the long-term tier's licensing.

## Pilot high-impact controls in simulation — always
- DLP, labels, and retention changes are tenant-impacting. Create DLP in **simulation/test mode**
  (`TestWithoutNotifications`) first; it **evidences detection without blocking users**, which is exactly what
  you want during validation. Move to **enforce** (`-Mode Enable`) only after the pilot passes.
- Keep every change **reversible** and record the rollback (`-Remove`, `-SetMode`) with each change so a
  questioned control can be backed out cleanly.

## Least-privilege roles and separation of duties (AC-5)
- Give assessors **Compliance Manager Reader/Assessor**; give the configuring admin the capability roles
  (Information Protection, DLP, Records, Audit). Reserve Global Administrator for one-time enablement.
- Separation of duties is itself a control — the person who configures should not be the sole person who
  attests. Review role membership periodically and log configuration changes.

## Map to the tailored baseline, not the full catalog
- Work from the **tailored baseline / overlay** for your impact level (Requirement 2.5), not the entire 800-53
  catalog. Configure and evidence what applies; record inheritance (e.g. identity controls inherited from
  Entra/Conditional Access) rather than re-implementing it in Purview.
- Note **control enhancements** explicitly — a base control met without its required enhancement is a partial,
  not a pass; the assessor decides.

## Treat the template and portal as evolving
- Compliance Manager's improvement-action count, the NIST template version, and portal paths change. **Verify
  against current Microsoft documentation** rather than freezing a snapshot; re-baseline the map when the
  template updates.
- Confirm current **Compliance Manager automation** options for your tenant before standardizing on any API;
  the scripts here inventory and validate the **underlying Purview controls**, which is the durable evidence
  layer regardless of portal changes.

## Corroborate and cross-reference
- One control often has evidence in more than one place — AU evidence in Purview Audit, monitoring evidence in
  DLP alerts and DSPM, access evidence in labels *and* Entra. Cross-reference in the map so an assessor can
  follow the thread.
- Where a NIST family maps to a control implemented outside Purview (identity, endpoint config, physical),
  **point to the owning system** in the map instead of claiming it.

## Maintain, don't re-project
- The program's value is that it's **maintained**: scheduled read-only Discovery/Validate/Report, drift caught
  early, evidence refreshed, the map updated when scope or template changes. A one-time configuration decays;
  a maintained program passes the *next* assessment too.
