---
title: Certificates and the checker
order: 6
summary: The certificate data type and JSON format, what the verified checker accepts and rejects, the soundness theorems, and the CertifyingDatalog export.
---
# Certificates and the checker

A certificate is a proof DAG: one node per triple, each a fact of the graph or one rule application whose premises are earlier nodes. The checker in `LeanRDF.Cert` is the only code between an untrusted search and a theorem.

## The data type

```lean
structure Node where
  id : Nat
  conclusion : Triple
  rule : String          -- "fact" for a triple of the graph
  premises : List Nat    -- ids of earlier nodes, in the rule's body order

structure Certificate where
  version : Nat := 1
  nodes : List Node
  goals : List Nat
  mapping : List (BlankNode × Term) := []   -- the instance of a query's blank nodes
  envelope : Option Envelope := none        -- version 2: what the certificate is about

structure Envelope where
  graph : String       -- Graph.digest of the data
  query : String       -- Graph.digest of the query
  rules : RulesRef     -- the rule set's id and rulesDigest
  regime : String
  checker : String     -- the package and version that wrote it
  toolchain : String
  thm : String         -- the theorem an acceptance stands for
```

## JSON

Every term is written in N-Triples syntax, so a certificate is readable on its own and is read back with the N-Triples term parser:

```json
{"version": 1,
 "mapping": [["_:pet", "<http://example.org/rex>"]],
 "goals": [4],
 "nodes": [
   {"id": 0, "conclusion": ["<http://example.org/A>", "<http://www.w3.org/2000/01/rdf-schema#subClassOf>", "<http://example.org/B>"], "rule": "fact", "premises": []},
   {"id": 4, "conclusion": ["<http://example.org/rex>", "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>", "<http://example.org/B>"], "rule": "rdfs9", "premises": [0, 3]}]}
```

`Certificate.render` writes it and `Certificate.parse` reads it. `mapping` may be omitted. A literal may appear as a subject, because conclusions are generalized triples. Reading JSON is untrusted: a malformed certificate is a parse error, and a wrong one fails the checker.

## Version 2: the envelope

Version 2 adds an `envelope` that says what the certificate is about:

```json
"envelope": {"graph": "sha256:6956dd56…", "query": "sha256:7317c98d…",
             "rules": {"id": "rdfs", "digest": "sha256:3f141744…"}, "regime": "rdfs",
             "checker": "leanrdf-elpi 0.4.0", "toolchain": "leanprover/lean4:v4.35.0",
             "theorem": "checkQuery_sound"}
```

- `graph` and `query` are `Graph.digest`: `sha256:` and the SHA-256 of the graph's RDFC-1.0 canonical N-Quads. They do not depend on triple order or blank-node labels, and other RDFC-1.0 tools compute the same value.
- `rules.digest` is `rulesDigest`: the SHA-256 of one line per rule (name, body patterns, head, guards), in list order. Any change to a rule changes it.

The envelope is untrusted metadata. `checkQuery` never reads it, and no soundness theorem mentions it. A checker verifies it beside the proof by recomputing the digests from what it read (`Envelope.verify`). A wrong envelope can make a check fail, never pass. Both versions are read: version 1 has no envelope, and any other version is an error. `leanrdf-demo` writes version 2.

## What the checker accepts

`checkNode` accepts node `n`, given the conclusions accepted so far, exactly when:

1. `n.id` equals the number of nodes before it, so ids are `0, 1, 2, …` in order and premises can only point backwards (the DAG is acyclic by construction);
2. for `"fact"`: there are no premises and the conclusion is in the graph;
3. otherwise: the rule name is in the rule list, every premise id is an accepted node, the premise triples match the rule's body patterns *in order* under one substitution, every guard holds, and the head instantiated by that substitution is the conclusion.

`check rules g c` checks every node and returns the conclusion of the first goal. `checkQuery rules g q c` checks every node and then that every triple of the query, with its blank nodes replaced by the mapping, is an accepted conclusion.

## The theorems

| Theorem | Statement |
|---|---|
| `check_sound` | `check rules g c = .ok t → Derives rules g t`, for any rule list |
| `checkQuery_derives` | `checkQuery rules g q c = .ok () →` every query triple, instantiated, is derivable |
| `checkQuery_sound` | `checkQuery RDFS.rdfsRules g q c = .ok () → g.RDFSEntails q` |
| `checkB_sound`, `checkQueryB_sound` | the same for the Boolean versions, which `native_decide` can evaluate |

So a theorem about concrete data takes one line:

```lean
theorem x_type_C : Derives rdfsRules g (T (ex "x") ty (ex "C")) :=
  checkB_sound (c := cert) (by native_decide)

theorem g_entails_q : g.RDFSEntails q := checkQueryB_sound (c := cert) (by native_decide)
```

`native_decide` runs the compiled checker, so a theorem proved this way also trusts the Lean compiler. The library's own theorems never use it. It is meant for concrete data in tests and applications, where the alternative is a derivation written by hand.

## Checking a certificate from the command line

`leanrdf-check --data DATA --query QUERY --cert CERT.json --rules REGIME` reads a certificate written by any tool. It verifies the envelope of a version-2 certificate, then runs the checker under one of five regimes (`simple`, `rdf`, `rdfs`, `owl`, `el`). `checkRegime_sound` gives the regime's entailment from an acceptance. See [the command-line tools](/docs/cli/#leanrdf-check).

## CertifyingDatalog export

`toDatalog rules g c` writes the certificate, its rules and its graph as a `GraphProblemInput` of [CertifyingDatalog](https://github.com/knowsys/CertifyingDatalog), the verified Datalog proof checker from TU Dresden. A second checker, developed independently, can then accept the same derivation. `leanrdf-demo --datalog OUT.json` writes one.
