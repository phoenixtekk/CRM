# 1. Solution Overview — Print DLP (Microsoft Purview)

## What this solution is
Most data-loss controls watch the *file* — email DLP, external-sharing blocks, encryption. None of them
see a user select **Print**, send a sensitive document to a printer, and walk away with paper that leaves
the building unlogged and unrecoverable. **Microsoft Purview Endpoint Data Loss Prevention (Endpoint DLP)**
closes that path by watching the *print activity* on an **onboarded device**: when a document whose content
matches your **sensitive information types** (or carries a sensitive **sensitivity label**) is sent to a
printer, the policy can **audit** the print, **warn with a policy tip and allow-with-justification**, or
**block** it — and can distinguish **corporate/allowed printers** from **local, network, or universal
(print-to-PDF/XPS)** printing.

This solution is a repeatable, evidence-driven way to configure the **Print** restriction for sensitive
content on endpoints using only the **Microsoft Purview portal**, **Security & Compliance PowerShell**
(`Connect-IPPSSession`), and **Microsoft Graph** — no third-party agent. Its defining discipline is that
**every restriction is built and proven in SIMULATION / audit mode first** (Microsoft's built-in test mode
that records what *would* have been restricted against real device activity, with zero user impact), tuned
for a low false-positive rate, and only then moved to enforcement.

> **Scope boundary.** This solution delivers the **technical method and evidence** for restricting printing
> of sensitive content on endpoints. *Which* data is regulated, *which* classifiers or labels legally apply,
> and *what* the enforced action must be for a given data category are **business, compliance, privacy, and
> legal determinations** — deferred to those functions. The solution configures and proves the control; it
> does not make the policy decision.

## Why this matters
- **Printing is the file controls' blind spot.** A document can be encrypted, un-shareable, and blocked from
  email, yet a user opens it and prints it — and none of the file-level controls ever see it. Paper has no
  audit trail, no revocation, and no DLP at the mail gateway. Endpoint DLP watches the *print activity*, not
  just the file.
- **Endpoint DLP is licensing- and onboarding-dependent.** The Print restriction requires the right plan
  (typically **Microsoft 365 E5** / the **E5 Compliance** add-on) and devices **onboarded** to Purview
  (shared with Microsoft Defender for Endpoint onboarding). A Devices-location policy is inert until
  onboarding is complete — **verify your licensing/tenant**.
- **Print controls are OS- and printer-dependent.** Print restriction is most complete on **onboarded
  Windows 10/11** devices; **macOS** print support and specific behaviours differ and evolve — this solution
  flags "verify your licensing/tenant" rather than asserting availability. **Printer groups** (corporate vs
  network vs local vs universal/PDF) let you allow sanctioned printing while restricting the rest.
- **Enforced-first is the classic failure.** Blocking printing straight away breaks legitimate work — a
  clerk printing a routine form, a nurse printing a chart at the ward printer — floods the help desk, and
  gets the policy disabled. Audit/simulation first, tuned, is the difference between a control that survives
  and one that is turned off.

## How it works
1. **Sensitive information types (SITs), classifiers, and sensitivity labels** define *what* content is
   sensitive. Endpoint DLP matches the content of the document being printed against built-in SITs
   (credit card, national ID, health identifiers, etc.), **custom SITs**, **Exact Data Match (EDM)** SITs,
   **trainable classifiers**, or the presence of a **sensitivity label** on the item.
2. **A DLP policy scoped to the Devices (Endpoint) location** binds those detectors to the **Print**
   endpoint activity under *"Audit or restrict activities on devices."* The action per activity is **Audit**,
   **Block with override**, or **Block**, and can differentiate **printer types** using **printer groups**.
3. **Printer groups** (defined once in **Endpoint DLP settings**) let you treat classes of printers
   differently — e.g. allow printing sensitive content to a locked-down **corporate** printer group while
   auditing or blocking **network**, **local (USB/directly attached)**, and **universal/print-to-PDF/XPS**
   printing.
4. **Simulation / audit mode** runs the policy against live device activity and records what *would* have
   been restricted — with or without policy tips shown — so you see the true volume and false positives
   **before** any enforcement. Every restriction in this solution starts here.
5. **Tuning** reduces false positives using confidence levels, instance thresholds, supporting keywords,
   EDM, label-based conditions, and **printer-group / app exceptions**, measured against the simulation
   results.
6. **Enforcement** turns the tuned restriction on (tip / allow-with-justification / block) in a limited
   ring, then expands.
