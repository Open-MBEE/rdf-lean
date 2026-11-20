## Why

An agent's memory is a tiramemsu store: bitemporal statement records that are never deleted, only retracted or corrected. LeanRDF can already export such a store to RDF 1.2 exactly ([[openspec:statement-graphs#Exact decoding]]), and it can certify entailments over any graph ([[openspec:certificates#Checker soundness]]). The two do not refer to each other. A certificate does not say which records it rests on or in which view of time it holds. When a record is corrected, nobody can say which certified conclusions lost their support.

This change joins them. A certificate may *cite* the statement records its facts come from. It is checked against a view of the store (now, as of transaction `t`, valid at time `v`), and an accepted check is a theorem about that view's export. Retraction impact, meaning which certificates no longer hold after a change of view, is computed exactly from the citations. This is feature F7 of `docs/ROADMAP.md`: *certified as of time t*.

## What Changes

- `LeanRDFStatements.Memory`, a new module of `leanrdf-statements`, which still requires only the core:
  - **citations**: a list of `(node id, eid)` pairs attached to a certificate;
  - `checkMem rules sg v q c`, which checks every citation against the store and then runs the core checker on `sg.toRDF v`;
  - `checkMem_sound` (for `rdfsRules`, plus RDF and simple variants), `checkMem_cites` and `checkMemRDF_sound`: an exported N-Triples file that decodes in view `v` gives the same theorem over the file's graph, through `toRDF_decode`;
  - **strict citations**: every `fact` node is the base triple of a cited live record, or a reifier or clock triple of a record;
  - `impact v₁ v₂ cs`, the certificates whose citations are live in `v₁` but not in `v₂`, and `unimpacted_checks`: a strict certificate that was accepted in `v₁` and has no citation in the impact set is accepted in `v₂`.
- Memory fields in the version-2 certificate envelope (from `add-certificate-envelope`): `view`, `export` (the digest of `sg.toRDF v`) and `citations`. A check recomputes the export digest and rejects a mismatch.
- `leanrdf-check` gains `--statements FILE.jsonl --view now|asof:T|history [--valid-at MS]` in place of `--data`, and an `impact` subcommand. The `check/` package now also requires `leanrdf-statements`. It still has no Elpi.
- Elpi certificates (in `leanrdf-elpi`) can be built with citations, by mapping each fact node back to the record whose base triple it is.
- Release v0.7.0.

## Capabilities

### New Capabilities

- `certified-memory`: citations, the view-relative check and its theorems, strict citations, retraction impact, the memory envelope fields, the memory command line and its example.

### Modified Capabilities

- `release`: version 0.7.0, and the `v0.7.0` release.

## Impact

**Roadmap:** F7, the fifth of seven agentic changes. It comes after `add-certificate-check` (F1), `add-certificate-envelope` (F2), `add-inconsistency-certificates` (F4) and `add-countermodels` (F5), and after `add-write-gate` (F6, v0.6.0). It ships as v0.7.0.

**Code:**
- `statements/LeanRDFStatements/Memory.lean` (new), `statements/StatementsTests/Memory.lean` (new);
- `check/lakefile.lean` (requires `leanrdf-statements`), and `check/` main (`--statements`, `--view`, `impact`);
- `elpi/LeanRDFElpi/Certify.lean` (citations when the data is a statement graph);
- `examples/certified-memory/`, `scripts/examples.sh`.

**tg.md sections touched:**
- binding decisions: [[decisions#Assertion is derived from a view]], [[decisions#Exact decoder and the reserved names]], [[decisions#A separate package with a CLI]], [[decisions#Own certificate format with a Datalog export]], [[decisions#Elpi finds, Lean checks]];
- binding constraints: [[constraints#tiramemsu record model]], [[constraints#Statement Graph definition]];
- new decisions: *Citations live beside the certificate*, *Memory checks run on the export*, *Strict citations make impact exact*, *Memory in the statements package, its command in check*;
- [[concepts#View]] gains the certified-view reading, and a new concept, *Citation*, is added.

**Requirements:**
- added: `certified-memory#Citations`, `#View-relative check`, `#Memory soundness`, `#Checks on exported files`, `#Strict citations`, `#Retraction impact`, `#Memory envelope fields`, `#Memory command line`, `#Certified memory example`; `release#Proof-carrying memory release`;
- modified: [[openspec:release#Release version]];
- depends on: [[openspec:statement-graphs#Views]], [[openspec:statement-graphs#Reifier export]], [[openspec:statement-graphs#Exact decoding]], [[openspec:certificates#Checker]], [[openspec:certificates#Checker soundness]], and the `certificate-check` and version-2 envelope requirements of `add-certificate-check` and `add-certificate-envelope`.
