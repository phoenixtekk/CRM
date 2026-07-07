# Implementation

Follow these stages in order: **Assess → Design → Configure → Pilot → Validate → Expand**. Every
artifact is **named to a convention** and reused verbatim later. Every high-impact production change is
**piloted first** and has a **rollback**. **Certification determinations are out of scope** — this
produces configuration and evidence; your assessor determines conformance.

**Naming conventions used throughout (create once, reuse exactly):**

| Artifact | Name |
|---|---|
| CUI boundary OU | `CUI – Boundary – Org` |
| CUI enclave sub-OU (optional) | `CUI – Enclave – Org` |
| Pilot group | `CUI – Pilot – Org` |
| Control map (matrix) | `NIST 800-171 – Control Map – Org` |
| DLP rule (Drive/Gmail) | `DLP – CUI – Enforce` (pilot: `DLP – CUI – Monitor`) |
| External-sharing policy | `Sharing – CUI Boundary – Restricted` |
| Context-aware access level | `CAA – CUI Boundary – Enforce` |
| Retention rule (Vault) | `Retention – CUI – Org` |
| Audit-log export sink | `AuditExport – CUI – Org` |
| Evidence package | `Evidence – CUI Boundary – <YYYY-MM-DD>` |
| System Security Plan | `SSP – CUI Boundary – Org` |
| Plan of Action & Milestones | `POA&M – CUI Boundary – Org` |

---

## Stage 1 — Assess (read-only, no changes)

1. **Confirm scope inputs.** Gather the CUI inventory / data-flow map (Requirement 2) and the
   compliance owner's expectations (Requirement 3). Record which of the 110 requirements the compliance
   team considers **in scope** — **do not decide this yourself; it is their determination.**
2. **Baseline the tenant.** Run the assessment tool read-only to capture the current state of every
   mappable control:
   ```
   python assess-nist-controls.py --domain corp.example --out control-map.csv
   ```
   This produces the first draft of the **`NIST 800-171 – Control Map – Org`** matrix: for each control
   it records the Workspace setting it maps to, the observed value, and a **status**
   (`configured` / `partial` / `not-configured` / `manual` / `verify-edition`).
3. **Baseline the boundary exposure.** Run the boundary checker read-only over the draft CUI OU/groups:
   ```
   python cui-boundary-check.py --ou "/CUI – Boundary – Org" --out boundary-exposure.csv
   ```
   Record external-sharing exposure, non-member access, and mail-flow to external domains as **findings**
   (not yet remediated).
4. **Gate 1 (Assess complete):** Control-map draft exists with a status for all in-scope requirements;
   boundary-exposure findings captured; compliance owner has confirmed the in-scope requirement set.
   **Fail** → resolve missing inputs before designing.

## Stage 2 — Design

5. **Draw the boundary.** Design the **`CUI – Boundary – Org`** OU (and **`CUI – Enclave – Org`**
   sub-OU if a stricter enclave is warranted): which users move in, which Shared Drives are in scope,
   which groups gate access.
6. **Design the control-to-setting mapping.** For each in-scope requirement, decide the concrete
   Workspace mechanism (see the family map below) and the **artifact name** that will implement it.
   Update the control map's "planned setting" column.
7. **Design the evidence model.** Decide, per control, what constitutes evidence: a config export, an
   audit-log extract, or a documented manual procedure (for the non-technical families such as PS/PE/AT).
8. **Design rollback** for each high-impact change (DLP, sharing, CAA, log export): the exact prior
   value and how to restore it.
9. **Gate 2 (Design complete):** Every in-scope requirement has a planned mechanism + evidence type +
   (for high-impact ones) a rollback. Compliance owner has reviewed the SSP outline.

### NIST 800-171 family → Google Workspace mechanism (design reference)

Map at this level; the exact click-path is validated against **current Google documentation** and your
edition. Items marked **(verify edition)** depend on your Workspace edition / Assured Controls add-on.

