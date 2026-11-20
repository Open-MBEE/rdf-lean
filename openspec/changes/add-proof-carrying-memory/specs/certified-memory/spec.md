## ADDED Requirements

### Requirement: Citations
A memory certificate SHALL be a certificate together with a list of citations, each a pair of a node id and a statement-record eid. A citation SHALL be accepted against a statement graph `sg` and a view `v` exactly when the eid names a record `r` of `sg`, `r` is live in `v`, and the cited node is a `fact` node whose conclusion is the base triple of `r`.

#### Scenario: A citation of a live record is accepted
- **WHEN** node 0, the fact `ex:ada ex:memberOf ex:staff`, cites eid 3, whose record has that base triple and is not retracted, and the view is `now`
- **THEN** the citation is accepted

#### Scenario: Bad citations are rejected
- **WHEN** a citation names an eid that is not in the store, a record retracted before the view, a derived node, or a fact whose conclusion is not the record's base triple
- **THEN** the memory check returns an error that names the citation

### Requirement: View-relative check
`checkMem rules sg v q c` SHALL accept exactly when every citation of `c` is accepted against `sg` and `v`, and `checkQuery rules (sg.toRDF v) q c` accepts.

#### Scenario: A certificate holds now but not as of an earlier transaction
- **WHEN** a certificate cites a record added in transaction 5 and is checked in the views `now` and `asOf 4`
- **THEN** it is accepted in `now` and rejected in `asOf 4`, naming the citation

### Requirement: Memory soundness
`checkMem_sound` SHALL prove that `checkMem rdfsRules sg v q c = .ok ()` implies `(sg.toRDF v).RDFSEntails q`, with RDF and simple variants for `rdfRules` and `simpleRules`. `checkMem_cites` SHALL prove that every accepted citation names a record of `sg` that is live in `v` and whose base triple is the cited conclusion. The theorems SHALL use no axiom beyond `propext`, `Classical.choice` and `Quot.sound`.

#### Scenario: An accepted memory check gives entailment of the view
- **WHEN** `checkMem rdfsRules` accepts a certificate of `ex:ada rdf:type ex:Person` over a three-record store in view `now`
- **THEN** a Lean theorem `(sg.toRDF {}).RDFSEntails q` is obtained from it

#### Scenario: Memory theorems are axiom-clean
- **WHEN** the axioms of `checkMem_sound`, `checkMem_cites`, `checkMemRDF_sound` and `unimpacted_checks` are printed
- **THEN** they are among `propext`, `Classical.choice` and `Quot.sound`

### Requirement: Checks on exported files
`checkMemRDF_sound` SHALL prove that, when `decode v g = .ok sg` and `checkMem rdfsRules sg v q c = .ok ()`, the exported graph itself entails the query: `g.RDFSEntails q`.

#### Scenario: A recorded tiramemsu export is a certified memory
- **WHEN** a recorded `tm export --format sg-nt12` file decodes in view `now`, and a certificate citing its records is checked
- **THEN** the check accepts and the entailment holds of the file's graph

### Requirement: Strict citations
A memory certificate SHALL be strict in a view `v` when every `fact` node either has an accepted citation, or is the reifying triple or a clock triple of a record of `sg`. `isStrict` SHALL decide strictness.

#### Scenario: An uncited base triple is not strict
- **WHEN** a certificate uses the base triple of a record as a fact without citing it
- **THEN** `isStrict` returns false and the command line reports `impact: unknown` for it

### Requirement: Retraction impact
`impact v₁ v₂ cs` SHALL return the certificates of `cs` that have a citation whose record is live in `v₁` and not live in `v₂`. `unimpacted_checks` SHALL prove that a certificate that is strict in `v₁`, accepted by `checkMem` in `v₁`, and not returned by `impact v₁ v₂ [c]` is accepted by `checkMem` in `v₂`.

#### Scenario: A correction impacts exactly the certificates that cite it
- **WHEN** record 4 (`ex:dist ex:km "665"`) is retracted in transaction 6 and replaced by record 7 (`"655"`), and three certificates are checked, one citing 4 and two citing neither
- **THEN** `impact (asOf 5) now` returns exactly the certificate citing 4, and the other two are accepted in `now`

#### Scenario: Impact agrees with re-checking on all small stores
- **WHEN** every store of at most three records over the test alphabet, every pair of views, and every strict certificate of at most four nodes is enumerated by the compiled test driver
- **THEN** a certificate is outside `impact v₁ v₂` exactly when it was accepted in `v₁` and is accepted in `v₂`, or it was not accepted in `v₁`

### Requirement: Memory envelope fields
The version-2 certificate envelope SHALL accept the optional fields `view`, `export` and `citations`. `export` SHALL be `sha256:` of the RDFC-1.0 canonical N-Quads of `sg.toRDF v`. A memory check SHALL recompute `export` and reject a mismatch, and when the envelope also has a `graph` digest, it SHALL equal `export`.

#### Scenario: A certificate for another view is rejected
- **WHEN** an envelope records the view `asOf 4` and its export digest, and `leanrdf-check` is run with `--view now` on a store whose transaction 5 added a record
- **THEN** the check exits 2 and reports that the export digest does not match

### Requirement: Memory command line
`leanrdf-check` SHALL accept `--statements FILE.jsonl` with `--view now|asof:T|history` and an optional `--valid-at MS` in place of `--data`, run the memory check, and use the common exit codes: 0 proven, 1 not derived, 2 rejected, 3 input error. `leanrdf-check impact --statements FILE.jsonl --from VIEW --to VIEW CERT…` SHALL print, for each certificate, `impacted`, `holds` or `unknown` (when the certificate is not strict), and with `--json` SHALL write them as JSON. A `history` view SHALL print a warning that retracted records are live in it.

#### Scenario: Impact on the command line
- **WHEN** `leanrdf-check impact --statements examples/certified-memory/store.jsonl --from asof:5 --to now` is run on the example's three certificates
- **THEN** it prints one `impacted` and two `holds`, and exits 0

### Requirement: Certified memory example
`examples/certified-memory/` SHALL hold a store with a correction, certificates with citations, and recorded outputs of the memory check and impact commands, and `scripts/examples.sh` SHALL check them.

#### Scenario: The example is checked in CI
- **WHEN** `scripts/examples.sh` runs
- **THEN** the certified-memory outputs equal the recorded ones
