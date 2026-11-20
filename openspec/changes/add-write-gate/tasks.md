## 1. Package

- [ ] 1.1 `gate/lakefile.lean` (`leanrdf-gate` 0.6.0; requires `leanrdf` from `..`, `leanrdf-shacl` from `../shacl`, `leanrdf-statements` from `../statements`, `leanrdf-check` from `../check`; lib `LeanRDFGate`, tests `GateTests`, `lean_exe leanrdf-gate`), `lean-toolchain` v4.35.0, `lake-manifest.json`

## 2. Delta and decision

- [ ] 2.1 `LeanRDFGate/Delta.lean` and `Manifest.lean`: added and removed N-Triples, a JSON manifest of derived triples with certificate paths and rule sets, errors with file and line; annotate with `@tg: implements:: [[openspec:write-gate#Delta format]]`
- [ ] 2.2 `LeanRDFGate/Admit.lean`: `postState`, `admit`, the `Rejection` type with every reason; annotate `[[openspec:write-gate#Admission decision]]` and `[[openspec:write-gate#Rejection reports]]`
- [ ] 2.3 `admit_conforms`, `admit_derived` (one case per rule set, through `checkQuery_sound*` and `Derives.owl_sound_graph` and `Derives.el_sound_graph`), `admit_consistent`, `reject_sound`; annotate `[[openspec:write-gate#Admission soundness]]`
- [ ] 2.4 The consistency policies (`default`, `require-model`) over F4's `checkClash` and F5's model checker; annotate `[[openspec:write-gate#Consistency policy]]`

## 3. Records and command line

- [ ] 3.1 `LeanRDFGate/Records.lean`: fresh eids, retractions by exact match against records live in `now`, provenance records with `urn:leanrdf:certifiedBy`, and a `WellFormed` check before emitting; annotate `[[openspec:write-gate#Record emission]]`
- [ ] 3.2 `LeanRDFGate/Cli.lean`, `GateMain.lean`: `admit` with every flag, `--json`, exit codes 0 to 4; annotate `[[openspec:write-gate#Gate command line]]`

## 4. Tests

- [ ] 4.1 `GateTests/`: one test per scenario of `Delta format`, `Admission decision`, `Rejection reports`, `Consistency policy`, `Record emission` and `Gate command line`, each with `@tg: verifies:: [[openspec:write-gate#<Requirement>#<Scenario>]]` directly above it
- [ ] 4.2 Pin the axioms of the four theorems; annotate `[[openspec:write-gate#Admission soundness#Admission theorems are axiom-clean]]`
- [ ] 4.3 Emitted records round-trip through `leanrdf-sg check`; annotate `[[openspec:write-gate#Record emission#Emitted records are well-formed]]`

## 5. Example, docs and release

- [ ] 5.1 `examples/write-gate/` (memory, shapes, one admitted and three rejected writes, certificates found with `leanrdf-demo`, recorded outputs), run by `scripts/examples.sh`; annotate `[[openspec:write-gate#Write gate example]]`
- [ ] 5.2 `site/content/docs/gate.md`, a book section "Gate the write", the CLI page and the site roadmap row for F6
- [ ] 5.3 CI job for `gate/`; versions bumped to 0.6.0 in every package; `scripts/check_release.py`; `docs/releases/v0.6.0.md`; annotate the lakefile with `[[openspec:release#Write gate release]]` and `[[openspec:release#Release version]]`

## 6. tg.md

- [ ] 6.1 Record the decisions *The gate checks and never searches*, *A gate package above shacl, statements and check*, *Admission is a pure function with theorems*, *Consistency is a policy, not a default*, *Provenance as statements about statements* and *Removals retract by exact match* in `tg.md/decisions.md`, with `- motivated_by::` edges to [[decisions#Elpi finds, Lean checks]], [[decisions#Layers as packages in one repository]], [[decisions#Demo never claims non-entailment]] and [[decisions#Bitemporal records with eid references]], and `- introduced_by::` the change
- [ ] 6.2 Add `- constrains:: [[openspec:write-gate#Admission soundness]] {strength: must}` to [[constraints#SHACL Core]], and `- constrains:: [[openspec:write-gate#Record emission]] {strength: must}` to [[constraints#tiramemsu record model]]
- [ ] 6.3 Add a file that explains the gate, or a section of an existing one, with `write-gate` in its `openspec:` frontmatter; add `add-write-gate` to `tg.md/changes.md`
- [ ] 6.4 Run `tg check`, `tg ontology check` and `tg trace write-gate --gaps`, and close every gap
