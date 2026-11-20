## 1. SHA-256 in the core

- [x] 1.1 Move the hash functions (SHA-256 with SHA-384, SHA-512, SHA-1 and MD5) to `LeanRDF/Text/Hash.lean`, re-export from `sparql/LeanRDFSparql/Hash.lean`; NIST vectors in `Tests/Text/Hash.lean`; SPARQL W3C suite unchanged

## 2. RDFC-1.0

- [x] 2.1 Vendor the W3C rdf-canon suite under `Tests/data/rdf-canon/` with its licence note
- [x] 2.2 `LeanRDF/Canon/Hash.lean`: the issuer, first-degree hash, hash-related blank nodes, N-degree hash with the work limit; the triple-term extension; `Canonical labeling` and `Triple terms in canonicalization` annotated on `canonicalLabels`
- [x] 2.3 `LeanRDF/Canon/Rdfc.lean`: the canonical issuer, `canonicalLabels`, `canonicalNQuads`; annotate `Canonical N-Quads`
- [x] 2.4 `LeanRDF/Canon/Label.lean`: swaps, `applySwaps_bijective`, `Dataset.Iso`, `iso_renameBNodes`; `canonicalLabels_injective` and `canonical_iso` in `Rdfc.lean`; annotate `Canonical isomorphism`
- [x] 2.5 `LeanRDF/Canon/Digest.lean`: `Graph.digest`, `Dataset.digest`; annotate `Graph digests`
- [x] 2.6 `Tests/Canon/`: the W3C suite runner (annotate `RDFC-1.0 conformance`), the isomorphic-copy, poison-graph, sorted-output, triple-term, digest-invariance and axiom scenarios, each with `@tg: verifies::`

## 3. Certificate version 2

- [x] 3.1 `LeanRDF/Cert/Envelope.lean`: `Envelope`, the rules rendering and `rulesDigest`; `Certificate.envelope`; JSON read and write for versions 1 and 2 in `Cert/Json.lean`; annotate `Certificate format`
- [x] 3.2 Tests: version-2 round trip, version-1 still read, the checker's verdict independent of the envelope

## 4. leanrdf-check and the demo

- [x] 4.1 `check/`: envelope verification before checking, digests in the text and JSON verdicts, *unbound* for version 1, `--emit-envelope`; annotate `Envelope verification`
- [x] 4.2 `elpi/LeanRDFElpi/Demo.lean` writes version 2; re-record the corpus and the examples' outputs
- [x] 4.3 Tests: bound certificate accepted on reordered and relabeled data, rejected on extended data, version-1 upgrade

## 5. Release v0.4.0, docs and tg.md

- [x] 5.1 Bump all seven packages to `0.4.0`; `scripts/check_release.py` `VERSION` and `RELEASES`; `docs/releases/v0.4.0.md`; annotate `Proof-carrying answers release`
- [x] 5.2 `site/content/docs/certificates.md` (version 2), the `cli.md` updates, a book section on digests; site roadmap rows for F1 and F2
- [x] 5.3 Record in `tg.md/` the decisions *The envelope is untrusted metadata*, *Digests over RDFC-1.0 canonical N-Quads*, *RDFC-1.0 written in the core, with an isomorphism theorem*, *Rules digest from a canonical rendering* and *Version 2 alongside version 1*; the constraints *RDFC-1.0* and *SHA-256 (FIPS 180-4)* with `constrains` edges; the simplifications *Canonical labels for blank nodes in triple terms* and *Canonicity is tested, not proven* with `deviates_from`; list `rdf-canonicalization` in the `openspec:` frontmatter
- [x] 5.4 `tg check`, `tg ontology check`, and `tg trace rdf-canonicalization --gaps` / `tg trace certificate-check --gaps` with no gaps
- [x] 5.5 Tag and publish `v0.4.0` after archiving, on the owner's go-ahead
