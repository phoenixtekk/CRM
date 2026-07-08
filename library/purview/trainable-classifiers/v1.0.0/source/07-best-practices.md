# Best Practices — Trainable Classifiers

Field-tested guidance for building and running trainable classifiers well. It complements — does not
replace — the implementation steps and the pass/fail gates.

## Use built-in classifiers before you build custom ones

- **Check the built-in catalog first.** Microsoft ships pre-trained classifiers (e.g. Resumes, Source
  Code, and others — verify the current catalog). If one covers your category, use it — no seeding,
  training, or testing needed.
- **Reserve custom classifiers for organization-specific content** (your contracts, your SOWs, your
  internal document types) that no built-in classifier recognizes.

## Seed and test like a data scientist

- **Seed with clean, representative, single-category examples.** A classifier is only as good as its
  seed set. Use enough samples (meet/exceed the Microsoft minimums — verify current counts), all
  genuinely of the target category, with the variety the real estate contains.
- **Keep the test set separate from the seed set.** Measuring accuracy on the data you trained on is
  meaningless. The Test stage needs items with a **known ground truth** the model has not seen.
- **Include true negatives in testing.** A classifier that matches *everything* has high recall and
  useless precision. Test with non-matching items too, and measure precision, not just recall.
- **Retrain iteratively.** If accuracy is low, add/clean seed samples and retrain — do not lower the
  bar. Classifier quality compounds downstream (every mislabel is a mis-protection).

## Never publish or enforce a classifier that fails its accuracy gate

- **Accuracy tolerance depends on what it drives.** A classifier feeding an **audit-only report** can
  tolerate more error than one **auto-applying an encrypting label** or a **DLP block**. Agree the
  threshold (R7) with the data owner *before* publishing, and match tolerance to impact.
- **Sign-off is a determination, not a technical default.** "Good enough" is the data owner's call —
  capture it in writing.

## The classifier is only half the job — wire it, in simulation

- **Publishing changes nothing on its own.** A classifier has value only once an **auto-labeling /
  DLP / retention** policy acts on it. Treat the wiring as a first-class deliverable.
- **Always simulate the wired control first.** Auto-labeling can apply **encrypting** labels; DLP can
  block. Run the control in **simulation** and review what it *would* do across the pilot estate before
  enforcing. Auto-labeling simulation processes real content — allow time.
- **Reuse one good classifier across controls.** A single published classifier can feed auto-labeling,
  DLP, and retention — build it once, wire it many times, each simulate-first.

## Mind the high-impact, hard-to-reverse nature of labeling

- **Applied labels don't auto-remove.** Disabling an auto-labeling policy stops *new* labeling but does
  **not** strip labels already applied. Plan any reversal (re-label / label change) under change
  control — another reason to get accuracy right before enforce.
- **Start narrow, expand in rings.** Pilot scope first (`SG-Classifier-Pilot`), validate, then widen.

## Operate it, don't set-and-forget

- **Re-check accuracy over time.** Content drifts; a classifier trained a year ago may need retraining
  as document styles change. Periodically re-test against a fresh ground-truth set.
- **Roll up modes and activity** with `CLSTRAIN-Report.ps1`; review which policies are in simulation vs
  enforce and what they are matching.
- **Version and name clearly.** Move from `AL-Classifier-Pilot` to a production `AL-Classifier` as you
  exit pilot; keep a change log of classifier versions and wiring changes.
- **Re-validate after portal changes.** Trainable classifiers and auto-labeling evolve (some settings
  are newer/preview); re-run `CLSTRAIN-Validate.ps1` after Microsoft feature updates.

## Keep the roles and determinations where they belong

- **Least privilege, split duties.** Classifier management and policy authoring are different roles —
  do not fold them into one over-privileged account.
- **Determinations stay with the owners.** *Which* label a category deserves, *what* accuracy is
  acceptable, and *whether* content is in scope are **compliance / data-owner** calls. You provide the
  classifier, the accuracy evidence, and the wiring, not the judgement (see
  `global-requirements-purview.md` §5).

## Security & handling of the tooling

- **Read-only / `-WhatIf` by default.** Run the provided scripts in their safe default first; only add
  `-Commit`/`-Apply` when you intend to write, under change control. The scripts **wire** controls;
  they do **not** invent a cmdlet to create/publish a classifier (that is a portal action).
- **No secrets in code.** The scripts use interactive modern-auth (`Connect-IPPSSession` /
  `Connect-MgGraph`); never hardcode credentials, tokens, or app secrets.
- **Least-privilege connections.** Connect with the least-privilege role that the task needs, not a
  standing Global Administrator session.
