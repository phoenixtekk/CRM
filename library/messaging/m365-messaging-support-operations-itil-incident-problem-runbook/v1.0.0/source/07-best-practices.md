# Best Practices

Durable practices for running Microsoft 365 messaging support to SLA with high CSAT. These are the
habits that keep the operating model healthy after go-live.

## Operating model and tiers

- **Escalate on criteria, never on frustration.** An analyst moves a ticket up only when a defined
  condition in `Escalation Matrix – Messaging – Design` is met. This is the single biggest lever against
  "hot-potato" bouncing.
- **Escalate with the diagnostic bundle, always.** No escalation leaves a tier without message trace,
  timestamps, message IDs, affected recipients, and relevant `Get-` output. The receiving tier should
  never restart triage.
- **Keep L2 read-heavy, L3 change-capable.** Least-privilege by tier limits blast radius and forces the
  right hand-off. Review role-group membership periodically — Microsoft adjusts role capabilities over
  time; **verify in your tenant**.
- **One incident lifecycle for every mail issue.** Even a first-contact fix gets logged, categorized, and
  prioritized, or your metrics lie to you.

## Priority and blast radius

- **Prioritize by how much mail is affected, not by who is shouting.** Org/domain = P1, group/site = P2,
  single user = P3, how-to = P4. Business impact modifies within a band; it does not override blast
  radius for genuine mail-flow outages.
- **Watch P2s trending to P1.** A partner connector rejecting today can become an org-wide problem;
  page on-call when a P2 is trending.

## Service availability

- **Check Microsoft Service Health first, every suspected outage.** Portal (**Health → Service health**)
  plus the Service Health triage script. Reading the **Message center** proactively catches
  *change-driven* incidents before they become tickets.
- **Record the Microsoft incident ID** on affected tickets so post-incident review can separate
  "our issues" from "service issues", and so trend reporting is honest.
- **Verify your cloud's endpoints.** Government (GCC High/DoD) uses `*.office365.us`,
  `admin.exchange.microsoft.us`, and `graph.microsoft.us`; do not assume Commercial URLs.

## Problem management and root-cause

- **Turn every recurring pain into a Problem record.** Run the recurring-incident analyzer each period;
  the top candidates get Problem records. Repeat incidents with no Problem record are unmanaged debt.
- **Publish the Known-Error + workaround immediately.** L2 should never have to re-solve a known problem
  from scratch while the permanent fix is pending.
- **Document the real root cause, not the symptom.** "Restarted / re-ran it" is not a root cause.
- **Fix under change control.** Mail-flow, connector, hygiene, DKIM/DMARC, and hybrid changes are
  high-impact — pilot the fix and keep a rollback.

## Quality: FCR, CSAT, reopen

- **Reopen rate is your truth serum.** A closed ticket that reopens was not resolved. Run a reopen review
  and feed the reason back into the KB.
- **Protect First-Call-Resolution with good KB.** Most FCR gains come from findable, current articles for
  the common mail tickets.
- **Close with confirmation where the SLA requires it**, and capture CSAT on close — you cannot improve
  what you do not measure.

## Knowledge and coaching

- **Every KB article has an owner and a next-review date.** Stale mail knowledge (old portal paths,
  retired cmdlet guidance) causes wrong fixes. The EXO/EAC surface changes — keep articles current.
- **Onboard by shadow → reverse-shadow → solo-with-review.** New analysts run the five scripts as part of
  ramp so they learn the tooling, not just the theory.
- **Coach from real tickets and real reopens**, not abstractions. Ticket-quality reviews close the loop
  between metrics and behavior.

## Automation and safety

- **Read-only or `-WhatIf` by default.** The included scripts never change anything unless an explicit
  `-Commit`/`-Apply` switch is passed; keep it that way for anything you add.
- **No credentials in code, ever.** Connect interactively with `Connect-ExchangeOnline` /
  `Connect-MgGraph` and inherit the operator's least-privilege permissions. For unattended reporting,
  use a managed identity / app registration with the minimum scope — never a stored password.
- **Do not invent cmdlets or portal paths.** When unsure, verify against Microsoft's current docs and
  your tenant/version before publishing a KB step.
