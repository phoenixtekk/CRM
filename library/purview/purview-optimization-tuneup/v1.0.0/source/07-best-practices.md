# 7. Best Practices — Microsoft Purview Optimization & Tune-Up

- **Tune on evidence, never on a hunch.** Start from `OPSOPT-Report.ps1` — adjust the rules the
  **override / reported-false-positive** data shows are noisy, ranked by volume. The console *feels*
  noisy everywhere; the data tells you *where*.
- **Simulation first, always.** Every change lands in a **Test** mode (`TestWithoutNotifications` for
  DLP, simulation for auto-labeling) before it enforces. Re-enforce is a **separate, approved** step —
  never bundle the tuning edit with the `Enable`.
- **Never remove signal to remove noise — prove it with a true-positive probe.** Before re-enforcing,
  confirm a **known-sensitive** item still matches. A quieter console that also misses real leaks is a
  worse outcome than the noise you started with.
- **Raise confidence and instance count before adding exceptions.** Tightening the **confidence level**
  and **min instance count** on the SIT condition removes the most false positives with the least risk
  of opening a gap. Reach for `ExceptIf` exceptions only when a specific workflow demands it.
- **Every exception needs a named owner and a written justification.** A false positive is only false
  relative to intended policy — an unjustified `ExceptIf` can silently open a real hole. Capture the
  owner and reason in `.\OPSOPT-out`; the *acceptability* of the exception is compliance/data owners'
  call, not the tuner's.
- **Record the prior value before you change it.** Rollback is only real if the baseline was captured —
  `OPSOPT-Tune.ps1` writes `rollback-<policy>.json` before every commit; keep it.
- **Fix alert noise at the threshold and aggregation, not by muting.** Raise the **threshold**, switch
  to **aggregated** alerting, and trim recipients to those who act — so an alert means something. Do not
  disable an alert policy to silence it.
- **Insider Risk is HR/privacy-sensitive — tune it under strict role separation and privacy-by-design.**
  Keep the IRM role separate from DLP/label admins and from case reviewers; keep **pseudonymization**
  on where available. Tune the indicator/threshold **noise** only — **case outcomes are HR/legal's**.
- **Don't leave simulation on forever.** Simulation is for tuning, not a resting state — a DLP policy
  sitting in `TestWithoutNotifications` is **not protecting** anything. Validate, then re-enforce, and
  let `OPSOPT-Scope-Health.ps1` flag policies stuck in test too long.
- **Make it recurring.** Noise regrows as the estate changes. Schedule the read-only
  `Discovery → Report → Scope-Health` chain (e.g. weekly) to catch new noisy rules, reverted
  thresholds, and drift before fatigue sets back in.
- **Determinations stay with their owners.** What DLP must protect, what a label means, and whether an
  insider-risk pattern is a real concern belong to compliance, records, privacy, security, HR, and
  legal. This solution reduces noise and evidences the reduction — it does not rule.
