# 5. Testing & Validation — Microsoft 365 ↔ Google Workspace Coexistence

Each phase in `03-implementation.md` has a **pass/fail exit gate**. Do not advance until the gate's
test passes. Tests use the same named objects as the runbook (`Coexistence – Pilot Members`,
`Coexistence – EXO→Google Connector`, `svc-interop-*`, etc.). The scripts automate the per-user checks;
this file defines what "pass" means.

**Test accounts:** at least one **Google-hosted** and one **M365-hosted** pilot user, plus one
resource/room and one shared mailbox equivalent, all in **`Coexistence – Pilot Members`**.

---

## T1 — Assess gate (readiness baseline)

**Goal:** the coexistence-readiness baseline is complete on both platforms and DNS.

| Check | How | Pass |
|---|---|---|
| M365 baseline | `GWCOEX-Discovery.ps1` ran; CSVs present | Accepted-domain types, connectors, contacts, and Interop state exported |
| DNS baseline | Inspect MX/SPF/DKIM/DMARC for `contoso.com` | Current records recorded as rollback baseline |
| Google baseline | Domains, Gmail Routing/Hosts, Calendar Interop management state noted | State recorded |
| Direction decided | Review R4 decision | MX-primary platform + relay direction written down and approved |

**Fail →** capture the missing baseline before any Configure step.

---

## T2 — Configure gate (all three pillars built for pilot)

| Pillar | Check | Pass |
|---|---|---|
| Mail | EXO accepted domain = **Internal relay**; `Coexistence – EXO→Google Connector` exists; Google `Coexistence – Split Delivery` rule + `Coexistence – M365 Host` exist | Both relay paths configured (pilot-scoped) |
| Free/busy | Exchange endpoint added in Calendar Interop; role accounts `svc-interop-exo@contoso.com` and `svc-interop-gcal@contoso.com` set | Both directions configured |
| Directory | GCDS simulate-sync shows expected users/groups/shared contacts; EXO mail contacts for Google-only recipients exist | Directory projection ready both ways |
| Auth | SPF authorizes both senders; DKIM selectors per platform; DMARC monitoring policy | DNS auth in place |

**Fail →** fix the specific pillar in `03-implementation.md` §2.x before piloting.

---

## T3 — Pilot gate (scoped to pilot only)

| Check | How | Pass |
|---|---|---|
| Scope correct | `GWCOEX-Set-ScopeTargeting.ps1` (default `-WhatIf`) plan shows scope = `Coexistence – Pilot Members` | Only pilot users in scope |
| Production untouched | Send a normal message to a non-pilot production user | Delivered exactly as before coexistence |

**Fail →** re-scope before validating; never validate with production in scope.

---

## T4 — Validate gate (pilot passes all pillars, both directions)

Run `GWCOEX-Validation.ps1` per pilot user, then `GWCOEX-Report.ps1`.

| Pillar | Test | Pass |
|---|---|---|
| Mail G→M | Google-hosted user emails an M365-hosted pilot user | Delivered, no NDR; header shows relay/split-delivery path |
| Mail M→G | M365-hosted user emails a Google-hosted pilot user | Delivered, no NDR; relayed via `Coexistence – EXO→Google Connector` |
| Free/busy G→X | Google user views an Exchange user's availability | Busy blocks resolve |
| Free/busy X→G | Outlook user views a Google user's availability | Busy blocks resolve |
| Directory G | Google-only recipient appears in EXO GAL (mail contact) | Resolves when addressed |
| Directory M | M365-only recipient appears in Google directory (shared contact) | Resolves when addressed |

**Pass gate:** **100%** of pilot users green on all six rows. **Fail →** `06-troubleshooting.md`, then
`GWCOEX-Remediation.ps1` (default `-WhatIf`).

---

## T5 — Expand gate (fleet coverage)

| Check | How | Pass |
|---|---|---|
| Scope widened | `GWCOEX-Set-ScopeTargeting.ps1 -Scope AllUsers` plan | Whole fleet in scope |
| Fleet coverage | `GWCOEX-Report.ps1` across a broad sample | Coverage ≥ agreed threshold (target 100%) |
| GCDS scheduled | GCDS running on interval | Automated sync healthy, no unexpected deletes |
| DMARC enforced | DNS shows enforcing DMARC | Enforcement on only after coverage proven |

**Fail →** do not tighten DMARC or declare done; remediate and re-report.

---

## Regression / ongoing checks

- **Weekly:** `GWCOEX-Report.ps1` for coverage drift; investigate any user that drops a pillar.
- **After any DNS or connector change:** re-run mail-routing rows (T4 Mail G→M / M→G).
- **After GCDS schema/OU changes:** re-run directory rows (T4 Directory G / M).
- **Before consolidation cutover:** full T4 sweep, then follow the decommission steps in
  `07-best-practices.md`.
