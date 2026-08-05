# Ollama Authoring Prompts — one per file

Send each of these as the **user message**, with the system prompt from `ollama-system-prompt.md` as
the system message. Author in the listed order (top to bottom). Substitute the variables:
`{{TOPIC}}`, `{{SOL}}` (code), `{{CATEGORY}}`, `{{NOTES}}` (optional shaping note, else "none").
Where a prompt says *"(context)"*, paste the previously-authored Overview + Requirements so later
sections stay consistent (keep it short to respect the model's context window).

`run_factory_ollama.py` sends these automatically — this file is the human-readable reference and the
place to tune wording.

---

## Order of authoring
1. `01-solution-overview.md`
2. `02-requirements.md`
3. `global-requirements-<category_slug>.md`  *(reuse existing file if present; only author if missing)*
4. `03-implementation.md`
5. `scripts/` (5 PowerShell scripts)
6. `05-testing.md`
7. `07-best-practices.md`
8. `08-deliverables-summary.md`
9. `executive-summary.md`
10. `06-troubleshooting.md`  ← **LAST**
11. `solution.meta.json`
12. `listing/bagisto-products.json`

---

### 1 — `01-solution-overview.md`
```
Write the file `01-solution-overview.md` for a solution titled "{{TOPIC}}".
Shaping note (binding if present): {{NOTES}}
Start with the heading:  # 1. Solution Overview — {{TOPIC}}
Cover, as ## subsections: What it is; How it works; Authentication/identity model (if relevant);
Benefits; Limitations (be honest); The standard deployment model (Assess → Configure → Pilot →
Validate → Expand). Explain the WHY here (the steps elsewhere will not repeat it). 500–900 words.
Remember the accuracy rules: mark anything uncertain with ‹VERIFY: … — check <source>›.
```

### 2 — `02-requirements.md`
```
Write `02-requirements.md` for "{{TOPIC}}".  Heading:  # 2. Requirements
List every prerequisite (licensing, identity/Entra roles, OS/versions, hardware/TPM, network/firewall
endpoints, certificates, tenant settings). Format EACH requirement as its own ## R-item with these
four bold labels, in this order:
**Description** — what it is.
**Why required** — why the solution needs it.
**How to verify** — the exact check (portal path or command) to see if it is present.
**How to implement if missing** — exact steps to add it.
Include the exact least-privilege admin role(s). Mark uncertain scope/role names with ‹VERIFY:›.
(context): {{OVERVIEW}}
```

### 3 — `global-requirements-<category_slug>.md`  *(only if the file does not already exist)*
```
Write `global-requirements-{{CATEGORY_SLUG}}.md`: the prerequisites common to EVERY solution in the
"{{CATEGORY}}" category (tenant, licensing baseline, admin roles, network baseline). Same four-label
format as the per-solution requirements. Keep it category-general, not specific to "{{TOPIC}}".
```

### 4 — `03-implementation.md`
```
Write `03-implementation.md` for "{{TOPIC}}".  Heading:  # 3. Implementation
Give the exact, ordered, click-by-click steps following Assess → Configure → Pilot → Validate →
Expand. Full navigation drill-downs on every step. NAME every object you create using
`<Purpose> – <Scope> – <Stage>` and reuse those names consistently. Reference the scripts by filename
where an admin should run one ({{SOL}}-Discovery.ps1, {{SOL}}-Validation.ps1, etc.). Pilot on a named
pilot group before the fleet. Mark any uncertain menu path, setting value, or command with ‹VERIFY:›.
(context): {{OVERVIEW}} + {{REQUIREMENTS}}
```

### 5 — the 5 PowerShell scripts  *(call once per script; write to `scripts/`)*
```
Write a PowerShell script named "{{SOL}}-{{ROLE}}.ps1" for the solution "{{TOPIC}}".
ROLE is one of: Discovery, Validation, Reporting, Remediation, and one topic-specific helper.
Rules: read-only by default; any change-making action must support -WhatIf and require an explicit
-Apply/-Commit switch. If it calls Microsoft Graph, make it cloud-aware (Connect-MgGraph -Environment
Global|USGov|USGovDoD). Begin the file with a comment header block containing: .SYNOPSIS (Purpose),
HOW TO RUN, EXPECTED RESULTS, and a neutral .NOTES line (NO company name). Use real cmdlets; if you
are unsure a cmdlet or Graph path exists, put ‹VERIFY: …› in a comment rather than inventing it.
Output ONLY the script.
```

### 6 — `05-testing.md`
```
Write `05-testing.md` for "{{TOPIC}}".  Heading:  # 5. Testing & Validation
Give concrete validation procedures with explicit PASS/FAIL gates (e.g. "Gate 1 — <condition>: PASS
if <observable>, FAIL if <observable>"). Reference the exact object names and scripts used earlier.
(context): {{IMPLEMENTATION_SUMMARY}}
```

### 7 — `07-best-practices.md`
```
Write `07-best-practices.md` for "{{TOPIC}}".  Heading:  # 7. Best Practices
Operational and design best practices specific to this solution (naming discipline, phased rollout,
security, ongoing hygiene). Bulleted, specific, not generic filler.
```

### 8 — `08-deliverables-summary.md`
```
Write `08-deliverables-summary.md` for "{{TOPIC}}".  Heading:  # 8. What's Included
Summarize the documentation sections and the 5 scripts (name each script + one line on what it does).
```

### 9 — `executive-summary.md`
```
Write `executive-summary.md` for "{{TOPIC}}".  Heading:  # Executive Summary
One page for a decision-maker: the problem, the outcome this solution delivers, the effort/risk
profile, and what they get. No step detail. White-label.
```

### 10 — `06-troubleshooting.md`  ← LAST
```
Write `06-troubleshooting.md` for "{{TOPIC}}".  Heading:  # 6. Troubleshooting
A symptom → cause → fix → re-validate table/list covering the real failure modes of the steps you
authored. Reference the EXACT object names and scripts from the implementation. This is written last
on purpose — use the actual names you already chose. Mark uncertain error codes/paths with ‹VERIFY:›.
(context): {{IMPLEMENTATION_SUMMARY}} + {{REQUIREMENTS}}
```

### 11 — `solution.meta.json`  *(JSON mode: set Ollama "format":"json")*
```
Output ONLY valid JSON for solution.meta.json with these exact keys:
slug, title, category, category_slug, sol_code (="{{SOL}}"), version ("1.0.0"), status ("generated"),
created ("{{TODAY}}"), updated ("{{TODAY}}"), published_at (null), version_directive ("New"),
branding ("off"), author_notes (array; include a "pricing: T? — reason" note and any ‹VERIFY› items),
products (array of 3: {sku:"PTK-{{SOL}}-COMM-001",audience:"commercial",price:{{COMM}}},
{sku:"PTK-{{SOL}}-NPO-001",audience:"nonprofit",price:{{NPO}}},
{sku:"PTK-{{SOL}}-GOV-001",audience:"government",price:{{GOV}}}),
deliverables (["{{SOL}}-Complete-Solution.zip"]).
```

### 12 — `listing/bagisto-products.json`  *(JSON mode)*
```
Output ONLY valid JSON matching this shape (it will be validated against a strict schema):
{
  "solution": { "slug":"<slug>", "title":"{{TOPIC}}", "category_path":["{{CATEGORY_STORE_NAME}}"], "version":"1.0.0" },
  "products": [ <3 products: commercial, nonprofit, government> ]
}
Each product object requires: sku, name, type ("downloadable"), audience, price, short_description
(HTML, ≥10 chars), description (HTML, ≥50 chars), and also include meta_title, meta_description,
url_key ("<slug>-commercial" | "-nonprofit" | "-government"), image ("{{SOL}}-hero.png"),
downloads ([{ "title":"Complete Solution Package (PDF, Word Doc & Scripts)", "source_type":"file",
"source":"{{SOL}}-Complete-Solution.zip" }]).
The commercial description is the persuasive sales copy: an <h3> hook, the problem, a "run it yourself
— simpler, cheaper, tested" value block (3 bullets), a "what's inside" list (docs + 5 scripts), and a
bottom-line outcome. The nonprofit/government descriptions are condensed variants noting the
discount + that eligibility is verified. Prices: commercial={{COMM}}, nonprofit={{NPO}} (=round(comm*0.60,2)),
government={{GOV}} (=round(comm*0.85,2)). White-label — no company name.
```

---

## Also needed: a hero spec (`listing/hero.json`) for the image tool
Author a small JSON the existing `build-hero.py` consumes:
```
Output ONLY JSON for listing/hero.json:
{ "title_lines":[{"text":"<part1>","color":"white","size":"main"},{"text":"<part2>","color":"green","size":"main"},
                 {"text":"<subtitle>","color":"blue","size":"sub"}],
  "from":{"label":"<BEFORE state>","items":["<pain1>","<pain2>","<pain3>","<pain4>"]},
  "to":{"label":"<target>","stat":"<one-line outcome>"},
  "tagline":"SECURE.  MODERN.  EFFICIENT.",
  "benefits":[{"icon":"shield","title":"<b1>","sub":"<s1>"},{"icon":"lock","title":"<b2>","sub":"<s2>"},
              {"icon":"chart","title":"<b3>","sub":"<s3>"},{"icon":"gear","title":"<b4>","sub":"<s4>"}] }
Valid icon names: shield, fingerprint, chip, cloud, lock, key, chart, gear, device, users.
```
