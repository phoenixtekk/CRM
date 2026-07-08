# 7. Best Practices — Sensitive Information Types Implementation (Microsoft Purview)

Field-tested practices for selecting, testing, and tuning **built-in** sensitive information types (SITs)
so the detection layer the whole Purview estate depends on stays accurate and low-noise. These complement
the Implementation and Testing guides.

## Reuse built-in before you build anything
- The built-in SIT library is large and **tested by Microsoft** — start there for every category. A well-
  chosen built-in SIT beats a hand-rolled custom one for the common data patterns (payment cards, national
  IDs, IBANs, health identifiers).
- **Pick the most specific SIT.** A country-specific national-ID SIT is more accurate than a generic number
  pattern. Prefer specificity; it cuts false positives at selection time, before any tuning.
- Only flag a **genuine gap** (an internal identifier, or a conceptual category like source code) for the
  custom-SIT / EDM / trainable-classifier solutions — don't force a built-in SIT to do a job it wasn't
  built for.

## Tune the two dials before touching the pattern
- **Confidence level and instance count are your first and cheapest levers.** Start at **High confidence**
  and a **realistic instance count** — a single credit-card match is noise; ten in one item is a likely
  leak. These two settings, changed per policy at no cost, resolve most false positives.
- **You cannot edit a built-in SIT's pattern** — and you usually shouldn't need to. Reach for an **editable
  copy** only when the two dials genuinely can't separate your true positives from your look-alikes (e.g.
  your internal reference numbers share the exact format). Tune the **copy**; never assume the built-in
  original changed.
- **Set the dials once, in the `SIT Threshold Register`**, and reuse them everywhere the SIT is consumed —
  DLP, auto-labeling, retention — so detection is consistent across the estate.

## Test with fake data, both ways
- Every SIT test uses **clearly-fake sample data** — documented test values for positives, synthetic look-
  alikes for negatives. **Never** use production sensitive data in a corpus.
- **Test the negatives as hard as the positives.** A SIT that catches every real card number but also fires
  on internal order IDs is a false-positive machine. The look-alike corpus is what proves the SIT is safe
  to turn on downstream.
- Use the portal **Test** experience for a quick per-SIT check and the scripted corpus run for scale — score
  the whole corpus before and after every tuning change.

## Measure against reality, in simulation
- The corpus proves a SIT in the lab; **a DLP policy in SIMULATION proves it against production content**,
  where the real false-positive drivers live. Always measure in simulation — zero user impact — before
  calling a SIT "tuned".
- Give the simulation enough **dwell time** to capture representative traffic; a one-hour sample isn't a
  false-positive rate.
- **Inspect the actual matches in Content Explorer** (with the content-viewer role) — a match count without
  seeing the items can't be classified TP vs FP. Treat the content-viewer grant as sensitive and time-box
  it to the tuning exercise.

## Keep the selection consistent and documented
- Maintain the **`SIT Selection Register`** (category → SIT → why) and **`SIT Threshold Register`**
  (confidence + instance count) as the single source of truth. Every downstream policy references these —
  drift here means inconsistent detection everywhere.
- **Version any tuned SIT copy** (pattern/keyword/proximity/confidence, owner, date) so changes are
  traceable and reversible.
- Re-validate periodically — the built-in library grows and improves, and a newer or more specific SIT may
  replace a copy you once needed.

## Stay inside the boundary
- A SIT detects a **pattern, not meaning** — verify it against your real look-alike data rather than trusting
  the name. Conceptual categories need **trainable classifiers**, not a built-in SIT.
- **Verify licensing/tenant** before relying on Content/Activity Explorer, auto-labeling, or any advanced
  measurement surface — plans and portal paths evolve; don't assume a feature or an exact library count is
  present.
- **Which SITs legally satisfy a regulation, and the acceptable false-positive threshold per category, are
  compliance/legal determinations** — you provide the accurate detector and the evidence; they own the
  decision.
