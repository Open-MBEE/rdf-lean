# certificate-check Specification

## Purpose
TBD - created by archiving change add-certificate-check. Update Purpose after archive.

## Requirements

### Requirement: Regimes
The `leanrdf-check` package SHALL define the regimes `simple`, `rdf`, `rdfs`, `owl` and `el`. Each SHALL have a name, a rule list (`simpleRules`, `rdfRules`, `rdfsRules`, `owlRules`, `owlELRules`), an entailment proposition (`SimpleEntails`, `RDFEntails`, `RDFSEntails`, `OWLEntails`, `OWLEntails`) and the name of the theorem its acceptance stands for. Regime names SHALL be read case-sensitively. An unknown name SHALL be an input error.

#### Scenario: Regime names round-trip
- **WHEN** each of the five regimes is printed by name and read back
- **THEN** it reads back to itself, and `RDFS` and `owl2` are rejected

#### Scenario: Each regime names its theorem
- **WHEN** the theorem name of each regime is asked for
- **THEN** `simple`, `rdf` and `rdfs` name `checkQuery_sound_simple`, `checkQuery_sound_rdf` and `checkQuery_sound`, and `owl` and `el` name `Derives.owl_sound_graph` and `Derives.el_sound_graph`

### Requirement: Regime checker soundness
`checkRegime r g q c` SHALL run the verified checker for the rule list of `r`. For `simple` it SHALL also require every query triple to be well-formed. `checkRegime_sound` SHALL prove that `checkRegime r g q c = .ok ()` implies `r.Entails g q`. The theorem SHALL use no axiom beyond `propext`, `Classical.choice` and `Quot.sound`.

#### Scenario: An accepted RDFS certificate gives RDFS entailment
- **WHEN** `checkRegime .rdfs` accepts the recorded certificate of `_:pet rdf:type ex:Mammal`
- **THEN** a Lean theorem `g.RDFSEntails q` is obtained from `checkRegime_sound`

#### Scenario: An accepted OWL certificate gives OWL entailment
- **WHEN** `checkRegime .owl` accepts a certificate that uses `prp-trp`
- **THEN** a Lean theorem `g.OWLEntails q` is obtained from `checkRegime_sound`

#### Scenario: The regime theorem is axiom-clean
- **WHEN** the axioms of `checkRegime_sound` are printed
- **THEN** they are among `propext`, `Classical.choice` and `Quot.sound`

#### Scenario: A certificate is checked only under its regime
- **WHEN** a certificate that uses `rdfs9` is checked under `simple`
- **THEN** it is rejected with the reason `unknown rule rdfs9`

### Requirement: Certificate check command
`leanrdf-check --data DATA --query QUERY --cert CERT [--rules REGIME] [--json]` SHALL read data and query as N-Triples, or as Turtle when the file name ends in `.ttl`, and the certificate as certificate JSON. It SHALL check the certificate under the regime, `rdfs` by default, with `checkRegime`, and SHALL NOT search for derivations. On acceptance it SHALL print `Verdict: PROVEN`, the regime, the theorem name and the query instance, and exit `0`. On rejection it SHALL print `Verdict: CERTIFICATE REJECTED` with the checker's reason and exit `2`. Unreadable, unparsable or missing input, or bad arguments, SHALL exit `3` with a message naming the file.

#### Scenario: A demo certificate is accepted
- **WHEN** `leanrdf-check` checks the certificate `leanrdf-demo` wrote for `examples/pets.nt` and `examples/query-mammal-owner.nt`
- **THEN** it prints `Verdict: PROVEN`, names `checkQuery_sound` and exits `0`

#### Scenario: A tampered certificate is rejected
- **WHEN** the same certificate is checked with one premise id changed, with a fact not in the data, or against a data file without one of its facts
- **THEN** it prints `Verdict: CERTIFICATE REJECTED` with the reason and exits `2`

#### Scenario: Bad input exits 3
- **WHEN** the certificate file is missing, is not JSON, or has version 7, or `--rules` names no regime
- **THEN** the command exits `3` and names the problem

### Requirement: JSON verdict
With `--json`, `leanrdf-check` SHALL write exactly one JSON object to standard output: `verdict` (one of `proven`, `refuted`, `unknown`, `inconsistent`, `rejected`, `input-error`), `exit` (the exit code), `regime`, `theorem` (on `proven`), `nodes` and `goals` (when a certificate was read), `mapping` (blank node to term, in N-Triples syntax) and `reason` (on `rejected` and `input-error`). The exit code SHALL be the same as without `--json`.

#### Scenario: A proven verdict as JSON
- **WHEN** the demo certificate is checked with `--json`
- **THEN** the output parses as JSON with `verdict` `proven`, `exit` 0, `regime` `rdfs`, `theorem` `checkQuery_sound` and the mapping of `_:owner` and `_:pet`

