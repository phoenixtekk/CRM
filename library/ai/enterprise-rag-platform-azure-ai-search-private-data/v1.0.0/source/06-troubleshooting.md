# 6. Troubleshooting Guide — Enterprise RAG Platform on Azure (AI Search + Private Data)

Use `AIRAG-Discovery.py` for the pre-deploy picture, `AIRAG-Validate.py` for infra/index/retrieval and the permission-trimming test, and `AIRAG-Report.py` for posture, ACL coverage, and eval scores. Objects are referenced by their `<Purpose> – <Scope> – <Stage>` names.

## A. The permission-trimming test FAILS (a restricted chunk reached an unauthorised user)
**This is the most important failure to get right — do not ship until it passes.**
| Symptom | Cause | Remediation |
|---|---|---|
| Unauthorised query returns a restricted chunk | The chunk was stamped with the **wrong** `group_ids`, or the mapping defaulted to an "everyone" group | Fix the source→`group_ids` mapping in `AIRAG-Ingest.py`, **re-ingest** the affected content, re-run `AIRAG-Validate.py --permission-trimming-test`. **Never** widen the filter to make the test pass |
| Restricted chunk has empty `group_ids` | The document had no resolvable ACL and was loaded anyway | Empty ACLs must **block** ingestion, not default open — re-ingest with the corrected mapping; `AIRAG-Report.py --acl-coverage` must read 100% |
| Filter not applied at all | The query was built without the security filter, or filtered in app code after retrieval | Ensure the filter `group_ids/any(g: search.in(g, '<caller groups>'))` is passed **into the search call**; resolve the caller's groups from Graph, not from a static list |
| Caller groups resolved wrong | Graph group-membership lookup returned partial/no groups (e.g. transitive groups missing) | Use transitive membership (`memberOf` transitive) so nested-group readers are included; confirm the test user's expected groups with `AIRAG-Discovery.py` |

## B. Bicep deploy / infra failures
| Symptom | Cause | Remediation |
|---|---|---|
| `what-if` / `create` fails with `AuthorizationFailed` | Operating account lacks rights to write resources or role assignments | Grant **Owner** or **Contributor + role-assignment** rights at the resource-group scope; re-run `what-if` then `create` |
| Semantic ranker not available / not enabled | Service tier too low, or semantic ranker not turned on | Deploy a supported tier and enable **Semantic ranker** on the service. *Verify current tier requirements and pricing in your region* |
| Model deployment fails (`rag-embeddings` / `rag-chat`) | Model/version not available in the region, or no quota | Pick a currently-available model/version + region; request TPM quota. *Verify current model availability and quota in your subscription* |
| Private endpoint / DNS errors | Private DNS zone not linked, or subnet policy blocks the endpoint | Link the Private DNS zone to the VNet and confirm the subnet allows private endpoints; re-deploy |

## C. Retrieval returns nothing or irrelevant chunks
| Symptom | Cause | Remediation |
|---|---|---|
| Authorised query returns 0 chunks | The security filter excludes everything (caller groups don't match any stamped `group_ids`), or the index is empty | Confirm the caller is in the expected group and that group's ID was stamped at ingest; confirm ingest ran (`AIRAG-Report.py`) |
| Results are keyword-ish, not semantic | Hybrid or semantic ranking not applied | Run `AIRAG-Validate.py --explain` — it prints the search mode and semantic score; enable semantic ranking and pass the vector + text query together |
| Vector search errors on dimensions | Embedding model dimensions ≠ the `contentVector` field dimensions, or query embedded with a different model than the chunks | Re-create the field / re-ingest so ingest and query use the **same** embedding model + dimensions |
| Good chunk exists but isn't retrieved | Chunking too coarse or `top-k` too low | Reduce chunk size / add overlap, raise `top-k`, re-ingest the sample and re-evaluate |

## D. Answers are wrong, uncited, or hallucinated
| Symptom | Cause | Remediation |
|---|---|---|
| Answer not supported by sources | Weak grounding prompt, or `top-k` too low so the supporting chunk wasn't retrieved | Strengthen the "answer only from the sources / refuse if unsupported" instruction; raise `top-k`; re-run `RAG Eval – Groundedness – NonProd` |
| No citations | Flow not returning the source references | Ensure the flow maps each retrieved chunk's `title`/`url` into the citation output |
| Model answers when it shouldn't | Refusal instruction missing or overridden | Add/repair the explicit refuse-when-unsupported instruction; confirm with Testing Guide Test 7 |
| Low groundedness across the board | Retrieval quality (Section C) — fix retrieval before prompt/model | Tune chunking/`top-k`/semantic ranking first, then re-evaluate |

## E. Auth / keyless issues
| Symptom | Cause | Remediation |
|---|---|---|
| `401/403` from Search or OpenAI | Managed identity missing the data-plane role, or code still using a key | Assign **Search Index Data Contributor/Reader** and **Cognitive Services OpenAI User**; switch the client to `DefaultAzureCredential` / managed identity |
| Query principal can write to the index | Runtime identity over-privileged | Split roles — the **query** path should hold **Data Reader** only; loading uses **Data Contributor** |
| `Public network access is disabled` when running the pipeline | Running from off the private network (by design) | Run ingestion/queries from a host with a path to the private endpoints (peering / VPN / jumpbox) |

## F. Cost / throttling
- **429 / rate-limit during ingestion** — embedding a large corpus exceeds the `rag-embeddings` TPM quota. Batch the ingest, add backoff (`AIRAG-Ingest.py` retries with backoff), and/or raise quota. *Verify current quota and pricing.*
- **Bill higher than expected** — re-embedding unchanged documents on every run. Ingest incrementally (only changed docs); keep the budget/alerts from Requirements 2.8 in place.

## G. Diagnostics quick reference
```bash
python AIRAG-Discovery.py                                  # readiness (read-only)
python AIRAG-Validate.py --check-infra --check-index       # private/keyless + security field
python AIRAG-Validate.py --permission-trimming-test        # the hard gate
python AIRAG-Report.py --acl-coverage --eval               # 100% ACL coverage + eval scores
az deployment group what-if -g rg-rag-platform-nonprod -f AIRAG-infra.bicep -p AIRAG-infra.bicepparam
```

## H. When to escalate
If the infra reports private + keyless, the index has a filterable `group_ids` field, ACL coverage is 100%, the caller's groups resolve correctly (transitive), and the **permission-trimming test still fails** — stop, treat it as a security incident, keep the platform out of production, collect `AIRAG-Validate.py --permission-trimming-test` and `AIRAG-Report.py` output, and open a Microsoft support case with the index definition and a redacted query trace. Never move to production with a failing negative test.
