## Why

LeanRDF's agentic story rests on certificates travelling between parties: one agent finds a derivation, and another checks it without redoing the search or trusting the first. Today half of that exchange has no tool. `leanrdf-demo --cert` writes a certificate, but no executable reads one back and checks it against data. The only way to check a certificate is to write Lean. This change adds the receiving side: a small executable that contains the verified checker and nothing that searches. First of seven changes on the agentic roadmap (`docs/ROADMAP.md`, F1).

## What Changes

- New Lake package `check/` (`leanrdf-check`). It requires the core and `leanrdf-owl`, and not lean-elpi, so the trusted tool builds without the untrusted search.
- `Regime`: `simple`, `rdf`, `rdfs`, `owl`, `el`. Each regime has its rule list, its entailment proposition and the name of its soundness theorem.
- `checkRegime` and one theorem `checkRegime_sound`: an accepted certificate proves the regime's entailment of the query. It is assembled from the existing `checkQuery_sound*`, `Derives.owl_sound_graph` and `Derives.el_sound_graph`, with no new axioms.
- `leanrdf-check --data D --query Q --cert C [--rules R] [--json]`. Data and query are read as N-Triples, or as Turtle by extension. The tool prints the verdict, the theorem the acceptance stands for, the query instance and, when rejected, the checker's reason. Exit codes: `0` proven, `2` rejected, `3` input error.
- `--json` writes one verdict object: `verdict`, `exit`, `regime`, `theorem`, `nodes`, `goals`, `mapping`, `reason`. The `verdict` vocabulary (`proven`, `refuted`, `unknown`, `inconsistent`, `rejected`, `input-error`) is fixed now, so later changes add values without renaming any.
- Recorded certificates for each regime, with tampered variants, under `check/CheckTests/data/`, and an `examples/certificate-check/` example.

## Capabilities

### New Capabilities

- `certificate-check`: the regimes, the regime checker and its soundness, the `leanrdf-check` command line, the JSON verdict, and the recorded certificate corpus.

### Modified Capabilities

None. `certificates` is unchanged: the format stays version 1, and binding a certificate to its graph is the next change, `add-certificate-envelope`.

## Impact

**Roadmap:** F1 of `docs/ROADMAP.md`. Followed by `add-certificate-envelope`; both ship as v0.4.0, and the release delta lives in that change.

**Code:**
- new package: `check/` (`lakefile.lean`, `lean-toolchain`, `LeanRDFCheck/{Regime,Cli,Verdict}.lean`, `CheckMain.lean`, `CheckTests/`)
- CI: a `check` job in `.github/workflows/ci.yaml`; `scripts/check_release.py` lists the seventh package
- docs: `site/content/docs/cli.md`, `site/content/docs/certificates.md`, `examples/certificate-check/`

**tg.md sections touched:**
- [[decisions#Elpi finds, Lean checks]]: this change ships the "Lean checks" half as a tool
- [[decisions#Layers as packages in one repository]] and [[decisions#Dependency-free core package]] bind the new package
- [[decisions#Demo never claims non-entailment]]: the checker has no "not derived" verdict at all
- new decisions: *A checker package without the search*, *One verdict vocabulary for every tool*

**Requirements:**
- added: `certificate-check#Regimes`, `#Regime checker soundness`, `#Certificate check command`, `#JSON verdict`, `#Certificate corpus`
- depends on: [[openspec:certificates#Checker soundness]], [[openspec:certificates#Certificate format]], [[openspec:owl-rl#OWL soundness]], [[openspec:owl-el#EL soundness]]
