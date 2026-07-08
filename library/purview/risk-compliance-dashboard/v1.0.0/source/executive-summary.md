# Executive Summary — Risk & Compliance Dashboard (Microsoft Purview)

Risk and compliance signals in Microsoft Purview are **scattered** across eight separate surfaces —
Compliance Manager, Data Loss Prevention, sensitivity labels, retention & records, Insider Risk,
Communication Compliance, Audit, and Data Security Posture Management. A leader who wants to answer "how
is our compliance posture?" has to open eight cards and stitch the picture together by hand. Left that
way, gaps hide, trends are invisible, and audit questions take days.

This solution delivers a **consolidated risk & compliance dashboard**: it **reads** each Purview signal
that exposes a reliable public interface (via **Security & Compliance PowerShell** and **Microsoft
Graph**), **captures** the ones that don't (via named owners, honestly flagged), and **renders** them in
**one view** with red/amber/green status and volume trend — collected, validated against the portal, and
refreshed on a schedule. It is a complete, **deploy-it-today** package written for an administrator with
no prior Purview-reporting experience, and it stays **read-only** by default.

## What you get
- A plain-language **Solution Overview** of the consolidated-dashboard model, the eight signals, and how
  live reads and owner-captured figures are kept honestly separate.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite (the category
  Purview requirements — compliance licensing, least-privilege roles, S&C PowerShell + Graph toolchain,
  stakeholders, pilot — are referenced, not repeated).
- An **Implementation Guide** of precise, ordered **S&C PowerShell + Graph + Purview portal** steps:
  discover signals, author the config (tiles, RAG thresholds, cadence), pilot collection and rendering
  **read-only**, reconcile against the portal, then schedule and distribute — each artifact named, with
  pass/fail gates and rollback.
- Five **PowerShell scripts** for signal discovery, safe configuration (`-WhatIf`/`-Commit`), the
  reconciliation validation, the consolidated dashboard generator (HTML + CSV with RAG and source
  badges), and a scope/health helper that checks role separation.
- **Testing** and **Troubleshooting** guides for a confident rollout.

## What this delivers
One view of compliance and data risk across Microsoft Purview — configured, piloted read-only, reconciled
against the source, and refreshed on a schedule — that a compliance lead, CISO, or auditor can trust.

## The deployment model
**Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand** — assess what's licensed and
readable, design the tiles and thresholds, configure collection and rendering, pilot read-only, validate
the numbers, then schedule and distribute.

## An honest note
This is a **reporting layer, not a control** — it reflects posture; it does not enforce policy or make
**regulatory, records, or legal determinations**, which remain with the governance functions. Several
signals require **E5 / E5 Compliance**, and a few (Compliance Manager score, Insider Risk / Communication
Compliance detail, DSPM) have **no reliable public read** — those are **owner-captured** and flagged
**"verify your licensing/tenant."** The HR-sensitive feeds are shown as **aggregate counts only**, with
strict **role separation**.

## Outcome
A consolidated, honest, privacy-respecting risk & compliance dashboard across Microsoft Purview signals —
validated against the portal and refreshed on a schedule — so posture is visible, trends are trackable,
and the capability is defensible.
