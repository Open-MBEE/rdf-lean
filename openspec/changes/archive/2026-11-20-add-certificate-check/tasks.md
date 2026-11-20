## 1. Package

- [x] 1.1 `check/lakefile.lean` (`leanrdf-check` at the current release version, `require leanrdf from ".."`, `require «leanrdf-owl» from "../owl"`, lib `LeanRDFCheck`, tests `CheckTests` with the corpus as an `input_dir`, test driver, `lean_exe leanrdf-check`), `lean-toolchain` v4.35.0, `lake-manifest.json`

## 2. Regimes and the checker

- [x] 2.1 `LeanRDFCheck/Regime.lean`: `Regime`, `name`, `ofName?`, `rules`, `Entails`, `theoremName`; annotate `Regimes`
- [x] 2.2 `checkRegime` and `checkRegime_sound`; annotate `Regime checker soundness`

## 3. Command line

- [x] 3.1 `LeanRDFCheck/Verdict.lean`: `Verdict` with its exit codes and JSON; annotate `JSON verdict`
- [x] 3.2 `LeanRDFCheck/Cli.lean`: argument parsing, reading data and query (N-Triples, or Turtle by extension) and the certificate, the text and JSON reports, and `run : Args → IO (UInt32 × String)`; annotate `Certificate check command`
- [x] 3.3 `CheckMain.lean`

## 4. Tests

- [x] 4.1 `CheckTests/Regime.lean`: name round trip, theorem names, an RDFS and an OWL theorem from `checkRegime_sound` with `native_decide`, the axiom pin, the regime mismatch; each with `@tg: verifies::`
- [x] 4.2 `CheckTests/data/`: the demo's certificates for `query-mammal-owner` and `query-tom-animal`, hand-built certificates for `simple`, `rdf`, `owl` and `el`, tampered variants, and a `corpus.tsv` of `regime data query cert expected-exit`
- [x] 4.3 `CheckTestsMain.lean` (the test driver): the corpus, bad input, and the JSON verdicts run through `run` in the test driver; annotate `Certificate corpus` and the command scenarios

## 5. CI, docs and tg.md

- [x] 5.1 A `check` job in `.github/workflows/ci.yaml`; `scripts/check_release.py` lists `check/lakefile.lean`
- [x] 5.2 `examples/certificate-check/` with a recorded output, run by `scripts/examples.sh`
- [x] 5.3 `site/content/docs/cli.md` and `certificates.md` describe `leanrdf-check`; the README tool table lists it
- [x] 5.4 Record the decisions *A checker package without the search*, *Regimes as a closed inductive with a soundness theorem*, *One verdict vocabulary for every tool* and *Turtle by extension* in `tg.md/decisions.md` with their `motivated_by` edges; add the change to `tg.md/changes.md`; list `certificate-check` in the `openspec:` frontmatter
- [x] 5.5 `tg check`, `tg ontology check` and `tg trace certificate-check --gaps` with no gaps in this change's five requirements (the remaining gaps are requirements of later, pending changes)
