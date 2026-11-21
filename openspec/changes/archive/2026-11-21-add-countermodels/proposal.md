## Why

Every reasoning verdict LeanRDF gives today is ENTAILED or NOT DERIVED. The rules are proven sound, not complete, so "not derived" proves nothing ([[decisions#Demo never claims non-entailment]]). An agent then either treats "unknown" as "no", which is unsound, or never concludes "no", which makes it useless for policy checks. Roadmap feature F5 (`docs/ROADMAP.md`) closes this gap the way the project closes every gap: *untrusted finds, Lean checks*. An untrusted finder builds a countermodel, a verified model checker accepts it, and the result is a theorem `¬ g.RDFSEntails q`. No completeness proof of the rule set is needed.

This change ships together with [[changes#add-inconsistency-certificates]] as v0.5.0. Together they give the four verdicts PROVEN / REFUTED / UNKNOWN / INCONSISTENT.

## What Changes

- **Finite presentations of interpretations.** The vacuity tests showed that an injective `IT` and injective literal values force an infinite carrier ([[decisions#Small models become free triple-term extensions]]). A countermodel is therefore not a finite interpretation. It is a finite *presentation* of an infinite one:
  - a finite set of *sorts* with their kinds and IR/IP flags;
  - an IRI table, a default sort for unlisted IRIs and a default sort for unlisted `rdf:_n`;
  - literal sorts per kind, with a finite override table for named literals;
  - one sort for all triple terms;
  - an `IEXT` table over sorts;
  - a sort assignment for the blank nodes of `g`.

  The carrier is the free structure `base i | lit l | tt x y z`, and every relation is the pullback of the finite table along the sort map.
- **The interpretation of a presentation.** `Presentation.interp` builds a `SimpleInterp`. `Presentation.dinterp` builds a `DInterp`. `IT` is the `tt` constructor and literal values are the literals themselves, so injectivity holds by construction.
- **A verified model checker.** `checkCountermodel regime g q m` checks:
  - the well-formedness of `m` (sort kinds, inhabitation, overrides consistent with literal kinds);
  - the regime's conditions on the finite sort structure;
  - that the assignment satisfies `g`;
  - by exhaustive search over sort assignments, that no assignment satisfies `q`.
- **The theorems.** `checkCountermodel_sound_simple`, `checkCountermodel_sound_rdf` and `checkCountermodel_sound_rdfs` give `¬ g.SimpleEntails q`, `¬ g.RDFEntails q` and `¬ g.RDFSEntails q`. `checkCountermodel_consistent` gives that `g` has a model of the regime. All of them are axiom-clean.
- **The lifting lemmas.** Every regime condition (`SimpleInterp` fields, `RDFConditions`, `RDFSConditions`) holds on the carrier when its sort-level form holds on the finite table. These lemmas carry the soundness argument. They cover the infinite families (`rdf:_n` axioms, all literals, all triple terms) through the default sorts.
- **Countermodel JSON** (`"kind": "countermodel"`), readable by `leanrdf-check` and carried in the version-2 envelope of [[changes#add-certificate-envelope]].
- **An untrusted finder in `leanrdf-elpi`.** It builds the canonical presentation from the saturated closure: one sort per closure term, plus default sorts for strings, language strings, directional strings, other literals, triple terms, unlisted IRIs and unlisted `rdf:_n`. A rejected candidate means the finder failed, not that something is wrong.
- **Verdicts.**
  - `leanrdf-check --countermodel FILE` exits `5` REFUTED, or `2` on rejection.
  - `leanrdf-demo` tries a countermodel when no instance is derived. It prints "REFUTED" and exits `5` only when the model checker accepts. Otherwise it keeps "NOT DERIVED", exit `1`.
  - JSON `verdict` is `refuted`.
- **Scope, in order:** simple, then RDF, then RDFS. OWL countermodels are out of scope.

## Capabilities

### New Capabilities

- `countermodels`: finite presentations of interpretations, their meaning, the verified model checker and its soundness, the lifting lemmas, the countermodel JSON, the untrusted finder, and the W3C negative-entailment runs.

### Modified Capabilities

- `certificate-check`: accepts countermodels and reports REFUTED with exit `5`.
- `demo`: exit codes and verdicts gain REFUTED, still only from a checked object.
- `release`: every package declares `0.5.0`, and `v0.5.0` is published as the four-valued verdicts release (F4 + F5).

## Impact

**Roadmap:** F5 in `docs/ROADMAP.md`, fourth of the seven agentic changes. It comes after [[changes#add-certificate-check]], [[changes#add-certificate-envelope]] and [[changes#add-inconsistency-certificates]], and ships with the last as v0.5.0.

**Code:**
- core: `LeanRDF/Model/{Presentation,Interp,Lift,Check,Search,Json}.lean`, which add no dependency
- `check/`: `--countermodel` input and exit `5`
- `elpi/`: `LeanRDFElpi/Countermodel.lean` (the canonical presentation from the closure), demo verdict
- tests: `Tests/Model/`, the W3C RDF 1.2 semantics negative-entailment run in `elpi/BridgeTests/`
- docs: book chapter "Saying no", `site/content/docs/countermodels.md`, `examples/countermodels/`

**tg.md sections touched:**
- decisions bound: [[decisions#Demo never claims non-entailment]] (amended: REFUTED only from a checked countermodel), [[decisions#Small-model family for vacuity]] (its remark that "a canonical-closure model would amount to a completeness proof" holds for *proving* completeness; *checking* one model needs no such proof), [[decisions#Small models become free triple-term extensions]], [[decisions#Single-carrier interpretations]], [[decisions#Layered interpretations with a core]], [[decisions#Three recognized datatypes with abstract values]]
- constraints bound: [[constraints#Simple interpretations]], [[constraints#RDF 1.2 RDF interpretations]], [[constraints#RDFS interpretation conditions]], [[constraints#RDF 1.2 RDFS conditions]], [[constraints#Entailed blank nodes are existential]]
- simplifications that limit what REFUTED means: [[simplifications#Three recognized datatypes with abstract values]], [[simplifications#Interpretations in universe zero]]
- new: decisions *Countermodels as finite presentations*, *Sort-level conditions with lifting lemmas*, *Exhaustive sort search for the query*, *Canonical presentation from the closure*, *REFUTED is relative to the recognized datatypes*; a simplification *All triple terms share one sort*

**Requirements:**
- added: `countermodels#Model presentations`, `#Presentation interpretations`, `#Model checker`, `#Countermodel soundness`, `#Lifting lemmas`, `#Countermodel format`, `#Countermodel finder`, `#Negative entailment conformance`
- added to `certificate-check`: `#Countermodel input`
- modified: [[openspec:demo#Exit codes and verdicts]], [[openspec:release#Release version]]
- added to `release`: `#Four-valued verdicts release`
- depends on: [[openspec:rdf-semantics#Simple interpretations]], [[openspec:rdf-semantics#RDF interpretations]], [[openspec:rdf-semantics#RDFS interpretations]], [[openspec:rdf-semantics#Entailment relations]], [[openspec:elpi-bridge#Saturation]]