#### Scenario: A rejected verdict as JSON
- **WHEN** a tampered certificate is checked with `--json`
- **THEN** the output has `verdict` `rejected`, `exit` 2 and a non-empty `reason`

### Requirement: Certificate corpus
`check/CheckTests/data/` SHALL hold, for each regime, at least one accepted certificate with its data and query and at least one tampered variant, and the test driver SHALL check every one through the command line and expect the recorded exit code. The RDFS certificates SHALL be the ones `leanrdf-demo` writes for its examples.

#### Scenario: The corpus passes
- **WHEN** the `leanrdf-check` test driver runs
- **THEN** every corpus entry gives its recorded exit code, and the count of entries per regime is printed

### Requirement: Envelope verification
When a certificate has an envelope, `leanrdf-check` SHALL:
- recompute the digests of the data and query it read, and of the regime's rule list, before checking;
- require the envelope's `regime` to equal the regime in use.

Any mismatch SHALL be a rejection with exit `2` and a reason naming the field (`envelope: graph digest mismatch`, `envelope: query digest mismatch`, `envelope: rules digest mismatch`, `envelope: regime mismatch`). The text and JSON verdicts SHALL report the graph and query digests. `--emit-envelope OUT` SHALL write the accepted certificate as version 2, with the envelope filled from the check. A version-1 certificate SHALL be checked as before, and the verdict SHALL say that it is unbound.

#### Scenario: A bound certificate is accepted
- **WHEN** a version-2 certificate written by `leanrdf-demo` is checked against the same data with the triples reordered and blank nodes renamed
- **THEN** it is accepted, and the JSON verdict carries the same `graph` digest as the envelope

#### Scenario: A certificate checked against other data is rejected
- **WHEN** the same certificate is checked against data with one unrelated triple added
- **THEN** it is rejected with `envelope: graph digest mismatch` and exit `2`, although the proof DAG alone would pass

#### Scenario: Version 1 is upgraded
- **WHEN** a version-1 certificate is checked with `--emit-envelope out.json`
- **THEN** the verdict says the input was unbound, and `out.json` is a version-2 certificate that passes envelope verification

### Requirement: Clash certificate checking
`leanrdf-check` SHALL accept clash certificates: given `--rules owl` or `--rules rdfs` and a certificate with a `clash` member, it SHALL run `checkClash` with the matching rule list and clash rule list, verify the envelope as for any certificate, and name `checkClash_sound_owl` or `checkClash_sound_rdfs` as the theorem the check stands for. An accepted clash certificate SHALL exit 4 with verdict `inconsistent`, and a rejected one SHALL exit 2 with verdict `rejected`. A clash certificate given with `--query` SHALL be an input error (exit 3).

#### Scenario: A clash certificate is verified
- **WHEN** `leanrdf-check --data cats.nt --rules owl --cert clash.json` runs on the cat-and-dog graph and the certificate written by `leanrdf-demo --profile owl --cert clash.json`
- **THEN** it prints `INCONSISTENT`, names `checkClash_sound_owl`, and exits 4

#### Scenario: A tampered clash certificate is rejected
- **WHEN** the same certificate is checked after its `clash` premises are reordered
- **THEN** `leanrdf-check` exits 2 with verdict `rejected`

#### Scenario: JSON verdict for a clash
- **WHEN** the verified clash certificate is checked with `--json`
- **THEN** the output has `"verdict": "inconsistent"`, `"exit": 4` and `"theorem": "checkClash_sound_owl"`

### Requirement: Countermodel input
`leanrdf-check` SHALL accept a countermodel with `--countermodel FILE` (or a version-2 envelope whose payload kind is `countermodel`), together with the data, the query and the regime (`simple`, `rdf` or `rdfs`). It SHALL check the countermodel with `checkCountermodel`. When the checker accepts, it SHALL print "REFUTED", the regime, the recognized datatypes and the theorem name (`checkCountermodel_sound_simple`, `_rdf` or `_rdfs`), and exit `5`. When the checker rejects or the step budget is exhausted, it SHALL exit `2`. With `--json` the verdict SHALL be `refuted`, with `"datatypes"` and `"theorem"` fields. `--rules owl` and `--rules el` SHALL be input errors (exit `3`) for countermodels.

#### Scenario: An accepted countermodel exits 5
- **WHEN** `leanrdf-check` is given the pet ontology, the query `ex:tom rdf:type ex:Dog`, `--rules rdfs` and the countermodel the finder wrote
- **THEN** it prints "REFUTED" with the regime, the datatypes and `checkCountermodel_sound_rdfs`, and exits `5`

#### Scenario: A forged countermodel exits 2
- **WHEN** the same countermodel is edited so that its `IEXT` table makes the query true
- **THEN** `leanrdf-check` exits `2` and reports the satisfying assignment

#### Scenario: OWL countermodels are an input error
- **WHEN** a countermodel is given with `--rules owl`
- **THEN** `leanrdf-check` exits `3`
