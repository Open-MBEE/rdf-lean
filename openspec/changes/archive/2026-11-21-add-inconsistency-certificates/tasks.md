## 1. Clash rules and the checker (core)

- [x] 1.1 `LeanRDF/Entailment/Clash.lean`: `ClashRule`, `ClashRule.SoundIn`, `ClashRule.SoundIn.mono`; annotate `@tg: implements:: [[openspec:inconsistency#Clash rules]]`
- [x] 1.2 `Xsd.isStringLexical` (XML 1.1 `Char`), with a lemma characterising it; guard `illTypedString` in `Guard` with `Guard.check_sound`
- [x] 1.3 `DInterp.IsWellTyped` (the fallback: `strVal_none` would cascade into the core and OWL test models), plus a simplification; instead of `DInterp.strVal_none`, update `Tests/Semantics/SmallModel.lean` and every concrete `DInterp`; `dClashString` and `dClashString_sound` under `RDFSCore`; annotate `[[openspec:inconsistency#Datatype clash]]`
- [x] 1.4 `Certificate` gains `clash : Option ClashRef`; JSON reads and writes the `clash` member, version 2 only; annotate `[[openspec:inconsistency#Clash certificates]]`
- [x] 1.5 `LeanRDF/Cert/Clash.lean`: `checkClash`, `checkClashB`; annotate `[[openspec:inconsistency#Clash checker]]`
- [x] 1.6 `checkClash_sound` (general `C`), `checkClash_sound_rdfs`; annotate `[[openspec:inconsistency#Clash checker soundness]]`

## 2. OWL conditions and clash rules (`leanrdf-owl`)

- [x] 2.1 `Vocab`: `disjointWith`, `complementOf`, `propertyDisjointWith`, `differentFrom`, `IrreflexiveProperty`, `AsymmetricProperty`, `NegativePropertyAssertion`, `sourceIndividual`, `assertionProperty`, `targetIndividual`, `targetValue`, `onClass` (exists), `zero`
- [x] 2.2 `OWLConds` fields `disjointWith`, `complementOf`, `propDisjoint`, `differentFrom`, `irreflexive`, `asymmetric`, `npaIndividual`, `npaValue`, `maxCard0`, `maxQCard0`; `differentFrom` lemma; annotate `@tg: implements:: [[openspec:owl-rl#OWL conditions]]` (existing annotation stays)
- [x] 2.3 First check `owlAxioms` against the new vocabulary; extend `OwlTests/Model.lean` (custom classes and properties with empty extensions), the `differentFrom` model and the `disjointWith ⊭ sameAs` countermodel, without `native_decide`; annotate `[[openspec:owl-rl#OWL non-vacuity]]`
- [x] 2.4 `LeanRDFOwl/Clash.lean`: `owlClashRules` (twelve rules); annotate `[[openspec:owl-rl#OWL 2 RL clash rules]]`
- [x] 2.5 `LeanRDFOwl/ClashSoundness.lean`: one soundness proof per rule, `owlClashRules_sound`, `checkClash_sound_owl`, `checkClash_explodes_owl`, and `checkClash_sound_el` for the classifier; annotate `[[openspec:owl-rl#OWL clash soundness]]`

## 3. Search and tools (`leanrdf-elpi`, `leanrdf-check`)

- [x] 3.1 Clash search over the Elpi closure in Lean (`matchClash`, a backtracking join with `matchTPat` and `Guard.check`) instead of generated Elpi `clash` clauses; `guardSrc` maps the new guard to `fail`, since no derivation rule uses it
- [x] 3.2 `Certify.lean`: `clashCertificate` after saturation, pruned by the backward closure; annotate `[[openspec:inconsistency#Clash search]]`
- [x] 3.3 `leanrdf-demo --profile rdfs|owl` (default `rdfs`), and the clash check before entailment in `Demo.lean`, `OxiliteMain.lean` and `ClassifyMain.lean`: `INCONSISTENT`, exit 4, `--cert`, `--json` verdict `inconsistent`; annotate `[[openspec:inconsistency#Inconsistent verdict]]`
- [x] 3.4 `leanrdf-check`: clash certificates with `--rules owl|rdfs`, exit 4 or 2, the theorem name, `--query` with a clash is exit 3; annotate `[[openspec:certificate-check#Clash certificate checking]]`

