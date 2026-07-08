# 2. Requirements Guide — Data Estate Insights & Data Quality (Microsoft Purview)

Verify every requirement before you configure insights or author a data-quality rule. Each entry gives
Description, Why, How to verify, and How to implement if missing. Category-wide prerequisites (tenant,
compliance licensing, least-privilege roles, toolchain, in-scope data, stakeholders, pilot) are in
`global-requirements-purview.md` — this guide adds the prerequisites specific to **Data Estate
Insights and Data Quality**.

> **Licensing/availability caveat.** Data Estate Insights / analytics and Unified Catalog **Data
> Quality** are licensing-/plan- and **consumption**-dependent, and some features may be in
> **preview**. Where this guide names a capability, portal path, or role, **verify its current
> availability, naming, and pricing for your tenant** in Microsoft's documentation and the Purview
> portal before relying on it — the experience is evolving.

## 2.1 A governed estate already mapped, scanned, and catalogued
Description: A Microsoft Purview account whose sources are already **registered, scanned, and
classified**, with a working **Unified Catalog** (at least one **governance domain** and one **data
product**). This solution measures and reports on that estate; it does not create it.
Why: Insights aggregate scanned/catalogued assets, and data-quality rules bind to **data assets inside
a data product** — without a governed estate there is nothing to report on or score.
How to verify: The Purview account endpoint (`https://<account>.purview.azure.com`) resolves and the
catalog returns assets; run `DGINSIGHT-Discovery.ps1` to confirm assets, domains, and data products
exist.
How to implement if missing: Stand up the Data Map / scanning / Unified Catalog foundation first (see
the *Data Governance: Data Map, Scanning & Unified Catalog* solution), then return here.

## 2.2 Least-privilege insights + data-quality roles
Description: Role assignments at the right scope — a **catalog / Data Governance reader** to view
insights, a **governance domain owner** and **data steward** to curate, and a **data-quality steward**
to author and run data-quality rules. Account-level or **Data Governance Administrator** only where
account-level changes are required. **Verify current role names for your tenant** — Unified Catalog
roles are evolving.
Why: Purview uses fine-grained governance roles; viewing insights, authoring rules, and running scoring
each require the matching role, and least-privilege is a governance requirement in its own right.
How to verify: In the Purview portal open the governance domain's **roles** and the data-quality role
page; run `DGINSIGHT-Discovery.ps1` (reports role/feature coverage, read-only).
How to implement if missing: Assign the least-privilege role at the narrowest domain scope under change
control; reserve Data Governance Administrator for a small named group.

## 2.3 Data Quality enabled and its compute available (verify licensing/preview)
Description: The Unified Catalog **Data Quality** capability enabled for the tenant, with the
**compute** it uses to profile and evaluate data available (Data Quality runs a scan that reads source
data). Confirm the capability is licensed/enabled and not blocked by a preview gate.
Why: Rules cannot run and scores cannot be produced without Data Quality enabled and its scan compute
available; this is the most common "the feature isn't there" blocker and it is plan-/preview-gated.
How to verify: Data Quality is visible in the Unified Catalog for a data product and a test rule can be
created; `DGINSIGHT-Discovery.ps1` reports whether the data-quality surface responds.
How to implement if missing: Confirm the required licensing/consumption model and enablement with your
Purview/Azure owner; if the feature is in preview or unavailable in your tenant/region, record it and
defer data-quality scoring — **do not assume availability**.

## 2.4 A pilot data product with critical data elements identified
Description: One bounded **data product** chosen as the pilot, with its **critical data elements**
(CDEs) — the specific columns that matter (for example `CustomerID`, `Email`, `AccountBalance`) —
identified with the data owner, and the **data assets** that back them mapped into the data product.
Why: Data-quality rules bind to critical data elements inside a data product; without an agreed CDE set
there is nothing to write rules against.
How to verify: The pilot data product exists in the catalog with its assets mapped and 3–10 CDEs named;
run `DGINSIGHT-Set-Scope.ps1` to record the pilot scope manifest.
How to implement if missing: Facilitate a short workshop with the data owner to pick one high-value data
product, confirm its backing assets, and name the CDEs to measure.

