# 7. Best Practices — Oracle C2M DevOps Release Management & CI/CD Automation

- Treat a release as one versioned tuple. Build version + configuration bundle + IWS list + environment
  settings move together, retained in source control; a bundle without its matching build (or a build
  without its config) is a half-release. Promote the tuple, not a piece of it.
- Put every release artifact under version control. The code build, the binary CMA export bundle, and the
  per-environment settings are just files — retain them so the exact reviewed artifacts that passed QA are
  the ones applied to Production, and so every release is auditable and reproducible.
- Define the stages and gates once, run them the same way every release. Build → migrate config → deploy →
  validate, each with a named artifact and an explicit pass/fail gate. "Do the steps I remember" is neither
  repeatable nor safe.
- Automate the routine admin, don't do it by hand. The graceful stop/start order, the batch/threadpool
  quiesce-and-resume, and the post-deploy health checks are the most common source of a botched deploy;
  script them into the deploy stage so a release is consistent and hands-off.
- Always quiesce batch before you promote. Pause the `threadpoolworker`s / online batch submission so no
  job runs against a half-promoted schema, then resume as part of the deploy — never leave batch running
  through a config/code change.
- Source `splenviron` for every scripted step. OUAF utilities (`initialSetup`, `iwsdeploy`,
  `threadpoolworker`, batch) depend on the product environment; a pipeline step that runs without it will
  fail or, worse, act against the wrong environment.
- Deploy IWS from the command line for QA and Prod. The online IWS deployment portal is supported only in
  non-production; use `iwsdeploy` under `splenviron` for controlled environments and confirm the Deployment
  Status zone / WLST state reads current and active.
- Back up the target before every deploy stage. Because the deploy installs a build and imports a bundle
  that replaces objects, the pre-deploy backup (plus the recorded prior bundle/build levels) is your
  rollback; take it every time, not just for Production.
- Validate parity *and* health, don't assume. "The pipeline ran" is not "the target equals the source and
  is healthy." Run the compare and the health/IWS validations on every release; parity + healthy confirmed
  is the evidence of a clean deploy.
- Promote one direction, through the gates. Dev → QA → Prod, never sideways or backward; pass the explicit
  gate (parity + health + functional test) at each hop before the next, with the *same* artifacts.
- Prove the pipeline on a pilot release first. Run one bounded release Dev → QA before running a full
  release or touching Production — the pilot gate catches stage, restart-order, IWS, and health-check gaps
  cheaply.
- Never author configuration or hand-tune settings directly in QA or Prod. All change originates in Dev and
  flows through the pipeline; a hand-edit downstream is exactly the drift and the un-reproducible release
  this method exists to prevent.
- Keep source and target at compatible levels. Same-release promotion is the safe default; treat a
  framework-version gap as its own planned exercise, not an incidental part of a release.
