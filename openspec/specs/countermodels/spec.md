# countermodels Specification

## Purpose
TBD - created by archiving change add-countermodels. Update Purpose after archive.

## Requirements

### Requirement: Model presentations
A `Presentation` SHALL describe an interpretation by finite data:
- sorts, each with a kind (`base`, `string`, `lang`, `dirLang`, `otherLit`, `triple`) and IR and IP flags;
- a table from listed IRIs to sorts, a default sort for every other IRI, and a default sort for every unlisted `rdf:_n`;
- a default sort for each literal kind, and a table of overridden literals with their sorts;
- one sort for all triple terms;
- an `IEXT` table of sort triples;
- an assignment of sorts to blank nodes.

`Presentation.WellFormed` SHALL be decidable. It SHALL require that every index is in range, that sort kinds are pure (a literal's sort has the literal's kind, a `base` sort is not the sort of any literal, and the triple-term sort has kind `triple`), and that every override sort is the target of at least one override.

#### Scenario: A well-formed presentation is accepted
- **WHEN** a presentation with two base sorts, the four literal default sorts, a triple sort and an `IEXT` table is checked for well-formedness
- **THEN** `WellFormed` holds and is decided `true`

#### Scenario: Impure kinds are rejected
- **WHEN** an `xsd:string` literal is overridden to a sort of kind `base`, or a `lang` sort is the default for `xsd:string`, or an override sort has no literal
- **THEN** `WellFormed` is decided `false` with a located reason

### Requirement: Presentation interpretations
`Presentation.interp` SHALL build a `SimpleInterp`, and `Presentation.dinterp` a `DInterp`. Both SHALL have as carrier the free type `CDom := base i | lit l | tt x y z`, `IT := tt`, `IL l := some (lit l)` with tags lowercased, and IR, IP and `IEXT` given by the sort tables through `sortOf`. The `SimpleInterp` and `DInterp` fields SHALL be proven for every well-formed presentation whose triple sort and IRI sorts satisfy the IR ∪ IP conditions.

#### Scenario: IT is injective by construction
- **WHEN** `IT_inj` is proven for `Presentation.interp`
- **THEN** the proof uses only the injectivity of `tt` and no property of the tables

#### Scenario: Literal values are injective
- **WHEN** `strVal_inj`, `langVal_inj` and `dirLangVal_inj` are proven for `Presentation.dinterp`
- **THEN** they hold for every presentation, by the injectivity of `lit` and of `Literal`'s constructors

### Requirement: Lifting lemmas
For each regime, every condition SHALL have a decidable sort-level form over the finite tables and a lemma showing that the sort-level form implies the condition on `Presentation.interp` or `Presentation.dinterp`. The regimes are the `SimpleInterp` fields, `RDFConditions` (`IsRDF`) and `RDFSConditions` (`IsRDFS`). Conditions over all `rdf:_n` SHALL be discharged by the listed IRIs together with the default `rdf:_n` sort. Conditions over all literals SHALL be discharged by the overrides together with the kind defaults. Conditions over all triple terms SHALL be discharged by the triple sort.

#### Scenario: The rdf:_n axioms lift
- **WHEN** a presentation lists `rdf:_1` and `rdf:_2`, and its default `rdf:_n` sort is a property in the class `rdf:Property`
- **THEN** `axioms_member` holds for every `n` on `Presentation.dinterp`

#### Scenario: Datatype classes lift through kind purity
- **WHEN** the sort-level form of `string_class` holds (a sort is in the class of `xsd:string` iff its kind is `string`) on a well-formed presentation
- **THEN** `string_class` holds for every element of the carrier

#### Scenario: A violated sort-level condition is detected
- **WHEN** a presentation's `IEXT` table has `ex:A rdfs:subClassOf ex:B` and `ex:x rdf:type ex:A` but not `ex:x rdf:type ex:B`
- **THEN** the sort-level form of `subClass_ext` is decided `false` and names the condition

### Requirement: Model checker
`checkCountermodel regime g q m` SHALL return `.ok ()` only when all of the following hold:
- `m` is well-formed;
- every sort-level condition of the regime holds;
- the assignment of `m`, extended to the blank nodes of `g`, makes every triple of `g` hold;
- no assignment of IR sorts to the blank nodes of `q` makes every triple of `q` hold, decided by an exhaustive backtracking search.

The regime is `simple`, `rdf` or `rdfs`. The search SHALL take a step budget, and exhausting the budget SHALL be an error, never an acceptance. Otherwise the checker SHALL return an error naming the first failed condition, the triple of `g` that does not hold, or the satisfying assignment of `q`.

#### Scenario: subClassOf is not symmetric
- **WHEN** a countermodel for `{ex:A rdfs:subClassOf ex:B} ⊭ {ex:B rdfs:subClassOf ex:A}` is checked under `rdfs`
- **THEN** the checker accepts it

