## 1. Library

- [ ] 1.1 `statements/LeanRDFStatements/Memory.lean`: `Citation`, `MemCert` (certificate plus citations), `checkCitation`, `checkMem`; annotate with `@tg: implements:: [[openspec:certified-memory#Citations]]` and `[[openspec:certified-memory#View-relative check]]`
- [ ] 1.2 `checkMem_sound` (RDFS), `checkMem_sound_rdf`, `checkMem_sound_simple`, `checkMem_cites`; annotate `[[openspec:certified-memory#Memory soundness]]`
- [ ] 1.3 `checkMemRDF_sound` through `toRDF_decode`, with a lemma that entailment depends only on graph membership; annotate `[[openspec:certified-memory#Checks on exported files]]`
- [ ] 1.4 `isStrict` with its correctness lemma; annotate `[[openspec:certified-memory#Strict citations]]`
- [ ] 1.5 `impact` and `unimpacted_checks`, through `mem_toRDF` and a lemma that `checkCert` depends on the graph only through the membership of `fact` conclusions; annotate `[[openspec:certified-memory#Retraction impact]]`
- [ ] 1.6 Pin the axioms of the four theorems in `StatementsTests/Memory.lean`

## 2. Envelope and command line

- [ ] 2.1 Envelope fields `view`, `export`, `citations` (read and written beside the F2 envelope), with the export digest recomputed from the records; annotate `[[openspec:certified-memory#Memory envelope fields]]`
- [ ] 2.2 `check/lakefile.lean` requires `leanrdf-statements`; `leanrdf-check --statements --view --valid-at`, the `impact` subcommand, `--json`, the `history` warning; annotate `[[openspec:certified-memory#Memory command line]]`
- [ ] 2.3 `elpi/LeanRDFElpi/Certify.lean`: build citations when the data is a statement graph (untrusted; the result is checked by `checkMem`)

## 3. Tests

- [ ] 3.1 `StatementsTests/Memory.lean`: one test per scenario of `Citations`, `View-relative check`, `Memory soundness`, `Strict citations` and `Retraction impact`, each with `@tg: verifies:: [[openspec:certified-memory#<Requirement>#<Scenario>]]` directly above it
- [ ] 3.2 A recorded tiramemsu export from `StatementsTests/data/tm/` with a citing certificate; annotate `[[openspec:certified-memory#Checks on exported files#A recorded tiramemsu export is a certified memory]]`
- [ ] 3.3 Exhaustive impact test in the compiled test driver over all stores of at most three records, all view pairs and strict certificates of at most four nodes; print the count; annotate `[[openspec:certified-memory#Retraction impact#Impact agrees with re-checking on all small stores]]`
- [ ] 3.4 Command-line scenarios (envelope mismatch, impact) in the `check/` test driver, annotated with their scenarios

## 4. Example, docs and release

- [ ] 4.1 `examples/certified-memory/` (store with the 665 → 655 km correction, three certificates, recorded outputs) run by `scripts/examples.sh`; annotate `[[openspec:certified-memory#Certified memory example]]`
- [ ] 4.2 Book chapter section and `site/content/docs/statements.md`: citations, views, impact; site roadmap row for F7
- [ ] 4.3 Versions bumped to 0.7.0 in every package, `scripts/check_release.py` updated, `docs/releases/v0.7.0.md`; annotate the lakefile with `[[openspec:release#Proof-carrying memory release]]`

## 5. tg.md

- [ ] 5.1 Record the decisions *Citations live beside the certificate*, *Memory checks run on the export*, *Strict citations make impact exact* and *Memory in the statements package, its command in check* in `tg.md/decisions.md` (`type: Decision`), with `- motivated_by::` edges to [[decisions#Assertion is derived from a view]], [[decisions#Own certificate format with a Datalog export]] and [[decisions#Layers as packages in one repository]], and `- introduced_by::` the change
- [ ] 5.2 Add `- constrains:: [[openspec:certified-memory#Citations]] {strength: must}` to [[constraints#tiramemsu record model]], and the same for `#Memory soundness` to [[constraints#RDFS interpretation conditions]]
- [ ] 5.3 Add the concept *Citation* to `tg.md/concepts.md`, extend [[concepts#View]], and list `certified-memory` in the `openspec:` frontmatter of the file that explains it
- [ ] 5.4 Add `add-proof-carrying-memory` to `tg.md/changes.md`
- [ ] 5.5 Run `tg check`, `tg ontology check` and `tg trace certified-memory --gaps`, and close every gap
