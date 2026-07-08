# 1. Solution Overview — Document Fingerprinting (Microsoft Purview)

## What this solution is
Most organizations run their sensitive business on **standard forms and templates** — a patent
application form, an employee onboarding packet, a customer intake sheet, a government form, a
contract template, a benefits enrollment form. These documents follow the *same layout and boilerplate
text* every time, only the filled-in values change. That structural sameness is exactly what makes them
detectable — and exactly what generic pattern detectors miss.

**Microsoft Purview Document Fingerprinting** converts a standard form into a **sensitive information
type (SIT)** built from the form's own text. Purview reads the blank/representative template, builds a
compact **fingerprint** of its word pattern, and thereafter recognizes *any document that carries that
same pattern* — regardless of the data typed into it. You then wire that fingerprint SIT into **Data
Loss Prevention (DLP)** so email, SharePoint, OneDrive, and Teams movement of those forms is detected
and controlled.

This solution is a repeatable, evidence-driven way to fingerprint your standard forms and wire them to
DLP using only the **Microsoft Purview portal** and **Security & Compliance PowerShell**
(`Connect-IPPSSession`) — no third-party tooling. Its defining discipline, like every solution in this
category, is that **the DLP policy carrying the fingerprint is built and proven in SIMULATION mode
first** (Microsoft's built-in test mode that evaluates a policy against real traffic and shows what
*would* have matched, with zero user impact), tuned, and only then enforced.

> **Scope boundary.** This solution delivers the **technical method and evidence** for fingerprinting
> forms and detecting them with DLP. *Which* forms are sensitive, *which* legal/regulatory obligation
> applies to a given form, and *what* the enforced action must be are **business, compliance, privacy,
> and legal determinations** — deferred to those functions. The solution helps you build and prove the
> control; it does not make the policy decision.

## Why this matters
- **Standard forms leak silently.** A completed intake form emailed to the wrong recipient, a blank
  template with a filled record shared "anyone with the link," a benefits form dropped in a Teams chat
  — none of these necessarily contain a neat credit-card or SSN pattern, so a generic SIT never fires.
  The *form itself* is the sensitive artifact, and fingerprinting is how you detect it.
- **Fingerprinting beats keyword/regex for structured documents.** A pattern detector matches a string;
  a fingerprint matches the *document's word structure*. For a form whose boilerplate is identical every
  time, a fingerprint gives high-precision detection that keyword rules can't match without heavy tuning.
- **It reuses the DLP you already run.** A fingerprint is just another SIT — once created it plugs into
  the same DLP policies, simulation mode, policy tips, and Activity Explorer evidence trail as the rest
  of your DLP estate. No new control plane to operate.
- **Precision protects adoption.** Because a fingerprint keys off the whole form pattern rather than a
  single number, it produces fewer false positives on unrelated content — which is what keeps a DLP
  control trusted rather than switched off.

## How Document Fingerprinting works
1. **Pick the source template.** Choose a **blank or representative** copy of the form — text-based
   (`.docx`, `.dotx`, `.pdf`, `.txt`, and similar supported formats). The template should contain the
   form's boilerplate text; the fingerprint is built from that text, not from filled-in values.
2. **Create the fingerprint.** Purview reads the file and computes a fingerprint — a small,
   non-reversible representation of the document's word pattern. It does **not** store the document
   itself. In PowerShell this is `New-DlpFingerprint`; in the portal it is **Data classification →
   Classifiers → Sensitive info types → Create → Document fingerprint** (verify availability in your
   tenant).
3. **Wrap the fingerprint in a sensitive information type.** One or more fingerprints become a named
   **fingerprint SIT** (`New-DlpSensitiveInformationType -Fingerprints ...`). One SIT can carry several
   related form fingerprints (e.g. all HR onboarding forms).
4. **Reference the SIT in a DLP policy** exactly like any other SIT — condition *Content contains* the
   fingerprint SIT, across the chosen locations, with an action (audit / policy tip / restrict / block).
5. **Detection at runtime.** When a document whose word pattern matches the fingerprint moves through a
   covered channel, the policy matches — even though the *values* in the form differ from the template.
6. **Evidence & handling.** Matches raise DLP **alerts** and flow to **Activity Explorer**, feeding the
   same triage workflow as the rest of your DLP program.

## What a fingerprint can and cannot detect (be honest with buyers)
- **Detects:** documents that carry substantially the **same text pattern** as the fingerprinted
  template — the filled-in versions of your standard forms, forwarded copies, and re-saved variants that
  keep the boilerplate.
- **Does not reliably detect:** a form that is **only an image / scanned** (no extractable text), a
  **password-protected** file, a document that contains **only a small fragment** of the form's text,
  or a form so heavily edited that the boilerplate no longer resembles the template. Fingerprinting is a
  **text-pattern** match — no extractable text, no match.
- **Format & size limits apply** (supported file types and a maximum file size per Microsoft's
  documentation) — **verify current limits for your tenant** before fingerprinting large or unusual
  files.
- Fingerprinting is **one detection technique** among several (built-in SITs, custom SITs, EDM,
  trainable classifiers). Use it where the *form structure* is the signal; use the others where a value
  pattern or a learned category is the signal.

## Naming convention (used in every doc and script)
Every artifact this solution creates uses `<Purpose> – <Scope> – <Stage>`, reused verbatim across the
docs, scripts, and the Purview portal. The standard set:

| Artifact | Name |
|---|---|
| Fingerprint (single form) | `Onboarding Form – Fingerprint – Source` |
| Fingerprint SIT (one or more forms) | `Standard Forms – Fingerprint SIT – Classification` |
| DLP policy (simulation) | `DLP – Fingerprinted Forms – Simulation` |
| DLP rule | `Rule – Fingerprinted Forms – ContentContains` |
| Enforced pilot policy scope | `DLP – Fingerprinted Forms – Enforce Pilot` |
| Pilot user ring | `Fingerprint Pilot Ring – Stage1` |
| Policy-tip / override text | `Fingerprint Notice – Standard – AllPolicies` |
| Incident/alert workflow | `Fingerprint Alerts – Triage – Operations` |

## The standard deployment model
> **Assess** which forms are candidates and confirm licensing/roles → **Design** the fingerprint SIT(s)
> and the DLP policy → **Configure** the fingerprints and build the policy **in simulation** →
> **Pilot** (simulate → measure → enforce to a ring) → **Validate** against pass/fail gates (forms
> detected, false positives low, incidents handled) → **Expand** to full-scope enforcement and ongoing
> operation. Every high-impact change is piloted in simulation first, with a documented rollback. The
> DLP policy is never switched straight to enforce.
