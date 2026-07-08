# 2. Requirements Guide — Custom Sensitive Information Types (Microsoft Purview)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant licensing, Purview roles, the
PowerShell/Graph toolchain, in-scope data sources, compliance/privacy/legal stakeholders, and a pilot
scope with change control) are in `global-requirements-purview.md` — this guide adds the
**custom-SIT-specific** detail. **Licensing, portal paths, the rule-package schema, and cmdlets are
plan-dependent and the portal evolves — verify each against your own licensing and tenant.**

## 2.1 The org-specific identifier(s) and their exact format, from the data owner
**Description:** For each identifier you will turn into a SIT (e.g. **Employee ID**, **Account/Customer
number**, **Case/Matter number**, **Part number**, **Contract ID**, **Project codename**), the **exact
format**: structure (prefix, fixed length, letters/digits, delimiters, any **check digit/character**),
whether variants exist, and — critically — the **words that appear near it** in real documents
("Employee ID:", "Emp #", "Account No.", "Matter"). This is the raw material for the primary regex/
keyword element and the supporting evidence.
**Why:** A SIT is only as good as the pattern it encodes; a guessed format produces both false positives
and false negatives. The corroborating keywords are what make a bare number match *in context* only.
**Verify:** A written spec of each identifier's format and its surrounding keywords, confirmed by the
**data owner** (Requirement 2.6). Ideally, real sample documents to derive the pattern from.
**Implement:** Interview the data owner / examine real documents; document the regex-able structure and
the near-context keyword list before designing the SIT.

## 2.2 Curated positive AND negative validation samples
**Description:** Two curated sample sets: a **positive** set — content that **should** match (real or
realistic examples of the identifier in context, `Custom SIT Test – Positive`) — and a **negative** set
— **look-alike** content that must **not** match (other numbers of similar shape, the identifier without
its context, adjacent formats, `Custom SIT Test – Negative`).
**Why:** Precision can only be measured against known truth. The negative set is what catches an
over-broad regex; without it you cannot prove the SIT won't flood downstream DLP with false positives.
**Verify:** Both sets exist and are labeled; each item's *expected* result (match / no-match) is
recorded. Real sample data must be handled per your data-handling policy.
**Implement:** Assemble both sets with the data owner. Include hard negatives (numbers of the same
length, the ID stripped of its keyword) so validation is meaningful.

## 2.3 Purview roles for creating and managing sensitive information types
**Description:** The least-privilege role to **create/edit sensitive information types** — membership in
a role group holding the relevant permission, typically **Compliance Administrator** or **Compliance
Data Administrator** (which include the *Sensitive Information Type* management permissions), or an
equivalent custom role group. Global Administrator is **not** required just to build a SIT.
**Why:** SIT creation/import is permission-gated; without the role the portal option and the
`DlpSensitiveInformationType*` cmdlets are unavailable.
**Verify:** Purview portal → `Settings → Roles & scopes → Permissions` shows your account in a role
group that can manage sensitive info types; the **Create sensitive info type** option is visible under
`Data classification → Classifiers → Sensitive info types`. `CLSCUSTOM-Discovery.ps1` reports whether
the `Get-DlpSensitiveInformationType` cmdlets succeed.
**Implement:** Assign the least-privilege role group under change control (`global-requirements-purview.md`
§2).

## 2.4 Security & Compliance PowerShell (Connect-IPPSSession) and Graph
**Description:** A workstation with the **ExchangeOnlineManagement** module (providing
`Connect-IPPSSession`, and the `Get/New/Set/Remove-DlpSensitiveInformationType`,
`*-DlpSensitiveInformationTypeRulePackage`, and **`Test-DataClassification`** cmdlets), plus **Microsoft
Graph PowerShell** for usage reporting, used with a modern-auth / MFA-capable admin holding the role in
2.3.
**Why:** All five provided scripts run through Security & Compliance PowerShell; importing a custom SIT
as a **rule package**, and validating it with `Test-DataClassification`, are done through these cmdlets.
**Verify:** `Connect-IPPSSession` succeeds; `Get-DlpSensitiveInformationType` returns the built-in SITs;
`Test-DataClassification -TestTextItem 'test' -ClassificationNames 'Credit Card Number'` runs without
error. `CLSCUSTOM-Discovery.ps1` performs these checks.
**Implement:** `Install-Module ExchangeOnlineManagement`; sign in with the role-holding admin; confirm
the SIT cmdlets and `Test-DataClassification` are present.

## 2.5 Decision on the primary element and confidence design
**Description:** A design decision per SIT: whether the **primary element** is a **regex** (structured
IDs), a **keyword list** (small fixed vocabulary), or a **keyword dictionary** (large term set); what
**supporting evidence** (keywords/second regex) corroborates it; the **character-proximity** window
(default **300**); and the **confidence levels** (High **85** / Medium **75** / Low **65**) and which is
**recommended**. Large keyword dictionaries have size/format constraints — **verify the current limits
against Microsoft docs and your tenant.**
**Why:** The primary-element choice and confidence design *are* the SIT's precision. Getting the
proximity and supporting evidence right is what separates a usable detector from a noise generator.
**Verify:** A documented design per SIT (primary element, supporting keywords, proximity, confidence
levels, recommended level) approved before build.
**Implement:** Draft the design from Requirement 2.1's format spec; pick regex vs keyword list vs
dictionary by the identifier's shape; set proximity and confidence conservatively and prove them in
validation (Requirement 2.2).

## 2.6 Data owner and stakeholder engagement
**Description:** The **data owner** for each identifier (the business function that owns employee IDs,
account numbers, matter numbers, etc.) and the compliance/privacy stakeholders
(`global-requirements-purview.md` §5) who confirm the identifier is sensitive and how it should be
detected. Where a SIT will feed a **records/retention** or **legal-hold** policy, the records/legal
owner is engaged for that determination.
**Why:** The data owner defines what the identifier is and validates the samples; whether the detected
data drives retention/records/legal actions is **their determination**, not a technical one — the SIT
provides the method and evidence.
**Verify:** Named data owner and stakeholders on file; sign-off on the identifier format, the samples,
and the sensitivity intent.
**Implement:** Identify the owner per identifier; capture the format, samples, and sensitivity intent
before building. Defer any retention/records/legal *determination* to the relevant governance function.

## 2.7 A consuming policy and a pilot/simulation scope
**Description:** Because a SIT only *detects*, plan the **consuming policy** that will exercise it in the
pilot — typically a **DLP policy** (or **auto-labeling** policy) referencing the new SIT, run in
**simulation / test / disabled** mode over a **limited scope** (`Custom SIT DLP – Simulation`) before
any enforcement — plus a change-control path (`global-requirements-purview.md` §6).
**Why:** You validate a SIT's real-world precision by seeing what it *would* catch on live content
without acting on it. DLP simulation/test mode and auto-label simulation are exactly this; enforcement
before a clean pilot is the high-impact mistake the model exists to prevent.
**Verify:** A named consuming policy and a limited pilot scope exist; the consuming capability supports
**simulation/test** mode (**verify — availability is plan-dependent**); a change window/approval path is
defined.
**Implement:** Choose the consuming policy and pilot scope; confirm the capability's simulation/test mode
is available; agree change control before enabling anything in enforce.
