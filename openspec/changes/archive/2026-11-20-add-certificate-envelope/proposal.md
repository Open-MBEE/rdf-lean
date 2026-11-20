## Why

A version-1 certificate is a proof DAG and nothing else. It does not say which graph it was checked against, under which rules, by which checker, or which theorem its acceptance stands for. Checked against the wrong graph, it can still pass when that graph happens to contain the facts it uses. Without a content identity for graphs, two parties cannot even agree on what was proven. This change binds a certificate to its context so that it becomes a portable claim: "graph `sha256:…` RDFS-entails query `sha256:…`, by `checkQuery_sound`". This is F2 of `docs/ROADMAP.md`, and every later agentic change (memory, gate, policy) carries this envelope.

## What Changes

- **SHA-256 moves to the core** (`LeanRDF.Text.Sha256`). `leanrdf-sparql` re-exports it for its `SHA256` function, and the W3C SPARQL results are unchanged.
- **RDF Dataset Canonicalization (RDFC-1.0)** in the core (`LeanRDF.Canon`):
  - canonical blank-node labels `c14nN`, and canonical N-Quads output;
  - the W3C rdf-canon test suite, vendored and run;
  - a proof that canonical relabeling is injective on the blank nodes of the input, so the canonical graph is isomorphic to it.
- **An RDF 1.2 extension.** Blank nodes inside triple terms are hashed through their enclosing quads, recursively. RDFC-1.0 does not define this case, and it is recorded as a simplification.
- **Graph digests**: `Graph.digest`, `Dataset.digest = "sha256:" ++ hex (sha256 (canonical N-Quads))`.
- **Certificate version 2**: an `envelope` object with:
  - `graph` and `query` digests;
  - `rules`: the regime id and a digest of the rule list's canonical rendering;
  - `regime`, `checker` (package and version), `toolchain` and `theorem`.

  Version 1 certificates are still read.
- **`leanrdf-check` checks the envelope.** It recomputes every digest and rejects any mismatch (exit 2, reason `envelope: graph digest mismatch`, and so on) before running the checker. `--emit-envelope OUT` upgrades an accepted version-1 certificate to version 2.
- **`leanrdf-demo --cert` writes version 2.**
- **Release v0.4.0**: every package, now seven, declares `0.4.0`.

## Capabilities

### New Capabilities

- `rdf-canonicalization`: RDFC-1.0 canonical labeling and N-Quads, its isomorphism theorem, the RDF 1.2 triple-term extension, digests and the W3C rdf-canon suite.

### Modified Capabilities

- `certificates`: the format gains version 2 with the envelope; reading accepts versions 1 and 2.
- `certificate-check`: the command checks envelopes, reports digests in the text and JSON verdicts, and upgrades version 1.
- `release`: version `0.4.0`, and the *Proof-carrying answers release* `v0.4.0`.

## Impact

**Roadmap:** F2 of `docs/ROADMAP.md`, after [[changes#add-certificate-check]]. Ships v0.4.0 together with it.

**Code:**
- core: `LeanRDF/Text/Sha256.lean` (moved from `sparql/LeanRDFSparql/Hash.lean`), `LeanRDF/Canon/{Hash,Label,Rdfc,Digest}.lean`, `LeanRDF/Cert/{Envelope,Json}.lean`, `Tests/Canon/` with the vendored suite
- `sparql/LeanRDFSparql/Hash.lean` re-exports
- `check/`: envelope verification, `--emit-envelope`
- `elpi/LeanRDFElpi/Demo.lean`: writes version 2
- every `lakefile.lean`, `scripts/check_release.py`, `docs/releases/v0.4.0.md`

**tg.md sections touched:**
- [[decisions#Own certificate format with a Datalog export]]: the format gains a version
- [[decisions#Canonical N-Triples output]]: digests are taken over canonical N-Quads, not over input bytes
- [[decisions#Dependency-free core package]]: SHA-256 and RDFC-1.0 are written in the core with no dependency
- new constraints: *RDFC-1.0*, *SHA-256 (FIPS 180-4)*
- new simplification: *Canonical labels for blank nodes in triple terms*
- new decisions: *The envelope is untrusted metadata*, *Digests over RDFC-1.0 canonical N-Quads*

**Requirements:**
- added: `rdf-canonicalization#Canonical labeling`, `#Canonical N-Quads`, `#Canonical isomorphism`, `#Triple terms in canonicalization`, `#Graph digests`, `#RDFC-1.0 conformance`; `certificate-check#Envelope verification`; `release#Proof-carrying answers release`
- modified: [[openspec:certificates#Certificate format]], [[openspec:release#Release version]]
