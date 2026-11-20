## Context

- **The checker** (`LeanRDF/Cert/Check.lean`) accepts a proof DAG whose nodes are facts or `Rule` applications. `check_sound` turns acceptance into `Derives rules g t`, and `Derives.owl_sound_graph` turns that into `g.OWLEntails q`. Every `Rule` has a triple head, so nothing in the pipeline can conclude `false`.
- **OWL conditions** (`owl/LeanRDFOwl/Semantics.lean`). `OWLConds` already has `nothing : ∀ x, ¬ InClass x (IS owl:Nothing)` and `sameAs` as identity, but nothing for `owl:disjointWith`, `owl:complementOf`, `owl:propertyDisjointWith`, `owl:differentFrom`, `owl:IrreflexiveProperty`, `owl:AsymmetricProperty`, negative property assertions or cardinality zero. These are recorded as omitted in [[simplifications#A subset of the OWL 2 RDF-Based conditions]].
- **OWL 2 Profiles §4.3** lists the rules with conclusion `false`. Those with a fixed number of premises are `eq-diff1`, `prp-irp`, `prp-asyp`, `prp-pdw`, `prp-npa1`, `prp-npa2`, `cls-nothing2`, `cls-com`, `cls-maxc1`, `cls-maxqc1`, `cls-maxqc2` and `cax-dw`. The others (`eq-diff2`, `eq-diff3`, `prp-adp`, `cax-adc`) read an `rdf:List` of arbitrary length, and `dt-not-type` needs value spaces.
- **Datatypes.** `DInterp` recognises `xsd:string`, `rdf:langString` and `rdf:dirLangString`. `IL_str` maps `"s"^^xsd:string` to `strVal s`, which is documented as "partial for ill-typed strings", but no condition says *which* strings are ill-typed. RDF 1.1 Semantics §7 (kept by RDF 1.2) makes a graph that contains an ill-typed literal of a recognised datatype D-unsatisfiable.
- **Verdicts** are shared across the seven roadmap changes: exit 0 PROVEN, 1 NOT DERIVED, 2 rejected, 3 input error, **4 INCONSISTENT** (this change), 5 REFUTED (`add-countermodels`). The JSON verdicts are `proven`, `refuted`, `unknown`, `inconsistent`, `rejected` and `input-error`.

## Goals / Non-Goals

**Goals:**
- A verified, small checker for "this graph has no OWL model", sound by theorem.
- Every reasoning tool reports INCONSISTENT before it reports any entailment.
- The explosion stated as a theorem, so tools and documents can cite it.

**Non-Goals:**
- *Consistency* proofs. "No clash found" stays UNKNOWN. A positive consistency proof is a model, which is `add-countermodels`' territory and only for RDF/RDFS.
- List-premise clash rules (`eq-diff2/3`, `prp-adp`, `cax-adc`) and `dt-not-type`.
- Unsatisfiable *classes*. `leanrdf-classify` already reports them as subsumptions of `owl:Nothing`. A class with no instance does not make the graph inconsistent, so the classifier only exits 4 when a clash is found for the graph itself.
- Repair suggestions (minimal inconsistent subsets). The certificate's `fact` nodes are a sufficient, not minimal, explanation.

## Decisions

### Clash rules are a separate rule kind

```lean
structure ClashRule where
  name : String
  body : List TPat
  guards : List Guard := []

def ClashRule.SoundIn (C : SimpleInterp → Prop) (r : ClashRule) : Prop :=
  ∀ I, C I → ∀ (A : BlankNode → I.Dom) (σ : Subst),
    (∀ gd ∈ r.guards, gd.Holds σ) → ¬ ∀ b ∈ r.body, I.Holds A (b.apply σ)
```

**Alternatives rejected.**
- A reserved head triple such as `owl:Nothing rdf:type owl:Nothing` as "false": soundness would need `OWLConds` to make that triple unsatisfiable, the encoding would leak into `Derives`, and an ordinary query could ask for the sentinel.
- A `Rule` with `head : Option TPat`: this changes `Rule`, `Derives`, `Rule.SoundIn`, the Elpi codegen and every soundness proof in four packages.

**Reasons.** `Derives`, `check_sound` and the 140-odd rule soundness proofs stay untouched. The checker reuses `matchBody` and `Guard.check` ([[decisions#Horn rules matched by the checker]]).

- motivated_by: [[decisions#Horn rules matched by the checker]]
- motivated_by: [[decisions#Axiom-clean library]]

### Clash certificates extend the envelope, not the node list

A clash certificate is a version-2 certificate ([[openspec:certificates#Certificate format]], from `add-certificate-envelope`) whose `goals` list is empty and that carries `"clash": {"rule": "cax-dw", "premises": [3, 5, 6]}`. The header's `theorem` field reads `checkClash_sound`. Version 1 has no `clash` member, so a version-1 reader rejects these certificates instead of misreading them as query certificates with no goals.

```lean
def checkClash (rules : List Rule) (clashes : List ClashRule) (g : Graph) (c : Certificate) :
    Except String Unit
-- check every node (checkCert), find the clash rule by name, look up the premise ids,
-- matchBody against them, check the guards

theorem checkClash_sound {C} (hr : ∀ r ∈ rules, r.SoundIn C) (hc : ∀ r ∈ clashes, r.SoundIn C)
    (h : checkClash rules clashes g c = .ok ()) : ¬ ∃ I, C I ∧ ∃ A, ∀ t ∈ g, I.Holds A t
```

The general theorem is instantiated twice: under `OWLCore` with `owlRules` and `owlClashRules` (`checkClash_sound_owl : … → ¬ ∃ I : DInterp, I.IsOWL ∧ I.Satisfies g`), and under `RDFSCore` with `rdfsRules` and `[dClashString]` (`checkClash_sound_rdfs`). Explosion follows in one line: `checkClash_explodes_owl : … → ∀ q, g.OWLEntails q`.

**Alternative rejected.** A separate file format. Clash certificates need the same digests, rule-set id and toolchain fields as entailment certificates, and `leanrdf-check` already reads the envelope.

- motivated_by: [[decisions#Own certificate format with a Datalog export]]

### The new OWL conditions

`OWLConds` gains one field per condition, with the same discipline as before: only the direction the rules use, and each a consequence of the full §5 semantics.

| Field | §  | Statement (on resources) | Clash rule |
|---|---|---|---|
| `disjointWith` | 5.10 | `⟨c,d⟩ ∈ IEXT(owl:disjointWith) → ICEXT c ∩ ICEXT d = ∅` | `cax-dw` |
| `complementOf` | 5.4 | `⟨c,d⟩ ∈ IEXT(owl:complementOf) → ICEXT c ∩ ICEXT d = ∅` (the forward half of `ICEXT c = IR \ ICEXT d`) | `cls-com` |
| `propDisjoint` | 5.10 | `⟨p,q⟩ ∈ IEXT(owl:propertyDisjointWith) → IEXT p ∩ IEXT q = ∅` | `prp-pdw` |
| `differentFrom` | 5.10 | `⟨x,y⟩ ∈ IEXT(owl:differentFrom) → x ≠ y` | `eq-diff1` |
| `irreflexive` | 5.13 | `p ∈ ICEXT(owl:IrreflexiveProperty) → ⟨x,x⟩ ∉ IEXT p` | `prp-irp` |
| `asymmetric` | 5.13 | `p ∈ ICEXT(owl:AsymmetricProperty) → ⟨x,y⟩ ∈ IEXT p → ⟨y,x⟩ ∉ IEXT p` | `prp-asyp` |
| `npaIndividual` | 5.15 | an `owl:NegativePropertyAssertion` with source `i`, property `p` and target individual `j` excludes `⟨i,j⟩ ∈ IEXT p` | `prp-npa1` |
| `npaValue` | 5.15 | the same with `owl:targetValue` | `prp-npa2` |
| `maxCard0` | 5.6 | `IL("0"^^xsd:nonNegativeInteger) = n`, `⟨r,n⟩ ∈ IEXT(owl:maxCardinality)`, `⟨r,p⟩ ∈ IEXT(owl:onProperty)`, `x ∈ ICEXT r` → no `y` with `⟨x,y⟩ ∈ IEXT p` | `cls-maxc1` |
| `maxQCard0` | 5.6 | the qualified form, with `owl:onClass c` (and `owl:Thing` for `cls-maxqc2`) | `cls-maxqc1`, `cls-maxqc2` |

`cls-nothing2` uses the existing `nothing` field. `maxCard0` follows the existing `maxCard1` pattern, which assumes the literal denotes, through `IL zero = some n`, because nonNegativeInteger is not a recognised datatype ([[simplifications#Three recognized datatypes with abstract values]]).

- motivated_by: [[constraints#OWL 2 RDF-Based Semantics]]
- motivated_by: [[constraints#OWL 2 RL rules]]
- amends: [[decisions#OWL 2 RL as sound rules over a subset of the RDF-Based conditions]]

### The extended model stays a model

[[decisions#Semantics tested against vacuity]] requires a concrete interpretation of every condition set. `OwlTests/Model.lean` adds `IrreflexiveProperty`, `AsymmetricProperty` and `NegativePropertyAssertion` to `customClasses`, with empty extensions, and `disjointWith`, `complementOf`, `propertyDisjointWith`, `differentFrom`, `sourceIndividual`, `assertionProperty`, `targetIndividual` and `targetValue` to `customProps`, also with empty extensions. Every new field is an implication from a membership in an empty extension, so each holds vacuously. The existing model graph and both countermodels are unaffected. A new countermodel shows the conditions are not trivial: `{a owl:differentFrom b}` is satisfiable, and `{c owl:disjointWith d}` does not entail `{c owl:sameAs d}`.

**Risk.** `owlAxioms` may mention the new vocabulary (for example `owl:disjointWith rdfs:domain owl:Class`). Empty property extensions satisfy domain and range axioms, and the axioms only assert vocabulary-level triples, so the model needs the IRIs in `IR` and `IP`, not non-empty extensions. Task 2.3 checks this first.

- motivated_by: [[decisions#Semantics tested against vacuity]]

### The datatype clash is about xsd:string only

With the three recognised datatypes, the only ill-typed literals are `xsd:string` literals whose lexical form contains a code point outside XML 1.1 `Char` (U+0000, the surrogates U+D800–U+DFFF, U+FFFE and U+FFFF). `rdf:langString` and `rdf:dirLangString` literals always carry a tag in RDF 1.2 abstract syntax, so they are never ill-typed. `DInterp` gains one field:

```lean
strVal_none : ∀ s, ¬ Xsd.isStringLexical s → strVal s = none
```

This is the transcription of "IL is undefined on ill-typed literals" for `xsd:string`, which `IL_str` currently only gestures at. `Xsd.isStringLexical` is new: `LeanRDF.Xsd` has no lexical check for `xsd:string` yet. A new guard `illTypedString` (decided by `Xsd.isStringLexical`, with `Guard.check_sound`) and the clash rule `dClashString : ?s ?p ?o` with `illTypedString ?o` give the clash. Like GrdfD1, it sees only literals in object position of asserted triples ([[simplifications#Datatype rules see asserted positions only]]).

**Risk.** Adding a field to `DInterp` touches every concrete D-interpretation: the small models in `Tests/Semantics/SmallModel.lean` and their users. They define `strVal` as total (`some`). Each must become `if isStringLexical s then some … else none`, and `strVal_inj` re-proven. If that cascades beyond the semantics tests, the fallback is to put the condition in a new `DInterp.IsWellTyped` predicate that only `checkClash_sound_rdfs` assumes, recorded as a soundness-neutral simplification.

- motivated_by: [[constraints#RDF 1.2 RDF interpretations]]
- motivated_by: [[constraints#XSD datatypes]]

### Inconsistency is checked before entailment

Every reasoning tool runs the clash search on the saturated closure before it builds or prints any entailment certificate. When a clash certificate is accepted, it prints `Verdict: INCONSISTENT. The graph has no OWL model; every query follows from it.`, exits 4, and writes the clash certificate to `--cert` if given. A clash certificate the checker *rejects* is exit 2, as for any rejected certificate: the search has a bug. No clash found means no claim of consistency, so the tool goes on to entailment.

**Alternative rejected.** Reporting ENTAILED together with an INCONSISTENT warning. An agent that branches on the exit code would act on the vacuous answer, which is the very failure this change exists to prevent.

- motivated_by: [[decisions#Demo never claims non-entailment]]

### Clash search in Elpi

The codegen emits each clash rule as an Elpi clause `clash Name [P1, …, Pn] :- triple P1, …, guards`. It runs after saturation. The first solution is turned into a pruned certificate by the same backward closure that `Certify.lean` uses for goals: the premises of the clash become the goals. oxilite does not explain inconsistencies, so for `leanrdf-oxilite` the clash search always runs in Elpi on oxilite's data.

- motivated_by: [[decisions#Elpi finds, Lean checks]]
- motivated_by: [[decisions#Forward-chaining saturation in Elpi]]

## Constraints

- **OWL 2 Profiles §4.3** binds the bodies of the clash rules exactly, as for the derivation rules. Constrains `owl-rl#OWL 2 RL clash rules`.
- **OWL 2 RDF-Based Semantics §5.4, §5.6, §5.10, §5.13, §5.15** bind the new `OWLConds` fields. Constrains `owl-rl#OWL conditions`.
- **RDF 1.1 Semantics §7 / RDF 1.2 Semantics §7.1** (ill-typed literals have no denotation) and **XSD 1.1 Part 2 §3.3.1** (`xsd:string` lexical space = `Char*`) bind the datatype clash. Constrains `inconsistency#Datatype clash`.

## Risks / Trade-offs

- **Vacuity of a stronger `OWLConds`** → mitigated by the extended model (above). The new conditions are all negative, which makes a model easy to build. The risk is mostly in `owlAxioms`.
- **`DInterp` field cascade** → mitigated by the `IsWellTyped` fallback.
- **Clash in the RDFS regime is rare in practice.** With three datatypes, only control characters in `xsd:string` clash. Its value grows with F8 (D-entailment over XSD values), which will add clashes such as `"abc"^^xsd:integer`. The guard and rule shapes here are designed so that F8 only adds rules.
- **Search order.** A clash search on every query doubles saturation work in the worst case. Saturation is shared, so the extra cost is one clause query.
- **Reading `--profile owl` answers.** oxilite may still return answers for an inconsistent graph. The bridge reports INCONSISTENT and certifies none of them.

## Migration Plan

Additive. Existing certificates and theorems are unchanged. Exit 4 is new. Scripts that treated any non-zero, non-2 exit as "not derived" must handle it, as the release notes of v0.5.0 will say.

## Open Questions

- Should `leanrdf-classify` exit 4 when an OWL class with a declared instance is unsatisfiable? It will automatically, because that is a `cls-nothing2` clash on the graph. Classes without instances stay a classification result, not an inconsistency.
