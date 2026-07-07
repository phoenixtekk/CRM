# Best Practices

Durable practices for keeping a Google Workspace tenant CMMC Level 2 **assessment-ready** on NIST SP
800-171. These sustain the posture between the readiness engagement and the assessment — and after.

## Boundary discipline

- **Keep the CUI boundary small and explicit.** The narrower and better-defined **`CUI – Boundary –
  Org`** OU is, the smaller and more stable your assessment scope. Resist letting CUI drift into
  general-population OUs or personal Drives.
- **One way in, one way out.** Route CUI ingress/egress through controlled paths (approved Shared
  Drives, allow-listed external domains) so the data-flow map stays true and the boundary checker stays
  meaningful.
- **Re-validate membership on every joiner/mover/leaver.** Tie boundary-OU membership to the identity
  source so personnel changes update scope automatically (PS family).

## Evidence hygiene

- **Evidence is a product, not an afterthought.** For every control, capture *both* the configuration
  state and operational proof (audit-log extract) — an assessor asks "show me it's on" *and* "show me
  it's working."
- **Timestamp and index every package.** Use the **`Evidence – CUI Boundary – <date>`** convention and
  index each artifact to its NIST control ID, so the assessor can trace requirement → evidence in one
  step.
- **Refresh evidence close to the assessment.** Audit-log evidence ages; regenerate the package within
  your assessor's expected freshness window.
- **Never let evidence collection require write access.** Keep the evidence tooling strictly read-only
  so running it can never change the posture it is measuring.

## Control-map as single source of truth

- **Drive everything from `NIST 800-171 – Control Map – Org`.** Control status, planned setting,
  configured value, evidence pointer, and POA&M linkage all live in one matrix; the SSP and POA&M are
  generated *from* it, not maintained separately.
- **Status honestly.** Use `partial` and `verify-edition` truthfully; an over-stated `configured`
  becomes an assessment finding. It is safer to carry an honest POA&M item than to assert a control you
  cannot evidence.

## Change safety

- **Pilot every enforcing control.** DLP, context-aware access, sharing restriction, and 2SV can block
  legitimate work; prove them on **`CUI – Pilot – Org`** with a rollback before fleet enforcement.
- **Monitor before you block.** Ship DLP as **`DLP – CUI – Monitor`** first, read the hits, then promote
  to **`DLP – CUI – Enforce`**.
- **Document the rollback with the change.** Record the prior value in the control map at the moment you
  change it, so rollback is a lookup, not an investigation.

## Least privilege & credential safety

- **Read-only, least-scope credentials for tooling.** The five tools need only `*.readonly` admin
  scopes; never grant them write scopes.
- **No secrets in the repo, ever.** Use OAuth user consent, ADC, or a secured secret store; never commit
  a key, service-account JSON, or exported credential. Rotate the tooling credential on a schedule.
- **Separate admin duties.** Split super-admin, user-management, and compliance/eDiscovery roles (AC/MA
  families); log and review admin actions.

## Keep the assessment boundary where it belongs

- **Configure and evidence; let the assessor determine.** Treat every "meets control X" statement as
  "*configured to support control X, pending assessor determination*." Do not self-certify, and do not
  interpret ITAR/DFARS applicability in the SSP — cite the framework and reference the compliance/legal
  team's determinations.
- **Verify edition-dependent features, don't assume them.** Assured Controls, data regions, and
  client-side encryption vary by edition/rollout — confirm each in your tenant and POA&M anything you
  cannot confirm.

## Continuous monitoring

- **Schedule re-assessment.** Re-run `assess-nist-controls.py` and `cui-boundary-check.py` on a regular
  cadence; treat new `partial`/`not-configured` results as POA&M items immediately.
- **Keep the POA&M live.** A current POA&M with real owners and dates is itself evidence of a functioning
  security-assessment (CA) process.
