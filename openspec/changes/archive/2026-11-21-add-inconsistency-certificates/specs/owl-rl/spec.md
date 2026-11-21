## MODIFIED Requirements

### Requirement: OWL conditions
`leanrdf-owl` SHALL define `OWLConds` over an RDFS interpretation, transcribing the OWL 2 RDF-Based Semantics §5 conditions for the vocabulary that the included rules and clash rules use, one field per condition, and `IsOWL` and `Graph.OWLEntails` from them. Since `add-inconsistency-certificates`, the fields SHALL include `owl:disjointWith`, `owl:complementOf` (the disjointness half), `owl:propertyDisjointWith`, `owl:differentFrom`, irreflexive and asymmetric properties, negative property assertions with a target individual and with a target value, and (qualified) cardinality zero. Every omitted condition SHALL be listed as a soundness-neutral simplification.

#### Scenario: sameAs is identity
- **WHEN** an interpretation satisfies `IsOWL`
- **THEN** `⟨x, y⟩ ∈ IEXT(I(owl:sameAs))` holds exactly when `x = y`, as a lemma

#### Scenario: differentFrom excludes identity
- **WHEN** an interpretation satisfies `IsOWL` and `⟨x, y⟩ ∈ IEXT(I(owl:differentFrom))`
- **THEN** `x ≠ y`, as a lemma

### Requirement: OWL non-vacuity
There SHALL be kernel-checked evidence that the OWL conditions, including those added for the clash rules, are satisfiable and not trivial: an interpretation satisfying `IsOWL` and a graph using `owl:inverseOf`, `owl:sameAs` and a someValuesFrom restriction, and at least two non-entailments proven by countermodels. Since `add-inconsistency-certificates`, there SHALL also be a model of a graph using `owl:differentFrom`, and a countermodel for `{c owl:disjointWith d} ⊭ {c owl:sameAs d}`.

#### Scenario: A model and two countermodels
- **WHEN** the vacuity tests are built
- **THEN** the model theorem and `¬ OWLEntails` theorems for `{p inverseOf q} ⊭ {p equivalentProperty q}` and `{a type C} ⊭ {a sameAs b}` are proven without `native_decide`

#### Scenario: The clash conditions have a model
- **WHEN** the vacuity tests are built after this change
- **THEN** the extended model satisfies `IsOWL` and `{ex:a owl:differentFrom ex:b}`, and `¬ OWLEntails` is proven for `{c owl:disjointWith d} ⊭ {c owl:sameAs d}`, without `native_decide`

## ADDED Requirements

### Requirement: OWL 2 RL clash rules
`owlClashRules` SHALL encode, as `ClashRule` values, the OWL 2 RL/RDF rules of OWL 2 Profiles §4.3 that have a fixed number of premises and conclusion `false`: `eq-diff1`, `prp-irp`, `prp-asyp`, `prp-pdw`, `prp-npa1`, `prp-npa2`, `cls-nothing2`, `cls-com`, `cls-maxc1`, `cls-maxqc1`, `cls-maxqc2` and `cax-dw`, each with the body of the specification in its order. `eq-diff2`, `eq-diff3`, `prp-adp`, `cax-adc` and `dt-not-type` SHALL be listed as simplifications.

#### Scenario: The twelve clash rules are present
- **WHEN** `owlClashRules` is listed
- **THEN** it has twelve rules with the names above, and each body matches OWL 2 Profiles Tables 4–6

#### Scenario: An irreflexive self-loop clashes
- **WHEN** a clash certificate uses `prp-irp` on `ex:parentOf rdf:type owl:IrreflexiveProperty` and `ex:a ex:parentOf ex:a`
- **THEN** `checkClash owlRules owlClashRules` accepts it

### Requirement: OWL clash soundness
Every rule in `owlClashRules` SHALL be proven sound against `OWLCore` as a `ClashRule`, with no `sorry` and only Lean's standard axioms, and `owlClashRules_sound` SHALL collect them.

#### Scenario: Clash soundness theorem
- **WHEN** the package is built
- **THEN** `owlClashRules_sound : ∀ r ∈ owlClashRules, r.SoundIn OWLCore` is a theorem, and `#print axioms` shows only `propext`, `Quot.sound` and `Classical.choice`
