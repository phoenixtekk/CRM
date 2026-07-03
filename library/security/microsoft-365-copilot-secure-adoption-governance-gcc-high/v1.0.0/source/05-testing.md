# Testing Guide — Microsoft 365 Copilot Secure Adoption & Governance (GCC High)

Testing proves the guardrails work **before** you expand Copilot past the pilot. Every check is
**pass/fail** and, where possible, is produced by the included scripts (all connecting to **US Gov
Graph**, `-Environment USGov`). Run these after Phase 1 (Configure) and again after each expansion
wave.

> **Portals:** validation portals are the GCC High `*.us` set — `compliance.microsoft.us`,
> `security.microsoft.us`, `portal.office365.us` (→ SharePoint admin), `entra.microsoft.us`.

---

## Test suite A — Governance posture (run `COPILOTG-Validation.ps1`)

```
powershell -ExecutionPolicy Bypass -File .\COPILOTG-Validation.ps1
```

| # | Check | Pass criteria | Fail action |
| --- | --- | --- | --- |
| A1 | US Gov connection | Script reports connected to `graph.microsoft.us` (USGov) | Fix connection (Troubleshooting T1); do not trust results from Global |
| A2 | Restricted SharePoint Search | RSS **enabled** and scoped to `Copilot Search Allowed Sites` | Enable RSS (Impl. 1.3) or fall back to permission tightening; **verify for GCC High** |
| A3 | CUI sensitivity label | Mandated CUI label **exists and is published** to pilot group | Create/publish label (Impl. 1.1) |
| A4 | DLP policy | `DLP-COPILOTG-CUI` present and **enforced** (not just simulation) | Move policy out of test mode (Impl. 1.2) |
| A5 | License scope | Copilot add-on assigned **only** to `SG-COPILOTG-Pilot` (and Wave groups you intend) | Remove stray assignments (Set-ScopeTargeting) |
| A6 | Allow-list hygiene | **No** broadly-shared site from Discovery remains in the RSS allow-list | Remove/remediate the site (Impl. 1.4/1.5) |

**Suite A gate:** all rows PASS.

---

## Test suite B — Oversharing behavior (manual, the core proof)

These confirm Copilot's *actual* reach matches intent — the reason this solution exists.

| # | Test | How | Pass criteria |
| --- | --- | --- | --- |
| B1 | Kept-out site is invisible | As a pilot user, ask Copilot Chat to summarize/find content from a site **deliberately excluded** from the allow-list | Copilot **cannot** surface that content |
| B2 | Entitlement respected | As a pilot user with no access to a specific CUI library, prompt for its content | Copilot returns **nothing** from that library |
| B3 | Allowed site works | Ask Copilot about content in an **allow-listed, entitled** site | Copilot returns the expected content |
| B4 | Label honored | Confirm a CUI-labeled document keeps its label/marking when referenced by Copilot output workflows | Label/marking persists per policy |

**Suite B gate:** B1 and B2 PASS (no oversharing) **and** B3 PASS (Copilot still useful).

---

## Test suite C — GCC High parity expectations (verify, don't assume)

Because parity lags Commercial, explicitly confirm what is/ isn't available so you don't promise
users a capability that hasn't landed.

| # | Capability | Expected in GCC High (verify for your tenant) | Test |
| --- | --- | --- | --- |
| C1 | Copilot in Word/Excel/PPT/Outlook | Available | Pilot user sees Copilot in these apps |
| C2 | Copilot Chat (work grounding) | Available | Chat returns entitled tenant content |
| C3 | Web grounding | **OFF by default** | Confirm no live web results unless explicitly enabled; expect knowledge cutoff |
| C4 | Teams meeting Copilot / Teams chat Copilot | **Limited / may be unavailable** | Verify status before promising; do not fail the pilot if absent |
| C5 | Copilot Studio agents / Teams app / triggers | **Restricted** in GCC High | Confirm which agent surfaces exist before designing agents |
| C6 | Wave 2 (GPT-5, image gen, code interpreter, Researcher/Analyst) | Staged into **H1 2026** | Verify what has actually shipped for your tenant |

Source for expected parity: see the **GCC High parity notes** doc (cited). **Record the actual
observed state** — availability changes over time.

---

## Test suite D — Evidence report

```
powershell -ExecutionPolicy Bypass -File .\COPILOTG-Report.ps1
```
Produces a consolidated report of posture + Suite A results for the change record and sign-off.

**Overall gate to expand:** Suite A all PASS, Suite B core tests PASS, Suite C observed state
recorded, Suite D report generated and attached to the change ticket. Any failure → remediate and
re-test; do not proceed to the next wave.
