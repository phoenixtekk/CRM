# 5. Testing Guide — Configuration Manager Cloud Management Gateway (CMG)

Run after the CMG and connection point are in place (Implementation Step 10) and again after each
expansion wave.

## Test 1 — CMG service is Ready
Do: Console → Administration → Cloud Services → Cloud Management Gateway → check the
`CMG – Internet Clients – Pilot` service.
Expected: Status shows Ready (green); no provisioning or certificate errors.

## Test 2 — Connection point is healthy
Do: Console → Administration → Cloud Services → Cloud Management Gateway → Connection Analyzer (or
review the CMG connection point status).
Expected: The connection point connects outbound to the CMG; the analyzer reports the channel and the
management/SUP endpoints reachable.

## Test 3 — Public endpoint and certificate
Do: From an internet host run `CMG-Validation.ps1` (or browse the CMG name).
Expected: The CMG DNS name resolves, TLS succeeds against the `CMG – Internet Clients – Server Auth`
certificate, and the certificate is valid and not expired.

## Test 4 — Client uses the CMG
Do: On a pilot internet client run `CMG-Validation.ps1`, or check the Configuration Manager control
panel applet → Network shows an internet/CMG management point.
Expected: The client reports an internet-facing management point and authenticates (token or PKI).

## Test 5 — Policy and inventory flow
Do: On a pilot client trigger Machine Policy Retrieval and a Hardware Inventory Cycle; then run
`CMG-Report.ps1`.
Expected: The client's last policy and last inventory times update within the report; the device is no
longer dark.

## Test 6 — Content / deployment over the CMG
Do: Deploy a small required application or a software update to `CMG – Internet Clients – Pilot`.
Expected: The pilot internet client downloads content via the CMG (or configured internet content
source) and installs successfully.

## Test 7 — Fleet report
Do: Run `CMG-Report.ps1`.
Expected: A clear list of internet clients with CMG reachability, last policy/inventory time, and
overall CMG health.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–6 pass for `CMG – Internet Clients – Pilot`; a deployment installs over the CMG |
| Expand pass | Tests 1–5 and 7 pass for each new wave before widening client settings |
