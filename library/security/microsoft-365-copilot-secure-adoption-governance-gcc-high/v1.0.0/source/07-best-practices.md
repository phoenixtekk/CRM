# Best Practices — Microsoft 365 Copilot Secure Adoption & Governance (GCC High)

Field-tested guidance for adopting Copilot on a **GCC High** tenant without turning it into a
CUI-oversharing engine. These practices assume you have followed the Implementation Guide; they are
the "do this, avoid that" layer on top.

---

## Govern before you grant

1. **Never license Copilot before you assess.** Run Discovery and remediate broad sharing *first*.
   On a CUI tenant, an oversharing gap is a spillage path the moment Copilot can reason over it.
2. **Restricted SharePoint Search is a throttle, not a fix.** Use RSS to shrink Copilot's reach to a
   vetted allow-list *while* you remediate — then widen the allow-list only as fast as you remediate.
   Do not treat RSS as a substitute for correct site permissions. **Verify RSS is available in your
   GCC High tenant** before relying on it.
3. **Label to the mandate, not to convenience.** Use your program's **mandated CUI taxonomy** in
   Purview. Do not invent labels; do not simplify away categories your contract requires.
4. **Enforce DLP, don't just simulate it.** A DLP policy left in test mode protects nothing. Move
   `DLP-COPILOTG-CUI` to enforce after reviewing simulation matches.

## Use the sovereign surfaces correctly

5. **`*.us` everywhere.** Bookmark and allow-list only the GCC High portals
   (`portal.office365.us`, `entra.microsoft.us`, `compliance.microsoft.us`, `security.microsoft.us`,
   `endpoint.microsoft.us`, `portal.azure.us`, `high.powerva.microsoft.us`). Remove Commercial URLs
   to prevent misconfiguration and wrong-tenant sign-in.
6. **Always `-Environment USGov`.** Every script and every manual `Connect-MgGraph` must target US
   Gov Graph (`graph.microsoft.us`). A silent connection to the default Global environment returns
   empty/incorrect results and can mask real exposure.
7. **Allow the US Gov endpoint set through filtering** (`*.microsoft.us`, `*.azure.us`,
   `*.usgovcloudapi.net`, the `AzureCloud.usgov*` IP ranges), not the Commercial ranges.

## Respect the parity gaps (don't over-promise)

8. **Plan for web grounding OFF.** Copilot answers from tenant content by default in GCC High; expect
   a knowledge cutoff. Only enable web grounding if your organization explicitly accepts the
   data-boundary tradeoff — and document that decision.
9. **Verify Teams-meeting Copilot before promising it.** It has historically been limited/unavailable
   in GCC High. Set pilot expectations to what actually works today.
10. **Assume Copilot Studio / agents are restricted.** Teams app experience, Teams/M365 channel,
    M365-extending agents, Prompt Action, transfer-to-agent, and triggers/autonomous agents are
    limited or unavailable in GCC High. Design agent scenarios only around surfaces you can confirm.
11. **Re-check parity quarterly.** Wave 2 features stage into GCC High through H1 2026; update
    expectations and pilot scope as capabilities land. **Cite/verify — never assume parity.**

## Roll out with gates

12. **Pilot with a named group** (`SG-COPILOTG-Pilot`), never the whole tenant. Group-based licensing
    keeps scope tight and reversible.
13. **Gate every expansion wave** on clean Validation + Report results. `SG-COPILOTG-Wave2` only gets
    licenses after Wave 1 validates.
14. **Keep Remediation and Set-ScopeTargeting in -WhatIf until reviewed.** Preview → review against
    the change ticket → apply deliberately. Never blind-apply.

## Operate it as ongoing hygiene

15. **Re-run Discovery monthly.** New sites and new oversharing appear continuously; governance is a
    standing duty, not a launch task.
16. **Tie changes to change control.** Every label, DLP, and RSS change gets a ticket with approver,
    window, and rollback (global requirement G8) — because these changes alter what users *and*
    Copilot can find.
17. **Keep the evidence.** Retain Discovery baselines and Validation/Report output; on a CUI tenant
    this is your audit trail that Copilot was adopted under control.
