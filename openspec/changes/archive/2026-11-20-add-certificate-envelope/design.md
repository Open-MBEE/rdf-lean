## Context

After `add-certificate-check`, `leanrdf-check` checks a certificate against data and query files. It cannot tell whether those files are the ones the certificate was produced for. Graph identity needs canonicalization because blank-node labels are arbitrary. LeanRDF has canonical N-Triples, which fixes term syntax, but no blank-node canonicalization. SHA-256 exists, in `sparql/LeanRDFSparql/Hash.lean`, written for SPARQL's hash functions.

## Goals / Non-Goals

**Goals:**
- A content identity for graphs and datasets that two parties compute independently: W3C RDFC-1.0 with SHA-256.
- Certificates that say what they prove: graph, query, rules, regime, theorem, checker, toolchain.
- No change to what the checker trusts.

**Non-Goals:**
- Signing certificates. Digests make signing possible, and key management is out of scope.
- Proving canonicity (isomorphic inputs give equal outputs). It is tested on the W3C suite and recorded as a simplification.
- Proving SHA-256 against FIPS 180-4. It is tested on the NIST vectors.

## Decisions

### The envelope is untrusted metadata

The checker never reads the envelope, and `checkQuery` and `checkRegime_sound` are unchanged. The envelope is checked *beside* the proof by recomputation: a wrong envelope makes `leanrdf-check` reject, and it can never make a certificate pass. The trust base therefore grows by SHA-256 and RDFC-1.0 only in the sense that a bug in them could reject a good certificate, or bind a proof to the wrong name. The proven statement is always about the graph that was parsed.

- motivated_by:: [[decisions#Elpi finds, Lean checks]] {weight: primary}
- motivated_by:: [[decisions#Own certificate format with a Datalog export]]

Rejected: making `checkQuery` take a digest and fail on mismatch. That would put hashing into the soundness statement for no gain, since the statement is about `g` itself.

### Digests over RDFC-1.0 canonical N-Quads

`digest = "sha256:" ++ hex(sha256(canonicalNQuads d))`. This is the identity of RDFC-1.0 §4 and of W3C Verifiable Credentials Data Integrity, so outside tools compute the same value.

- motivated_by:: [[decisions#Canonical N-Triples output]]

Rejected: hashing input bytes (it changes with order and labels); hashing canonical N-Triples with labels as written (it changes with labels).

### RDFC-1.0 written in the core, with an isomorphism theorem

The algorithm is written in Lean in `LeanRDF.Canon`, with no dependency, following the specification's sections. The proven part is the part that matters for soundness of *naming*: the issued labeling is injective on the input's blank nodes, so the canonical dataset is isomorphic to the input (`canonical_iso`). Canonicity is a property of the hash ordering, and it is tested.

- motivated_by:: [[decisions#Dependency-free core package]] {weight: primary}

### Rules digest from a canonical rendering

A rule list's digest is the SHA-256 of a line-per-rule rendering: name, body patterns, head, guards, in list order, with terms in N-Triples syntax and variables as `?name`. Any change to a rule changes the digest. So a certificate states the exact rule set it was checked under, which matters once users add rules (roadmap F14).

### Version 2 alongside version 1

`Certificate.version` 2 adds `envelope : Option Envelope`. Version 1 is read forever. `leanrdf-check` reports it as *unbound*, and `--emit-envelope` upgrades it after a successful check. `leanrdf-demo` writes version 2.

## Constraints

- **RDFC-1.0** (W3C Recommendation, 21 May 2024) binds `rdf-canonicalization`: the hash algorithm, issuer order and N-degree hashing.
  - constrains:: [[openspec:rdf-canonicalization#Canonical labeling]] {strength: must}
- **SHA-256** (FIPS 180-4) binds `Graph.digest`.
- **RDF 1.2 Concepts, triple terms**: RDFC-1.0 predates triple terms. The extension in *Triple terms in canonicalization* is LeanRDF's own, and it is recorded as a simplification, *Canonical labels for blank nodes in triple terms*.

## Risks / Trade-offs

- [The N-degree hash is exponential on adversarial graphs] → A work limit (RDFC-1.0 §4.4), an error rather than a hang, and the W3C poison-graph tests.
- [The triple-term extension may differ from a future W3C RDFC for RDF 1.2] → Digests name the algorithm: a future version prefixes `rdfc12-sha256:`, and the current form stays `sha256:`.
- [Moving SHA-256 could change SPARQL results] → The SPARQL W3C suite runs unchanged, including the `SHA256` tests.
