# 5. Testing Guide — Double Key Encryption (DKE) Implementation, Microsoft Purview

Run after the key service is deployed (Implementation Step 5) and the label is published to
`Purview - DKE Pilot Users` (Step 7), and again after each expansion. Apply/open DKE content on a
**supported Windows Office desktop client** (Requirement 2.5).

## Test 1 — Key service endpoint is healthy
**Do:** Browse to `https://dke.contoso.com/DKE-Key-01`, or run
`IPDKE-Scope-And-ServiceHealth.ps1 -DkeEndpointUrl https://dke.contoso.com/DKE-Key-01`.
**Expected:** The endpoint returns the **public key JSON** for `DKE-Key-01` over a trusted HTTPS/TLS
connection and is reachable from a pilot client.

## Test 2 — DKE label is published and visible
**Do:** As a member of `Purview - DKE Pilot Users`, open the **Sensitivity** button in Word or Outlook
(desktop, Windows). Or run `IPDKE-Validation.ps1`.
**Expected:** `Sensitivity Label - Ultra Confidential (DKE) - Named Group` appears via
`Label Policy - DKE Ultra Confidential - DKE Pilot`.

## Test 3 — Applying the label double-encrypts (requires your key)
**Do:** Apply the DKE label to a test document and save. Then, on a client that **cannot reach**
`dke.contoso.com` (block it or disconnect from the key service network path), try to open the file.
**Expected:** Applying the label succeeds only after the client authenticates and reaches **your** DKE
service; when the service is unreachable the content **cannot** be opened — proving the customer-held
key is required.

## Test 4 — Only authorized readers can open
**Do:** As a user **in** `SG - DKE Ultra Confidential Readers`, open the DKE-protected item. Then, as a
user **outside** that group, attempt to open the same item.
**Expected:** The authorized reader opens it; the unauthorized user is **denied** per the label's
permissions — even inside the tenant.

## Test 5 — Microsoft cannot read DKE content (by design)
**Do:** Confirm DKE content is excluded from cloud content services: check that a content-based DLP
policy does not match the DKE item's content, and that eDiscovery **content search** does not index
its body. **Verify the current unsupported-services list for your tenant.**
**Expected:** DKE content is not readable by cloud content services — the intended trade-off; metadata
(not content) may still be visible.

## Test 6 — Endpoint URL wired correctly on the label
**Do:** Run `IPDKE-Validation.ps1`.
**Expected:** The label reports DKE encryption enabled and the DKE endpoint URL matches
`https://dke.contoso.com/DKE-Key-01`; the label policy targets `Purview - DKE Pilot Users`.

## Test 7 — Usage / coverage report
**Do:** Run `IPDKE-Report.ps1`.
**Expected:** A summary of the DKE label(s), the publishing policy and its audience, and a reminder of
the content-service exclusions — so coverage and scope are visible.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Service pass** | Test 1 passes — the endpoint returns the public key over HTTPS and is reachable |
| **Pilot pass** | Tests 2–4, 6 pass on `Purview - DKE Pilot Users`; the customer key is provably required (Test 3) and permissions hold (Test 4) |
| **Trade-off confirmed** | Test 5 confirms the accepted content-service exclusions |
| **Expand pass** | Tests 1, 2, 4, 6, 7 pass after widening the audience; the key service is monitored and backed up |
