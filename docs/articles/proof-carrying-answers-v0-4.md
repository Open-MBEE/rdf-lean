# A Proof Is Not Enough: It Has to Say What It Is About

### LeanRDF 0.4 gives agents certificates they can hand to each other, a checker that never searches, and a fingerprint that binds every proof to its data.

---

In my last essay, *No Proof, No Entry*, I argued that in an agentic flow an unchecked inference is an error with descendants, so every inference an agent consumes should come with a proof that a small, verified checker accepts. LeanRDF already did that inside one process: Elpi searched, Lean checked, and an accepted certificate became the theorem `g.RDFSEntails q`.

The weak point was the word *inside*. Agents do not live in one process. Agent A derives something and agent B acts on it. For certificates to matter in that setting, two things have to be true:

1. B can check A's certificate **without A's search engine**, and without trusting A.
2. The certificate says **which data it is about**, so that nobody can present a valid proof as if it were about something else.

LeanRDF 0.4 does both. This post is about what that took and what is proven.

---

### Problem one: the checker came with a search engine attached

Until now, the only way to check a certificate from the command line was `leanrdf-demo`, and the demo lives in the package that depends on lean-elpi, the Elpi interpreter we use for search. So to check a proof you had to build and install a search engine. That is backwards. The whole point of "Elpi finds, Lean checks" is that the checking side is small and the searching side is not trusted.

0.4 adds a seventh package, `leanrdf-check`. It has the verified checker, the parsers, the semantics and the OWL rules, and nothing that searches:

```
leanrdf-check --data DATA --query QUERY --cert CERT.json [--rules simple|rdf|rdfs|owl|el] [--json]
```

The checker is generic in its rule list, so "the certificate was accepted" on its own says little. What was proven, under which semantics? The answer is the **regime**. There are five: simple, RDF, RDFS, OWL 2 RL and OWL 2 EL. Each one has a rule list, an entailment proposition and the theorem that connects them. One theorem covers all five:

```lean
theorem checkRegime_sound {r : Regime} {g q : Graph} {c : Certificate}
    (h : checkRegime r g q c = .ok ()) : r.Entails g q
```

It is a case split over theorems that already existed: `checkQuery_sound` for RDFS, `Derives.owl_sound_graph` for OWL, and so on. It depends only on Lean's three standard axioms, and a test pins that. Every verdict names its regime and its theorem, so the reader knows exactly which statement is being claimed.

### Exit codes are a protocol, so I fixed them now

Agents branch on what a tool returns. If one release renames a verdict or reuses an exit code, every integration breaks. So 0.4 fixes the vocabulary for every LeanRDF tool, including the ones not written yet:

| Verdict | Exit | Meaning |
|---|---|---|
| `proven` | 0 | the checker accepted a certificate |
| `unknown` | 1 | the search found nothing (not a claim of non-entailment) |
| `rejected` | 2 | the certificate is wrong |
| `input-error` | 3 | the files could not be read |
| `inconsistent` | 4 | reserved: the data has no model (v0.5) |
| `refuted` | 5 | reserved: a checked countermodel (v0.5) |

`unknown` is never `refuted`. "My search found nothing" and "this does not follow" are different claims, and an agent that confuses them will deny things that are true. LeanRDF has always refused to print "not entailed" when its search fails. Now that rule is part of the machine-readable protocol.

---

### Problem two: a proof about which graph?

A certificate is a proof DAG. Each node is a triple, justified as a fact of the data or as one rule application over earlier nodes. The checker confirms every fact against the graph it was given and every step against the rule. If it accepts, the theorem holds **for the graph it was given**.

Now picture agent A writing a certificate against its knowledge graph on Monday. On Tuesday somebody hands agent B that certificate together with a different file. Perhaps the file has extra triples, or a different query. If every fact the proof uses is still in the new file, B's checker accepts, and the theorem is true. But it is not the theorem anybody asked about. The proof was quietly moved to other data.

Nothing is unsound here. The checker proves exactly what it says. The gap is in the **naming**: nothing in a version-1 certificate says which data it was made for.

The fix sounds simple: put a hash of the data in the certificate. The difficulty is in *which* hash.

### Hashing a graph is harder than hashing a file

An RDF graph is a set of triples, and some of its nodes are **blank nodes**, which have no global name. `_:b0` in my file and `_:x17` in yours can be the same node. So the same graph can be written as many different files:

- the triples in any order;
- the blank nodes under any labels.

Hashing the bytes of the file is useless, because every reordering gives a new hash. Hashing sorted lines is still useless, because every relabeling gives a new hash. What you need is to give every blank node a **canonical** name, determined by the structure of the graph and not by the file it came from. Then you can sort and hash.

