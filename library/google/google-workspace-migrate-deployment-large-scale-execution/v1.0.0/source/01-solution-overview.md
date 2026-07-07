# Solution Overview

## What this is

This solution is the **deployment and large-scale execution playbook** for **Google Workspace
Migrate (GWSMigrate)** — Google's own on-premises platform for moving enterprise volumes of files
and mail from **Microsoft 365** (SharePoint Online, OneDrive for Business, Exchange Online) into
**Google Workspace** (Drive, Shared Drives, Gmail). It covers everything an enterprise migration
team must own to run the tool at scale: designing and sizing the **node/database platform**, wiring
the **Microsoft 365 and Google connections**, building **mappings and bridges**, sequencing
**throttled migration waves**, and **validating** the results.

It is a **tool playbook**, not a strategy paper. It gives you the architecture, prerequisites,
setup order, mapping and wave design, throttling levers, and validation gates you need to run
Google Workspace Migrate to implement. Because the tool's console changes across releases, the
**deep console internals, exact screen labels, licensing, and support boundaries are deferred to
Google's own Google Workspace Migrate documentation** — where a step depends on version-specific
behavior it is flagged **"verify for your version."** The *procedure, sequencing, and design* are
given here; the *button-by-button console detail* you confirm against Google's current docs.

### Where it sits among the migration solutions
- **The tool-agnostic program/strategy playbook** owns the *decision* of how to migrate (waves,
  coexistence, cutover strategy, org change) independent of tool choice. This solution assumes that
  decision is made and executes it on Google's native tool.
- **The third-party tool playbooks** (BitTitan MigrationWiz, CloudM Migrate, and the Google
  Workspace Migration for Microsoft Exchange / GWMME desktop tool) cover *those* tools. This
  solution is specifically for **Google Workspace Migrate**, the server-based platform Google
  provides for **large-scale file and mail** moves.
- Use Google Workspace Migrate when the dataset is large enough (typically SharePoint/OneDrive at
  scale plus mail) to justify standing up node infrastructure and running parallelized, throttled
  waves under central control.

## How it works (reference architecture)

Google Workspace Migrate is a **self-hosted platform** the organization runs on Windows Server
hosts inside its own network. Its logical parts:

- **Platform node (management node)** — runs the management service, the web console the migration
  team drives, and the encrypted **platform database** that holds project state, mappings, scan
  results, and run history. Named here **`GWSM Platform Node – Migration – Prod`**.
- **Worker (data) nodes** — the horsepower. Each worker node runs the scan and transfer work in
  parallel; you add nodes to increase throughput. Named **`GWSM Worker Node – Migration – NN`**
  (e.g. `01`, `02`).
- **Connections** — credentialed links to each side: a **Microsoft 365 connection** (app
  registration in Microsoft Entra ID with Graph/SharePoint scopes) named
  `Connection – Microsoft 365 – Source`, and a **Google connection** (a Google Cloud project + a
  service account with domain-wide delegation) named `Connection – Google Workspace – Target`.
- **Mappings** — how a **source object maps to a target object**: user → user, OneDrive → My Drive,
  SharePoint site/library → Shared Drive, mailbox → Gmail. Built from a **mapping CSV** the team
  authors and imports. Named per scope, e.g. `Mapping – Finance OneDrive – Pilot`.
- **Bridges** — the connective identity mapping that resolves **source identities to target
  identities** (and permissions) so ownership and sharing survive the move. Named
  `Bridge – Identity – Corp`.
- **Scans then migrations** — you **scan** first (read-only discovery of what exists and how big),
  review the scan, then run a **migration** for a defined scope. Every run is a **wave**.

The team drives all of this from the platform node's console; the **Python tools in this solution**
work *alongside* it against the **Google Workspace Admin SDK and Microsoft Graph** to size nodes,
generate the mapping/connection artifacts the tool consumes, plan throttled waves, and validate the
target after each wave — the parts that are scriptable outside the tool's own console.

### The wave model
Data moves in **waves** — a scoped batch (a set of users/sites) migrated together:

1. **Pre-stage (bulk) pass** — the large, slow copy of the bulk of the data while users still work
   on the source. Run with conservative throttling over days/nights.
2. **Delta pass(es)** — incremental re-runs that carry only what changed since the last pass.
3. **Cutover** — the final delta plus the switch of the user to the target (mail routing / user
   communication). High-impact; gated and reversible.

Waves are named `Migration Wave – <Scope> – <Stage>` (e.g. `Migration Wave – Finance – Pilot`,
`Migration Wave – Sales – Delta`).

## Deployment model

This solution follows the house model end to end, with explicit pass/fail gates and a documented
rollback for every production change:

**Assess → Design → Configure → Pilot → Validate → Expand.**

- **Assess** — inventory the source (item counts, data volume, largest mailboxes/sites, sharing
  complexity); size the node platform; confirm prerequisites.
- **Design** — node count/sizing, connection scopes, mapping strategy (OneDrive→My Drive,
  SharePoint→Shared Drive), identity bridge, wave plan and throttling budget.
- **Configure** — stand up nodes + database, create both connections, import mappings and the
  identity bridge, run a **scan**.
- **Pilot** — migrate a small named wave (`Migration Wave – Finance – Pilot`) pre-stage → delta →
  cutover, measuring throughput, error rate, and throttling behavior.
- **Validate** — item-count parity, permission/ownership fidelity, and (for mail) message-count and
  mail-flow checks against pass/fail gates.
- **Expand** — schedule production waves only after the pilot passes, tuning throttling and node
  count from the pilot's measured throughput.

## Benefits
- **Google's native large-scale tool**, run correctly: node platform sized to the dataset, waves
  parallelized and throttled so you don't trip source or target API limits.
- **Predictable, reversible rollout** — pilot-first with measured throughput and defined gates
  before any production wave; cutover is the only high-impact step and it is gated and reversible.
- **Fidelity preserved** — identity bridge and mapping design keep ownership and sharing intact;
  post-wave validation proves item-count and permission parity rather than assuming it.
- **Scriptable edges** — the five Python tools remove the manual, error-prone parts (sizing,
  artifact generation, throttling math, validation) while leaving the tool's console authoritative.

## Limitations / scope boundary
- **Tool-console internals are deferred to Google's documentation.** Exact console labels, wizard
  screens, node installer prompts, supported source/target scopes, and licensing/support terms
  change across releases — this playbook gives procedure and sequencing and flags version-specific
  behavior **"verify for your version."** Always confirm the current supported-scope matrix (what
  content types Migrate does and does not carry) in Google's docs before committing a wave plan.
- **Not a Teams/Chat data-mover.** This solution scopes **files (SharePoint/OneDrive) and mail**,
  the workloads Google Workspace Migrate is built for. Teams/Chat history and other workloads are
  out of scope here and follow their own approach.
- **Gemini or any preview target-side feature** referenced is flagged **"verify in your tenant."**
- The Python tools are **safe-by-default** (read-only or `--dry-run` until `--apply`) and never
  drive an invented tool API — they generate the CSV/JSON artifacts Migrate consumes or read the
  Admin SDK / Graph to validate; they do not fabricate a private Migrate endpoint.
