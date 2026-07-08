# 2. Requirements — Sensitive Information Types Implementation (Microsoft Purview)

These are the **solution-specific** prerequisites for selecting, testing, and tuning **built-in** sensitive
information types (SITs) in Microsoft Purview. They build on — and do not repeat — the six shared
prerequisites in **`global-requirements-purview.md`** (tenant + compliance licensing, least-privilege
Purview roles, S&C PowerShell + Graph toolchain, in-scope data sources, compliance/records/privacy/legal
stakeholders, and a pilot scope + change control). Verify each item below before starting the
Implementation Guide.

For every requirement: **Description** (what it is), **Why required**, **How to verify**, **How to
implement if missing**.

---

## 2.1 Licensing sufficient to view, test, and use SITs (and to see where they match)
- **Description:** The built-in SIT **library** and basic SIT use in DLP are broadly available, but the
  surfaces you tune and validate against — **Content explorer**, **Activity explorer**, **auto-labeling**,
  and advanced classifiers — are **plan-gated** (typically **Microsoft 365 E5** or the **E5 Compliance**
  add-on; some capabilities are in **preview**). This extends GR-#1 with the SIT-specific detail.
- **Why required:** You can *select* a built-in SIT on most plans, but *measuring* its false-positive rate
  in Content/Activity Explorer — the core of tuning — depends on the compliance plan. Testing a SIT against
  real-traffic volume via a simulation DLP policy needs DLP available.
- **How to verify:** In the **Microsoft 365 admin center** confirm the subscription/add-ons; in the
  **Purview portal → Data classification** confirm **Content explorer** and **Activity explorer** are
  visible, and **Data loss prevention** is available for simulation measurement. **Flag "verify your
  licensing/tenant"** — availability evolves.
- **How to implement if missing:** Assign/acquire the required licensing (E5 / E5 Compliance) before
  relying on Content/Activity Explorer for tuning; on lower plans, use the portal **Test** experience and a
  simulation DLP policy for measurement instead.

## 2.2 SIT-specific least-privilege roles — including Content Explorer access
- **Description:** The Purview roles needed to work with SITs: **Compliance Administrator** or **Compliance
  Data Administrator** to view the SIT library and create/tune the measurement policy and any editable SIT
  copy; **DLP Compliance Management** for the simulation policy; and — critically — the **Content Explorer
  List viewer** and **Content Explorer Content viewer** roles to *see the actual matched items* when tuning
  false positives. Global Administrator only where genuinely required. Extends GR-#2.
- **Why required:** Tuning is impossible without seeing what matched. The Content Explorer roles are a
  **separate, deliberately restricted** grant (they expose sensitive content) — without them you can count
  matches but not inspect them to classify true vs false positive.
- **How to verify:** **Purview portal → Settings → Roles & scopes → Permissions** — confirm your account's
  role-group membership includes the compliance and **Content Explorer** roles.
- **How to implement if missing:** Assign the least-privilege role groups under change control; treat the
  Content Explorer content-viewer grant as sensitive and time-boxed to the tuning exercise.

## 2.3 A classification intent and a data-category inventory
- **Description:** A documented view of **what sensitive data you are protecting** (e.g. payment card data,
  national IDs, health identifiers, bank account numbers, customer PII) so each category can be mapped to a
  built-in SIT. This is the input to the **`SIT Selection Register`**. Extends GR-#4.
- **Why required:** Selection is category-driven: without knowing which data categories matter, you cannot
  choose the right built-in SITs or judge whether a match is a true or false positive.
- **How to verify:** Confirm the in-scope data categories with the data owners; **Purview portal → Data
  classification → Classifiers → Sensitive info types** lists the built-in SITs available to map them to.
- **How to implement if missing:** Build the category inventory with stakeholders before selecting SITs
  (this solution's Discovery script inventories the built-in library to map against).

## 2.4 A representative test corpus of clearly-fake sample data
- **Description:** A small **test corpus** of **non-real, clearly-fake** sample content per category — both
  **positive** samples (content that *should* match, using documented fake test values such as the test
  credit-card number `4111 1111 1111 1111`) and **negative / look-alike** samples (internal reference
  numbers, order IDs, and other content that *resembles* the pattern but must **not** match). This becomes
  the **`SIT Test Corpus – <Category>`**.
- **Why required:** Testing and tuning require known inputs. Without a corpus you cannot prove a SIT detects
  true positives *and* rejects the look-alikes that drive false positives — which is the whole point.
- **How to verify:** Confirm you have positive and negative samples per category and that **no real
  customer/employee data** is used.
- **How to implement if missing:** Assemble the corpus from documented test values and synthetic look-alike
  content before testing. **Never** use production sensitive data in a test corpus.

## 2.5 DLP available for simulation-based measurement
- **Description:** For measuring a SIT's false-positive rate against **real traffic** (not just a static
  corpus), a **DLP policy run in SIMULATION mode** referencing the selected SITs — the
  **`SIT Measure – <Category> – Simulation`** policy. Simulation evaluates against live content and records
  what *would* match, with **zero** user impact.
- **Why required:** The portal Test experience proves a SIT against your corpus; simulation proves it
  against the messy reality of production content, which is where the real false-positive drivers surface.
  Simulation is the safe way to do this without touching a single user.
- **How to verify:** **Purview portal → Data loss prevention → Policies** — confirm you can create a policy
  and select **Run the policy in simulation mode**.
- **How to implement if missing:** If DLP is not in your plan, tune against the portal Test experience and
  Content Explorer only; acquire DLP for real-traffic measurement where the category warrants it.

## 2.6 A false-positive threshold and a pilot scope (SIT-specific)
- **Description:** An agreed **false-positive threshold** per category (the maximum acceptable share of
  matches that are false positives — a compliance/privacy decision), an agreed **simulation dwell time**
  (long enough to capture representative traffic), and a named **`SIT Pilot Ring – Stage1`** to measure
  against before the selection is adopted tenant-wide. Extends GR-#6.
- **Why required:** "Tuned" is meaningless without a target. The threshold defines *done*; the dwell time
  ensures the measurement is representative; the ring keeps measurement scoped.
- **How to verify:** Confirm the threshold, dwell time, and ring membership with compliance and the data
  owners.
- **How to implement if missing:** Agree the threshold and dwell time and define the ring before measuring;
  record them in the **`SIT Threshold Register`**.

---

### Requirements summary

| # | Requirement | Gate |
|---|---|---|
| GR 1–6 | Category prerequisites (`global-requirements-purview.md`) | Tenant/licensing, roles, toolchain, scope, stakeholders, pilot + change control |
| 2.1 | Licensing to view/test/measure SITs (E5 / E5 Compliance; verify) | Content/Activity Explorer + DLP simulation available |
| 2.2 | SIT roles **incl. Content Explorer viewer** | Can see & classify matched items |
| 2.3 | Classification intent + data-category inventory | Selection is category-driven |
| 2.4 | Fake positive + negative test corpus | Testing has known inputs |
| 2.5 | DLP available for simulation measurement | Real-traffic false-positive measurement |
| 2.6 | FP threshold + dwell time + pilot ring | "Tuned" has a defined target |

> **Deferred to compliance/privacy/legal:** which data categories are in scope, which SITs legally satisfy
> a regulation, and the acceptable false-positive threshold per category. This solution provides the
> technical selection, test, and tuning method and the evidence — not the determination.
