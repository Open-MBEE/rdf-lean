## ADDED Requirements

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
