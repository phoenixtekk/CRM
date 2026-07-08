# Implementation — Purview DLP, Labels & Retention (Government / GCC High)

Follow these steps **in order**. Every navigation path uses the **GCC High** portals — sign in at
**`https://login.microsoftonline.us`** and work in **`https://compliance.microsoft.us`** (the
Microsoft Purview portal; it may redirect to `purview.microsoft.us`). If a portal loads at a `.com`
host, stop — you are in the Commercial cloud.

**Naming — use these object names verbatim** (reuse them exactly in later steps and in the scripts):

| Object | Name to create and reuse |
| --- | --- |
| Pilot Entra security group | `SG-Purview-Pilot` |
| Sensitivity labels | `Public`, `General`, `Confidential`, `Confidential \ CUI` |
| Label policy | `LP-Purview-Pilot` |
| Auto-labeling policy (service-side) | `AL-CUI-ServiceSide` |
| DLP policy | `DLP-CUI-Baseline` |
| DLP rule (inside the policy) | `DLP-CUI-Baseline-Rule1` |
| Retention label | `Ret-CUI-7yr` |
| Retention label policy (auto-apply) | `RP-CUI-7yr-Auto` |
| Org-wide retention policy | `RP-Baseline-Retain` |

**GCC High parity reminders are inlined at the step where they matter.** Full detail:
`gcc-high-parity-notes.md`.

---

## Phase 0 — Assess (gate before you build)

1. Sign in at **`https://login.microsoftonline.us`**; open **`https://compliance.microsoft.us`**.
   Confirm the Purview solutions **Information Protection**, **Data Loss Prevention**, **Data
   Lifecycle Management**, and **Records Management** all appear in the left navigation.
2. Confirm licensing (R2) at **`https://portal.office365.us` → Billing → Licenses** — G3/G5 (+ G5
   Compliance / IP&G) present.
3. Confirm roles (R3) at **`compliance.microsoft.us` → Settings → Roles & scopes → Permissions**.
4. Confirm **`SG-Purview-Pilot`** exists at **`https://entra.microsoft.us` → Groups**. If not:
   **Groups → New group → Security**, name it `SG-Purview-Pilot`, add pilot users.
5. **Run the parity check (R8).** For every feature you intend to use, confirm **Available** in
   `gcc-high-parity-notes.md` and that the option is visible in the portal.

**Gate:** portal loads at `.us`, licensing/roles present, pilot group exists, parity check done.
Do not proceed until all pass.

---

## Phase 1 — Sensitivity labels + label policy

### Step 1.1 — Create the labels

1. In **`compliance.microsoft.us`** go to **Information Protection → Labels** (under **Solutions**;
   in the newer Purview portal this is **Information Protection → Sensitivity labels**).
2. **+ Create a label**. Create these four, in order, with these exact names:
   - `Public` — scope **Items** (Files & emails). No encryption, no content marking.
   - `General` — scope **Items**. No encryption; optional footer "General".
   - `Confidential` — scope **Items**. Turn on **Encrypt** (assign permissions to your org),
     content marking footer "Confidential".
   - `Confidential \ CUI` — create `Confidential` first, then create **CUI** as a **sublabel** of
     `Confidential`. Turn on **Encrypt** with a restrictive permission set; content marking header
     "CUI".
3. For each label, complete the wizard (scope → protection settings → content marking → auto-labeling
   for files/emails **left OFF here**; you configure auto-labeling in Phase 2).

> **GCC High note (containers):** if you want to label **Teams/Groups/SharePoint sites**
> (container labels), enable **Groups & sites** scope. Container labeling is available, but
> **granular Conditional Access via sensitivity labels for SPO sites is *not available* in GCC High**
> (*on engineering backlog*) — do not design site access-control on that feature. Verify container
> behavior in your tenant. (`gcc-high-parity-notes.md` §2.)

### Step 1.2 — Publish the labels with a label policy

