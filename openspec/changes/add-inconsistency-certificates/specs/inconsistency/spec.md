## ADDED Requirements

### Requirement: Clash rules
The core SHALL define `ClashRule`, a name, a list of body triple patterns and a list of guards with no head, and `ClashRule.SoundIn C`: in every interpretation of `C`, under every blank-node mapping and every substitution whose guards hold, not every body instance is true. `matchBody` and `Guard.check` SHALL be reused unchanged, and `Rule`, `Derives` and `Rule.SoundIn` SHALL not change.

#### Scenario: A clash rule has no head
- **WHEN** `cax-dw` is defined as a `ClashRule`
- **THEN** it has the three body patterns `?c1 owl:disjointWith ?c2`, `?x rdf:type ?c1` and `?x rdf:type ?c2`, and no conclusion

#### Scenario: Existing theorems are untouched
- **WHEN** the core, `leanrdf-owl` and `leanrdf-elpi` are built after this change
- **THEN** `check_sound`, `checkQuery_sound`, `owlRules_sound` and `Derives.owl_sound` have the same statements as before

### Requirement: Datatype clash
`DInterp` SHALL state that `strVal s = none` whenever `s` is not in the lexical space of `xsd:string` (a code point outside XML 1.1 `Char`), `Xsd.isStringLexical` SHALL decide that lexical space, and the clash rule `dClashString` (`?s ?p ?o` with the guard `illTypedString ?o`) SHALL be proven sound under `RDFSCore`. If the field cannot be added without breaking unrelated models, the condition SHALL instead be a separate predicate `DInterp.IsWellTyped` assumed only by the RDFS clash theorem, and recorded as a simplification.

#### Scenario: An ill-typed string literal clashes
- **WHEN** the graph `ex:a ex:p "a\u0000b"^^xsd:string .` is checked with a clash certificate using `dClashString`
- **THEN** the checker accepts it, and the graph is proven to have no RDFS interpretation

#### Scenario: A well-typed string does not clash
- **WHEN** `dClashString` is matched against `ex:a ex:p "ab"^^xsd:string .`
- **THEN** the guard fails and the clash certificate is rejected

### Requirement: Clash certificates
A clash certificate SHALL be a version-2 certificate with an empty `goals` list and a `clash` member naming a clash rule and the ids of its premise nodes. Its JSON form SHALL round-trip, and a reader SHALL reject a `clash` member in a version-1 certificate.

#### Scenario: Clash certificate JSON round-trips
- **WHEN** a clash certificate for `cax-dw` with premises `[0, 1, 2]` is rendered to JSON and parsed back
- **THEN** it parses to itself

#### Scenario: Version 1 cannot carry a clash
- **WHEN** a certificate with `"version": 1` and a `clash` member is parsed
- **THEN** parsing returns an error

### Requirement: Clash checker
`checkClash rules clashes g c` SHALL accept a certificate only when every node is accepted by the existing node checker under `rules`, the clash rule is in `clashes`, every premise id names an accepted node, the premises match the clash rule's body in order under one substitution, and every guard holds.

#### Scenario: A disjointness clash is accepted
- **WHEN** a graph states `ex:Cat owl:disjointWith ex:Dog`, `ex:tom rdf:type ex:Cat` and `ex:tom rdf:type ex:Dog`, and its clash certificate uses `cax-dw`
- **THEN** `checkClash owlRules owlClashRules` accepts it

#### Scenario: Tampered clash certificates are rejected
- **WHEN** a clash certificate names an unknown clash rule, a premise that is not a node, premises in the wrong order, premises that do not match the body, or a derived node the node checker rejects
- **THEN** `checkClash` returns an error

