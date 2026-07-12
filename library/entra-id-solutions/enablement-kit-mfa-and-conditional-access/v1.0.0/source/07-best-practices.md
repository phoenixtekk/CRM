# 7. Best Practices — Enablement Kit: Multi-Factor Authentication & Conditional Access

Keep-it-clean guidance for turning an MFA/CA kit into a durable design-test-troubleshoot skill — and
where to go next once the capability is in place.

## Report-only before enforce — always

- **Learn in report-only; enforce nowhere in this kit.** Every lab policy is created **report-only**;
  it evaluates and logs but cannot block. Carry that discipline into every real policy you build later:
  report-only, validate with a few days of data and What-If, then enforce in waves.
- **What-If every policy against every persona.** Before a policy is ever enforced (in the production
  solutions), simulate it for each persona **and** for a break-glass account. A break-glass account
  applying to any policy means the exclusion is missing.

## Protect break-glass, every policy, no exceptions

- **Two cloud-only emergency accounts, excluded from every CA policy.** Keep them in
  `Grp-MfaCa-Excl-BreakGlass` and exclude that group from every policy — `EKMFACA-Validate.ps1` flags
  any policy that forgets. Teach the habit in report-only so it is automatic before any enforced
  policy exists.
- **Exclude the group, not the users.** A group exclusion is durable; a per-user exclusion is fragile
  and easy to lose when accounts change.

## Choose MFA methods by strength

- **Prefer phishing-resistant.** SMS/voice are phishable; push+number-matching is good; FIDO2/passkeys,
  Windows Hello for Business, and certificate-based auth are **phishing-resistant** — require them for
  admins via an **authentication strength** grant control. *Passkey/CBA support may be preview or
  licensing-gated — verify.*
- **Drive registration before you require.** A policy that requires a method users have not registered
  locks them out. Confirm registration coverage (Lab 1 / `EKMFACA-Discovery.ps1`) first — the
  **Passwordless & Passkey** solution deploys the method at scale.

## Design by persona, not by mega-policy

- **Admins, internals, guests, service accounts.** A numbered, persona-based set is legible, auditable,
  and rolled out group by group; a single "all users, all apps" policy is a lock-out waiting to happen.
- **Target groups, not individuals.** Scope policies to persona security groups so the design is
  legible and scalable.
- **Handle service accounts deliberately.** Non-interactive accounts break under interactive MFA —
  scope them out of interactive policies and govern them separately (workload-identity CA where
  licensed), never a blanket silent exclusion.

## Troubleshoot from the sign-in log, not from a guess

- **Read the CA tab.** Every sign-in records which policies applied and why (success / failure /
  reportOnly* / notApplied) and which method satisfied MFA. Most "MFA is broken" tickets are a policy
  doing exactly what it was told — the log tells you which one.
- **Distinguish report-only from real.** A `reportOnlyFailure` means the policy *would have* blocked —
  it did not. Do not chase a report-only result as an outage.

## Verify, don't assume

- **Verify licensing before you promise a feature.** CA needs **P1**; risk-based conditions and PIM
  need **P2**; some MFA methods may be preview. Check **Billing -> Licenses** (or
  `EKMFACA-Discovery.ps1`) — *bundles change and differ by cloud (Commercial vs GCC / GCC High)*.
- **Verify portal navigation and preview status** against your tenant — Microsoft renames blades and
  ships features in preview.

## Run it as a program, not a one-off class

- **Re-run for new hires.** The take-home runbook and knowledge-check make onboarding a new security
  admin repeatable; the persona groups and scripts are reusable.
- **Keep the runbook current** as your CA baseline evolves in the production solutions.

## Where to go next

With the team able to design, test, and troubleshoot MFA/CA, the natural next steps in this catalog
are:

- **Zero Trust Conditional Access Baseline (ENTZTCA)** and **Conditional Access Integration** — design
  and roll out a real, **enforced** baseline (this kit built the skill in report-only; those build the
  production system).
- **Passwordless & Passkey (ENTPASSKEY)** — deploy the phishing-resistant methods that a
  phishing-resistant auth-strength policy requires.
- **Privileged Identity Management (ENTPIM)** — pair CA with just-in-time, approval-gated admin
  elevation.
- **Identity Protection (P2)** — add risk-based sign-in and user-risk conditions once the team is
  comfortable with the fundamentals of CA.
- **Enablement Kit — Microsoft Entra Identity Fundamentals (EKIDFUND)** — the prerequisite grounding
  for anyone on the team still shaky on tenants, users, groups, and roles.
