# Best Practices — Adaptive Protection in Microsoft Purview

Field-tested guidance for running Adaptive Protection well. It follows the same order the solution is
built: get the **signal and its guardrails** right, then let the **risk level** drive protection —
piloted, proportionate, and defensible.

## 1. Treat the risk level as an automation input, not a verdict

- A user reaching **Elevated** means their **controls tighten** — it is **not** a finding of
  wrongdoing. Communicate this internally so a risk level is never read as an accusation.
- Judgement about whether risky activity warrants a consequence is an **HR/legal determination** (via
  Insider Risk Management), not a technical default and not the administrator's call. Adaptive
  Protection automates **protection**, not decisions.

## 2. Protect the source signal's privacy

- Adaptive Protection is only as trustworthy as the **IRM policy** underneath it. Keep IRM
  **anonymization on** and **role separation** intact; scope the source policy to the **minimum**
  population.
- Deploy with **HR, legal, privacy** (and works-council where applicable) — the same stakeholders IRM
  requires. Record the **lawful basis** before enforcing; the applicability is a **legal
  determination** (`global-requirements-purview.md` §5).

## 3. Always pilot in simulation / report-only first

- **DLP → simulation/test** and **Conditional Access → report-only** are non-negotiable first states.
  They prove risk levels are assigned and the rules *would* act **without disrupting work**.
- Keep the pilot scoped to **`SG-AP-Pilot`** and expand **group-by-group** — never flip to enforce,
  tenant-wide, in one move. Re-run the gates after each expansion.

## 4. Make protection proportionate across the three levels

- Map actions so friction scales with risk: **Minor = audit**, **Moderate = warn/override**,
  **Elevated = block**. Blocking *everyone* defeats the point of Adaptive Protection; auditing *the
  risky* defeats it the other way.
- Reserve the hardest controls (DLP block, CA block/step-up) for **Elevated**, and prefer
  **override/justification** at Moderate so legitimate work has a path.

## 5. Key enforcement on classification, not just risk

- Combine the risk-level condition with a **sensitivity-label** (or SIT) condition so the strongest
  protection lands on your **most sensitive, labeled content** — not on everything a risky user
  touches. This is what makes "label enforcement" precise and defensible.
- If labels are still rolling out, start with sensitive info types and add label conditions as labeling
  matures (R5).

## 6. Tune the mapping deliberately (Custom setup)

- Start with **Quick setup** (recommended default) to get value fast; move to **Custom setup** only
  when you need explicit control over which insider-risk signals map to each level.
- If too many users reach Elevated/Moderate, **retune the source thresholds** (fewer/higher-severity
  triggers) rather than weakening the DLP/CA action — fix the **signal**, not the **response**.

## 7. Guard access continuity on the Conditional Access side

- Always **exclude a break-glass/emergency-access account** from any blocking CA policy, and test that
  exclusion before turning the policy on.
- Prefer a **graduated** access response (require MFA / password change / limited session) over a hard
  block where the business can tolerate it, reserving hard block for genuinely high-risk apps/data.

## 8. Let risk levels decay — don't hard-code them

- Risk levels are **dynamic and time-bound** by design; they **decrease automatically** as behavior
  normalizes. Do not build side-processes that pin a user at a level — that turns an adaptive control
  into a static punishment.

## 9. Report on adaptive behavior, not on people

- Report **counts by risk level, action, and workload** (`PURVAP-Report.ps1`) — the portal's
  **Activity explorer / DLP alerts** and **CA report-only insights** are authoritative.
- Keep leadership reporting **aggregate and privacy-respecting**; identity exposure follows IRM's
  role-gated, audited rules, not a reporting convenience.

## 10. Verify against your tenant — the surfaces evolve

- Adaptive Protection, the DLP risk-level condition, and the CA insider-risk condition are
  **licensing-dependent** and the portals **change**. Confirm capability availability and exact paths
  **against your licensing/tenant** rather than assuming; where a capability is in preview, treat it as
  such.

## 11. Keep the evidence trail intact

- Do **not** delete DLP alerts, IRM cases, or audit records to "clean up" — they are the defensible,
  HR/legal-facing evidence of how protection adapted. Retention/disposition of those records is a
  **records/legal determination**.
