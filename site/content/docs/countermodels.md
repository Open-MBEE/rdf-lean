---
title: Countermodels
order: 6
summary: How LeanRDF proves that a query does not follow: finite presentations of interpretations, the verified model checker, its soundness theorems, the countermodel JSON, and the finder.
---
# Countermodels

A certificate proves that a query follows. To prove that it does *not* follow, LeanRDF checks a **countermodel**: an interpretation that satisfies the data and not the query. The untrusted finder builds one from the Elpi closure. `checkCountermodel` decides it, and the soundness theorems turn acceptance into non-entailment:

```lean
theorem checkCountermodel_sound_simple (h : checkCountermodel .simple g q P budget = .ok ()) : ¬ g.SimpleEntails q
theorem checkCountermodel_sound_rdf    (h : checkCountermodel .rdf    g q P budget = .ok ()) : ¬ g.RDFEntails q
theorem checkCountermodel_sound_rdfs   (h : checkCountermodel .rdfs   g q P budget = .ok ()) : ¬ g.RDFSEntails q
theorem checkCountermodel_consistent   (h : checkCountermodel .rdfs   g q P budget = .ok ()) :
    ∃ I : DInterp, I.IsRDFS ∧ I.Satisfies g
```

All four use only `propext`, `Quot.sound` and `Classical.choice`.

## Finite presentations of infinite models

A countermodel cannot be finite. `IT` and the literal value maps are injective, so the carrier of any interpretation with two resources is infinite, and the RDF and RDFS conditions quantify over every `rdf:_n` and every literal. A `Presentation` is a finite description of an infinite interpretation instead:

```lean
inductive CDom | base (i : Nat) | lit (l : Literal) | tt (x y z : CDom)
```

Every element has a sort:
- `base i` has sort `i`;
- a literal has its override's sort, or the default sort of its kind (`string`, `lang`, `dirLang`, `otherLit`);
- every triple term has the triple sort.

The presentation lists the sorts with their kinds and IR/IP flags, a sort for each listed IRI with defaults for every other IRI and every other `rdf:_n`, an `IEXT` table over sorts, and the sorts of the data's blank nodes. `Presentation.dinterp` is the `DInterp` it describes:
- `IT := tt`, so `IT` is injective by construction;
- `IL l` is the literal itself with its tag lowercased, so the value maps are injective too;
- IR, IP and `IEXT` are read off the tables through `sortOf`.

## What the checker checks

1. **Well-formedness**: indices in range and pure kinds. A literal's sort has the literal's kind, and every literal sort is a default or an override sort.
2. **The regime's conditions, over sorts.** Every condition of `RDFConditions` and `RDFSConditions` has a sort-level form, and a lifting lemma proves that it makes the condition hold on every element. Conditions over all `rdf:_n` are checked on the listed ones and the default. The datatype classes hold through kind purity: a sort is in the class `xsd:string` exactly when its kind is `string`.
3. **The data holds** under the presentation's blank-node sorts.
4. **The query fails under every assignment** of resource sorts to its blank nodes. Truth depends only on sorts (`holds_iff`), so this covers every `A : BlankNode → CDom`. The search takes a step budget, and exceeding it is a rejection, never an acceptance.

A rejection names the first failed condition, the data triple that does not hold, or the assignment under which the query holds.

## The finder

`findCountermodel` (in `leanrdf-elpi`) adds a few representative triples to the data: an unlisted IRI, an `rdf:_n` used as a predicate, one literal of each kind, a triple term, and each IRI of the query. It saturates in Elpi under the regime's rules and builds the canonical presentation of the closure: one sort per term, the closure as the `IEXT` table. This is the Herbrand model of the closure, and it is a model only where the rules are complete for the data. When it is not, the checker rejects the candidate, and the verdict stays NOT DERIVED with the failed condition.

## JSON

```json
{"kind": "countermodel", "regime": "rdfs",
 "sorts": [{"kind": "base", "ir": true, "ip": false}, …],
 "iris": [["<http://example.org/tom>", 12], …], "defaultIri": 0, "defaultCmp": 1,
 "literals": {"string": 2, "lang": 3, "dirLang": 4, "other": 5},
 "overrides": [["\"Rex\"@en", 30], …], "tripleSort": 6,
 "ext": [[7, 12, 20], …], "assign": [],
 "envelope": { … }}
```

`leanrdf-demo --countermodel OUT.json` writes it, with the envelope of version-2 certificates. `leanrdf-check --countermodel FILE` verifies it. See [the command-line tools](/docs/cli/#leanrdf-check) and [`examples/countermodels/`](https://github.com/Volland/rdf-lean/tree/main/examples/countermodels).

## What REFUTED means

- **Relative to D.** A refutation is for D = {xsd:string, rdf:langString, rdf:dirLangString}. With more recognized datatypes, an ill-typed `xsd:integer` literal would make the data unsatisfiable, and then everything would follow.
- **Simple, RDF and RDFS only.** OWL countermodels are not implemented.
- **All triple terms share one sort.** A countermodel cannot tell two propositions apart, so some refutations are not found. On the W3C RDF 1.2 semantics suite, one of the four negative tests is refuted and three are reported with this reason. None of the 16 positive tests is refuted.