1. **Information Protection → Label policies → Publish labels**.
2. Select `Public`, `General`, `Confidential`, `Confidential \ CUI`.
3. **Assign to users and groups:** choose **`SG-Purview-Pilot`** only (pilot scope).
4. Policy settings:
   - **Default label for documents/emails:** `General`.
   - **Require users to apply a label** (mandatory labeling): **On** for the pilot.
   - **Require justification to remove a label or lower classification:** **On**.
5. **Name the policy `LP-Purview-Pilot`**; finish.

> **GCC High note:** applying a **"default label" to unlabeled files uploaded to a SharePoint
> library**, and **default label on documents being edited**, are **not available** in GCC High
> (*in development*). The **user default label** above (via label policy) **is** available. Do not
> rely on library-side default labeling yet.

**Gate:** pilot users see the four labels in Word/Excel/PowerPoint/Outlook (allow up to a few hours
to replicate). If not visible, see `06-troubleshooting.md`.

---

## Phase 2 — Auto-labeling (service-side)

### Step 2.1 — Build conditions from GA classifiers only

> **GCC High parity — read first:** **Named entity SITs and their policy-authoring templates are
> *not available*** in GCC High (*on engineering backlog*). Build conditions from **built-in
> sensitive information types**, **Exact Data Match (EDM)** (Available), **keyword dictionaries**,
> and **regex SITs**. **Trainable classifiers** work for **client-side** auto-labeling (Available)
> but **not** for auto-applying *records* labels (*in development*). **Office *mobile* auto-labeling
> is *not available***. (`gcc-high-parity-notes.md` §2.)

1. If you need a custom match, create it first under **Data classification → Classifiers →
   Sensitive info types** (built-in/EDM/keyword/regex) or **Exact data match**. Do **not** select a
   named-entity SIT — it will not be present.

### Step 2.2 — Create the service-side auto-labeling policy

1. **Information Protection → Auto-labeling** → **+ Create auto-labeling policy**.
2. Choose a template or **Custom**. **Locations:** Exchange Online, SharePoint Online, OneDrive
   (service-side auto-labeling for these three is **Available** in GCC High).
3. **Rules:** add conditions using the GA SITs/EDM/keywords from Step 2.1 (e.g. content contains your
   CUI EDM/keyword set).
4. **Label to apply:** `Confidential \ CUI`.
5. **Scope:** restrict to **`SG-Purview-Pilot`** mailboxes/sites where possible.
6. **Name the policy `AL-CUI-ServiceSide`**. Create it in **simulation (test) mode** — do **not**
   turn on immediately.
7. Run **simulation**, review matches in the policy's results, then turn the policy **On** only after
   the pilot gate passes.

**Gate:** simulation shows expected matches with acceptable false positives; no unexpected mass-label.

---

## Phase 3 — DLP (audit first, then enforce)

### Step 3.1 — Create the DLP policy in test/audit mode

1. **Data Loss Prevention → Policies → + Create policy**.
2. **Custom** policy. **Locations:** Exchange, SharePoint, OneDrive, **Teams chat and channel**, and
   **Devices (Endpoint DLP)** — all **Available** in GCC High (Endpoint DLP requires onboarded
   devices, R7).