The W3C standardized exactly this in 2024: **RDF Dataset Canonicalization, RDFC-1.0**. It names each blank node by hashing its neighbourhood. When two blank nodes have the same neighbourhood, it hashes the paths between them, recursively. It is also the algorithm under W3C Verifiable Credentials, so a digest computed with it means something outside LeanRDF.

0.4 implements RDFC-1.0 in Lean, in the core package, with no dependencies. The digest of a graph is

```
sha256:<SHA-256 of its RDFC-1.0 canonical N-Quads>
```

and the whole W3C rdf-canon test suite passes: 64 output tests, 21 tests of the issued labels, and the poison graph.

### The poison graph, and why the algorithm has a work limit

RDFC-1.0 has an uncomfortable property. On graphs where many blank nodes look identical, the recursive path hashing tries permutations, and that can explode. The W3C suite includes a 10-node clique of blank nodes, each related to every other, that no implementation should try to finish.

So the algorithm counts its work (recursive calls plus permutations examined) and fails with an error past a limit, as the Recommendation permits. The limit has to be generous, because the suite also has three "evil" graphs that *must* complete. I measured them: they need 3,348 units of work, and every other test needs at most 54. LeanRDF's limit is `10000 + 100·n` for `n` blank nodes that share a hash. The clique hits the limit and is reported as an error, instead of hanging an agent.

### What is proven about canonicalization, and what is only tested

I want to be precise here, because "verified canonicalization" could be read as more than it is.

The property that matters for soundness of *naming* is that canonicalization **never merges two blank nodes and never invents one**. If it merged two, two different graphs could get the same digest, and a proof could be bound to the wrong data. That property is proven, for every input:

```lean
theorem canonical_iso (σ : Labeling) (d : Dataset) : Dataset.Iso d (canonicalize σ d)
```

The canonical dataset is isomorphic to the input. The proof does not go through the hashing at all. The relabeling is applied as a chain of swaps: the i-th blank node in issue order is swapped with `_:c14n<i>`. A composition of swaps is a bijection, whatever order the hashes produced. So the theorem holds for any labeling the algorithm could return, including a buggy one.

The converse property, **canonicity**, is that two isomorphic inputs get the *same* output. It depends on SHA-256 and on the hash ordering, and it is tested, not proven: on the W3C suite, and on copies of graphs with reordered triples and renamed blank nodes. SHA-256 is likewise tested on the NIST vectors, not proven against FIPS 180-4. Both are recorded in the project as simplifications.

One more honest note. RDFC-1.0 predates RDF 1.2 triple terms, and LeanRDF supports RDF 1.2. So blank nodes inside triple terms (`<<( _:x ex:p ex:o )>>`) are canonicalized by an extension of my own: they are hashed at every depth. On data without triple terms, the output is RDFC-1.0 exactly. On data with them, a future W3C algorithm may disagree, and its digests would get a different prefix.

---

### The envelope: binding a proof to its data without trusting the binding

A version-2 certificate carries an **envelope**:

```json
"envelope": {
  "graph": "sha256:6956dd56…",  "query": "sha256:7317c98d…",
  "rules": {"id": "rdfs", "digest": "sha256:3f141744…"},
  "regime": "rdfs", "theorem": "checkQuery_sound",
  "checker": "leanrdf-elpi 0.4.0", "toolchain": "leanprover/lean4:v4.35.0"
}
```

The design rule I care most about is this: **the envelope is untrusted metadata.** The checker never reads it. `checkQuery` and every soundness theorem are unchanged. `leanrdf-check` verifies the envelope *beside* the proof, by recomputing the three digests from the files it actually read and comparing the regime. A mismatch is a rejection, and the reason names the field.

So the envelope can make a check **fail**, never **pass**. A bug in my canonicalization could, at worst, reject a good certificate or attach a proof to the wrong name. It cannot make a wrong proof go through, because the proven statement is always about the graph that was parsed. The trusted base is the same as in 0.3.

The rules get a digest too: the SHA-256 of one canonical line per rule (name, body, head, guards). Today that pins the regime. Once users can add their own rules, it will be the only way to say exactly which rule set a certificate was checked under.

### What it looks like

The example in the repository takes a university ontology and asks whether `uni:kurt` is a `uni:Person`. The demo searches, writes a version-2 certificate, and the checker checks it:

