## ADDED Requirements

### Requirement: Delta format
A delta SHALL consist of triples to add and triples to remove, each read from RDF 1.2 N-Triples, and a JSON manifest that lists the derived triples of the addition, each with the path of a version-2 certificate envelope and the rule set it is checked under (`simple`, `rdf`, `rdfs`, `owl` or `el`). A derived triple SHALL also appear in the added triples. Reading SHALL report malformed input with its file and line.

#### Scenario: A delta with one derived triple is read
- **WHEN** an addition of three triples and a manifest marking `ex:ada rdf:type ex:Staff` as derived under `rdfs` with `cert-ada.json` are read
- **THEN** the delta has two asserted triples, one derived triple, and no removals

#### Scenario: A derived triple that is not added is an input error
- **WHEN** the manifest marks a triple that is not among the added triples
- **THEN** reading fails with exit 3 and names the triple

### Requirement: Admission decision
`admit` SHALL compute the asserted post-state `(pre ∪ asserted additions) \ removals` and admit the delta exactly when:
- the post-state together with the derived triples conforms to the shapes under the proven validator;
- every derived triple has a certificate that `checkQuery` accepts against the asserted post-state under its rule set, with an envelope whose graph digest is the post-state's;
- no supplied clash certificate is accepted on the post-state with the derived triples;
- under the `require-model` policy, a supplied model certificate is accepted for the post-state with the derived triples.

#### Scenario: A conforming, certified write is admitted
- **WHEN** an agent adds `ex:ada ex:role ex:Lecturer` and the derived `ex:ada rdf:type ex:Staff` with an Elpi certificate under `rdfs`, and the post-state conforms
- **THEN** `admit` returns the records to write

#### Scenario: A removal that breaks a derivation is rejected
- **WHEN** a delta removes `ex:Lecturer rdfs:subClassOf ex:Staff` and adds a derived triple whose certificate uses it
- **THEN** `admit` rejects the delta and names the certificate node whose fact is not in the post-state

### Requirement: Admission soundness
`admit_conforms` SHALL prove that an admitted post-state with its derived triples satisfies `DataConforms` for the shapes. `admit_derived` SHALL prove that each admitted derived triple is entailed by the asserted post-state in the regime of its rule set. `admit_consistent` SHALL prove that, under `require-model`, the admitted post-state with its derived triples has a model in its regime. The theorems SHALL use no axiom beyond `propext`, `Classical.choice` and `Quot.sound`.

#### Scenario: Admission theorems are axiom-clean
- **WHEN** the axioms of `admit_conforms`, `admit_derived`, `admit_consistent` and `reject_sound` are printed
- **THEN** they are among `propext`, `Classical.choice` and `Quot.sound`

### Requirement: Rejection reports
A rejection SHALL list every reason found: each SHACL validation result in the SHACL report vocabulary, each derived triple whose certificate is missing or not accepted with the checker's error, each accepted clash certificate, and, under `require-model`, a missing or rejected model. `reject_sound` SHALL prove that every SHACL result in a rejection is a `Violation` of the post-state.

#### Scenario: A shape violation is reported as a repair target
- **WHEN** an agent adds `hr:kid hr:age "12"^^xsd:integer` against a shape with `sh:minInclusive 16`
- **THEN** the rejection has one result with focus node `hr:kid`, path `hr:age`, value `"12"^^xsd:integer` and component `sh:MinInclusiveConstraintComponent`, and exit code 1

#### Scenario: A forged derivation is rejected
- **WHEN** the certificate of a derived triple names a fact that is not in the post-state
- **THEN** the rejection reports the certificate's error, and the exit code is 2

### Requirement: Consistency policy
Under the `default` policy, the gate SHALL reject with exit 4 when a supplied clash certificate is accepted on the post-state, and otherwise SHALL report `consistency: unknown`. Under `require-model`, the gate SHALL report `consistency: proven` only when a supplied model certificate is accepted, and SHALL reject with exit 1 and the reason `no model` when none is supplied.

#### Scenario: An inconsistent write is rejected
- **WHEN** an agent adds `ex:tom rdf:type ex:Cat` to a memory with `ex:Cat owl:disjointWith ex:Dog` and `ex:tom rdf:type ex:Dog`, and supplies the clash certificate found by Elpi
- **THEN** the gate exits 4 and reports the clash

#### Scenario: Require-model without a model
- **WHEN** a conforming, certified write is submitted with `--policy require-model` and no model certificate
- **THEN** the gate exits 1 with the reason `no model`

### Requirement: Record emission
On admission, the gate SHALL emit tiramemsu JSON-lines records:
- one record per added triple, with transaction `T` and fresh eids increasing from the given first eid;
- for each removal, the matching record of the store that is live in `now`, with `txRetracted` set to `T`;
- for each derived triple with record eid `e`, a provenance record whose subject is `{"eid": e}`, whose predicate is `urn:leanrdf:certifiedBy` and whose object is the certificate's `sha256:` digest as an `xsd:string` literal.

The emitted records together with the store SHALL satisfy the statement-graph `WellFormed`. A removal that matches no live record SHALL be an input error.

#### Scenario: Emitted records carry provenance
- **WHEN** the admitted write of the scenario above is emitted with `--tx 9 --first-eid 40`
- **THEN** records 40 and 41 hold the two added triples in transaction 9, and record 42 is `({"eid": 41}, urn:leanrdf:certifiedBy, "sha256:…")`

#### Scenario: Emitted records are well-formed
- **WHEN** the emitted records are appended to the store and checked with `leanrdf-sg check`
- **THEN** the check passes

### Requirement: Gate command line
`leanrdf-gate admit --store S.jsonl --add A.nt --remove R.nt --shapes SH.ttl --manifest M.json --tx T --first-eid E [--policy default|require-model] [--clash C.json…] [--model M.json] [--json]` SHALL print the verdict, write the records to standard output or `--out FILE`, and exit with 0 admitted, 1 rejected, 2 a certificate rejected, 3 input error, 4 inconsistent. With `--json`, it SHALL write `{verdict, exit, consistency, records | reasons, theorems}`, where `verdict` is one of `proven`, `unknown`, `inconsistent`, `rejected` or `input-error`.

#### Scenario: JSON verdict for an admitted write
- **WHEN** the admitted write is run with `--json`
- **THEN** the output has `"verdict": "proven"`, `"exit": 0`, `"consistency": "unknown"`, the records, and the theorem names `admit_conforms` and `admit_derived`

### Requirement: Write gate example
`examples/write-gate/` SHALL hold a memory, its shapes, one admitted write and three rejected writes (a shape violation, a forged derivation and an inconsistent write), with recorded outputs that `scripts/examples.sh` checks.

#### Scenario: The example is checked in CI
- **WHEN** `scripts/examples.sh` runs
- **THEN** the four write-gate outputs and exit codes equal the recorded ones
