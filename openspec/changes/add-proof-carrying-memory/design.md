## Context

- `leanrdf-statements` models tiramemsu's records `(eid, s, p, o, txAdded, txRetracted?, validFrom?, validTo?)`. It decides `Record.live v r` for a `View` (`TxSel` now / asOf t / history, `ValidSel` unfiltered / at d). It exports `sg.toRDF v`: for every record, a reifier `stmt:e rdf:reifies <<( s p o )>>` and its clock triples; and for each record live in `v`, its base triple. `decode_toRDF` and `toRDF_decode` make the export exact ([[decisions#Exact decoder and the reserved names]]).
- The core checker's soundness is generic: `check_sound` gives `Derives rules g t` for any rule list, and `checkQuery_sound*` give entailment for the three regimes.
- `add-certificate-envelope` (F2) wraps a certificate in a version-2 envelope with graph, query and rule digests, and `leanrdf-check` (F1) recomputes the digests.
- A certificate's `fact` nodes are triples of the graph and carry no provenance.

## Goals / Non-Goals

**Goals:**
- A certificate can say which records it rests on, and that claim is checked.
- An accepted memory check is a Lean theorem about one view of the store.
- When the view moves (a new transaction, a correction, a different valid time), the certificates that may have lost support are found exactly, and the ones that did not are proven to still hold.

**Non-Goals:**
- Certifying tiramemsu's live database or its write path. The store is read from an export or from JSON-lines records, as today.
- Re-deriving a conclusion that has lost support. That is the finder's job.
- Valid-time *reasoning*, such as entailments that quantify over intervals. Valid time only selects which records are live.
- OWL countermodels, and citing records in `clash` certificates. These are possible later, since citations are independent of the goal kind.

## Decisions

### Citations live beside the certificate

A citation is a pair `(node id, eid)`. Citations are stored in the version-2 envelope (`citations`), not inside `Node`.

- **Alternative rejected:** a `cites : Option Nat` field on `Node`. It changes the core data type that every checker theorem is stated over, and every certificate producer, for a feature only statement graphs use.
- **Reason:** the core checker stays unchanged, and so do its theorems. Citations are checked by a separate function whose soundness is about the store, not about derivations.

Motivated by [[decisions#Own certificate format with a Datalog export]] and [[decisions#Layers as packages in one repository]].

### Memory checks run on the export

`checkMem rules sg v q c` first checks each citation: `sg.find? e = some r`, `r.live v`, and node `i` is a `fact` node whose conclusion is `r.base`. It then runs `checkQuery rules (sg.toRDF v) q c`. Soundness is the core theorem applied to the export graph: `checkMem_sound : checkMem rdfsRules sg v q c = .ok () → (sg.toRDF v).RDFSEntails q`.

- **Alternative rejected:** a new semantics of statement graphs, interpreting records directly. It would duplicate the export and need its own soundness proof.
- **Reason:** [[decisions#Assertion is derived from a view]] already makes the export *the* RDF meaning of a view, and [[decisions#Reifier export is primary]] makes it strict RDF 1.2. Entailment is then the standard notion, with no new definitions.

For an exported file `g` (for example from `tm export --format sg-nt12`), `checkMemRDF_sound` combines the decoder with the check: if `decode v g = .ok sg` and `checkMem rdfsRules sg v q c = .ok ()`, then `g.RDFSEntails q`. The proof rewrites along `toRDF_decode`, which says that `sg.toRDF v` and `g` have the same members, and uses the fact that entailment depends only on membership.

### Strict citations make impact exact

A certificate is *strict* in `v` when each `fact` node is either cited (the base triple of a record live in `v`), or the reifying or clock triple of some record of `sg`. Reifiers and clocks are exported in every view, so they never lose support. `impact v₁ v₂ cs` returns the certificates with a citation `(i, e)` where `e` is live in `v₁` and not in `v₂`. `unimpacted_checks` states: a strict certificate that is accepted in `v₁` and not in `impact v₁ v₂ [c]` is accepted in `v₂`.

- **Alternative rejected:** impact by re-checking every certificate in the new view. That is correct but gives no reason, and it costs a full check per certificate.
- **Alternative rejected:** impact for non-strict certificates. An uncited `fact` may be a base triple that silently disappears, so impact would be a heuristic.
- **Reason:** exactness is what an agent needs to revisit its conclusions after a correction. Non-strict certificates are still checked, and are reported as `impact: unknown`.

The proof uses `mem_toRDF` (a base triple is in the export exactly when its record is live) and the fact that `checkCert` depends on the graph only through `fact` membership.

### Memory in the statements package, its command in check

The library goes in `leanrdf-statements` (`LeanRDFStatements.Memory`), which still requires only the core. The command line goes in `leanrdf-check`, which now requires `leanrdf-statements` as well as the core and `leanrdf-owl`.

- **Alternative rejected:** a new package. It would be one more lakefile for one module.
- **Alternative rejected:** the library in `check/`. Users of statement graphs would then have to build the OWL rules to cite records.
- **Reason:** the check stays the single small trusted executable ([[decisions#Elpi finds, Lean checks]]), and statement graphs stay usable without it. Follows [[decisions#A separate package with a CLI]] and [[decisions#Layers as packages in one repository]].

### Memory envelope fields

The version-2 envelope gains three optional fields:

- `view`, for example `{"tx": "asOf", "t": 4, "validAt": 1730000000000}`;
- `export`, `sha256:` of the RDFC-1.0 canonical N-Quads of `sg.toRDF v`;
- `citations`, a list of `[nodeId, eid]` pairs.

`leanrdf-check` recomputes `export` from the records and the view and rejects a mismatch with exit 2. The envelope's `graph` digest, when present, must equal `export`.

## Constraints

- [[constraints#tiramemsu record model]] binds the meaning of `eid`, liveness and the clocks. Citations must name eids that exist in the store.
- [[constraints#Statement Graph definition]] binds the reserved `stmt:` and `tm:` names. A citation may target only base triples, never reserved-name triples.
- RDF 1.1 Semantics §5 (entailment over the export) binds `checkMem_sound`, through the existing [[constraints#Simple interpretations]] and [[constraints#RDFS interpretation conditions]].

## Risks / Trade-offs

- **`history` views are not consistent with time:** in `history`, every base triple is live, retracted ones included, so a certificate can rest on a fact and its correction together. The command line warns when the view is `history`. → Recommend `now` or `asOf t` for decisions.
- **Export digest cost:** canonicalizing the whole export per check is linear in the store. → Accept the cost for the reference tool. A per-record digest is a later optimization.
- **Strictness is opt-in for producers:** oxilite certificates have no citations. → Report `impact: unknown` instead of rejecting them.
