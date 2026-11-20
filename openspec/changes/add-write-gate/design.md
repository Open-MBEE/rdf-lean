## Context

- `leanrdf-shacl` has `validate G S`, with `validate_conforms` (conforms ⇔ `DataConforms G S`) and `validate_sound` (every result is a `Violation`). Recursive shapes are a read error ([[simplifications#Recursive shapes are rejected]]).
- `leanrdf-check` (F1) checks a version-2 certificate envelope (F2) against data, query and rule set, and recomputes the graph and query digests.
- `add-inconsistency-certificates` (F4) adds `clash` certificates with `checkClash_sound : … → ¬ ∃ I, I ⊨ g`, and exit 4.
- `add-countermodels` (F5) adds a verified checker for finite interpretations, for the simple, RDF and RDFS regimes. A model that satisfies `g` proves that `g` is satisfiable, which is the property this gate uses.
- `leanrdf-statements` reads and writes tiramemsu JSON-lines records. A subject or object may be `{"eid": n}`, which lets one record talk about another.

## Goals / Non-Goals

**Goals:**
- One call, one verdict, one exit code, for "may this write enter memory".
- Every admission is backed by named theorems. Every rejection carries a machine-readable reason.
- What is written records *why* it was admitted.

**Non-Goals:**
- Searching for derivations or clashes inside the gate.
- Writing to tiramemsu. The gate emits records, and the agent framework commits them.
- Retraction impact on certificates already in memory. That is `add-proof-carrying-memory` (F7).
- An MCP server. That is the F3 agent-surface work, which consumes the gate's `--json` verdicts.
- Shapes or certificates for OWL consistency. OWL countermodels are out of F5's scope.

## Decisions

### The gate checks and never searches

`admit` takes the certificates as input. It runs only verified checkers: the SHACL validator, `checkQuery`, `checkClash` and the model checker. An agent that wants the gate to find derivations first calls a finder (`leanrdf-demo --cert`, oxilite through `leanrdf-oxilite`), then calls the gate.

- **Alternative rejected:** Elpi search inside the gate. The gate would require lean-elpi, its build and its runtime, and a bug in the search would sit inside the admission path.
- **Reason:** [[decisions#Elpi finds, Lean checks]]. The gate's trusted base is the checkers and the decision function, both small and proven.

### A gate package above shacl, statements and check

`gate/` (`leanrdf-gate`) requires `leanrdf`, `leanrdf-shacl`, `leanrdf-statements` and `leanrdf-check`.

- **Alternative rejected:** putting the gate in `check/`. That package would gain the SHACL validator, and the smallest trusted tool would grow.
- **Alternative rejected:** putting it in `shacl/` or `statements/`. Each would then depend on the other, against the one-way layering.
- **Reason:** [[decisions#Layers as packages in one repository]] and [[decisions#Dependency-free core package]]. Packages compose by `require`, and nothing below the gate learns about it.

### Admission is a pure function with theorems

```
admit pre delta shapes certs clash? model? policy : Except Rejection (List Record)
post := (pre ∪ delta.add) \ delta.remove     -- asserted part; derived triples are added after the checks
```

`admit` returns `ok` exactly when all of these hold:

1. `validate (post ∪ derived) shapes` conforms;
2. each derived triple `t` has a manifest entry whose certificate is accepted by `checkQuery rules post {t} c`, and whose envelope's `graph` digest is the digest of `post`;
3. no supplied clash certificate is accepted on `post ∪ derived`;
4. under `require-model`, a supplied model certificate is accepted for `post ∪ derived`.

Validation and certificates run on the post-state, not on the delta, because a removal can break a shape or a derivation.

- `admit_conforms` and `reject_sound` come from `validate_conforms` and `validate_sound`.
- `admit_derived` comes from `checkQuery_sound*`, applied per regime to `post`.
- `admit_consistent` comes from F5's model-checker soundness.

### Consistency is a policy, not a default

Without a finder, the gate cannot prove that a post-state is consistent. Unless it is given a model, it can only refute consistency with a supplied clash. So there are two policies:

- `default`: reject with exit 4 when any supplied clash certificate is accepted; otherwise record `consistency: unknown` in the verdict;
- `require-model`: additionally require an accepted model certificate for the post-state (RDF and RDFS regimes), and reject with exit 1 and the reason `no model` when it is missing.

- **Alternative rejected:** always requiring a model. OWL data has no model certificates until there are OWL countermodels.
- **Reason:** [[decisions#Demo never claims non-entailment]]. The gate never claims more than it has proven, and the verdict says which guarantee applies.

### Provenance as statements about statements

For each admitted derived triple with record eid `e` and certificate digest `d`, the gate emits a record `(e', {"eid": e}, urn:leanrdf:certifiedBy, "d"^^xsd:string)` in the same transaction. Asserted triples get no provenance record.

- **Alternative rejected:** a new field in the record. tiramemsu's model has no such field ([[constraints#tiramemsu record model]]).
- **Alternative rejected:** a side file. It can drift from memory.
- **Reason:** a statement about a statement is exactly what [[decisions#Bitemporal records with eid references]] allows. The export makes it an RDF 1.2 reifier annotation, and the provenance is bitemporal, like any record.

`urn:leanrdf:certifiedBy` is outside the `stmt:` and `tm:` names the well-formedness check reserves, so emitted records pass `WellFormed`. The gate checks this before emitting.

### Removals retract by exact match

A removed triple must equal the base triple of a record of `--store` that is live in `now`. The gate emits that record with `txRetracted := T`. A removal that matches no live record is an input error (exit 3).

## Constraints

- [[constraints#SHACL Core]] binds the post-state check, through the proven validator.
- [[constraints#tiramemsu record model]] binds the emitted records: eids are fresh and increasing from `--first-eid`, all of them share the transaction `T`, and there is no self-reference.
- RDF 1.1 Semantics §5 binds the meaning of an admitted derived triple (entailment by the asserted post-state).

## Risks / Trade-offs

- **Derived triples are checked against the asserted post-state only:** a derivation cannot use another derived triple of the same delta unless that triple is in the certificate's DAG. → Finders produce one certificate per goal, as `leanrdf-demo` already does.
- **Digest binding costs canonicalization per write:** RDFC-1.0 over the whole post-state is linear in the memory size. → Acceptable for the reference gate. Incremental digests are later work.
- **`consistency: unknown` by default:** a careless integration may ignore it. → The JSON verdict puts `consistency` at the top level, and the docs recommend `require-model` for RDFS memories.
