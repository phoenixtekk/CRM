# 1. Solution Overview — Enterprise DLP Assessment & Strategy (Microsoft Purview)

## What this solution is
Most Data Loss Prevention projects fail at the same point: a team writes DLP policies before they know
**what** sensitive data they hold, **where** it lives, or **how** it moves — then switches those policies
to enforce and drowns the business in false positives. This solution inverts that order. It delivers a
**DLP posture assessment**, a **sensitive-data discovery** exercise, and a **prioritized DLP rollout
strategy** in **Microsoft Purview** — so you know exactly what to protect, in what order, and with what
policy, **before** you write a single enforcing rule.

It uses only the **Microsoft Purview portal** (purview.microsoft.com), **Security & Compliance PowerShell**
(`Connect-IPPSSession`), and **Microsoft Graph** — no third-party tooling. The output is not an enforced
control; it is the **evidence base and the roadmap** that makes a later enforcement project succeed: a
documented picture of current DLP posture, a data map of where sensitive information actually resides and
travels, and a ringed, simulation-first rollout plan with priorities set by real exposure — not guesswork.

> **Scope boundary.** This solution produces the **technical assessment, the discovery evidence, and the
> proposed roadmap**. *Which* data is regulated, *which* classifiers legally apply, *what* the enforced
> action must eventually be, and *which* categories are in scope are **business, compliance, privacy, and
> legal determinations** — deferred to those functions. We map the terrain and recommend the route; the
> governance owners decide the destination.

## Why this matters
- **DLP without a data map produces noise, not protection.** A policy scoped to "credit card numbers
  everywhere, block on match" with no idea where card data lives will fire on internal reference numbers,
  bury the help desk, and be disabled within a week. Discovery first is the difference.
- **Priorities should follow exposure, not opinion.** The category worth enforcing first is the one with
  the most sensitive data in the most exposed locations (externally shared sites, high-volume mail flows),
  not the one someone remembered in a meeting. This solution ranks by measured prevalence.
- **A baseline you can defend.** "We assessed our DLP posture, discovered where sensitive data resides, and
  produced a prioritized rollout plan" is a defensible compliance position. An empty DLP blade is not.
- **The classification layer you build here pays off everywhere.** The same sensitive information types and
  labels that drive the assessment later drive DLP enforcement, auto-labeling, and insider risk — get the
  discovery right once and reuse it across the Purview estate.

## How it works
1. **Posture assessment (Assess).** Enumerate what already exists: current DLP policies and their **mode**
   (enforce / simulation / disabled), sensitive information type (SIT) coverage (built-in vs custom),
   sensitivity and retention labels in play, whether **audit logging** and **Content Explorer** are
   available, and the licensing/role readiness that gates the discovery tools. Delivered read-only.
2. **Sensitive-data discovery (Assess).** Find **where sensitive data actually is**. Purview's
   **Content Explorer** (Data classification → Content explorer) shows, per SIT and per label, the actual
   files and locations across Exchange, SharePoint, OneDrive, and Teams. **Activity Explorer** shows how
   labelled/sensitive content is being **used and shared**. Where content has never been evaluated,
   **on-demand / auto-classification** can be pointed at it. The delivered data-scan tool exports Content
   Explorer results into a data map.
3. **A monitor-only simulation baseline (Configure — no user impact).** To measure *movement* (not just
   data at rest), the solution stands up **one broad DLP policy in SIMULATION mode** across all locations —
   Microsoft's built-in test mode that records what *would* match against real traffic with **zero** user
   impact. This populates real match data by SIT, location, and volume for the prioritization, and is never
   enforced.
4. **Prioritize (Design).** Combine the data map (where sensitive data rests) with the simulation matches
   (how it moves) into a **ranked exposure view** — which data categories, in which locations, at what
   volume and external-sharing exposure. That ranking is the backbone of the roadmap.
5. **Roadmap (Design).** Produce the **prioritized DLP rollout strategy**: which category to enforce first,
   in what location, with which detector and action, on which pilot ring, in what order — every step
   **simulation-first**, with pass/fail gates and rollback, ready to hand to an enforcement project.