| Family | Primary Workspace mechanism(s) |
|---|---|
| **AC** Access Control | OU/group membership on `CUI – Boundary – Org`; **`Sharing – CUI Boundary – Restricted`** external-sharing policy; **`CAA – CUI Boundary – Enforce`** context-aware access; Shared Drive member/role limits; admin role separation |
| **AT** Awareness & Training | Documented CUI-handling training + attestation records (**manual evidence**) |
| **AU** Audit & Accountability | Admin/login/Drive/Gmail **audit logs**; **`AuditExport – CUI – Org`** log export to a retained sink; log review procedure |
| **CM** Configuration Management | Baseline of OU policies; change-control records; app allow/deny (Marketplace + API access) for the boundary OU |
| **IA** Identification & Authentication | Enforced **2-step verification / security keys**; SSO/identity source; session-length policy; no shared accounts |
| **IR** Incident Response | Alert Center / audit-driven detection; documented IR procedure and reporting path (**manual + tooling evidence**) |
| **MA** Maintenance | Admin-action logging for maintenance; least-privilege admin roles (**mostly manual/managed-service evidence**) |
| **MP** Media Protection | Data-region / **client-side or default encryption (verify edition)**; DLP-controlled export; device-policy controls |
| **PS** Personnel Security | Onboarding/offboarding tied to identity source; suspension on separation (**manual + directory evidence**) |
| **PE** Physical Protection | Inherited from Google data-center controls (cite Google compliance docs) + endpoint physical controls (**manual/inherited evidence**) |
| **RA** Risk Assessment | Vulnerability/risk process; this readiness assessment itself (**manual evidence + control map**) |
| **CA** Security Assessment | The SSP, POA&M, and continuous control monitoring (this solution's outputs) |
| **SC** System & Communications Protection | TLS/mail security (SPF/DKIM/DMARC), **data regions / Assured Controls (verify edition)**, encryption in transit/at rest, boundary separation |
| **SI** System & Information Integrity | DLP (**`DLP – CUI – Enforce`**), Gmail security sandbox/attachment controls, alerting, flaw-remediation process |

## Stage 3 — Configure (against the boundary OU)

Perform each change in the Admin console (paths **verified against current Google documentation**;
where a label/path is version-dependent, **verify in your tenant**), and record the resulting value in
the control map. Configure on the OU, not the whole domain.

10. **Create/confirm the boundary OU** `CUI – Boundary – Org` and move the in-scope users into it;
    create the **`CUI – Pilot – Org`** group as a subset for piloting.
11. **AC — external sharing:** apply **`Sharing – CUI Boundary – Restricted`** (Drive external-sharing
    restricted/allow-listed) to the OU. **Rollback:** restore the OU's prior sharing setting.
12. **AC — context-aware access:** create access level **`CAA – CUI Boundary – Enforce`** and assign it
    to the CUI apps for the OU. **Rollback:** unassign the access level.
13. **IA — 2SV / keys:** enforce 2-step verification (security keys where required) for the OU;
    configure session length. **Rollback:** revert enforcement to prior state.
14. **SI/MP — DLP:** create the DLP rule, first as **`DLP – CUI – Monitor`** (audit action) for the
    pilot, later promoted to **`DLP – CUI – Enforce`** (block/warn). **Rollback:** set the rule to
    monitor/off.
15. **AU — audit-log export & retention:** configure **`AuditExport – CUI – Org`** (log export/BigQuery
    or your retained sink) and the **`Retention – CUI – Org`** Vault rule. **Rollback:** disable the
    export sink / retention rule.
16. **SC/MP — data region & encryption:** confirm the CUI OU's **data-region** policy and, where the
    workload requires and the edition supports it, **client-side/default encryption** — **verify
    Assured Controls / encryption availability in your tenant**; if unavailable, record a **POA&M** item
    rather than asserting the control.
17. **CM — app control:** restrict Marketplace/third-party app and API access for the boundary OU to an
    allow-list. **Rollback:** restore prior app-access setting.
18. Record every configured value and its **evidence pointer** in `NIST 800-171 – Control Map – Org`.

## Stage 4 — Pilot (`CUI – Pilot – Org`)

19. Apply the enforcing variants (DLP monitor→warn, CAA, sharing restriction, 2SV) to the **pilot group
    only**.
20. Run the validation suite (see 05-testing) against the pilot; confirm legitimate work is not blocked
    and controls behave as designed.
21. **Gate 3 (Pilot pass):** All pilot validations pass and no legitimate-workflow breakage. **Fail** →
    tune the rule (e.g. DLP detector, sharing exception) and re-pilot; **do not expand on a failed
    pilot.** Rollback the pilot changes if unrecoverable.

## Stage 5 — Validate & evidence

22. **Collect evidence** across the boundary OU:
    ```
    python collect-evidence.py --ou "/CUI – Boundary – Org" --package "Evidence – CUI Boundary – 2026-07-06"
    ```
    This exports the **configuration state** (policies/settings, read-only) and the **operational
    evidence** (audit-log extracts, read-only) into the named package, indexed to the control map.
23. **Generate the SSP + POA&M drafts** from the completed control map:
    ```
    python generate-ssp-poam.py --control-map control-map.csv --out-ssp "SSP – CUI Boundary – Org.md" --out-poam "POA&M – CUI Boundary – Org.csv"
    ```
    The SSP gets one implementation statement per requirement; the POA&M gets one row per
    `partial`/`not-configured`/`verify-edition` requirement with owner + milestone placeholders. **A
    human compliance owner reviews, corrects, and owns these — the tool drafts, it does not attest.**
24. **Gate 4 (Assessment-ready):** every in-scope requirement is `configured` **and** evidenced, **or**
    tracked on the POA&M with an owner and milestone; the boundary-exposure check is clean; SSP and POA&M
    are complete and reviewed by the compliance owner. **This gate is readiness — not a certification.**

## Stage 6 — Expand & sustain

25. Roll the enforcing controls from the pilot to the full **`CUI – Boundary – Org`** OU under the
    change window, with rollback ready.
26. Schedule **continuous monitoring**: re-run `assess-nist-controls.py` and `cui-boundary-check.py` on a
    cadence, refresh the evidence package before the assessment window, and keep the POA&M current.
27. **Hand off to the C3PAO/compliance team.** The assessment, the scoring submission to SPRS, and the
    certification decision are **theirs** — this solution's responsibility ends at a reviewed,
    evidenced, assessment-ready posture.

> **Rollback summary.** Each high-impact control (sharing, CAA, 2SV, DLP, log export, encryption) has a
> single documented prior value restorable from the control map. Because everything is applied to the
> **OU/pilot group** first, a rollback is scoped to the boundary and never touches the wider tenant.
