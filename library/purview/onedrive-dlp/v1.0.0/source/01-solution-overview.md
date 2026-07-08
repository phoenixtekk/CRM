# 1. Solution Overview — OneDrive for Business DLP (Microsoft Purview)

## What this solution is
OneDrive for Business is personal cloud storage that fills up with corporate data — customer
spreadsheets, contracts, exports, and screenshots that individuals save "just to work on." Two risks
follow: **sensitive content sitting in personal storage**, and **that content being over-shared** —
most often a document handed out as "anyone with the link" or shared directly to an external address.
**Microsoft Purview Data Loss Prevention (DLP)** addresses both by matching the *content* in OneDrive
against **sensitive information types** and **classifiers**, and by evaluating **how a file is shared**,
then applying a policy action — audit only, warn the user with a **policy tip**, allow with a business
**justification/override**, or **block/restrict** access — scoped to the **OneDrive for Business**
location.

This solution is a repeatable, evidence-driven way to implement OneDrive DLP using only the **Microsoft
Purview portal**, **Security & Compliance PowerShell** (`Connect-IPPSSession`), and **Microsoft Graph** —
no third-party tooling. Its defining discipline is that **every policy is built and proven in SIMULATION
mode first** (Microsoft's built-in test mode that evaluates policy against real OneDrive content and
sharing activity and shows what *would* have matched, without affecting a single user), tuned for a low
false-positive rate, and only then moved to enforcement.

> **Scope boundary.** This solution delivers the **technical method and evidence** for OneDrive DLP
> configuration. *Which* data is regulated, *which* classifiers legally apply, and *what* the enforced
> action must be for a given data category (e.g. block external sharing outright vs. warn-and-override)
> are **business, compliance, privacy, and legal determinations** — deferred to those functions. The
> solution helps you configure and prove the control; it does not make the policy decision.

## Why this matters
- OneDrive is where corporate data quietly becomes **personal-cloud data**. A file shared "anyone with
  the link" is reachable by anyone that link reaches — inside or outside the company — with no further
  gate. DLP is the control that detects the sensitive content and clamps the risky share.
- DLP that is switched straight to **enforce** without simulation is the classic failure: it strips
  sharing on legitimate collaboration, floods the help desk, and gets disabled within a week.
  Simulation-first is the difference between a control that survives and one that is turned off.
- False positives are the enemy of adoption. A built-in credit-card detector that fires on internal
  reference numbers trains users to ignore every policy tip. Tuning — confidence levels, instance
  counts, supporting keywords, and Exact Data Match — is what makes the control trusted.
- The same sensitive-information-type library drives DLP, auto-labeling, and insider risk. Getting the
  classification layer right for OneDrive pays off across the whole Purview estate.

## How it works
1. **Sensitive information types (SITs) and classifiers** define *what* to look for. Purview ships
   150+ **built-in SITs** (credit card, SSN/national ID, IBAN, health record numbers, etc.), and you can
   add **custom SITs** (regex + keyword + confidence), **Exact Data Match (EDM)** SITs (matched against a
   hashed upload of your real data for near-zero false positives), and **trainable classifiers**
   (machine-learned categories such as source code, resumes, or financial statements).
2. **A OneDrive DLP policy** binds those SITs to the **OneDrive accounts** location with **conditions**
   (which SIT, how many instances, what confidence — and, crucially for OneDrive, *how the file is
   shared*: **content is shared with people outside my organization** vs. **only inside**), **actions**
   (audit / notify / restrict access / block external access), and **user experience** (policy tips,
   allow-with-justification, allow-override).
3. **Simulation mode** runs the policy against live OneDrive content and sharing activity and records
   what *would* have matched — with or without policy tips shown — so you can see the true hit volume
   and false positives **before** any enforcement. Every policy in this solution starts here.
4. **Tuning** reduces false positives using confidence levels, instance thresholds, supporting keyword
   evidence, EDM, and exceptions — measured against the simulation results.
5. **Enforcement** turns the tuned policy on (tips / override / restrict / block external share) in a
   limited **pilot ring** of users, then expands.
6. **Incident/alert handling** — DLP rule matches raise **alerts** in the Purview portal and DLP events
   flow to **Activity Explorer**; this solution wires the triage, severity, and response workflow so
   matches are actually acted on.

