## Context

- Query graphs with blank nodes are existential ([[constraints#Entailed blank nodes are existential]]). A certificate carries the instance mapping ([[decisions#Graph queries with instance mappings]]), and `checkQuery_sound` gives `g.RDFSEntails q`.
- `add-countermodels` (F5) adds a checker for finite interpretations whose soundness gives `¬ g.RDFSEntails q`, and whose model satisfies `g`. It covers the simple, RDF and RDFS regimes, not OWL.
- `add-inconsistency-certificates` (F4) adds `clash` certificates, with exit 4.
- The proven SPARQL evaluator computes the SPARQL semantics over a graph exactly, but the RDFS rules are proven sound, not complete. So "no answer over the derived closure" is not "not entailed".
- ODRL 2.2 is the W3C policy language. Its full model (party and asset collections, refinements, duties, logical constraints, conflict strategies) is far larger than an agent guard needs.

## Goals / Non-Goals

**Goals:**
- Three certified outcomes, each a Lean theorem about a W3C semantics: PERMIT, DENY and INCONSISTENT. NOT DECIDED is the honest fourth.
- Class hierarchies in policies and data work without extra rules.
- A runnable guard that an agent framework can copy.

**Non-Goals:**
- Full ODRL: duties, refinements, logical constraints, `odrl:conflict` strategies. A mapping table is given, but no reader.
- Numeric, temporal or comparison constraints. These wait for D-entailment (F8).
- OWL policies. Countermodels are RDFS-only, so PERMIT is RDFS-only.
- Searching inside `leanrdf-policy`.

## Decisions

### Applicability is entailment of a match pattern

For a rule kind `K` (`pol:Permission` or `pol:Prohibition`) and a request `R = (a, x, t, u)`, the pattern is:

```
_:r rdf:type K .
_:r pol:assignee _:ca .  a rdf:type _:ca .
_:r pol:action   _:cx .  x rdf:type _:cx .
_:r pol:target   _:ct .  t rdf:type _:ct .
_:r pol:purpose  _:cu .  u rdf:type _:cu .
```

`Applies g R K := (G_R).RDFSEntails (pattern K R)`, where `G_R = g ∪ {u rdf:type pol:AnyPurpose}`.

- **Alternative rejected:** a new semantics for policies, with its own interpretation. Its decisions would be about a definition only this project uses.
- **Reason:** applicability becomes plain RDFS entailment, so the existing checker and soundness apply unchanged. Hierarchies such as "a Lecturer is Staff" and "read is an access action" come from `rdfs9` and `rdfs11`. Motivated by [[decisions#Graph queries with instance mappings]] and [[constraints#Entailed blank nodes are existential]].

### Absence by countermodel, not by query

PERMIT requires `¬ G_R.RDFSEntails (pattern Prohibition R)`. This is shown by an F5 countermodel: a finite RDFS interpretation that satisfies `G_R` and falsifies the prohibition pattern.

- **Alternative rejected:** run the prohibition pattern as a SPARQL query, with the proven evaluator, over a closure in which every triple is certified. An empty answer proves only that the *closure* has no match. Without a completeness theorem for the rule set, which LeanRDF does not have ([[simplifications#Container axioms only for occurring rdf:_n]] alone breaks it), that is "not derived", not "not entailed". [[decisions#Demo never claims non-entailment]] forbids presenting it as a decision.
- **Reason:** a countermodel gives exactly `¬ entails`, by a checker in the trusted base. Because the model also satisfies `G_R`, `permit_consistent` comes for free: a PERMIT is never the vacuous consequence of an inconsistent policy base.

### Prohibition overrides permission

`decide` checks for DENY first. If a prohibition certificate is accepted, the outcome is DENY, whatever else is supplied. PERMIT needs both a permission certificate and an accepted absence countermodel. Any other combination is NOT DECIDED.

- **Alternative rejected:** permission overrides, or the most specific rule wins. These need a notion of specificity that RDFS does not give.
- **Reason:** for agent guards, the safe default is to refuse. Since a prohibition certificate and an absence countermodel cannot both be accepted (soundness of both checkers), the order changes the outcome only when the evidence is inconsistent. In that case DENY is the safe choice.

### Classes, not individuals, in rules

Every rule property names a class. A grant to one agent uses a class with one member.

- **Alternative rejected:** allow both individuals and classes. Each property would double the number of patterns, and PERMIT would then need a countermodel that refutes all 16 prohibition patterns at once.
- **Reason:** one pattern per kind keeps one certificate and one countermodel per decision. The ODRL mapping turns an `odrl:assignee` party into a singleton class.

### Purpose is the only constraint until datatypes

The only constraint is `pol:purpose`, a class that the request's purpose must belong to. `pol:AnyPurpose` matches every request, because `G_R` types the purpose with it. Numeric and temporal constraints wait for F8 and are recorded as the simplification *Policy constraints limited to purpose classes*.

### Well-formed policies by SHACL

`policy-shapes.ttl` requires that every `pol:Permission` and `pol:Prohibition` has exactly one `pol:assignee`, `pol:action`, `pol:target` and `pol:purpose`, each an IRI. `leanrdf-policy` validates the policy base with the proven validator before deciding, and rejects a non-conforming base with exit 3 and the report.

- **Reason:** with one value per property, the existential pattern means the same as "the rule's own classes contain the request". Several values would turn the pattern into a disjunction over the values.
- The shapes check the asserted policy base. A `rdfs:subPropertyOf` axiom on a `pol:` property could still add values by entailment, so the shapes also forbid `pol:` properties as the subject of `rdfs:subPropertyOf`.

### A policy package

`policy/` (`leanrdf-policy`) requires `leanrdf`, `leanrdf-shacl` and `leanrdf-check`, following [[decisions#Layers as packages in one repository]]. It does not require `leanrdf-gate`: a decision is not a write.

## Constraints

- RDF 1.1 Semantics §5 and §9 (RDFS interpretations) bind the meaning of "applies": [[constraints#RDFS interpretation conditions]] constrains the decision theorems.
- [[constraints#SHACL Core]] binds the well-formedness check of the policy base.
- ODRL 2.2 Information Model §2 binds the mapping table only (informative): `pol:Permission` ↔ `odrl:Permission`, `pol:Prohibition` ↔ `odrl:Prohibition`, `pol:assignee` ↔ `odrl:assignee` (a `odrl:PartyCollection` as a class), `pol:action` ↔ `odrl:action`, `pol:target` ↔ `odrl:target` (an `odrl:AssetCollection` as a class), and `pol:purpose` ↔ an `odrl:constraint` with `odrl:leftOperand odrl:purpose` and `odrl:operator odrl:isA`.

## Risks / Trade-offs

- **Countermodel size:** F5's finder must produce an RDFS model of the whole decision graph. For a large memory, this is the cost of every PERMIT. → Decide over the relevant module (the policy base plus the type and hierarchy triples of the four individuals); document this, since soundness is per decision graph.
- **NOT DECIDED is frequent when the finders are weak.** → The guard treats it as deny and logs why. That is the correct behaviour for an agent.
- **ODRL users expect more.** → The mapping table and the simplification state the subset plainly. An ODRL reader is a separate later change.
