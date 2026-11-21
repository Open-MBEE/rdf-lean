## Why

LeanRDF certifies that a query follows from a graph. If the graph has no model, every query follows, so every certificate is still correct but carries no information. Today no tool can notice this. `owlRLRules` leaves out every OWL 2 RL rule that concludes `false` ([[simplifications#OWL 2 RL without list rules and inconsistency rules]]). So an agent can receive ENTAILED for a knowledge base that contradicts itself, and act on it. The roadmap ([`docs/ROADMAP.md`](../../../docs/ROADMAP.md), F4, gap 4) names this as the most dangerous gap for agents.

This change adds the missing verdict, **INCONSISTENT**. As with entailment, it is found by an untrusted search and decided by a verified checker. An accepted clash certificate proves that no OWL interpretation satisfies the graph.

## What Changes

- **Clash rules.** A new rule kind, `ClashRule`: a Horn body with guards and no head. `ClashRule.SoundIn C` says that no interpretation of class `C` makes an instance of the body true. Clash rules are a separate list, not `Rule` values with a sentinel head, so `Derives` and every existing soundness theorem stay untouched.
- **OWL 2 RL clash rules.** The fixed-arity OWL 2 RL/RDF rules with conclusion `false` (OWL 2 Profiles §4.3, Tables 4–6): `cax-dw`, `cls-nothing2`, `cls-com`, `cls-maxc1`, `cls-maxqc1`, `cls-maxqc2`, `prp-irp`, `prp-asyp`, `prp-pdw`, `prp-npa1`, `prp-npa2`, `eq-diff1`. Each is proven sound against `OWLCore`.
- **New OWL conditions.** `OWLConds` gains the OWL 2 RDF-Based §5 conditions these rules need: `owl:disjointWith`, `owl:complementOf`, `owl:propertyDisjointWith`, `owl:differentFrom`, irreflexive and asymmetric properties, negative property assertions, and cardinality zero. The non-vacuity model in `OwlTests/Model.lean` is extended so that it still satisfies them.
- **Datatype clash.** The one D-clash expressible over the recognised datatypes: a literal typed `rdf:langString` or `rdf:dirLangString` without a language tag is ill-typed, and a graph that types it with its datatype has no D-interpretation. This is subject to the design's check that `DInterp` already forces it (see Risks).
- **Clash certificates.** A certificate in the version-2 envelope ([[openspec:certificates#Certificate format]], from `add-certificate-envelope`) may carry a `clash` member: the name of a clash rule and the ids of its premise nodes. The ordinary node checker validates the DAG beneath it.
- **Clash checker.** `checkClash` with `checkClash_sound` (accepted ⇒ `¬ ∃ I, I.IsOWL ∧ I.Satisfies g`) and the corollary `checkClash_explodes` (accepted ⇒ `g.OWLEntails q` for every `q`), so the vacuity is stated as a theorem rather than as prose.
- **Search.** The Elpi bridge generates the clash rules, saturates as usual, and reports the first clash instance as a pruned clash certificate.
- **`leanrdf-demo --profile rdfs|owl`.** The demo gains the OWL profile that `leanrdf-oxilite` already has (default `rdfs`), so an OWL clash can be found and shown from the demo.
- **Verdict INCONSISTENT, exit 4.** `leanrdf-demo`, `leanrdf-oxilite` (`--profile owl`) and `leanrdf-classify` search for a clash before anything else. When the checker accepts one, they print `INCONSISTENT`, exit `4`, and do not report any entailment. `leanrdf-check` accepts clash certificates and exits `4` when it verifies one. In JSON output, the verdict is `"inconsistent"`.

## Capabilities

### New Capabilities

- `inconsistency`: clash rules and their soundness, the datatype clash, clash certificates, the clash checker and its soundness and explosion theorems, clash search, the INCONSISTENT verdict across the tools, and the test corpus.

### Modified Capabilities

- `owl-rl`: `OWL conditions` gains the conditions above; `OWL non-vacuity` requires the extended model; new requirements `OWL 2 RL clash rules` and `OWL clash soundness`.
- `certificate-check` (introduced by `add-certificate-check`): `leanrdf-check` verifies clash certificates and maps them to exit 4.

The release (`v0.5.0`) is recorded in `add-countermodels`, which ships together with this change.

## Impact

**Roadmap:** third of seven changes, after [[changes#add-certificate-check]] and [[changes#add-certificate-envelope]] (both still to be recorded in `tg.md/changes.md`), and before `add-countermodels`. F4 in `docs/ROADMAP.md`. Ships in v0.5.0 with F5.

**Code:**
- core `leanrdf`: `LeanRDF/Entailment/Clash.lean` (`ClashRule`, `ClashRule.SoundIn`, the datatype clash and its soundness), `LeanRDF/Cert/Clash.lean` (`checkClash`, soundness), `LeanRDF/Cert/Json.lean` (the `clash` member)
- `leanrdf-owl`: `LeanRDFOwl/{Vocab,Semantics,Clash,ClashSoundness}.lean`, `OwlTests/{Model,Clash}.lean`
- `leanrdf-elpi`: clash rule codegen, clash search in `Certify.lean`, exit 4 in `Demo.lean`, `OxiliteMain.lean`, `ClassifyMain.lean`
- `leanrdf-check` (`check/`): clash certificates, exit 4
- docs: `site/content/docs/{certificates,cli,owl}.md`, book chapter on OWL, `examples/inconsistency/`

**tg.md sections touched:**
- simplification [[simplifications#OWL 2 RL without list rules and inconsistency rules]]: narrowed to the list rules (`eq-diff2`, `eq-diff3`, `prp-adp`, `cax-adc`) and the `dt-*` rules
- simplification [[simplifications#A subset of the OWL 2 RDF-Based conditions]]: the vocabulary list shrinks by the conditions added here
- simplification [[simplifications#Three recognized datatypes with abstract values]]: states which D-clashes are covered
- decision [[decisions#OWL 2 RL as sound rules over a subset of the RDF-Based conditions]]: amended by the new decisions *Clash rules are a separate rule kind* and *Inconsistency is checked before entailment*
- decision [[decisions#Demo never claims non-entailment]]: unchanged, cited by the new exit code
- decision [[decisions#Horn rules matched by the checker]]: the clash checker reuses `matchBody`
- concepts: new `Clash certificate` concept

**Binding decisions and constraints** (from `tg cypher` over `motivated_by` and `constrains`):
- [[constraints#OWL 2 RDF-Based Semantics]] and [[constraints#OWL 2 RL rules]] constrain [[decisions#OWL 2 RL as sound rules over a subset of the RDF-Based conditions]], and through it every condition and rule added here
- [[decisions#Axiom-clean library]]: the new theorems use only `propext`, `Quot.sound` and `Classical.choice`
- [[decisions#Semantics tested against vacuity]]: the extended conditions need a model

**Requirements:**
- added: `inconsistency#Clash rules`, `#Datatype clash`, `#Clash certificates`, `#Clash checker`, `#Clash checker soundness`, `#Clash search`, `#Inconsistent verdict`, `#Inconsistency test corpus`
- added: `owl-rl#OWL 2 RL clash rules`, `owl-rl#OWL clash soundness`, `certificate-check#Clash certificate checking`
- modified: [[openspec:owl-rl#OWL conditions]], [[openspec:owl-rl#OWL non-vacuity]]
- depends on: [[openspec:certificates#Checker]], [[openspec:certificates#Certificate format]], [[openspec:owl-rl#OWL soundness]]
