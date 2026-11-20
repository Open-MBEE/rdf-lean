## ADDED Requirements

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
