# Executive Summary

**Outcome.** AI delivery organized for pace and proven for quality: delivery teams structured as
pods and squads with clear roles and interfaces, and a small, honest set of KPIs — spanning
engineering productivity and delivery quality — instrumented against targets, with an improvement
cadence that turns variance into action. Leaders get to *see* whether AI delivery is getting better,
not guess.

**The problem it solves.** Teams delivering AI at pace routinely get two things wrong: an unclear
team structure (ownership and hand-offs are tribal, not written down) and the wrong measures (a
dashboard full of vanity metrics — output counts, utilization, lines of code — that look busy but
never move outcomes). The result is delivery that feels fast and fragile, with no credible way to
prove quality or safety is holding.

**The approach.** The framework defines three layers and instruments all three. **Structure:** a
pod/squad topology with named roles and explicit intake, hand-off, and escalation interfaces.
**Measurement:** a curated catalog of 6–10 KPIs, each with a definition, data source, target, and
owner, screened by an automated vanity-metric guard so raw counts and utilization never make the
cut. **Improvement:** targets, a portable dashboard feed, and a recurring cadence where the largest
gaps drive concrete, owned actions. It ships with five Python tools — a pod/squad capacity planner, a
KPI-definition validator, a rollup/dashboard-feed generator, a target-vs-actual variance reporter,
and a privacy checker — and follows a pilot-first **Assess → Design → Generate/Build → Validate →
Expand** model with explicit pass/fail gates.

**Why it's safe.** The work it measures runs on **synthetic** data in **isolated, non-production**
environments. The KPI pipeline consumes only operational telemetry and **aggregate, PHI-free**
validation pass/fail signals — **never real Protected Health Information**, never patient-level
detail. A non-negotiable privacy gate (with an automated checker) blocks expansion if any real PHI is
ever found in the pipeline. Regulatory and de-identification *determinations* remain with the
organization's privacy, compliance, and legal functions; the framework supplies the technical
evidence, not the legal call. Crucially, privacy-gate first-pass rate is itself a first-class quality
KPI — so "fast" can never quietly mean "unsafe".

**The bottom line.** Pods/squads structured, KPIs instrumented and de-vanitized, and an improvement
cadence running — a self-guided framework, tested, at a fraction of the cost of a consulting
engagement.