3. **Create rule** named **`DLP-CUI-Baseline-Rule1`**:
   - **Conditions:** *Content contains* → your GA SITs/EDM/keywords **and/or** *Content contains
     sensitivity label* → `Confidential \ CUI` (label-as-condition = "label once, enforce
     everywhere").
   - **Actions:** for the pilot, **audit only** — **no block**. (Notify admin; optional policy tip.)
4. **Name the policy `DLP-CUI-Baseline`**.
5. Set the policy **mode to *Test it out* / *Run in test mode* (audit)** — **not** "Turn it on".
   Scope to **`SG-Purview-Pilot`** where the location supports user scoping.

> **GCC High note (SITs):** confirm each SIT in your rule is a **built-in/EDM/keyword/regex** type,
> not a named-entity SIT (not available). **Adaptive Protection** (risk-based DLP) is **rolling out
> to Gov clouds** — if you plan to gate DLP actions on Insider Risk levels, **verify Adaptive
> Protection is present in your tenant first** (`gcc-high-parity-notes.md` §5).

### Step 3.2 — Tune, then enforce

1. Let the policy run in **test/audit** for the pilot window. Review matches in **Data Loss
   Prevention → Alerts** and **Activity Explorer** (**Available** in GCC High).
2. Tune conditions to reduce false positives.
3. Only after the pilot gate passes, edit `DLP-CUI-Baseline`, add **Block** / **Restrict** actions
   (with user override + justification if appropriate), and switch mode to **On**. Expand scope
   group-by-group.

**Gate:** DLP matches are accurate in audit; enforcement change goes through change control (G8)
before any block is enabled.

---

## Phase 4 — Retention & records

### Step 4.1 — Org-wide baseline retention policy

1. **Data Lifecycle Management → Retention policies → + New retention policy**.
2. **Name `RP-Baseline-Retain`**. **Locations:** Exchange email, SharePoint, OneDrive, Microsoft 365
   Groups, **Teams chat / channel / meeting recordings** (all **Available** in GCC High).
3. Set retain-then-delete for your baseline period. **Adaptive scopes** (Available) can target by
   attribute if needed.

### Step 4.2 — Retention label for CUI

1. **Data Lifecycle Management → Retention labels → + Create a label**.
2. **Name `Ret-CUI-7yr`**. Set **Retain items for 7 years**, then choose the end-of-period behavior.

> **GCC High note:** **"Apply retention *label* action at end of retention period"** is **not
> available** (*on engineering backlog*). For the end-of-life step, use a supported behavior
> (retain-then-delete, or start a disposition review) rather than a label-action-at-end-of-period.
> (`gcc-high-parity-notes.md` §4.)

3. To make it a **record**, enable **Mark items as a record** (records management is **Available**).
   Use **Preservation Lock** (Available) where immutability is required.

### Step 4.3 — Auto-apply the retention label

1. **Retention labels → `Ret-CUI-7yr` → Auto-apply** (or **Label policies → Auto-apply a label**).
2. **Name the policy `RP-CUI-7yr-Auto`**. Condition: content contains your **GA SITs/EDM/keywords**.

> **GCC High note:** **auto-applying record policies *with trainable classifiers*** is **not
> available** (*in development*). Use **condition-based** (keyword/SIT/EDM) or **event-based**
> auto-apply for records, which **is** available.

3. Scope to **`SG-Purview-Pilot`** where supported; publish.

### Step 4.4 — Disposition / file plan (records)

1. **Records Management → File plan** — import/define record categories; **File plan manager**,
   **regulatory records**, **proof of disposal**, and **disposition review** are **Available**.
2. **Multi-stage disposition review** is **Rolling out** — verify it is present before relying on it.

> **GCC High note:** **Records Management Power Automate integration** and **Records Management Graph
> APIs** are **not available** (*backlog / in development*). Do not build record automations on
> Power Automate/Graph for records yet.

**Gate:** retention/records applied to pilot content as expected; disposition review reachable for
records.

---

## Phase 5 — Pilot → Validate → Expand

1. **Pilot** is already scoped to **`SG-Purview-Pilot`** across labels, DLP (audit), and retention.
2. **Validate** using the pass/fail gates in `05-testing.md`. Run **`PURVIEWG-Validation.ps1`** and
   **`PURVIEWG-Report.ps1`** (US Gov Graph) to confirm coverage.
3. **Expand** only after gates pass: widen the label policy and DLP scope group-by-group (use
   **`PURVIEWG-Set-ScopeTargeting.ps1`**, which defaults to `-WhatIf`), and flip DLP from audit to
   enforce under change control.

---

**The deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**

> **Sources:** Microsoft Learn — *Plan for Microsoft Purview — GCC High deployments* (parity table);
> *Microsoft Purview service description*; *Adaptive Protection* docs. Portals: `portal.office365.us`,
> `compliance.microsoft.us`/`purview.microsoft.us`, `security.microsoft.us`, `entra.microsoft.us`,
> `login.microsoftonline.us`. Full citations in `gcc-high-parity-notes.md`.