#### Scenario: A model of q is rejected
- **WHEN** a presentation in which the query `_:x rdf:type ex:C` holds for some sort is checked as a countermodel to that query
- **THEN** the checker returns an error that gives the satisfying sort assignment

#### Scenario: A model that misses g is rejected
- **WHEN** a presentation's `IEXT` table lacks a triple of `g`
- **THEN** the checker returns an error naming that triple

#### Scenario: Budget exhaustion is not acceptance
- **WHEN** the query search exceeds its step budget
- **THEN** the checker returns an error and the verdict is not REFUTED

### Requirement: Countermodel soundness
`checkCountermodel_sound_simple`, `checkCountermodel_sound_rdf` and `checkCountermodel_sound_rdfs` SHALL prove that acceptance under the regime gives `¬ g.SimpleEntails q`, `¬ g.RDFEntails q` and `¬ g.RDFSEntails q`. `checkCountermodel_consistent` SHALL prove that acceptance gives an interpretation of the regime that satisfies `g`. The query-search completeness lemma SHALL prove that a search returning no assignment means no assignment `A : BlankNode → CDom` into IR satisfies `q`. Every theorem SHALL use no axiom beyond `propext`, `Classical.choice` and `Quot.sound`.

#### Scenario: An accepted countermodel gives non-entailment
- **WHEN** the checker accepts a countermodel for `{ex:x rdf:type ex:C} ⊭ {ex:x rdf:type ex:D}` under `rdfs`
- **THEN** a Lean theorem `¬ g.RDFSEntails q` is obtained from it by `checkCountermodel_sound_rdfs`

#### Scenario: Refuting RDFS refutes the weaker regimes
- **WHEN** an `rdfs` countermodel is accepted
- **THEN** `¬ g.RDFEntails q` and `¬ g.SimpleEntails q` follow through `RDFEntails.toRDFS`, `DEntails.toRDF` and `SimpleEntails.toD`

#### Scenario: Countermodel theorems are axiom-clean
- **WHEN** the axioms of the three soundness theorems and of `checkCountermodel_consistent` are printed
- **THEN** they are among `propext`, `Classical.choice` and `Quot.sound`

#### Scenario: The hand-built vacuity countermodels are reproduced
- **WHEN** the three non-entailments of `Tests/Semantics/Vacuity.lean` are restated as presentations and checked
- **THEN** each is accepted, and the resulting theorems match the hand proofs' statements

### Requirement: Countermodel format
A countermodel SHALL have a JSON form with `"kind": "countermodel"`, the regime, the sorts with kinds and flags, the IRI table with its two defaults, the literal defaults and overrides (terms in RDF 1.2 N-Triples syntax), the triple sort, the `IEXT` table and the blank-node assignment. Reading it SHALL be untrusted: malformed JSON is a parse error, and a wrong model fails the checker. The JSON form SHALL round-trip, and SHALL be carried as the payload of a version-2 envelope.

#### Scenario: Countermodel JSON round-trips
- **WHEN** a presentation with literal overrides, a directional literal and a blank-node assignment is rendered to JSON and parsed back
- **THEN** it parses to itself and the checker gives the same verdict on both

### Requirement: Countermodel finder
The Elpi bridge SHALL build a candidate presentation from the closure of `g` under the regime's rules:
- one sort per closure term;
- every IRI of `q` listed as its own sort;
- default sorts for literals by kind, for triple terms, for unlisted IRIs and for unlisted `rdf:_n`, saturated together with `g`;
- the closure's triples as the `IEXT` table;
- the blank nodes of `g` assigned their own sorts.

The finder is untrusted. A candidate the checker rejects SHALL be reported with the failed condition and SHALL give the verdict UNKNOWN, never REFUTED.

#### Scenario: The finder refutes a missing type
- **WHEN** the pet ontology and the query `ex:tom rdf:type ex:Dog` are given to the finder under `rdfs`
- **THEN** it builds a candidate that the checker accepts

#### Scenario: A rejected candidate gives UNKNOWN
- **WHEN** a graph needs a datatype typing that the rules do not derive (a literal inside a triple term) and the canonical candidate violates a condition
- **THEN** the finder's candidate is rejected, the failed condition is reported, and the verdict is UNKNOWN

### Requirement: Negative entailment conformance
The W3C RDF 1.2 semantics suite runner SHALL run every `NegativeEntailmentTest` whose datatypes are within `{xsd:string, rdf:langString, rdf:dirLangString}` under its regime (simple, RDF or RDFS), try the finder, and record each test as refuted (countermodel accepted), unknown (candidate rejected or budget exhausted) or not run (datatypes outside D, or OWL). A test the suite marks as a positive entailment SHALL never be refuted.

#### Scenario: Negative tests are refuted or reported
- **WHEN** the RDF 1.2 semantics suite runs
- **THEN** every negative entailment test within D is listed as refuted or unknown with a reason, and the counts are printed

#### Scenario: Positive tests are never refuted
- **WHEN** the finder is run on every positive entailment test of the suite
- **THEN** the checker accepts no candidate for any of them
