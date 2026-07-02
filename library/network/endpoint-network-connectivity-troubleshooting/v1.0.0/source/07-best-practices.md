# Best Practices

These are the habits that make network triage **repeatable** and escalation **evidence-based**. They
apply on every connectivity incident, regardless of vendor.

## 1. Always work top-down through the layers
Resolve the name first, then the route/proxy/VPN decision, then the port, then the URL. An earlier
layer failing masks everything below it, so testing out of order wastes time and produces misleading
results. The symptom tree in the Playbook exists precisely to keep you in order.

## 2. Change one thing, test one thing, prove one layer
Never restart the app, reboot, flush DNS, and toggle the VPN all at once. If it then works you have
learned nothing and cannot document a root cause. Isolate a single variable, re-test the single
matching gate, and record whether it changed the result.

## 3. Always keep a control
A control endpoint, a control DNS resolver (a public one), a control host on the same port, and a
control URL of a benign category. Every verdict in this method is a *comparison*: "the target fails
but the control passes." Without a control you can prove nothing.

## 4. Prove the layer before you escalate
Do not send "the app is broken" to the network team. Send: "name resolves to `203.0.113.10`; TCP to
`203.0.113.10:443` times out; the same port to a control host succeeds — this is an upstream IP:port
block." An evidence-backed ticket is actioned in minutes; a vague one bounces for days.

## 5. Capture evidence as you go, not after
Save the Discovery output at the start and the exact command output for the first failing gate. Screen
memory fades and endpoints get rebooted; a saved JSON/text artifact is the durable proof. The scripts
write to files for this reason.

## 6. Distinguish a drop from a refusal
A **timeout** (no response) points upstream — a firewall silently dropping traffic. A **refusal**
(fast RST) means something answered and said no — often the service isn't listening on that port, or a
device is actively resetting. They lead to different owners; don't conflate them.

## 7. Know the intended path before judging the actual one
"Wrong proxy" and "split-tunnel gap" only mean something relative to design intent. Confirm from R4
whether each target is *supposed* to go direct, via proxy, or via VPN before you call the actual
behavior wrong.

## 8. Prefer safe, local, reversible remediation — and only for local causes
Flushing the DNS cache, resetting the route cache, or clearing a stale local proxy are safe and
reversible, and only make sense when the block is *local to the endpoint*. Never "fix" a proxy, VPN,
or firewall from the endpoint — those are escalated with evidence to their owners. Keep remediation in
`-WhatIf` until you have confirmed the cause is local.

## 9. Defer vendor console internals to the vendor
This toolkit proves *which layer* blocks the traffic. Reading a proxy's own logs, adjusting a URL
category, or editing a VPN split-tunnel profile happens in that vendor's console — follow that
vendor's official documentation and your own console for the specific control.

## 10. Pilot before fleet-wide validation
When rolling out a new app or a connectivity change, scope a small pilot group first
(`NETDX-Set-ScopeTargeting.ps1`), validate the full target list against it, and only then expand.
Catching a layer-4 firewall gap on five pilot devices is far cheaper than on the whole fleet.

## 11. Build and reuse a target library
Keep the R3 target CSVs per application. The next time that app "breaks," you re-run Validation against
a known-good target list in seconds instead of rediscovering what it should reach. Treat these lists
as reusable assets.

## 12. Re-baseline after any network change
Proxy, PAC, VPN, and firewall changes drift the endpoint posture. After any such change, re-run
Discovery to capture the new baseline so your next incident compares against reality, not a stale
snapshot.