## 2.5 A source connection and credentials for the data-quality scan (never in code)
Description: A working **connection** from Data Quality to the pilot data product's backing source, with
credentials via the Purview account's **managed identity** or an **Azure Key Vault**–stored secret. The
scan **reads live data**, so the identity is granted the **least read** role on the source only.
**No credential is ever placed in a script or document.**
Why: A data-quality scan profiles and evaluates real values; it must authenticate to the live source,
and storing that credential safely (managed identity / Key Vault, least-privilege) is mandatory and is
what keeps the provided scripts secret-free.
How to verify: The data-quality **connection / Test connection** for the pilot source succeeds and the
identity has only read; no secret appears in any script.
How to implement if missing: Configure the connection, grant the managed identity (or a Key
Vault–stored secret) the least read role on the source, and confirm the test succeeds before scoring.

## 2.6 Agreed quality dimensions, rules, and thresholds (owner-set, not technical defaults)
Description: With the data owner, agree which **quality dimensions** to measure for each CDE — for
example **Completeness, Conformity, Consistency, Accuracy, Uniqueness/Validity, Timeliness** — the
specific **rule** per dimension (e.g. "Email matches format", "CustomerID is unique"), and the
**threshold** that counts as pass/fail (e.g. completeness ≥ 98%). Thresholds are a **business
determination**, not a technical default.
Why: A score is only meaningful against an agreed threshold; the dimensions and thresholds are the
owner's call, and the solution measures against them rather than inventing them.
How to verify: For each pilot CDE the dimension(s), rule, and threshold are written down and confirmed
by the owner; `DGINSIGHT-Set-Scope.ps1` records them.
How to implement if missing: Run the CDE workshop (2.4) far enough to capture, per CDE, the dimension,
rule intent, and pass threshold before authoring rules.

## 2.7 A data-owner / steward review path and privacy sign-off
Description: A named **data owner / steward** to review the scores and decide what a low score means,
plus a **privacy acknowledgement** that a data-quality scan reads live data on the bounded pilot scope.
Why: The solution produces scores; the owner interprets them and owns remediation, and because scoring
reads real data, a privacy-aware, least-privilege, bounded pilot is required.
How to verify: The owner/steward is named and has agreed the pilot scan reads live data on the bounded
scope; determinations (thresholds, remediation, compliance meaning) are assigned to them.
How to implement if missing: Identify the owner/steward and capture their agreement to the bounded pilot
before running any data-quality scan.

## 2.8 A pilot scope and change control
Description: A **bounded pilot** — one governance domain, one data product, its CDEs and rules — to
prove insights and data-quality scoring before estate-wide rollout, plus a **change-control** window
for scans (data-quality scans consume compute and read live data).
Why: Every solution in this category follows Assess → Design → Configure → **Pilot** → Validate →
Expand; data-quality scanning is compute- and data-access-sensitive and is always proven on a bounded
scope first.
How to verify: A named pilot domain/data product, its CDE/rule set, and a scan change window exist; run
`DGINSIGHT-Set-Scope.ps1` to materialize the pilot scope.
How to implement if missing: Choose one well-understood, high-value data product as the pilot; agree the
scan window and change control with the data owner.

---
## Checklist
- [ ] Governed estate already mapped/scanned/catalogued (domain + data product exist) — `DGINSIGHT-Discovery.ps1`
- [ ] Least-privilege insights + data-quality roles assigned (verify current names) — `DGINSIGHT-Discovery.ps1`
- [ ] Data Quality enabled + its scan compute available (verify licensing/preview) — `DGINSIGHT-Discovery.ps1`
- [ ] Pilot data product with critical data elements identified — `DGINSIGHT-Set-Scope.ps1`
- [ ] Source connection + credentials via managed identity / Key Vault (no secrets in code)
- [ ] Quality dimensions, rules, and thresholds agreed with the owner — `DGINSIGHT-Set-Scope.ps1`
- [ ] Data-owner/steward review path + privacy sign-off for live-data scan
- [ ] Pilot scope and scan change window agreed
