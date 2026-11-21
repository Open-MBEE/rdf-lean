# Saying No With Proof

### LeanRDF 0.5 gives agents four answers: proven, refuted, inconsistent, and an honest "don't know". Each of the first three is a theorem.

---

In *A Proof Is Not Enough* I described how LeanRDF 0.4 made answers proof-carrying. An agent that derives a fact can hand over a certificate. Anyone can check it with a small verified program, and the certificate says which data it is about.

That covered only one kind of answer: **yes**. Every other answer was the same shrug, `NOT DERIVED`. The rules are proven sound, not complete, so "I did not derive it" proves nothing. It might be false. It might be true by an argument the rules do not find. Or the data might be so broken that *everything* follows from it.

An agent cannot act on a shrug. "Is this account frozen?" "Is this user an admin?" "Is Tom a dog?" Each of these needs a no that is as solid as the yes. LeanRDF 0.5 adds two negative answers. Both are checked by the kernel, and the search that finds them is never trusted:

| Verdict | Exit | Backed by |
|---|---|---|
| PROVEN | 0 | a certificate the verified checker accepts |
| REFUTED | 5 | a countermodel the verified model checker accepts |
| UNKNOWN (not derived) | 1 | nothing: neither was found |
| INCONSISTENT | 4 | a clash certificate the verified checker accepts |

0.4 already reserved exit codes 4 and 5. 0.5 gives them meaning.

---

## Part one: data that contradicts itself

Start with the worse case. A graph with **no model** entails every query. That is not a quirk of LeanRDF. It is what entailment means: if no world makes the data true, then every world that makes the data true also makes the query true, vacuously. So on inconsistent data a proof of entailment carries no information. A reasoner that answers "yes, proven" there is technically right and practically lying.

Here is a small inconsistent graph:

```
ex:Cat    owl:disjointWith ex:Dog .
ex:Kitten rdfs:subClassOf  ex:Cat .
ex:tom    rdf:type         ex:Kitten .
ex:tom    rdf:type         ex:Dog .
```

Tom is a kitten, kittens are cats, cats and dogs are disjoint, and Tom is a dog. Ask "is Tom a fish?" under OWL, and an honest reasoner should refuse to answer:

```
$ leanrdf-demo cats.nt query-tom-fish.nt --profile owl
Clash: cax-dw on nodes [0, 4, 2]
Certificate: 5 nodes
  [0] ex:Cat owl:disjointWith ex:Dog                   (fact)
  [2] ex:tom rdf:type ex:Dog                           (fact)
  [4] ex:tom rdf:type ex:Cat                           (rdfs9 [1, 3])
Verdict: INCONSISTENT. The verified checker accepted the clash: by checkClash_sound_owl,
the data has no OWL model, so every query follows from it. No entailment is reported.
# exit 4
```

### Clash rules: rules that conclude `false`

The OWL 2 RL rule set already contains rules whose conclusion is `false`. `cax-dw` says that if `C owl:disjointWith D`, `x a C` and `x a D`, then the data is inconsistent. I did not bolt these onto the existing `Rule` type. They are a separate kind, `ClashRule`: a name, body patterns and guards, and no head. `Rule`, `Derives` and every existing soundness theorem stayed exactly as they were.

A clash certificate is an ordinary proof DAG for the premises, plus the clash rule that fires on them. The theorem is general in the class `C` of interpretations:

```lean
theorem checkClash_sound {C : SimpleInterp → Prop} {rules : List Rule} {clashes : List ClashRule}
    {g : Graph} {c : Certificate} (hr : ∀ r ∈ rules, r.SoundIn C)
    (hc : ∀ r ∈ clashes, r.SoundIn C) (h : checkClash rules clashes g c = .ok ()) :
    ¬ ∃ I, C I ∧ ∃ A : BlankNode → I.Dom, ∀ t ∈ g, I.Holds A t
```

If every derivation rule is sound in `C`, every clash rule is sound in `C`, and the checker accepts, then no interpretation in `C` satisfies the data. It is instantiated twice: for OWL (`checkClash_sound_owl`, with EL as a corollary) and for RDFS (`checkClash_sound_rdfs`).

The twelve fixed-arity OWL 2 RL clash rules are each proven sound against the OWL semantic conditions: `cax-dw`, `cls-nothing2`, `cls-com`, `cls-maxc1`, `cls-maxqc1`, `cls-maxqc2`, `prp-irp`, `prp-asyp`, `prp-pdw`, `prp-npa1`, `prp-npa2` and `eq-diff1`. That needed ten new conditions in `OWLConds`: `owl:differentFrom` is inequality, `owl:disjointWith` means no common member, and so on. The concrete OWL test model still satisfies every one of them. That matters, because it proves the conditions are not contradictory. A theory with no models would make every clash theorem vacuously true.

