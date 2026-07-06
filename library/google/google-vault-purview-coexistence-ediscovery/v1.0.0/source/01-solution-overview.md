# 1. Solution Overview — Vault ↔ Purview Coexistence: eDiscovery, Legal Hold & Retention

## The problem this solves
During a Microsoft-to-Google (or dual-suite) transition, your organization's electronically stored
information (ESI) lives in **two governance ecosystems at once**: **Microsoft Purview** governs the
Microsoft 365 estate (Exchange Online mailboxes, SharePoint, OneDrive, Teams), and **Google Vault**
governs the Google Workspace estate (Gmail, Drive, Chat, Meet, Groups, Calendar, Voice, Sites, and —
per recent Google updates — the Gemini app). Legal and compliance must be able to **hold, retain,
and discover across both**. The single most dangerous misconception is that a hold placed in one tool
somehow reaches the other. **It does not.** Coexistence is defensible only when holds, retention, and
discovery are *coordinated by design* across the two systems — not assumed to sync.

> **Vendor boundary.** Google Vault (`vault.google.com`), the Google Admin console
> (`admin.google.com`), and the Microsoft **Purview portal** (`purview.microsoft.com`) are authored
> click-by-click from each vendor's current public documentation. Vault's **Gemini app** hold/
> retention support and Purview's evolving **eDiscovery** experience are cited or flagged **"verify in
> your tenant."** **This solution provides the *technical* mapping of governance across the two
> ecosystems; it is not legal advice.** Whether a given retention period, hold scope, or discovery
> approach satisfies a specific regulation or legal obligation is a determination for **legal/records
> counsel** — engage them as named stakeholders (global requirement 6).

## What is governed where (during coexistence)
| Data / workload | Governed by | Preservation & discovery surface |
|---|---|---|
| Gmail, Google Chat, Google Groups, Google Voice | **Google Vault** | Vault retention rules + holds; Vault search/export |
| Google Drive files, Google Sites, Meet recordings, Calendar | **Google Vault** | Vault retention rules + holds; Vault search/export |
| Google **Gemini app** messages | **Google Vault** *(newer capability — verify in your tenant)* | Vault retention rules + litigation holds for the Gemini app |
| Exchange Online mailboxes (incl. Teams 1:1/group chat, card, meeting/call data) | **Microsoft Purview** | Retention policies/labels, Litigation Hold, eDiscovery holds |
| SharePoint sites, OneDrive accounts (incl. Teams channel files) | **Microsoft Purview** | Retention policies/labels, eDiscovery holds (Preservation Hold library) |
| Teams channel conversations | **Microsoft Purview** | Held via the Team's group mailbox + SharePoint site |

The **boundary follows the data's home**: content created and stored in Workspace is a Vault matter;
content created and stored in M365 is a Purview matter. During coexistence a *single custodian* often
has data on **both** sides (e.g. a mailbox migrating from Exchange to Gmail, or files in both OneDrive
and Drive), which is exactly why holds must be issued in parallel.

## How holds and retention map across the two ecosystems
There is **no automatic synchronization** between Vault and Purview. The mapping is operational, not
technical:

- **Legal hold → issue in parallel.** A custodian under legal hold must be placed on hold in **both**
  Vault (a hold inside a Vault **matter**) **and** Purview (an **eDiscovery hold policy** inside an
  eDiscovery **case**), for every workload where that custodian has data. One playbook, two systems,
  the same named custodians on each side.
- **Retention → align to the longer of the two.** Where the same class of record exists on both
  sides, set the retention period on each platform to the **longer** of the two schedules, so the
  stricter obligation is satisfied by default and content is not purged out from under a hold.
- **Most-restrictive-preservation-wins (within each platform).** On each side, multiple preservation
  sources can coexist and any one is enough to keep content:
  - **Vault:** a **hold** retains data **indefinitely** and **takes precedence** over default and
    custom retention rules. (Source: Google Vault Help.)
  - **Purview:** eDiscovery holds, retention policies, retention labels, **Litigation Hold**, delay
    holds, and Single Item Recovery each independently preserve content — the most restrictive wins.
    (Source: Microsoft Learn.)
- **Discovery → collect from both, reconcile in one place.** Defensible discovery searches **both**
  Vault (search + export by matter) **and** Purview (search + export by case), then reconciles the two
  export sets into a single production so nothing in the coexistence gap is missed.

## The coexistence eDiscovery model
1. **Inventory the estate** — which custodians and record classes live in Vault, in Purview, or
   (during migration) in both. This is the coverage map every hold and search works from.
2. **Name matters/cases once, reuse everywhere** — a matter/case name that is identical on both
   platforms (e.g. `Litigation – Acme v. Example – Hold`) so a custodian's Vault matter and Purview
   case are unmistakably the same legal matter.
3. **Hold in parallel** — issue the hold in Vault and in Purview for every workload the custodian
   touches; record both hold IDs against the one matter.
4. **Retain to the longer schedule** — align Vault retention rules and Purview retention policies so
   neither side purges a record the other must keep.
5. **Discover across both** — run the matched search on each side, export, and reconcile.
6. **Prove it on a pilot** — validate the whole loop (hold effective, retention applied, discovery
   returns the right data on both sides) on a small pilot before extending to all custodians.

## Benefits
- **No coexistence gap** — every custodian is held and discoverable on **both** ecosystems, so a
  transition does not create a preservation blind spot.
- **Defensible by design** — parallel holds, longer-of-two retention, and cross-system reconciliation
  are documented and repeatable, not ad hoc.
- **One playbook, two systems** — a single matter naming convention and custodian list drives both
  Vault and Purview, so legal reasons about *the matter*, not the tooling.
- **Proven before scaled** — the pilot gate confirms holds are effective and discovery returns data
  before the whole custodian population depends on it.
- **Audit-ready** — coverage/gap reporting shows exactly what is held and retained where.

## Limitations (be honest with buyers)
- **No cross-system sync.** Vault and Purview do not talk to each other; parallel administration is
  inherent to coexistence and is the work this solution operationalizes.
- **This is the technical mapping, not legal advice.** Retention *periods*, hold *triggers*, and
  what "defensible" requires for a given matter are legal/records-counsel determinations — engage
  them. This package does not interpret regulation.
- **Licensing gates capability on each side.** Vault requires a Vault-capable Workspace edition;
  Purview eDiscovery holds require an eligible license on **every held user** (frontline tiers such as
  F1/F3 cannot be the *target* of an eDiscovery hold; query-based/custodian-scoped holds require E5/
  A5/G5-class or the E5 Compliance / eDiscovery add-ons). **Verify licensing before you begin.**
- **Evolving surfaces.** Vault's Gemini-app hold/retention support and the Purview eDiscovery
  experience are changing — admin paths are flagged **"verify in your tenant"** and volatile
  specifics are deferred to the vendors' documentation, never invented.

## The deployment model
> **Assess what's governed where → Configure Vault retention/holds and map to Purview → Pilot with a
> small custodian scope → Validate holds effective / retention applied / discovery returns on both →
> Expand.** The pattern is **Assess → Configure → Pilot → Validate → Expand**, with an explicit pilot
> gate and a documented rollback for every production change.
