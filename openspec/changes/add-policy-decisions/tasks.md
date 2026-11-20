## 1. Package and vocabulary

- [ ] 1.1 `policy/lakefile.lean` (`leanrdf-policy` 0.8.0; requires `leanrdf` from `..`, `leanrdf-shacl` from `../shacl`, `leanrdf-check` from `../check`; lib `LeanRDFPolicy`, tests `PolicyTests`, `lean_exe leanrdf-policy`), `lean-toolchain` v4.35.0, `lake-manifest.json`
- [ ] 1.2 `LeanRDFPolicy/Vocab.lean` and `policy/vocab.ttl`; annotate with `@tg: implements:: [[openspec:policy-decisions#Policy vocabulary]]`
- [ ] 1.3 `LeanRDFPolicy/Shapes.lean` and `policy/policy-shapes.ttl`, validated with `validate` before every decision; annotate `[[openspec:policy-decisions#Well-formed policies]]`

## 2. Requests, patterns and decisions

- [ ] 2.1 `LeanRDFPolicy/Request.lean`: `Request` and `decisionGraph`; annotate `[[openspec:policy-decisions#Requests and decision graphs]]`
- [ ] 2.2 `LeanRDFPolicy/Pattern.lean`: `pattern K R`, `Applies`, `Allowed`; annotate `[[openspec:policy-decisions#Match patterns]]`
- [ ] 2.3 `LeanRDFPolicy/Decide.lean`: `decide` over the evidence, the reasons for `notDecided`; annotate `[[openspec:policy-decisions#Decision function]]`
- [ ] 2.4 `decide_permit_sound`, `decide_deny_sound`, `permit_consistent` and `decide_inconsistent_sound`, through `checkQuery_sound`, F5's countermodel soundness and F4's `checkClash_sound`; annotate `[[openspec:policy-decisions#Decision soundness]]`

## 3. Command line

- [ ] 3.1 `LeanRDFPolicy/Cli.lean`, `PolicyMain.lean`: `decide` and `patterns`, `--json`, exit codes 0 to 5; annotate `[[openspec:policy-decisions#Policy command line]]`

## 4. Tests

- [ ] 4.1 `PolicyTests/`: one test per scenario of `Policy vocabulary`, `Well-formed policies`, `Requests and decision graphs`, `Match patterns`, `Decision function` and `Policy command line`, each with `@tg: verifies:: [[openspec:policy-decisions#<Requirement>#<Scenario>]]` directly above it
- [ ] 4.2 Pin the axioms of the four theorems, and obtain `Allowed g R` for the example with `native_decide`; annotate both scenarios of `[[openspec:policy-decisions#Decision soundness]]`

## 5. Example, docs and release

- [ ] 5.1 `examples/policy-guard/` (`policies.ttl`, `data.nt`, `guard.sh` running `leanrdf-policy patterns`, the Elpi finder, F5's countermodel finder and `leanrdf-policy decide`; recorded permit, deny and not-decided runs), checked by `scripts/examples.sh`; annotate `[[openspec:policy-decisions#Tool-call guard example]]`
- [ ] 5.2 `site/content/docs/policy.md` with the ODRL mapping table and the features not covered; a book section "Certified decisions for agents"; the site roadmap row for F9; annotate `[[openspec:policy-decisions#ODRL mapping]]`
- [ ] 5.3 CI job for `policy/`; versions bumped to 0.8.0 in every package; `scripts/check_release.py`; `docs/releases/v0.8.0.md`; annotate the lakefile with `[[openspec:release#Policy decisions release]]` and `[[openspec:release#Release version]]`

## 6. tg.md

- [ ] 6.1 Record the decisions *Applicability is entailment of a match pattern*, *Absence by countermodel, not by query*, *Prohibition overrides permission*, *Classes, not individuals, in rules*, *Purpose is the only constraint until datatypes*, *Well-formed policies by SHACL* and *A policy package* in `tg.md/decisions.md`, with `- motivated_by::` edges to [[constraints#Entailed blank nodes are existential]], [[decisions#Demo never claims non-entailment]], [[decisions#Graph queries with instance mappings]] and [[decisions#Layers as packages in one repository]], and `- introduced_by::` the change
- [ ] 6.2 Add the simplification *Policy constraints limited to purpose classes* to `tg.md/simplifications.md` (`source:: ODRL 2.2 Information Model §2.5`, `impact:: scope`); add a Constraint section for ODRL 2.2 with `source:` and `- constrains:: [[openspec:policy-decisions#ODRL mapping]] {strength: should}` for the simplification to deviate from; add `- constrains:: [[openspec:policy-decisions#Decision soundness]] {strength: must}` to [[constraints#RDFS interpretation conditions]]
- [ ] 6.3 Add a file that explains policy decisions, or a section of an existing one, with `policy-decisions` in its `openspec:` frontmatter; add `add-policy-decisions` to `tg.md/changes.md`
- [ ] 6.4 Run `tg check`, `tg ontology check` and `tg trace policy-decisions --gaps`, and close every gap
