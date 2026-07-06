# 6. Troubleshooting Guide — Gemini Enterprise: Secure Adoption, Guardrails & Data-Access Boundaries

Use `GEMGOV-Discovery.ps1` / `GEMGOV-Validation.ps1` for the current state, `GEMGOV-Report.ps1` for
the access-boundary picture, and `GEMGOV-Remediation.ps1` (default `-WhatIf`) for safe fixes. Cross-check
live behavior in the **security investigation tool** (Gemini access to Drive) and the **Drive audit
log**.

> **Verify in your tenant.** Gemini Enterprise admin pages and toggles are evolving / partly preview —
> confirm exact paths for your edition and defer volatile specifics to Google's documentation.

## A. Gemini surfaces content it shouldn't
| Symptom | Cause | Remediation |
|---|---|---|
| Gemini returns confidential/HR/stale files to a user | Oversharing — the user actually has access via a public "anyone with the link", domain-wide, or stale grant | Run `GEMGOV-Discovery.ps1` to find the broad grants; run `GEMGOV-Remediation.ps1 -Apply` to remove public/domain-wide links; tighten sharing + Trust rules |
| Sensitive file still surfaced during pilot | DLP/IRM not applied to that content, or remediation incomplete | Apply a DLP rule with IRM (prevent download/print/copy) so Gemini won't retrieve it; finish remediating the file's sharing |
| Guest surfaced internal content via Gemini | Stale external/guest access | Review sharing reports; remove stale external grants; tighten tenant external-sharing and Trust rules |

## B. Guardrails not honored
| Symptom | Cause | Remediation |
|---|---|---|
| Gemini uses content that should be blocked | The DLP/IRM rule isn't applied to that content, or it isn't CSE-protected | Confirm the DLP rule targets the content and applies IRM; apply CSE where the content must be indecipherable to any assistant; re-test per Testing Tests 5–6 |
| CSE document still readable by Gemini | CSE not actually enabled on that content | Confirm Client-Side Encryption is applied; CSE content is indecipherable to Gemini only where CSE is in force |

## C. Data-access boundary not taking effect
- Confirm the **"Allow Gemini Enterprise to access Google Workspace data"** setting is scoped to the
  correct OU / configuration group and saved. Confirm you are editing the correct **edition** sub-page
  under **Generative AI → Gemini Enterprise** (paths vary by edition — **verify in your tenant**). Allow
  time for settings to propagate before re-testing.

## D. Legitimate work is now blocked (over-remediation)
- If tightening sharing, Trust rules, or DLP blocked people who need access: re-grant via specific
  people/groups (not broad links), narrow the Trust rule/DLP scope, or relax an over-aggressive rule on
  the affected scope. Use the change-control rollback (global requirement 6).

## E. Gemini not working for a pilot user
| Symptom | Cause | Remediation |
|---|---|---|
| Pilot user has no Gemini | Service off for the user's OU/group, or not licensed | Confirm **Generative AI → Gemini Enterprise → Service status** is on for the pilot scope and the user is licensed and in `Gemini Adoption – Pilot Users – Pilot` |
| Gemini answers with no Workspace grounding | Data-access setting off for the scope, or indexing not ready | Confirm **"Allow Gemini Enterprise to access Google Workspace data"** is on for the pilot scope; allow time after enablement |

## F. Diagnostics quick reference
```powershell
# Read-only signals and exposure baseline
.\GEMGOV-Discovery.ps1
.\GEMGOV-Report.ps1

# Confirm remediation held (broad links removed, DLP/IRM present, enablement pilot-only)
.\GEMGOV-Validation.ps1

# Preview safe remediation before applying
.\GEMGOV-Remediation.ps1 -WhatIf
```
Portal checks: Admin console → **Apps → Google Workspace → Drive and Docs → Sharing settings**;
**Security → Data protection** (DLP/IRM); **Generative AI → Gemini Enterprise** (Service status +
data-access, per edition); **security investigation tool** (Gemini access to Drive); **Google Vault**
(Gemini conversation eDiscovery). *(Verify exact paths in your tenant.)*

## G. When to escalate
If oversharing is remediated, DLP/IRM (and CSE where required) are applied and honored, the
data-access boundary and service enablement are pilot-only, and Gemini still surfaces content it
should not — capture the exact prompt, the cited item, and the user's effective permissions on that
item, review the security investigation tool logs, and open a Google Workspace support case. Volatile
Gemini Enterprise admin and connector specifics are deferred to Google's documentation.
