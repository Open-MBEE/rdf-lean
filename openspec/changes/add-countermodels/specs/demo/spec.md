## MODIFIED Requirements

### Requirement: Exit codes and verdicts
The demo SHALL use these exit codes and verdicts:
- `0` and "ENTAILED" only when the verified checker accepts the certificate;
- `5` and "REFUTED", with the regime and the recognized datatypes, only when no instance of the query is derived and the verified model checker accepts the finder's countermodel;
- `1` and "NOT DERIVED", with the note that this is not a claim of non-entailment, when no instance of the query is derived and no countermodel is accepted (the finder's candidate was rejected, or the budget was exhausted), reporting the failed condition;
- `2` when the checker rejects the certificate or the search fails;
- `3` on a usage error, an unreadable file or an N-Triples parse error.

With `--countermodel OUT.json` the demo SHALL write the accepted countermodel.

#### Scenario: Not derived is not non-entailment
- **WHEN** the demo is asked a query that is not derived and whose canonical candidate the model checker rejects
- **THEN** it exits `1`, prints "NOT DERIVED", the note and the failed condition, and never prints "not entailed" or "REFUTED"

#### Scenario: A checked countermodel gives REFUTED
- **WHEN** the demo is asked whether `ex:tom rdf:type ex:Dog` over the pet ontology
- **THEN** it exits `5`, prints "REFUTED" with "RDFS" and "D = {xsd:string, rdf:langString, rdf:dirLangString}", and with `--countermodel` writes a countermodel that `leanrdf-check` accepts

#### Scenario: A rejected certificate exits 2
- **WHEN** a certificate for a true query is forged so that its derived nodes name the wrong rule
- **THEN** the verdict is exit code `2`, while the honest certificate gives `0`

#### Scenario: Bad input exits 3
- **WHEN** the query file does not exist, or the data file is not N-Triples
- **THEN** the demo exits `3`
