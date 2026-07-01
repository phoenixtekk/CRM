# 7. Best Practices — Endpoint Health & Digital Experience Monitoring

- **Pilot first, always.** Onboard a small representative pilot and let it collect a baseline before
  judging scores — the baseline period is the gate that keeps you from chasing noise.
- **Name everything consistently.** Use `<Purpose> – <Scope> – <Stage>` for every group and
  remediation package (e.g. `Proactive Remediation – Restart Stale Devices – Pilot`) so the tenant
  stays self-documenting and repeatable.
- **Trend, don't snapshot.** A single score means little; watch the overall and sub-scores move over
  weeks and react to declines, not one-off dips.
- **Target the worst models and devices.** Endpoint analytics breaks scores down by model and device
  — fix the heaviest offenders first for the biggest fleet-wide gain.
- **Start remediations from tested packages.** Begin with Microsoft's sample proactive-remediation
  packages or your own validated scripts; pilot every package before broad assignment and review its
  run history.
- **Keep remediations safe and reversible.** Detection scripts should be read-only; remediation
  scripts should do one well-understood thing and log what they changed.
- **Don't over-collect.** Enable the diagnostic data Endpoint analytics needs and no more; respect
  your data-governance policy.
- **Treat a dedicated DEX platform as additive and optional.** Only adopt Nexthink/Tanium when
  Endpoint analytics genuinely falls short, and follow the vendor's own documentation for its setup.
- **Close the loop with users.** Pair proactive fixes (e.g. restart nudges) with a short user message
  to reduce confusion and tickets.
- **Document the cadence.** Record which scores you review, on what schedule, and which remediation
  packages run where — for audits and repeatability.