## The two things a OneDrive policy controls
- **Sensitive content at rest** — sensitive data *stored* in OneDrive, regardless of sharing (e.g. a
  spreadsheet of card numbers in a user's OneDrive). This surfaces exposure even before anyone shares.
- **Risky sharing of sensitive content** — the higher-severity case: a file containing a SIT that is
  **shared externally** or via **"anyone with the link."** The DLP rule condition *Content is shared
  from Microsoft 365 → with people outside my organization* lets you act specifically on the over-share,
  up to **removing external access** while leaving internal collaboration untouched.

## The simulate→enforce journey (the core discipline)
> Define SITs/classifiers → build the OneDrive DLP policy in **SIMULATION** (no user impact) → measure
> hit volume and false positives in **Activity Explorer / DLP alerts** → **tune** (confidence, instance
> count, keywords, EDM, sharing condition, exceptions) → re-simulate until false positives are
> acceptable → enable with **policy tips + allow-override/justification** in a **pilot ring** → validate
> → expand to enforce (restrict/block external share) across the intended scope → operate (triage
> alerts, review overrides, re-tune).

## What you can control
- Which SITs/classifiers are in scope and at what **confidence** and **instance count** they trigger.
- Whether the policy acts on **content at rest**, **externally-shared content**, or both.
- Which OneDrive accounts are **included or excluded** (all accounts, or scoped to a pilot-ring group).
- The **action** per data category (audit → tip → justify → restrict → block external access) — set per
  compliance's determination.
- Whether users get **policy tips**, can **override** with justification, and what the override says.
- The **pilot ring** enforced first, and the simulation dwell time before enforcement.

## Limitations (be honest with buyers)
- **Advanced classifiers are licensing-dependent** — DLP for OneDrive and built-in SITs are broadly
  available, but **custom/Exact Data Match/trainable classifiers** and some capabilities are gated
  behind **E5 / the E5 Compliance add-on** (some are in preview). This solution flags "verify your
  licensing/tenant" rather than asserting availability that may differ in your tenant.
- DLP inspects **content it can classify**; strongly encrypted or unrecognized file formats, or content
  below the confidence/instance threshold, will not match. DLP is one control among several, not a
  guarantee.
- **DLP acts on sharing, not on the underlying tenant sharing settings.** If your tenant permits
  "anyone" links broadly, DLP can restrict the *sensitive* over-shares, but tenant-level SharePoint/
  OneDrive external-sharing configuration is a complementary control (verify it separately).
- **Some features are in preview** and **portal paths evolve** — paths are cited from Microsoft docs
  and flagged to verify.
- The **enforced action for a data category is a compliance/legal decision**, not a technical default —
  this solution configures and proves the control; the determination is deferred.

## Naming convention (used in every doc and script)
Every artifact this solution creates uses `<Purpose> – <Scope> – <Stage>`, reused verbatim across the
docs, scripts, and the Purview portal. The standard set:

| Artifact | Name |
|---|---|
| Custom sensitive info type | `Customer PII – Custom SIT – Classification` |
| EDM schema / SIT | `Customer PII – EDM – Classification` |
| OneDrive at-rest DLP policy (simulation) | `DLP – OneDrive Sensitive – Simulation` |
| OneDrive external-share DLP policy (simulation) | `DLP – OneDrive External Share – Simulation` |
| Enforced pilot policy | `DLP – OneDrive – Enforce Pilot` |
| Pilot user ring | `DLP OneDrive Pilot Ring – Stage1` |
| Policy-tip / override text | `DLP Notice – OneDrive – Standard` |
| Incident/alert workflow | `DLP Alerts – OneDrive – Triage` |

## The standard deployment model
> **Assess** current OneDrive exposure and classification intent → **Design** SITs/classifiers, the
> policy, and the user experience → **Configure** the policy **in simulation** → **Pilot** (simulate →
> tune → enforce to a ring) → **Validate** against pass/fail gates (sensitive over-shares restricted,
> false-positive rate low, incidents handled) → **Expand** to the full intended scope and ongoing
> operations. Every high-impact change is piloted in simulation first, with a documented rollback.