Under RDFS there is exactly one clash with three datatypes: an `xsd:string` literal that contains U+0000, U+FFFE or U+FFFF, which are not XML characters. Its theorem has one stated assumption: ill-typed strings denote nothing (`IsWellTyped`). The semantics does not force that yet, and the docs say so.

### Inconsistency is checked first

All three tools that answer queries look for a clash *before* any entailment: `leanrdf-demo`, `leanrdf-oxilite` and `leanrdf-classify`. If they find one, they report INCONSISTENT and nothing else. `leanrdf-check` verifies clash certificates standalone, with no query at all:

```json
{"verdict":"inconsistent","exit":4,"regime":"owl","clash":"cax-dw",
 "theorem":"checkClash_sound_owl","graph":"sha256:c3aa3570…","bound":true}
```

Against the W3C OWL 2 test suite, 27 of the approved inconsistency tests come out INCONSISTENT with checked certificates. The other 91 are listed together with the reason each one is not decided. Mostly they need list rules or datatype reasoning. None of them is ever reported as consistent.

"No clash found" is not a claim of consistency. It is just the absence of an INCONSISTENT verdict.

---

## Part two: proving that something does not follow

Now the harder direction. To show that the data does **not** entail a query, you need a world where the data is true and the query is false: a countermodel. No derivation can stand in for that.

The catch is that RDF interpretations are infinite. Every IRI and every literal must denote something, and RDF has infinitely many of both. A countermodel cannot be a table. It has to be a **finite description of an infinite model**, and the checker has to be proven to understand that description correctly.

### Presentations

LeanRDF's description is called a **presentation**. It has:

- a handful of **sorts**, each with a kind (an ordinary resource, a string, a language-tagged string, a directional string, another literal, or a triple term), and flags that say whether its elements are resources and whether they are properties;
- a table of the **listed IRIs and literals** and their sorts, plus **default sorts** for everything not listed: unlisted IRIs, unlisted `rdf:_n`, each literal kind, and triple terms;
- the **`IEXT` table**, which says which sorts are related by which property sorts;
- an assignment of sorts to the data's blank nodes.

The interpretation lives over a free carrier, `base n | lit l | tt x y z`. So `IT`, the denotation of triple terms, is injective by construction, and so are the literal values. Nothing has to be checked for that.

### Lifting lemmas

The real work is the conditions. RDFS says things like "for every `x`, if `x` is in the class extension of `rdfs:Class`, then `(x, rdfs:Resource)` is in `rdfs:subClassOf`". That ranges over infinitely many elements. Every RDF and RDFS condition got a **sort-level form**, and a lemma proves that the sort-level form makes the real condition hold for every element:

```lean
theorem isRDFS_of (hw : P.WellFormed) (h1 : P.RDFSorts) (h : P.RDFSSorts) :
    (P.dinterp hw).IsRDFS
```

`RDFSorts` and `RDFSSorts` are finite conjunctions over sorts and are decidable, so the checker can evaluate it. The lemma is where the infinite becomes finite, and the kernel checks the lemma once, for every presentation.

### Searching the query, completely

The data must hold in the presentation, and the query must not. "Must not" means for **every** assignment of the query's blank nodes. The checker enumerates every assignment of sorts to the query's blank nodes, within a step budget, and a lemma proves that the enumeration covers every assignment. If the budget runs out, the countermodel is rejected. It is never accepted.

Put together:

```lean
theorem checkCountermodel_sound_rdfs {g q : Graph} {P : Presentation} {budget : Nat}
    (h : checkCountermodel .rdfs g q P budget = .ok ()) : ¬ g.RDFSEntails q
```

with the same for simple and RDF entailment. A fourth theorem connects the two halves of the release:

```lean
theorem checkCountermodel_consistent {g q : Graph} {P : Presentation} {budget : Nat}
    (h : checkCountermodel .rdfs g q P budget = .ok ()) :
    ∃ I : DInterp, I.IsRDFS ∧ I.Satisfies g
```

An accepted countermodel proves that the data has a model. So REFUTED and INCONSISTENT can never both come back for the same graph, and the checker guarantees it, not a convention.

All of these depend only on `propext`, `Classical.choice` and `Quot.sound`, and a test pins that. One detail I am a little proud of: two string lemmas came out naturally with `bv_decide`, but `bv_decide` adds `Lean.ofReduceBool` to the axioms. I proved them with `omega` and `UInt32` arithmetic instead, and the axiom list stayed clean.

### Where the countermodel comes from

The finder is untrusted, as always. It saturates the data under the regime's rules in Elpi, plus a few **representative triples**: one invented element for each default sort, so the infinite families get the facts they need. It then builds the canonical (Herbrand) model of the closure: one sort per term, and the closure itself as the `IEXT` table.

