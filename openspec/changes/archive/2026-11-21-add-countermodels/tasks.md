## 1. Presentations and their interpretations (core)

- [x] 1.1 `LeanRDF/Model/Presentation.lean` (with `toLower_toLower` and `isMemberIri_member`, proven with `omega`): `CDom`, `SortKind`, `Presentation`, `sortOf`, decidable `WellFormed` with located reasons (kind purity, inhabited overrides, indices in range); annotate `@tg: implements:: [[openspec:countermodels#Model presentations]]`
- [x] 1.2 `LeanRDF/Model/Interp.lean`: `Presentation.interp : SimpleInterp` and `Presentation.dinterp : DInterp`, with `IT := tt`, `IL` by `lit` with lowercased tags, the structural fields proven for every well-formed presentation; annotate `Presentation interpretations`
- [x] 1.3 `holds_sortOf`: `Holds A t` depends only on `sortOf ∘ A` (and on IR/IP flags for triple terms)

## 2. Lifting lemmas, one regime at a time

- [x] 2.1 Simple: sort-level forms of `IR_nonempty`, `IEXT_wt`, `IS_wt`, `IL_wt`, `IT_wt`, with lifting lemmas
- [x] 2.2 RDF: sort-level forms of every `RDFConditions` field; `axioms_member` through the listed `rdf:_n` and `defaultCmp`; kind-characterizations through kind purity
- [x] 2.3 RDFS: sort-level forms of every `RDFSConditions` field, `proposition` through `tripleSort`, the axiom lists, `member` axioms through `defaultCmp`
- [x] 2.4 Annotate `LeanRDF/Model/Lift.lean` with `@tg: implements:: [[openspec:countermodels#Lifting lemmas]]`; `{confidence: partial}` until 2.3 is done

## 3. Model checker and soundness

- [x] 3.1 In `LeanRDF/Model/Check.lean`: exhaustive enumeration (`assignments`) of IR-sort assignments for the blank nodes of `q`, bounded by a step budget; completeness lemma (`none` ⇒ no `A : BlankNode → CDom` into IR satisfies `q`)
- [x] 3.2 `LeanRDF/Model/Check.lean`: `checkCountermodel regime g q m` with located errors; annotate `Model checker`
- [x] 3.3 `checkCountermodel_sound_simple`, `_rdf`, `_rdfs`, `checkCountermodel_consistent`; `#print axioms` pinned in tests; annotate `Countermodel soundness`
- [x] 3.4 `LeanRDF/Model/Json.lean`: countermodel JSON (`"kind": "countermodel"`) render and parse, N-Triples terms; payload of the version-2 envelope; annotate `Countermodel format`

## 4. Finder and tools