7. **Incident/alert handling** — restricted print activities raise **alerts** in the Purview portal and flow
   to **Activity Explorer**; this solution wires the triage, severity, and response workflow so matches are
   actually acted on.

## The activity this solution controls (and what it stops)
- **Print →** sending a document that contains sensitive content to any printer. Endpoint DLP can **audit**
  the print, **warn-and-justify**, or **block** it, and can apply **different actions per printer group** —
  the core lever for allowing sanctioned corporate printing while restricting network, local, and
  print-to-PDF/XPS output. **Availability of specific print behaviours and macOS support varies — verify your
  licensing/tenant.**

## A complementary lever: sensitivity-label protection (RMS usage rights)
Where content carries a **sensitivity label with encryption**, the label's **usage rights** independently
govern printing: removing the **PRINT** usage right from a permission set prevents printing protected Office
files regardless of endpoint. This solution's primary path is **Endpoint DLP** (which covers any content,
labelled or not, and adds printer-group differentiation), but the label-usage-right lever is documented here
as a complementary control where labels are already in use — verify your labeling design with the
information-protection owner.

## The simulate→enforce journey (the core discipline)
> Confirm SITs/labels → define **printer groups** (corporate/allowed vs network/local/universal) → build the
> Endpoint DLP policy with the **Print** activity in **SIMULATION / audit** (no user impact) → measure volume
> and false positives in **Activity Explorer / DLP alerts** → **tune** (confidence, instance count, keywords,
> EDM, label condition, printer-group exceptions) → re-simulate until false positives are acceptable → enable
> with **policy tips + allow-override/justification** in a **pilot ring** → validate → expand to **enforce
> (block)** across the intended scope → operate (triage alerts, review overrides, re-tune).

## What you can control
- Which **SITs/classifiers/labels** trigger the restriction, and at what **confidence** and **instance count**.
- The **action** on the Print activity (audit → tip → justify → block), and **different actions per printer
  group** — allow corporate, restrict network/local/universal.
- Which **users / devices / groups** are **included or excluded**, and the **pilot ring** enforced first.
- The **printer groups** and any **app exceptions** so sanctioned printing isn't caught.
- Whether users get **policy tips**, can **override** with justification, and what the override says.

## Limitations (be honest with buyers)
- **Endpoint DLP requires onboarded devices and the appropriate licensing** (verify your plan — endpoint DLP
  is gated behind E5 / the E5 Compliance add-on). A Devices-location policy is inert until onboarding is
  complete.
- **Print behaviours are OS- and printer-dependent and evolve.** Restriction is most complete on onboarded
  **Windows 10/11**; **macOS** print support and specific behaviours differ — this solution flags "verify
  your licensing/tenant" rather than asserting availability.
- Endpoint DLP restricts content it can **classify** (SIT / label match). Content below the
  confidence/instance threshold, or that the device agent cannot classify at the moment of the print, will
  not match. DLP is one control among several, not a guarantee — a determined user can still photograph a
  screen or retype content.
- The **enforced action for a data category is a compliance/legal decision**, not a technical default — this
  solution configures and proves the control; the determination is deferred.

## Naming convention (used in every doc and script)
Every artifact this solution creates uses `<Purpose> – <Scope> – <Stage>`, reused verbatim across the docs,
scripts, and the Purview portal. The standard set:

| Artifact | Name |
|---|---|
| Endpoint DLP policy (simulation) | `DLP – Endpoint Print – Simulation` |
| Content rule on that policy | `DLP – Endpoint Print – Rule` |
| Enforced pilot policy | `DLP – Endpoint Print – Enforce Pilot` |
| Pilot user/device ring | `DLP Pilot Ring – Stage1` |
| Corporate/allowed printer group | `Printers – Corporate – Allowed` |
| Policy-tip / override text | `DLP Notice – Print – Standard` |
| Incident/alert workflow | `DLP Alerts – Print – Operations` |
| (Optional) label restricting print | `Confidential – No-Print – Endpoint` |

## The standard deployment model
> **Assess** current endpoint exposure and classification intent → **Design** the SIT/label detectors, the
> printer groups, and the print restriction → **Configure** the Endpoint DLP policy **in simulation/audit** →
> **Pilot** (simulate → tune → enforce to a ring) → **Validate** against pass/fail gates (printing of
> sensitive content restricted, corporate printing allowed, false-positive rate low, incidents handled) →
> **Expand** to the full scope and ongoing operations. Every high-impact change is piloted in simulation
> first, with a documented rollback.
