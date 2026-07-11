# 6 LinkedIn posts — ready to publish (repurposed from real answers)

Copy/paste, tweak voice to yours. Replace `<LINK>` with the matching product URL + `?src=linkedin`, or
`workplace.phoenixtekk.com/create?src=linkedin`. Keep line breaks — LinkedIn rewards white space.

---

## 1 — "Saw in the wild": cloud sync JoinNotFound
Your Entra Connect cloud sync is "Healthy."

Your users still aren't showing up in Entra.

Every one of them logs the same thing: **User was skipped — JoinNotFound.**

Here's the part nobody tells you: that's usually not a per-user bug. It's a **stale watermark.**

If the job was quarantined earlier (or your domain verified late), cloud sync already "saw" those users and parked them. Now that it's healthy, they're no longer "newly discovered" — so it skips them all.

And **Clear quarantine won't fix it.** You need **Restart sync** (full — resets watermarks + escrows), then re-run provision-on-demand. It flips from "skipped" to "Create."

Full runbook + the 5 diagnostic scripts: <LINK>

#Entra #Intune #Microsoft365 #IdentityManagement

---

## 2 — "You're doing it wrong": source anchor
If your Entra Connect source anchor is still **objectGUID**, your next domain consolidation will orphan every account you migrate.

objectGUID is **regenerated** when an object moves to a new domain. So every migrated user looks *brand new* to Entra → duplicate cloud accounts, lost mailboxes, lost licenses.

**mS-DS-ConsistencyGuid** is preserved across the move. Switch to it *before* you migrate, let your migration tool stamp it, and Entra hard-matches every user back to the right object.

The switch is safe for existing users (the anchor value is preserved — no re-sync). Two things to check first: the connector account's write permission, and that the attribute is empty on all in-scope objects.

Full step-by-step (incl. Quest ODM): <LINK>

#Entra #ActiveDirectory #AzureAD #Migration

---

## 3 — Behind-the-build (proof of "built in 1 day")
Someone posted a GlobalProtect PLAP question in a forum this week: Autopilot Hybrid Join, VPN before logon, and the registration app kept failing with an "unzipping" error.

That "unzipping" error is Intune Win32 **0x87D30067** — the IME can't extract the .intunewin (usually AV locking the IMECache, or a bad re-wrap). And the reboot inside their script was corrupting the ESP — the fix is `return 3010` and let ESP own the reboot.

By the end of the day it was a full runbook: deployment, registration, reboot sequencing, and a log-capture tool for the test window.

That's the model: real problem in the morning → click-by-click runbook by the afternoon.

Describe yours: workplace.phoenixtekk.com/create?src=linkedin

#Intune #Autopilot #GlobalProtect #EUC

---

## 4 — The pitch: engage a catalog, not a headcount
A senior Modern Workplace engineer: 6–12 weeks to hire, $150K–$220K/yr loaded.

A day-rate consultant: $1,500–$3,000/day, open meter.

Or: a catalog of **400+ ready-to-deploy** Microsoft & cloud runbooks — Intune, Entra, Purview, Defender, Networking — each one click-by-click documentation + tested scripts, one flat price, unlimited devices. Commercial and GCC High.

Same outcomes. Same day. No ramp, no recruiting, no bench.

Browse it: workplace.phoenixtekk.com?src=linkedin

#ModernWorkplace #MSP #Microsoft365 #ITLeadership

---

## 5 — Myth: pre-logon VPN
"Users can just connect the VPN after they log in."

Not your new remote hire on a fresh laptop with no cached credentials. Not the user whose password expired off-network. Both need the domain **before** the Windows logon completes.

That's what pre-logon VPN is for — Cisco Start Before Logon (PLAP) or Always On VPN device tunnel — the tunnel comes up at the logon screen, before the user authenticates.

If you moved off Always On VPN after a security event and went user-initiated, this is the gap you just opened. Here's how to close it.

Runbooks for both approaches: <LINK>

#VPN #Intune #ZeroTrust #EUC

---

## 6 — Carousel outline: "5 steps to safely switch your Entra source anchor"
(Build as a 6-slide carousel in your brand template.)
- **Slide 1 (cover):** "Switching your Entra Connect source anchor without orphaning a single account."
- **Slide 2:** Why objectGUID breaks on migration (regenerated → new object → duplicates).
- **Slide 3:** Why mS-DS-ConsistencyGuid is preserved (+ your migration tool stamps it).
- **Slide 4:** The 2 preconditions — connector write permission + attribute empty in scope.
- **Slide 5:** The switch (Entra Connect wizard → Configure Source Anchor) — seamless for existing users.
- **Slide 6 (CTA):** "Full runbook + scripts → <LINK>."

#Entra #ActiveDirectory #Migration #AzureAD
