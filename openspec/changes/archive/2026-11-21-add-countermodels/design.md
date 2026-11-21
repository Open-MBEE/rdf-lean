## Context

- **What a "no" must prove.** `g.RDFSEntails q` is `∀ I : DInterp, I.IsRDFS → I.Satisfies g → I.Satisfies q`. Refuting it means exhibiting one RDFS interpretation that satisfies `g` and not `q`. `Tests/Semantics/` already does this by hand for three non-entailments, through a parametric small model over `Term` ([[decisions#Small-model family for vacuity]]).
- **Why the model cannot be finite.** `IT` is injective on `IR × IP × IR`. `langVal`, `dirLangVal` and `strVal` are injective. Once `IR` has two elements, the carrier is infinite ([[decisions#Small models become free triple-term extensions]]). The RDF and RDFS conditions also quantify over every `rdf:_n` and every literal.
- **The house rule.** Untrusted engines find, and a small verified checker decides ([[decisions#Elpi finds, Lean checks]]). A completeness proof for the rule set is not available and not needed, because a found countermodel is checked on its own.
- **Universe.** `Entails` quantifies over interpretations in `Type` ([[simplifications#Interpretations in universe zero]]). A countermodel in `Type` refutes the Lean definition, and it is also an interpretation in the W3C sense, so the refutation transfers.
- **Datatypes.** `RDFEntails` and `RDFSEntails` recognize exactly `xsd:string`, `rdf:langString` and `rdf:dirLangString` ([[simplifications#Three recognized datatypes with abstract values]]). A refutation is a refutation *for that D*. Under a larger D an entailment can appear: an ill-typed `xsd:integer` literal makes `g` unsatisfiable, so it entails everything. The verdict must say so.

## Goals / Non-Goals

**Goals:**
- A theorem `¬ g.SimpleEntails q`, `¬ g.RDFEntails q` or `¬ g.RDFSEntails q` from a checked, finite object.
- One finite object format covering the infinite vocabularies honestly, with every universally quantified condition discharged by proof, not by sampling.
- An untrusted finder that succeeds on the common cases: missing class memberships, missing subclass and subproperty links, missing property values.
- REFUTED verdicts in `leanrdf-check` and `leanrdf-demo`.

**Non-Goals:**
- OWL 2 RL or EL countermodels. `OWLConds` would need its own lifting lemmas; this is a later change.
- A completeness theorem for `rdfsRules`.
- Countermodels for D beyond the three recognized datatypes.
- Minimal countermodels, or explanations of *why* a model refutes.

## Decisions

### Countermodels as finite presentations

A countermodel is a `Presentation`, a finite description whose meaning is an infinite interpretation over a free carrier.

```lean
inductive CDom
  | base (i : Nat)                 -- a named sort's own element
  | lit (l : Literal)              -- literals denote themselves (tags lowercased)
  | tt (x y z : CDom)              -- IT, free

inductive SortKind | base | string | lang | dirLang | otherLit | triple

structure Presentation where
  sorts      : Array (SortKind × Bool × Bool)      -- kind, IR, IP
  iris       : List (IRI × Nat)                     -- IS on listed IRIs
  defaultIri : Nat                                  -- IS on every other IRI
  defaultCmp : Nat                                  -- IS on every unlisted rdf:_n
  litDefault : SortKind → Nat                       -- string, lang, dirLang, otherLit
  litOverride: List (Literal × Nat)                 -- named literals with their own sort
  tripleSort : Nat
  ext        : List (Nat × Nat × Nat)               -- IEXT over sorts
  assign     : List (BlankNode × Nat)               -- A on g's blank nodes
```

`sortOf : CDom → Nat` sends `base i` to `i`, `lit l` to its override or its kind's default, and `tt …` to `tripleSort`. Then `IR x := (sorts[sortOf x]).IR`, `IP` the same, and `IEXT p x y := (sortOf p, sortOf x, sortOf y) ∈ ext`. `IS` and `IL` follow the tables. `IL l := some (lit (normalize l))`, where `normalize` lowercases tags.

- **Rejected: a truly finite carrier.** It cannot satisfy injective `IT` or the injective value maps.
- **Rejected: extending the `Params` small-model family.** It fixes most classes to "everything" and cannot express a canonical model of an arbitrary graph.
- **Rejected: a proven interpolation-lemma decider for simple entailment only.** It is valid for one regime and gives no route to RDF or RDFS.

- motivated_by:: [[decisions#Small models become free triple-term extensions]] {weight: primary}
- motivated_by:: [[decisions#Elpi finds, Lean checks]] {weight: primary}
- motivated_by:: [[constraints#Simple interpretations]]

### Sort-level conditions with lifting lemmas

The checker evaluates each regime condition on the finite sort structure. For every condition, a lifting lemma proves that the sort-level form implies the carrier-level form.

Every condition in `SimpleInterp`, `RDFConditions` and `RDFSConditions` is one of three shapes:
1. **Equality-free over IR, IP, IEXT and the named elements** (domain, range, subclass and subproperty conditions, `IP_iff`, `resource`, `proposition`, the finite axiom lists). These hold on the carrier iff they hold on the *inhabited* sorts, because every relation factors through `sortOf`.
2. **Structural** (`IT_inj`, `IT_wt`, the injectivity of `strVal`, `langVal` and `dirLangVal`, `IL_lang`, `IL_dirLang`, `IL_str`). These follow from constructor injectivity and the definition of `IL`, with no table check beyond `tripleSort` being IR.
3. **Kind-characterizations** (`string_class`, `langString_class`, `dirLangString_class` and their RDFS `_ext` forms: membership in the datatype class iff a literal value of that kind). These lift because the checker requires every sort to be *kind-pure*. A sort of kind `string` contains only `xsd:string` literals, and every `xsd:string` literal is in a sort of kind `string`. The sort-level form is then "`(type, σ, sort(xsd:string)) ∈ ext` iff `kind σ = string`".

**Inhabitation.**
- A `base` sort is inhabited by `base i`.
- A literal-kind default sort is inhabited by the infinitely many literals of its kind that are not overridden.
- An override sort must be the target of at least one override. The checker rejects an override sort that also receives a different kind.
- `tripleSort` is inhabited by `tt`.

Every sort is therefore inhabited, and "for all sorts" is equivalent to "for all elements".

**Infinite families.**
- `axioms_member` and `member_axioms` (∀ n) split into the listed `rdf:_n` (checked one by one) and every other `n` (checked once on `defaultCmp`).
- Literal conditions split into overrides and kind defaults.
- Triple-term conditions are checked once on `tripleSort`.

- motivated_by:: [[constraints#RDF 1.2 RDF interpretations]] {weight: primary}
- motivated_by:: [[constraints#RDF 1.2 RDFS conditions]] {weight: primary}
- motivated_by:: [[constraints#RDFS interpretation conditions]]
- motivated_by:: [[decisions#Layered interpretations with a core]]

### Exhaustive sort search for the query

`¬ I.Satisfies q` quantifies over every assignment `A : BlankNode → CDom` into `IR`. `Holds A t` depends only on `sortOf ∘ A`, by the lemma `holds_sortOf`: the denotation of a triple term is always `tt`, whose sort is fixed, and `ITon` depends only on the IR and IP flags. So the checker enumerates assignments of IR sorts to `q`'s blank nodes by backtracking over the triples of `q`, and fails as soon as one assignment satisfies `q`. The completeness of this search, "returns `none` ⇒ no sort assignment works", is a proven lemma of the checker. It is the only search inside the trusted base.

- **Rejected: requiring the finder to supply a proof of non-satisfaction.** Non-satisfaction is a universal claim, and the checker would have to verify it by the same enumeration anyway.
- **Bound.** The cost is at most `|IR sorts|^|bnodes q|`, pruned by triple order. The checker takes a step budget. Exhausting it is a rejection (exit `2` from `leanrdf-check`, UNKNOWN from the demo), never a verdict.

- motivated_by:: [[constraints#Entailed blank nodes are existential]] {weight: primary}

### Canonical presentation from the closure

The finder in `leanrdf-elpi` saturates `g` under the regime's rules (generalized RDF, [[constraints#Entailment rules use generalized RDF]]), then makes:
- one sort per closure term (blank nodes of `g` included, which also gives `assign`);
- the default sorts for strings, language strings, directional strings, other literals, triple terms, unlisted IRIs and unlisted `rdf:_n`;
- `ext` from the closure triples, plus the triples the infinite families force on the defaults (`defaultCmp rdf:type rdfs:ContainerMembershipProperty`, `rdfs:subPropertyOf rdfs:member`, the domain and range axioms; literal defaults in their datatype class, in `rdfs:Literal` and in `rdfs:Resource`; `tripleSort` in `rdfs:Proposition` and `rdfs:Resource`).

The default sorts are representative terms added to the graph and saturated with it.

This is the Herbrand model of the closure. It refutes `q` exactly when the closure has no instance of `q`. **It satisfies the regime's conditions only where the rule set is complete.** Where a recorded simplification loses completeness, for example [[simplifications#Datatype rules see asserted positions only]] or [[simplifications#Container axioms only for occurring rdf:_n]], the checker rejects the candidate on the violated condition and the verdict stays UNKNOWN. A wrong REFUTED is impossible; a missing one is expected.

- motivated_by:: [[decisions#Forward-chaining saturation in Elpi]]
- motivated_by:: [[decisions#Small-model family for vacuity]] {note: "checking one canonical model is not a completeness proof"}

### REFUTED is relative to the recognized datatypes

A REFUTED verdict prints the regime and "with D = {xsd:string, rdf:langString, rdf:dirLangString}". The JSON verdict carries `"datatypes"`. A countermodel also proves `g` satisfiable in the regime (`checkCountermodel_consistent`), so REFUTED and INCONSISTENT ([[changes#add-inconsistency-certificates]]) can never both be returned for one graph. When a clash certificate exists, the verdict is INCONSISTENT, and the finder is not run.

- motivated_by:: [[decisions#Three recognized datatypes with abstract values]] {weight: primary}
- amends:: [[decisions#Demo never claims non-entailment]] {note: "the demo claims non-entailment only from a checked countermodel"}

### All triple terms share one sort

Every element `tt x y z` has the sort `tripleSort`, so a presentation cannot put two triple terms in different classes. Countermodels that need to distinguish propositions are not expressible and are not found. This loses refutations, never soundness. It is recorded as a `Simplification` with impact `incompleteness`. A later change can key triple-term sorts by the sorts of their components, which keeps `IT` injective because `tt` stays free.

- motivated_by:: [[constraints#Triple-term denotation]]

## Constraints

- [[constraints#Simple interpretations]] binds `Presentation.interp`: a non-empty IR, `IEXT` well-typed into IP × IR × IR, `IS` into IR ∪ IP, `IL` into IR.
- [[constraints#RDF 1.2 RDF interpretations]] and [[constraints#RDF 1.2 RDFS conditions]] bind the sort-level conditions and their lifting lemmas.
- [[constraints#Entailed blank nodes are existential]] binds the query search: `q`'s blank nodes range over all of IR, not only named sorts.
- New constraint **W3C negative entailment tests**: the RDF 1.2 semantics suite's `NegativeEntailmentTest` entries state non-entailments. It binds `countermodels#Negative entailment conformance`.

## Risks / Trade-offs

- **[The lifting lemmas are the real work]** About 30 conditions, each needing a sort-level form and a proof. A transcription slip in a sort-level form would be caught by the lemma failing, not hidden. → Do simple first (6 fields), then RDF, then RDFS. Each regime is a separate milestone within the change.
- **[Kind-purity is subtle]** The `string_class` iff is where a careless design would be unsound: a base element in the `xsd:string` class that is not a string value. → Kind-purity is a checked well-formedness condition with its own lemma, and a test feeds a presentation that violates it and must be rejected.
- **[The query search is exponential]** → Step budget, backtracking by triple. Budget exhaustion is never a verdict.
- **[The canonical model often fails a condition]** Where the rules are incomplete, the finder produces candidates the checker rejects. → Report the failed condition. Track the rejection rate on the W3C suite and the examples. Do not weaken the checker.
- **[Refutations are relative to D3]** → Stated in every verdict and in the JSON, and recorded as a decision.
- **[Defaults that are too coarse]** All unlisted IRIs share one sort. If `q` names an IRI that `g` does not, the default sort may satisfy `q` in the canonical model where a finer model would not. → The finder lists every IRI of `q` as its own sort before saturating.
