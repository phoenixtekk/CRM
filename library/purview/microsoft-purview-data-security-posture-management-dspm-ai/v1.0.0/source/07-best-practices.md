# 7. Best Practices — Microsoft Purview Data Security Posture Management (DSPM & DSPM for AI)

- **Reduce oversharing *before* you turn on Copilot.** The safest AI adoption is one where the data was
  already tidied. Use DSPM for AI's pre-adoption posture to shrink broad access first — a file Copilot
  can't reach can't be surfaced by a prompt.
- **Always pilot in simulation/test.** Auto-labeling runs in **simulation** and DLP runs in **test**
  precisely so you can see impact before anyone is affected. `-WhatIf` is the default on the reduction
  helper for the same reason — read every intended action before you `-Commit`, and enforce only after
  the gate passes.
- **Work the recommendation queue; don't admire the dashboard.** DSPM's value is realized only when
  recommendations move to done. Snapshot the queue, agree the action set with stakeholders, act, then
  re-measure — the trend line, not the screenshot, is the outcome.
- **Fix the biggest exposure first.** Prioritize broadly-shared sites holding **unlabeled sensitive**
  content — that intersection is where AI exposure is highest. Start there, not with the easiest tickets.
- **Let compliance/records/privacy/legal own the determination.** You provide the technical method and
  the evidence; *what* must be restricted or retained and *what* AI-exposure level is acceptable are
  their calls. Capture the agreed set before configuring.
- **Verify availability, never assume it.** DSPM and DSPM for AI are evolving and licensing-dependent.
  When a blade, report, or one-click policy isn't where this guide says, confirm it in your tenant and
  use the closest current equivalent — don't force a path that isn't there.
- **Keep auditing on.** DSPM-for-AI prompt/response reporting is only as complete as the unified audit
  log feeding it. If AI reports look empty, check auditing and confirm AI usage has actually occurred.
- **Confirm the Copilot/AI DLP location in your portal.** The DLP-for-AI location name evolves; the
  reduction helper parameterizes it rather than assuming it. Verify the exact location before you enforce
  a DLP-for-AI policy so it scopes where you intend.
- **Labels and DLP are the levers — keep them healthy.** DSPM measures and recommends, but acts through
  your label taxonomy and DLP. A thin taxonomy caps how much posture you can improve; invest there.
- **Preserve separation of duties.** Read posture with a least-privilege role; keep configuration rights
  separate. Reserve Global/Compliance Administrator for the initial enablement only.
- **Make posture review recurring.** Data and AI usage drift. Schedule the read-only `ScopeConfig →
  Discovery → AIExposure → Tracker` chain under `DSPM Posture Review – Estate – Recurring` so the estate
  stays measured, not measured once.
- **Keep an easy rollback.** Every enforced policy should be one change from returning to simulation/test.
  Keep the tracker export as the before-state so any enforcement can be safely reverted.
