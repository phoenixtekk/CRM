# Requirements — Enablement Kit: Microsoft Defender for Endpoint

These are the **solution-specific** prerequisites for running the MDE enablement enablement kit. The
**category baseline** — an active Microsoft 365 / Entra tenant, Defender licensing in general,
least-privilege admin roles, onboarding reach, network access to Defender endpoints, a pilot ring, a
workspace where required, and response governance — is covered once in
**`global-requirements-defender.md`** (**G1–G8**). Read that first; the items below layer on top of
it and are not repeated here.

Each requirement is stated as **Description / Why required / How to verify / How to implement if
missing**.

---

## R1. Defender for Endpoint onboarded, with devices reporting

- **Description:** MDE is provisioned and a meaningful set of devices is **onboarded and reporting**
  (health = active), so incidents, timelines, and endpoint tables have real content.
- **Why required:** Every lab investigates or hunts **real device telemetry**. With no onboarded
  devices there are no timelines, no ASR events, no hunting data.
- **How to verify:** `security.microsoft.com → Assets → Devices` lists active devices; run
  `WSMDE-Discovery.ps1`, which reports device count and endpoint-table freshness.
- **How to implement if missing:** Onboard devices first — the **MDE onboarding accelerator** catalog
  solution. This enablement kit uses an onboarded MDE and does not perform onboarding.

## R2. MDE plan appropriate to the labs (P1 vs P2)

- **Description:** The Defender for Endpoint plan that covers the features in scope. **EDR, advanced
  hunting, Live Response, and custom detections are Plan 2 capabilities**; Plan 1 is
  prevention-focused. *Verify current plan-to-feature mapping in your tenant.*
- **Why required:** The investigation, hunting, Live Response, and detection labs depend on **P2**
  features. On P1 those labs cannot run in full.
- **How to verify:** Confirm the licensed plan (admin center billing / the Defender portal); confirm
  **Advanced hunting**, **Live Response**, and **Custom detection rules** are present.
- **How to implement if missing:** Assign Defender for Endpoint **Plan 2** (often bundled in M365 E5
  / E5 Security) to run the full enablement kit. On P1, run the prevention/ASR labs and defer the P2-only
  labs. *Verify licensing.*

## R3. A pilot lab device group

- **Description:** A small **device group** — `Grp-MDE-LabDevices-Pilot` — of non-critical devices to
  use for the Live Response and ASR-audit labs, so hands-on practice never touches a critical
  production endpoint.
- **Why required:** Live Response connects to a real device and ASR audit generates events. Practising
  on a dedicated, non-critical lab device is the safe way (category **G6**).
- **How to verify:** The device group exists in the Defender portal (or Intune) with the intended lab
  devices; those devices are onboarded and healthy.
- **How to implement if missing:** Create `Grp-MDE-LabDevices-Pilot` and add a couple of non-critical,
  onboarded test devices. Do **not** use executives’ or production-critical machines for the labs.

## R4. Roles: read/hunt for learners, response rights for the instructor

- **Description:** Learners hold a **read/hunt** role (**Security Reader** with hunting, or **Security
  Operator**). The instructor holds the rights needed for the gated demos — **Live Response**
  permission and the ability to create custom detection rules (**Security Administrator** or the
  granular equivalent, with Live Response enabled in **Advanced features**).
- **Why required:** Labs run at **least privilege** — read and hunt. Only the Live Response demo and
  the detection-authoring capstone need elevation, and only for the instructor.
- **How to verify:** Defender **Permissions & roles** (and Entra **Roles and administrators**) show
  the split; **Settings → Endpoints → Advanced features → Live Response** is enabled.
- **How to implement if missing:** Assign read/hunt roles to the cohort (prefer **PIM-eligible** for
  elevated roles where Entra ID P2 is available — *verify licensing*); enable Live Response and grant
  the instructor the response role.

## R5. A read-only / no-production-response lab posture

- **Description:** An agreed rule that all labs are **read-only or preview-first**: Live Response uses
  **only investigative commands**, ASR lab rules run in **audit**, the capstone detection is
  **alert-only**, and **no response action** (isolate, delete, disable) is executed against
  production during the enablement kit.
- **Why required:** Learners operate against live devices. The posture must be explicit so no one
  isolates a machine or runs a destructive command "to see what happens."
- **How to verify:** The enablement kit plan states the posture; ASR lab rules are audit; the detection is
  alert-only; Live Response transcripts show only read-only commands.
- **How to implement if missing:** State it at kickoff; route any real finding to the SOC’s normal
  incident process (category **G8**). Response actions are **taught and gated**, not performed in class.

## R6. The PowerShell helper toolchain

- **Description:** A workstation with **Microsoft.Graph** (security modules), signed in with an
  MFA-capable account holding at least read/hunt scopes; plus portal access to Advanced hunting, the
  device timeline, ASR settings, and Live Response for the interactive labs.
- **Why required:** The four delivered helpers check readiness, run a chosen lab query read-only,
  score the knowledge-check, and report cohort progress.
- **How to verify:** `Get-Module Microsoft.Graph -ListAvailable` returns a version; `Connect-MgGraph`
  succeeds; Advanced hunting loads in the portal.
- **How to implement if missing:** `Install-Module Microsoft.Graph -Scope CurrentUser`; sign in. For
  Government cloud, connect with the matching environment/endpoints — *verify the correct endpoints
  for your cloud*.
