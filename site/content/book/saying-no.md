---
title: Saying no
order: 16
summary: Why "not derived" proves nothing, and how a checked countermodel proves that a query does not follow.
---
# Saying no

A sound rule set can say yes. It cannot say no. When Elpi finds no derivation of "Tom is a dog", that only says the rules found nothing, and the rules are proven sound, not complete. An agent that reads "not derived" as "no" is guessing.

To prove a no, you show a world in which the data is true and the query false. Logicians call that a **countermodel**. If such a world exists, the query cannot follow, because entailment means "true in every world where the data is true".

## The world is infinite, its description is finite

An RDF interpretation that satisfies the RDF 1.2 conditions is infinite. It must give every triple term its own value, every string its own value, and every `rdf:_n` the axioms of a container membership property. LeanRDF therefore never writes down a world. It writes a finite **presentation** of one: a handful of *sorts*, each standing for a family of elements, and a table saying which sorts are related by which property sorts. All strings not mentioned in the data share one sort; all triple terms share another.

Every condition of the semantics has a finite form over the sorts. A lemma proves that if the finite form holds, the condition holds for every element of the infinite world. The checker decides the finite forms, so a theorem about an infinite model comes out of a finite computation.

## Untrusted finds, Lean checks, again

The finder is the same idea as the search for certificates. Saturate the data in Elpi, take every term of the closure as a sort, and use the closure as the table. If the rules derived everything that follows, this is a model, and it makes the query false exactly when the query is not derived. The finder does not know whether that is the case, and does not need to. The checker does:

```
$ leanrdf-demo pets.nt query-tom-dog.nt
No instance is derived. Countermodel: 54 sorts, 248 IEXT entries.
Verdict: REFUTED. … by checkCountermodel_sound_rdfs, the data does not RDFS-entail the query.
```

When the rules miss something, the candidate fails a condition, and the honest answer comes back:

```
$ leanrdf-demo reified.nt query-age.nt
Verdict: NOT DERIVED (no instance of the query is derived).
The candidate countermodel was rejected: condition failed: RDF: IP is the class rdf:Property
```

The data here only reifies the claim "Alice is 42". In every RDF world the predicate of that claim is a property, but no rule derives it, so the canonical candidate is not an RDF world. The verdict stays "not derived": a wrong REFUTED is impossible, and a missing one is expected.

## Four answers

With inconsistency certificates, an agent now gets one of four answers. Each one is a theorem or an honest "don't know":

| Answer | Exit | Meaning |
|---|---|---|
| PROVEN | 0 | a checked certificate: the query follows |
| REFUTED | 5 | a checked countermodel: the query does not follow |
| UNKNOWN (not derived) | 1 | neither was found |
| INCONSISTENT | 4 | a checked clash: the data has no model, so everything follows |

A REFUTED also proves the data consistent, because the countermodel is a model of it. So REFUTED and INCONSISTENT can never both be the answer for one graph.