## What "sensitive-data discovery" draws on (all Microsoft-native)
- **Content Explorer** — the current inventory of where each SIT and label is detected across workloads
  (requires the **Content Explorer List/Content Viewer** roles; **verify your licensing/tenant**).
- **Activity Explorer** — how sensitive/labelled content is used and shared over time.
- **On-demand / automatic classification** — evaluates content that classification hasn't yet reached
  (availability is plan-dependent — **verify your licensing/tenant**).
- **The monitor-only simulation DLP policy** — measures real movement of sensitive content with no
  enforcement.
- **Data Security Posture Management (DSPM)**, where licensed, aggregates much of this into a posture view —
  used as a cross-check, **verify availability in your tenant**.

## The assess→roadmap journey (the core discipline)
> Baseline current DLP **posture** → **discover** where sensitive data rests (Content Explorer) and how it
> moves (monitor-only **simulation** policy + Activity Explorer) → **rank** data categories by exposure →
> produce a **prioritized, simulation-first rollout roadmap** with per-step detector, action, ring, gate,
> and rollback → hand off to an enforcement project. **Nothing in this solution enforces anything.**

## What you can control
- Which **workloads** the discovery covers (Exchange, SharePoint, OneDrive, Teams) and which **SITs/labels**
  the data scan reports on.
- The **dwell time** the monitor-only simulation baseline runs to capture representative movement.
- The **ranking inputs** and weighting for prioritization (prevalence, external-sharing exposure, volume).
- The proposed **rollout order, rings, detectors, and actions** in the roadmap — all recommendations for
  compliance/legal to ratify.

## Limitations (be honest with buyers)
- **Discovery depth is licensing-dependent.** Content Explorer, Activity Explorer, advanced/trainable
  classifiers, on-demand classification, and DSPM are gated behind **E5 / the E5 Compliance add-on** and
  some are in **preview** — this solution flags "verify your licensing/tenant" rather than asserting
  availability. With lower plans the assessment is narrower (built-in SITs, basic reporting).
- **Discovery sees what classification can evaluate.** Strongly encrypted, unrecognized formats, or content
  never scanned may not appear; on-demand classification narrows but does not eliminate this gap.
- **This is an assessment, not an enforced control.** The monitor-only simulation policy protects nothing —
  it measures. Protection comes from the *enforcement* project this roadmap feeds.
- **The roadmap is a recommendation.** Scope, legal applicability, and enforced actions are compliance/
  privacy/legal determinations — the strategy proposes; those functions decide.

## Naming convention (used in every doc and script)
Every artifact this solution creates uses `<Purpose> – <Scope> – <Stage>`, reused verbatim across the docs,
scripts, and the Purview portal. The standard set:

| Artifact | Name |
|---|---|
| Posture baseline export | `DLP Posture – Baseline – Assessment` |
| Sensitive-data map (Content Explorer export) | `Data Discovery – Content Explorer – Assessment` |
| Monitor-only simulation policy | `DLP Baseline – All Locations – Simulation` |
| Simulation rule (monitor-all) | `Monitor All SITs – All Locations – Simulation` |
| Ranked exposure view | `Sensitive Data Map – Prioritized – Assessment` |
| Rollout roadmap deliverable | `DLP Roadmap – Prioritized – Strategy` |
| First rollout pilot ring (proposed) | `DLP Rollout Ring – Stage1` |

## The standard deployment model
> **Assess** current posture and discover where sensitive data rests and moves → **Design** the prioritized
> rollout roadmap → **Configure** the monitor-only **simulation** baseline (no user impact) → **Pilot** the
> discovery over an agreed dwell time → **Validate** the assessment against pass/fail gates (posture
> baselined, data mapped, movement measured, roadmap ranked) → **Expand** by handing the roadmap to the
> enforcement project. Every step is non-enforcing and reversible; the only Purview object created is a
> simulation policy that can be deleted with zero user impact.
