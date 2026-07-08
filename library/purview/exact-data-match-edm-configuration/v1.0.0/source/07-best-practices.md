# 7. Best Practices — Exact Data Match (EDM) in Microsoft Purview

Field-tested practices for running EDM so it stays **exact, current, and privacy-preserving**. These
complement the Implementation and Testing guides.

## Protect the plaintext and the salt — non-negotiable
- **The plaintext export never leaves the secure host.** Produce `C:\EDM\*.csv` under change control on
  an **access-controlled** machine, hash it there, and **securely delete** the plaintext once the
  upload is confirmed. Only the hashes ever go to the service.
- **Treat the salt as a secret and reuse it.** Whether you supply the salt or let the Agent generate
  one, **record it in a secret store** and use the **same salt** for every refresh — it is part of what
  makes hashes non-reversible and keeps matching consistent.
- **Never** put the salt, the plaintext, or any real record values into a script, log, ticket, or
  repository. The provided scripts deliberately **never read source data or take a salt**.

## Design the schema for exactness and performance
- **Choose a high-cardinality, stable-format field as the primary/searchable element** — an account or
  record ID, **not** a name or a low-cardinality field. The primary element is the lookup key; a poor
  choice bloats the index and weakens matching.
- **Always require supporting elements.** A primary value alone is a weak signal; requiring one or two
  supporting elements in proximity is what drives false positives toward zero. Define a **stricter,
  higher-confidence tier** (primary + two supporting) for your most sensitive actions.
- **Use configurable match deliberately.** *Ignore delimiters* for values people format
  inconsistently (SSNs, account numbers); *ignore case* for names/emails. Match the option to how the
  data actually appears in documents.
- **Keep the schema lean.** Only include the fields you actually match on or corroborate with; respect
  the current field-count limit. **(Verify current field / row / file-size limits on Microsoft
  Learn — they have increased over time.)**

## Refresh the data — a stale EDM data store silently fails
- **EDM matching decays as the source data drifts.** New records won't match and removed records keep
  matching until you refresh. Schedule a **re-hash + re-upload** (`EdmUploadAgent.exe /UploadData`) on
  a cadence that matches how fast the data changes (often nightly or weekly).
- **Automate the refresh on the secure host** — a scheduled task that regenerates the export, hashes
  with the **stored salt**, uploads, and securely deletes the plaintext. Alert on failures; a silently
  failed refresh is invisible until matching quality drops.
- **Verify each refresh took effect** (Test D2/D3): a newly-added value now matches; a removed value no
  longer does.

## Simulate before you enforce — always
- **Never** switch the consuming DLP policy straight to enforce. Run `DLP-EDM-CustomerRecords-Sim` in
  **simulation** first, confirm it matches real data and ignores look-alikes, then enforce to the
  **pilot ring**, then expand.
- Treat **simulation mode as your permanent safety switch** — any enforced policy returns to simulation
  in one setting, instantly removing enforcement with no data change.

## Use EDM where pattern SITs over-fire — not everywhere
- EDM's payoff is highest for categories that **pattern SITs match too loosely** (account numbers,
  member IDs, customer PII) where you have an authoritative source table. For genuinely
  pattern-defined data with good built-in detectors, a built-in/custom SIT may be simpler.
- **Combine EDM with sensitivity labels** in DLP rules when you want protection to key on **labeled +
  exactly-matched** content — the strongest, most precise tier.
- **Reuse one EDM data store across policies** (DLP, auto-labeling, retention, Communication
  Compliance) rather than maintaining several near-duplicate sources.

## Operations & governance
- **Give the data store an owner and a refresh SLA** (R8). Match volume without a current data store is
  not a reliable control.
- **Version and document** each schema (fields, primary/supporting, configurable match, confidence,
  owner) and each refresh, so changes are traceable.
- **Least privilege and separation of duties.** Keep **authoring** (schema/SIT), **uploading**
  (`EDM_DataUploaders`), and **alert triage** as distinct roles where possible.
- **Confirm the correct cloud build** for Government tenants (GCC/GCC High/DoD) — a Commercial Upload
  Agent will not work in a sovereign cloud.

## Stay inside the boundary
- **Verify licensing/tenant, limits, and Agent switches** before relying on any capability — plans,
  portal paths, schema limits, and `EdmUploadAgent.exe` switches evolve; run `EdmUploadAgent.exe /?`
  and check Microsoft Learn rather than assuming.
- EDM is **one control**, not a guarantee — it matches content it can read and classify; combine with
  labels, encryption, and insider-risk where the risk warrants.
- **Which records are lawful to load, their minimisation, and their retention** are
  **privacy/compliance/legal determinations** — you provide the technical method and the evidence; they
  own the decision.