```
$ leanrdf-check --data university.nt --query query-kurt-person.nt --cert kurt-person.json
LeanRDF check: 12 data triples, 1 query triples
Certificate: 7 nodes, goals [6]
Data digest: sha256:b69d5884b2f71a4f2f61519036708434e0e65d74cff6f9bb2a2788938aacb68c
Query digest: sha256:402b7bd8008310801fff3b15f1c455eda149f26d76cd525cafcbc4a55bb162ac
Envelope: verified (data, query, rules and regime match)
Verdict: PROVEN. The verified checker accepted the certificate under rdfs: by checkQuery_sound, the data RDFSEntails the query.
```

Add one unrelated triple to the data (`uni:ada uni:teaches uni:logic`) and check the same certificate again:

```
LeanRDF check: 13 data triples, 1 query triples
Certificate: 7 nodes, goals [6]
Data digest: sha256:1b92b9e5959b1d5856adbb252626993a95e1738b92134bf7798d9b875d3ad94b
Query digest: sha256:402b7bd8008310801fff3b15f1c455eda149f26d76cd525cafcbc4a55bb162ac
Verdict: CERTIFICATE REJECTED: envelope: graph digest mismatch
# exit 2
```

Note that the proof DAG alone would still pass here, because every fact it uses is still in the data. The rejection is about the claim, not the derivation: this certificate was not made for this graph.

Rename the blank nodes and reverse the order of the triples, and the digest does not move, so the certificate is accepted. For a graph with no blank nodes you can check the digest yourself, because RDFC-1.0 then reduces to sorting the lines:

```
$ grep -v '^#' pets.nt | LC_ALL=C sort | shasum -a 256
6956dd560aa479b53c85fca2ac31307e0cdd97abef70bcf6d105e970b8851156
```

That is the `graph` field of the demo's pets certificate above. I computed it with a two-line shell pipeline that shares no code with LeanRDF.

For agents, `--json` returns one object:

```json
{"verdict":"proven","exit":0,"regime":"rdfs","theorem":"checkQuery_sound",
 "graph":"sha256:b69d5884…","query":"sha256:402b7bd8…","bound":true,
 "nodes":7,"goals":[6],"dataTriples":12,"queryTriples":1}
```

Old certificates still work. A version-1 certificate is checked as before, the verdict says `"bound": false`, and `--emit-envelope out.json` writes it as version 2 after a successful check.

---

### Why this matters for agentic flows

Put the two halves together and a certificate becomes something an agent can **send**:

- Agent A runs the search and writes a version-2 certificate.
- Agent B receives the data, the query and the certificate, runs `leanrdf-check`, and branches on the exit code. B never trusts A and never runs a search.
- A log that records "proven, graph `sha256:b69d…`" is now an audit record. Anyone with the same data can reproduce the digest and the verdict. Anyone with different data will see that it is different.

This is also the foundation for what comes next. A memory store that keeps proven facts needs to know which data each proof was about, and so does a write gate that admits derived triples. Both are on the roadmap.

### What 0.4 does not give you

- **Completeness.** A certificate proves an answer is right, not that nothing is missing. `unknown` stays `unknown`.
- **Signatures.** A digest says *what* a certificate is about, not *who* stands behind it. Signing is now possible, since there is a stable thing to sign, but key management is out of scope.
- **Proofs of the hash.** SHA-256 and the canonicity of RDFC-1.0 are tested, not proven. As explained above, a bug there could reject good certificates and cannot accept bad ones.
- **The compiler.** Theorems proven with `native_decide` on concrete certificates trust the Lean compiler, as before.

### What is next

0.5 adds the two negative verdicts that are reserved today:

- `inconsistent`: a certificate that the data has no model, for example an OWL disjointness clash;
- `refuted`: a checked countermodel showing that a query does *not* follow.

After that come a write gate for agent memory (0.6), proof-carrying memory over bitemporal statement records (0.7), and certified allow/deny decisions for tool calls (0.8). The plan, ranked feature by feature, is in [`docs/ROADMAP.md`](https://github.com/Volland/rdf-lean/blob/main/docs/ROADMAP.md).

### Try it

```bash
git clone https://github.com/Volland/rdf-lean && cd rdf-lean
(cd check && lake build && lake test)   # the checker and its 21-certificate corpus
scripts/examples.sh check               # proven, tampered, JSON and other-data
lake test                               # the core, with the W3C rdf-canon suite
```

Release notes: [v0.4.0](https://github.com/Volland/rdf-lean/releases/tag/v0.4.0). Site, book and examples: [volland.github.io/rdf-lean](https://volland.github.io/rdf-lean/). LeanRDF is licensed under MIT or Apache-2.0.

A proof that does not say what it is about can be carried anywhere and presented as being about anything. Since 0.4, LeanRDF certificates say what they are about, and the checker verifies that before it checks the proof.