## 4. Tests

- [x] 4.1 `Tests/Cert/Clash.lean` and `OwlTests/Clash.lean`: an accepted and a tampered certificate for every clash rule and for `dClashString`; JSON round trip; version-1 rejection; `#print axioms` pins
- [x] 4.2 Annotate each test with `@tg: verifies::` its scenario: `inconsistency#Clash rules#A clash rule has no head`, `#Existing theorems are untouched`, `#Datatype clash#An ill-typed string literal clashes`, `#A well-typed string does not clash`, `#Clash certificates#Clash certificate JSON round-trips`, `#Version 1 cannot carry a clash`, `#Clash checker#A disjointness clash is accepted`, `#Tampered clash certificates are rejected`, `#Clash checker soundness#An accepted clash proves unsatisfiability`, `#Explosion is a theorem`, `#Clash theorems are axiom-clean`, `#Clash search#A derived clash is found`, `#A consistent graph gives no clash`, `#Inconsistent verdict#The demo reports an inconsistent graph`, `#oxilite's answers on an inconsistent graph are not certified`, `#Inconsistency test corpus#Every clash rule is exercised`, `#W3C inconsistency cases in the fragment`; `owl-rl#OWL conditions#differentFrom excludes identity`, `#OWL non-vacuity#The clash conditions have a model`, `#OWL 2 RL clash rules#The twelve clash rules are present`, `#An irreflexive self-loop clashes`, `#OWL clash soundness#Clash soundness theorem`; `certificate-check#Clash certificate checking#A clash certificate is verified`, `#A tampered clash certificate is rejected`, `#JSON verdict for a clash`
- [x] 4.3 Select the W3C OWL 2 test cases of type inconsistency whose rules are in the fixed-arity fragment; vendor them with their licence; list the others with the reason; annotate `[[openspec:inconsistency#Inconsistency test corpus]]`
- [x] 4.4 An oxilite replay on inconsistent data for the bridge test, written by hand (no oxilite binary was available; `BridgeTests/data/oxilite/inconsistent/README.md` says so)

## 5. Docs and examples

- [x] 5.1 `examples/inconsistency/` (cat-and-dog, irreflexive parent, ill-typed string) with recorded outputs in `expected/`, run by `scripts/examples.sh`
- [x] 5.2 Site: `docs/certificates.md` (clash certificates), `docs/cli.md` (exit 4, `--profile` on the demo), `docs/owl.md` (clash rules), the OWL book chapter (explosion and why INCONSISTENT comes first)

## 6. tg.md and traceability

- [x] 6.1 `tg.md/decisions.md`: add *Clash rules are a separate rule kind*, *Clash certificates extend the envelope, not the node list*, *The OWL conditions for clash rules*, *The extended model stays a model*, *The datatype clash is about xsd:string only* and *Inconsistency is checked before entailment* as typed `Decision` sections with `- motivated_by::` and `- amends::` lines as in design.md
- [x] 6.2 `tg.md/constraints.md`: extend [[constraints#OWL 2 RL rules]] and [[constraints#OWL 2 RDF-Based Semantics]] with the clash rules and §5 sections, with `constrains` edges to the new decisions (tg resolves `openspec:` links from code, not from docs); add *Ill-typed literals have no denotation* and *OWL 2 inconsistency test suite*
- [x] 6.3 `tg.md/simplifications.md`: rename and narrow *OWL 2 RL without list rules and inconsistency rules* to the list and `dt-*` rules (update every `-- SIMPLIFICATION:` comment that cites it); shrink *A subset of the OWL 2 RDF-Based conditions*; state the covered D-clash in *Three recognized datatypes with abstract values*
- [x] 6.4 `tg.md/concepts.md`: a `Clash certificate` concept with `- defines::` lines; `tg.md/changes.md`: `add-inconsistency-certificates`; add `inconsistency` to the `openspec:` frontmatter of the file that explains it
- [x] 6.5 Run `tg check`, `tg ontology check` and `tg trace inconsistency --gaps`, `tg trace owl-rl --gaps`, `tg trace certificate-check --gaps`, and close every gap they report