### Requirement: Clash checker soundness
`checkClash_sound` SHALL prove, for any class `C` under which every rule and every clash rule is sound, that an accepted clash certificate gives `¬ ∃ I, C I ∧ ∃ A, ∀ t ∈ g, I.Holds A t`. `checkClash_sound_owl` SHALL instantiate it as `¬ ∃ I : DInterp, I.IsOWL ∧ I.Satisfies g` and `checkClash_sound_rdfs` as `¬ ∃ I : DInterp, I.IsRDFS ∧ I.Satisfies g`. `checkClash_explodes_owl` SHALL derive `g.OWLEntails q` for every `q`. All of them SHALL use no axiom beyond `propext`, `Classical.choice` and `Quot.sound`.

#### Scenario: An accepted clash proves unsatisfiability
- **WHEN** the checker accepts the `cax-dw` clash certificate above
- **THEN** a Lean theorem `¬ ∃ I : DInterp, I.IsOWL ∧ I.Satisfies g` is obtained from it

#### Scenario: Explosion is a theorem
- **WHEN** the same certificate is accepted
- **THEN** `g.OWLEntails q` is obtained for the unrelated query `ex:moon rdf:type ex:Cheese`

#### Scenario: Clash theorems are axiom-clean
- **WHEN** the axioms of `checkClash_sound`, `checkClash_sound_owl`, `checkClash_sound_rdfs` and `checkClash_explodes_owl` are printed
- **THEN** they are among `propext`, `Classical.choice` and `Quot.sound`

### Requirement: Clash search
The Elpi bridge SHALL generate the clash rules from Lean, search for a clash after saturation, and turn the first one found into a pruned clash certificate whose nodes are exactly those the clash premises need, numbered so that premises precede conclusions. When no clash is found, the search SHALL return none and make no claim of consistency.

#### Scenario: A derived clash is found
- **WHEN** the graph states `ex:Cat owl:disjointWith ex:Dog`, `ex:Kitten rdfs:subClassOf ex:Cat`, `ex:tom rdf:type ex:Kitten` and `ex:tom rdf:type ex:Dog`
- **THEN** the search returns a clash certificate using `cax-dw` whose nodes include `ex:tom rdf:type ex:Cat` by `rdfs9`, and the checker accepts it

#### Scenario: A consistent graph gives no clash
- **WHEN** the pets example graph is searched
- **THEN** no clash is returned

### Requirement: Inconsistent verdict
`leanrdf-demo`, `leanrdf-oxilite` (with `--profile owl`) and `leanrdf-classify` SHALL search for a clash before reporting any entailment or subsumption. When the checker accepts a clash certificate, they SHALL print `INCONSISTENT` with the clash rule and its premises, write the certificate to `--cert` when given, report no entailment, and exit 4. With `--json`, the verdict SHALL be `"inconsistent"`. A rejected clash certificate SHALL exit 2.

#### Scenario: The demo reports an inconsistent graph
- **WHEN** `leanrdf-demo --profile owl` runs on the cat-and-dog graph with any query
- **THEN** it prints `Verdict: INCONSISTENT`, names `cax-dw`, prints no ENTAILED verdict and exits 4

#### Scenario: oxilite's answers on an inconsistent graph are not certified
- **WHEN** `leanrdf-oxilite --profile owl` runs on a recording whose data is inconsistent
- **THEN** it exits 4 and certifies none of oxilite's answers

### Requirement: Inconsistency test corpus
The tests SHALL cover each OWL 2 RL clash rule with a positive and a tampered certificate, the datatype clash, the W3C OWL 2 test cases of type inconsistency that fall into the fixed-arity fragment, and a runnable example `examples/inconsistency/` with recorded outputs checked by `scripts/examples.sh`.

#### Scenario: Every clash rule is exercised
- **WHEN** the clash tests run
- **THEN** each of the twelve OWL 2 RL clash rules and `dClashString` has an accepted certificate and a rejected tampered variant

#### Scenario: W3C inconsistency cases in the fragment
- **WHEN** the selected W3C OWL 2 inconsistency tests are run through the clash search and checker
- **THEN** each is reported INCONSISTENT with an accepted certificate, and the cases outside the fragment are listed with the reason
