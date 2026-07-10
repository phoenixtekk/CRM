# 7. Best Practices — Zero Trust Architecture: Conditional Access Baseline & Rollout

- Report-only before enforce, always. Every policy is created in `Report-only`, validated with a few
  days of real sign-in data and the What-If tool, and only then turned on. This single discipline is
  what makes a CA rollout safe.
- Exclude break-glass from every policy, no exceptions. Keep the two cloud-only emergency accounts in
  `CA Exclusion - Break-Glass - Steady` and exclude that group from every policy — `ENTZTCAG-Validate.ps1`
  flags any policy that forgets. This is the anti-lockout guarantee.
- Design by persona, not one mega-policy. A numbered, persona-based baseline (admins, internals,
  guests, service accounts) is legible, auditable, and rolled out group by group; a single "all users,
  all apps" policy is a lock-out waiting to happen.
- Number and name policies consistently. `CA0nn <Purpose> - <Persona> - <Stage>` makes the baseline
  self-documenting and lets you reason about order and coverage at a glance.
- Keep exclusions minimal and documented. Every exclusion is a hole in the baseline — make each one a
  named exception with an owner and a review date, not a convenience. Review them quarterly and remove
  what is no longer needed.
- Handle service accounts deliberately. Non-interactive accounts break under interactive MFA — scope
  them out of interactive policies, document each one, and where licensed use workload-identity
  Conditional Access instead of a blanket exclusion.
- Block legacy authentication early, but migrate first. Legacy/basic auth cannot do MFA and undermines
  the whole baseline — identify legacy-auth users/apps with `ENTZTCAG-Discovery.ps1`, migrate them to
  modern auth, then block legacy in waves so you do not break a line-of-business app.
- Require phishing-resistant MFA for admins. Generic MFA is still phishable; give the highest-value
  accounts the `Phishing-resistant MFA` authentication strength plus tighter session controls
  (sign-in frequency, no persistent browser).
- Prefer device + MFA over risk-only where you are P1. Risk policies need Entra ID P2 — if you are
  P1-only, compensate with require-compliant-device + MFA everywhere and note the gap; do not leave the
  persona uncovered.
- Roll out in waves with rollback ready. Enforce for the pilot ring, then a first wave, then the rest —
  re-running `ENTZTCAG-Report.ps1` between waves. Keep every policy one click from report-only.
- Let the business own the classifications. Which apps are "sensitive," which users are "privileged,"
  and how strict guest access must be are security/business decisions — the baseline enforces them; it
  does not decide them.
- Make review recurring. Re-run `ENTZTCAG-Discovery.ps1` and `ENTZTCAG-Validate.ps1` on a cadence so
  policy drift, a lost break-glass exclusion, or new legacy-auth sign-ins are caught as they appear.
- Lead with the mandate (GCC High). Map the baseline to the federal Zero Trust drivers — **OMB M-22-09**
  (phishing-resistant MFA, Zero Trust aligned to the CISA Maturity Model and NIST SP 800-207) and, for
  the DIB, **CMMC 2.0 / NIST SP 800-171**. `CA002` (phishing-resistant MFA for admins) and `CA007`
  (block legacy auth) are the highest-priority mandate controls; enforce them early regardless of P2
  availability.
- Verify GCC High/DoD parity before you design. Connect scripts with `-Environment USGov` (DoD: `USGovDoD`);
  use the Azure Government portal (`portal.azure.us`) / GCC High endpoints. **Risk-based CA (Entra ID P2 /
  Identity Protection), authentication strengths, and device controls may lag or differ in the sovereign
  cloud — verify each against current Microsoft Government documentation** (see `gcc-high-parity-notes.md`)
  and substitute non-risk controls where a feature is not yet available, noting the gap.

## Where to go next
- **Passwordless & Passkey (FIDO2) Rollout for Microsoft Entra** — deliver the phishing-resistant
  method that `CA002` requires for admins.
- **Intune device compliance / hybrid join** — stand up the device signal that `CA003` depends on.
- **Identity Protection risk policies** and **Privileged Identity Management (PIM)** — pair the
  baseline with risk-based access (P2) and just-in-time admin elevation for a complete Zero Trust
  identity story.
- **Enterprise App & Service Principal Governance** — govern the OAuth consent and workload-identity
  surface that sits alongside interactive Conditional Access.