- [x] 4.1 `LeanRDF/Model/Canonical.lean` (pure builder, in the core so recorded models can be tested there) and `elpi/LeanRDFElpi/Countermodel.lean` (saturation): canonical presentation from the closure (query IRIs listed, default sorts saturated with `g`, closure as `IEXT`, bnode assignment); annotate `@tg: implements:: [[openspec:countermodels#Countermodel finder]]`
- [x] 4.2 `check/`: `--countermodel FILE` and envelope payloads, exit `5`, `--json` verdict `refuted` with `datatypes` and `theorem`; OWL and EL regimes rejected with exit `3`; annotate `@tg: implements:: [[openspec:certificate-check#Countermodel input]]`
- [x] 4.3 `leanrdf-demo`: try the finder when no instance is derived; REFUTED exit `5` only on acceptance; report the failed condition otherwise; `--countermodel OUT.json`; annotate `@tg: implements:: [[openspec:demo#Exit codes and verdicts]]` (modified)
- [x] 4.4 Order with [[changes#add-inconsistency-certificates]]: run the clash check first, and never run the finder on an inconsistent graph

## 5. Tests

- [x] 5.1 `Tests/Model/Countermodels.lean` (one file for 5.1 to 5.6, on countermodels recorded from the finder in `Tests/data/model/`): well-formed and impure presentations; `@tg: verifies::` `Model presentations` › `A well-formed presentation is accepted`, `Impure kinds are rejected`
- [x] 5.2 `Tests/Model/Interp.lean`: `IT is injective by construction`, `Literal values are injective`
- [x] 5.3 `Tests/Model/Lift.lean`: `The rdf:_n axioms lift`, `Datatype classes lift through kind purity`, `A violated sort-level condition is detected`
- [x] 5.4 `Tests/Model/Check.lean`: `subClassOf is not symmetric`, `A model of q is rejected`, `A model that misses g is rejected`, `Budget exhaustion is not acceptance`
- [x] 5.5 `Tests/Model/Soundness.lean`: `An accepted countermodel gives non-entailment`, `Refuting RDFS refutes the weaker regimes`, `Countermodel theorems are axiom-clean`, `The hand-built vacuity countermodels are reproduced`
- [x] 5.6 `Tests/Model/Json.lean`: `Countermodel JSON round-trips`
- [x] 5.7 `elpi/BridgeTests/Countermodel.lean`: `The finder refutes a missing type`, `A rejected candidate gives UNKNOWN`
- [x] 5.8 W3C RDF 1.2 semantics runner: negative tests refuted or reported, positive tests never refuted; `Negative tests are refuted or reported`, `Positive tests are never refuted`; annotate the runner `@tg: implements:: [[openspec:countermodels#Negative entailment conformance]]`
- [x] 5.9 `check/` tests: `An accepted countermodel exits 5`, `A forged countermodel exits 2`, `OWL countermodels are an input error`
- [x] 5.10 Demo tests: `Not derived is not non-entailment`, `A checked countermodel gives REFUTED`, and the unchanged exit `2` and `3` scenarios
- [x] 5.11 Every test above carries `@tg: verifies:: [[openspec:<capability>#<Requirement>#<Scenario>]]` directly above it

## 6. Docs, typed graph and release v0.5.0

- [x] 6.1 Record in `tg.md/decisions.md` (`type: Decision`): *Countermodels as finite presentations*, *Sort-level conditions with lifting lemmas*, *Exhaustive sort search for the query*, *Canonical presentation from the closure*, *REFUTED is relative to the recognized datatypes*, with `motivated_by::` edges as in design.md; `amends:: [[decisions#Demo never claims non-entailment]]`
- [x] 6.2 Record the constraint *W3C negative entailment tests* in `tg.md/constraints.md` with `- constrains:: [[openspec:countermodels#Negative entailment conformance]] {strength: must}`
- [x] 6.3 Record the simplification *All triple terms share one sort* in `tg.md/simplifications.md` (`impact:: incompleteness`, `deviates_from:: [[constraints#Triple-term denotation]]`); code carries `-- SIMPLIFICATION:` naming it
- [x] 6.4 Add `countermodels` to the `openspec:` frontmatter of the lat.md file that explains it; add `add-countermodels` to `tg.md/changes.md`
- [x] 6.5 `site/content/docs/countermodels.md`, the book chapter "Saying no", `examples/countermodels/` with recorded outputs run by `scripts/examples.sh`; update the site roadmap and `docs/ROADMAP.md`
- [x] 6.6 Versions bumped to `0.5.0` in all seven lakefiles; release notes `docs/releases/v0.5.0.md` (four verdicts, theorems, D3 caveat, trust base); annotate lakefiles for `release#Release version`
- [x] 6.8 Tag and publish `v0.5.0` after archiving F4 and F5, on the owner's go-ahead (`release#Four-valued verdicts release`)
- [x] 6.7 Builds and tests in all packages; `tg check`, `tg ontology check`, `tg trace countermodels --gaps`, `tg trace certificate-check --gaps`, `tg trace demo --gaps` and `tg trace release --gaps`; close every gap they report
