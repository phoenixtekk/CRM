# 7. Best Practices — Cloud-App DLP (Defender for Cloud Apps)

Field-tested practices for running cloud-app DLP with Microsoft Defender for Cloud Apps so the control stays
trusted, effective, and low-noise across third-party SaaS. These complement the Implementation and Testing
guides.

## Pilot in test mode before you enforce — always
- **Never** switch a new session policy straight to *block* or a file policy straight to *quarantine*. Run
  the **Entra Conditional Access policy in report-only**, **session policies in Monitor only**, and **file
  policies in alert-only** first, long enough to capture representative activity (Req 2.6), and read the
  results before enforcing.
- Treat **report-only / Monitor only as your permanent safety switch**: any session control reverts to
  report-only in one setting, instantly removing real-time enforcement with no data change — this is your
  rollback.
- Enforce **one action at a time** on a **pilot ring** (scoped via the CA policy assignment and the file
  filter) before expanding; escalate *remove-sharing → apply-label → quarantine* and *monitor → protect →
  block* gradually, re-validating each step.

## Pick the right plane for the risk
- **Data already sitting in a SaaS app** (over-shared files, legacy exposure) is a **file-policy** problem —
  it needs an **API connector** and at-rest governance (remove sharing, apply label, quarantine).
- **Data moving in a live session** (download to an unmanaged device, upload, copy/print) is a
  **session-policy** problem — it needs **Conditional Access App Control** routing and real-time action.
- Most real programs need **both**. Using only one leaves the other exposure uncovered.

## Reduce false positives (adoption depends on it)
- Start at **higher SIT confidence** and a **realistic instance count** — a single card number is noise; ten
  in one file is a leak.
- **Narrow the filter**: target specific apps, folders/sites, sharing levels (external/public), or owners
  rather than "all files" — precision cuts false positives dramatically.
- **Match on a sensitivity label** where the label is more reliable than a broad SIT — it reuses a decision
  already made at classification time.
- Every false positive that governs or blocks legitimate work erodes trust in the whole program. Budget for
  a tuning cycle, not a one-time build.

## Session-control specifics (know the limits)
- **Verify the target app is supported for session control** and that the activities you want (download,
  upload, copy, print) are proxy-controllable — native/desktop clients and some apps have gaps. Don't assume
  coverage you haven't confirmed.
- Roll session controls out **Monitor-first** so you see real activity patterns before blocking; then move
  scoped activities to **Block/Protect**.
- Prefer **Protect on download** (apply label/encryption) over a hard **Block** where the business still
  needs the file — it controls the data without stopping the work.

## File-policy / connector specifics
- **The connector is the gate.** A file policy is inert until the app's **API connector** is connected and
  its initial scan has run — verify connector health before blaming the policy.
- Prefer **reversible governance** (remove sharing, apply label) before **irreversible** actions (trash);
  use **quarantine** (which is recoverable from the quarantine location) rather than trash where you need to
  hold a file.
- Watch **connector API limits and scan latency** — at-rest governance is periodic, not instantaneous;
  size expectations accordingly.

## Classification hygiene
- **Reuse the Purview SIT/label layer** — cloud-app DLP is an *extension* of your existing classification,
  not a parallel one. Fewer, well-tuned detectors beat a sprawl of overlapping ones.
- **Version and document** which SIT/label each policy matches (confidence, instance count, filter, owner)
  so tuning changes are traceable.

## Operations & governance
- Give MDCA **alerts an owner and an SLA** (Req 2.7). Match volume without triage is not a control. Forward
  to **SIEM/Microsoft Sentinel** where central SecOps needs visibility; MDCA alerts also surface as
  **incidents in the Microsoft Defender portal**.
- Review the false-positive rate, session blocks, and file-governance actions on a **recurring cadence**;
  re-tune as apps, data, and behavior drift.
- Enforce **least-privilege roles** and, where possible, **separate policy authors from connector admins and
  from alert triagers**.
- Keep a **change log** of every report-only→on / Monitor→Block / alert-only→governance transition, with the
  compliance sign-off attached.

## Stay inside the boundary
- Cloud-app DLP is **one control**, not a guarantee — session control has app/activity coverage limits and
  file inspection sees only content it can classify. Combine with sensitivity labels, endpoint DLP, and
  insider risk where the risk warrants.
- **Verify licensing/tenant** before relying on MDCA, content inspection, or Conditional Access App Control —
  plans and portal paths (now under the **Defender portal → Cloud apps**) evolve; don't assume a feature is
  present.
- The **governance/session action and the acceptable false-positive threshold per category are
  compliance/legal determinations** — you provide the technical control and the evidence; they own the
  decision.