That model satisfies the RDFS conditions exactly where the rules are complete for the data. Where they are not, the checker rejects the candidate, and the verdict stays `NOT DERIVED`, now with the condition that failed. A bug in the finder can only cost a refutation. It can never produce a wrong one.

### Is Tom a dog?

The pets example: Tom is someone's pet and a cat, and dogs and cats are both mammals.

```
$ leanrdf-demo pets.nt query-tom-dog.nt --countermodel tom-dog.json
Elpi closure under 80 rules: 218 triples
No instance is derived. Countermodel: 54 sorts, 248 IEXT entries.
Verdict: REFUTED. The verified model checker accepted the countermodel under RDFS,
with D = {xsd:string, rdf:langString, rdf:dirLangString}: by checkCountermodel_sound_rdfs,
the data does not RDFS-entail the query.
# exit 5
```

The countermodel is a JSON file with an envelope that binds it to the digests of the data and the query, just like a 0.4 certificate. A second agent checks it without the finder:

```
$ leanrdf-check --data pets.nt --query query-tom-dog.nt --countermodel tom-dog.json
Countermodel: 54 sorts
Envelope: verified (data, query, rules and regime match)
Verdict: REFUTED. ... by checkCountermodel_sound_rdfs, the data does not entail the query: ¬ RDFSEntails.
# exit 5
```

Now forge it. Add one `IEXT` entry that puts Tom's sort into the class extension of `ex:Dog`:

```
Verdict: COUNTERMODEL REJECTED: the query holds under the assignment []
# exit 2
```

The checker does not trust the claim. It looks for an assignment that makes the query true, and in a forged model it finds one.

### Honest limits of "no"

- **REFUTED is relative to D**, the recognized datatypes {xsd:string, rdf:langString, rdf:dirLangString}. With more datatypes, an ill-typed literal could make the data unsatisfiable. Every REFUTED verdict prints D, and the JSON carries it.
- **Scope.** Countermodels exist for simple, RDF and RDFS entailment. There are no OWL countermodels yet.
- **One sort for all triple terms.** This is a simplification of the finder, not the checker. It is why three of the four negative tests in the W3C RDF 1.2 semantics suite come back unknown rather than refuted. The fourth is refuted. Not one of the 16 positive tests is ever refuted, which is the result that matters most.
- **Some refutations are missed.** "Is Alice 42?" on data that only *reifies* the claim has a countermodel. But the canonical candidate fails an RDF condition, because the rules do not type the predicate inside a triple term as `rdf:Property`. The answer stays `NOT DERIVED`, with that condition named. This is the system working as designed: it would rather say "don't know" than say "no" without a proof.

Three existing examples changed their verdict from NOT DERIVED to REFUTED: Tom-the-dog, "does Kurt teach something?" in the university example, and the cat-and-dog data under RDFS. No other recorded output changed.

---

## Why four answers matter for agents

An agent branches on what a tool returns. With two answers, every branch on "no" was a guess. With four, each branch has a meaning:

- **0, proven**: act on it, and attach the certificate.
- **5, refuted**: act on the negation, and attach the countermodel. "Tom is not a dog" is now a fact with a proof, not a default.
- **4, inconsistent**: stop. The data is broken, and anything derived from it is noise. Fix the data before answering anything.
- **1, unknown**: ask, escalate or gather more data. Do not guess.

This is also the groundwork for the next releases. A write gate (0.6) has to reject writes that would make an agent's memory inconsistent, and it now has a checked way to say so. Proof-carrying memory (0.7) can store refutations next to proofs. Allow/deny decisions for tool calls (0.8) need a deny that is as solid as an allow.

## Scripts that read exit codes

If your integration treats every exit code other than 0 and 2 as "not derived", it needs updating: 4 and 5 are now real answers.

## Try it

```bash
git clone https://github.com/Volland/rdf-lean && cd rdf-lean
lake test                                   # the core, with the countermodel theorems
(cd owl && lake test)                       # the twelve OWL clash rules
(cd check && lake build && lake test)       # verifying clashes and countermodels standalone
scripts/examples.sh elpi                    # refuted, not-refuted, cats under OWL and RDFS
scripts/examples.sh check                   # clash and countermodel checks, and the forgery
```

Release notes: [v0.5.0](https://github.com/Volland/rdf-lean/releases/tag/v0.5.0). The new book chapter, *Saying no*, and the countermodel docs are on [volland.github.io/rdf-lean](https://volland.github.io/rdf-lean/). LeanRDF is licensed under MIT or Apache-2.0.

A reasoner that can only say yes is half a reasoner, and one that says no without a proof is worse. Since 0.5, LeanRDF's no is a theorem too, and when it cannot prove either answer, it says so.
