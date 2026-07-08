# 7. Best Practices — Document Fingerprinting (Microsoft Purview)

Field-tested practices for fingerprinting standard forms and running them in DLP so the control stays
precise, trusted, and current. These complement the Implementation and Testing guides.

## Fingerprint the right source
- **Use a blank or representative template**, not a heavily-filled instance — the fingerprint keys off
  the form's **boilerplate text**, so a clean template with the full boilerplate gives the strongest,
  most specific fingerprint.
- **Prefer form-specific text over generic letterhead.** If a form's only distinctive text is a common
  company header, its fingerprint can over-match unrelated documents that share that header. Choose the
  copy with the most form-unique boilerplate; if needed, trim generic chrome.
- **Confirm the template is text-based** (selectable text, not a flattened image) and inside Microsoft's
  supported **type/size** limits before fingerprinting — an image-only or oversized file yields no or a
  poor fingerprint. **Verify current limits for your tenant.**

## Simulate before you enforce — always
- **Never** switch the DLP policy carrying a fingerprint straight to enforce. Run it in **simulation**
  first, long enough to capture representative form traffic (Req 2.6), and read the results before
  enabling.
- Treat **simulation mode as your permanent safety switch**: the enforced policy can be returned to
  simulation in one setting, instantly removing enforcement with no data change — this is your rollback.
- Prove **both** the positive case (the filled form is detected) **and** the negative case (unrelated
  content is not) in simulation before enforcing.

## Keep detection specific (protect adoption)
- A fingerprint is high-precision by design, but **watch for shared boilerplate** across forms — test
  that each form is detected on its **own** distinctive text, not just a common header (Testing B3).
- Where one SIT over-matches, **split** it so each form is detected independently; where several truly
  related forms belong together, **group** their fingerprints in one SIT for simpler policy wiring.
- Every false positive that reaches a user erodes trust in **every** policy tip. Budget for a short
  tuning/re-sourcing cycle, not a one-time build.

## Refresh fingerprints as forms change
- A fingerprint reflects the template **as fingerprinted**. When a form is revised, detection of the new
  version degrades — **add the revised template's fingerprint to the SIT** (a SIT can hold multiple
  fingerprints) and retire the old where appropriate.
- Assign a **form owner and a refresh trigger** (Req 2.5) so template changes reliably reach the person
  who re-fingerprints. Stale fingerprints are a silent coverage gap.
- **Version and document** each fingerprint (form name, template version, owner, date) so refreshes are
  traceable.

## Right-size the user experience
- Show **clear, actionable policy tips** — tell the user *why* and *what to do* in business language,
  not a compliance error code. Reuse one standard notice (`Fingerprint Notice – Standard – AllPolicies`).
- Prefer **allow-with-justification / override** over hard block for forms where legitimate business
  sharing exists, then **review the overrides** — routine overriding means the policy is mis-scoped.
- Reserve **hard block** for the forms where compliance/legal require it; escalate to block one form at a
  time, re-validating each.

## Classification hygiene
- **Fingerprinting is one technique** — use it where the *form structure* is the signal. Where a value
  pattern is the signal use built-in/custom SITs or EDM; where a learned category is the signal use a
  trainable classifier. Fewer, well-targeted detectors beat a sprawl of overlapping ones.
- The same fingerprint SIT can drive **DLP, auto-labeling, and retention** — get the fingerprint right
  once and reuse it across the Purview estate.

## Operations & governance
- Give fingerprint **DLP alerts an owner and an SLA** (Req 2.7). Match volume without triage is not a
  control. Forward to SIEM/Sentinel where central SecOps needs visibility.
- Review **Activity Explorer** and the false-positive rate on a **recurring cadence**; re-source or
  re-scope as forms and behavior drift.
- Enforce **least-privilege roles** and, where possible, **separate SIT/policy authors from alert
  triagers**.
- Keep a **change log** of every fingerprint created/refreshed and every simulate→enforce transition,
  with the compliance sign-off attached.

## Stay inside the boundary
- Fingerprinting detects **text-pattern** matches — it will not catch an **image-only scan**, a
  **password-protected** file, or a form edited beyond recognition. It is one control among several, not
  a guarantee; combine with sensitivity labels, encryption, and other SITs where the risk warrants.
- **Verify licensing/tenant** before relying on any DLP location or action — plans and portal paths
  evolve; don't assume a feature is present.
- **Which forms are in scope, which obligation applies to each, and the enforced action per form are
  compliance/records/legal determinations** — you provide the technical control and the evidence; they
  own the decision.
