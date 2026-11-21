# LeanRDF roadmap: from certified reasoning to certified agents

*Status: proposal, 2026-11-20. Baseline: v0.3.1 (`b407b97`). Progress: F1 and F2 released as v0.4.0; F4 and F5 implemented for v0.5.0 (not yet tagged); F6, F7 and F9 proposed.*

The roadmap on the site ([`site/content/roadmap.md`](../site/content/roadmap.md)) records what was built, P0 to S2. This file is the next plan. It ranks the gaps that stand between today's LeanRDF and its stated purpose, *the proof layer that agentic flows run through*, and says what to build next and why.

## 1. Where the product stands

LeanRDF is strong on the inside and thin at its edges.

| Layer | State | Assessment |
|---|---|---|
| Semantics (RDF 1.1/1.2, RDFS, OWL 2 RL/EL, SPARQL 1.1, SHACL Core) | Transcribed, axiom-clean, W3C-tested | Strong; no work needed to start agentic features |
| Checkers and proven engines | `checkQuery_sound`, `evalN_perm`, `validate_conforms`, `decode_toRDF` | Strong |
| Untrusted finders | Elpi saturation, oxilite bridge, classifier | Good for test-sized data |
| **Certificate as an artifact that travels** | JSON proof DAG, version 1; no binding to the graph, rule set or regime it was checked against | **Gap.** A certificate cannot be checked by a second party without out-of-band agreement |
| **Verdicts** | Exit codes 0/1/2/3; "not derived" is never "false" | **Gap.** No certified "no"; no detection of an inconsistent knowledge base, under which every ENTAILED is vacuous |
| **Agent interface** | Six CLIs with human-oriented text output | **Gap.** No structured verdict output, no tool server, no prebuilt binaries |
| **Memory integration** | Exact statement-graph export/decode with tiramemsu | **Gap.** Certificates and statement records do not refer to each other; no "certified as of time t" |
| **Certifiability (for auditors)** | Axioms pinned in tests; simplifications in `tg.md/` | **Gap.** No machine-readable trust-base manifest, no signed or reproducible release artifacts |

## 2. Gaps found

Each gap is a place where the product, as described in [`docs/articles/certified-reasoning-for-agentic-flows.md`](articles/certified-reasoning-for-agentic-flows.md), promises more than the code delivers, or where an agent would act wrongly on a correct LeanRDF answer.

1. **No standalone verifier.** "Pattern 6: certificates as messages between agents" says agent B checks agent A's certificate with the verified checker. No executable does this: `--cert` writes a certificate, but nothing reads one back and checks it against data. The executables are `leanrdf-demo`, `-oxilite`, `-classify`, `-sparql`, `-shacl` and `-sg`.
2. **Certificates are unbound.** A `Certificate` holds nodes, goals and a mapping. It does not record which graph, which rule set (`rdfsRules`, `owlRules`, regime), which checker version or which toolchain it was checked under. A certificate checked against the wrong graph can still pass if that graph happens to contain the facts it uses. Without a content hash this cannot be detected.
3. **No canonical graph identity.** Canonical N-Triples exists, but RDF Dataset Canonicalization (RDFC-1.0) does not, so two graphs that differ only in blank-node labels cannot get the same digest. (SHA-256 exists, in `sparql/LeanRDFSparql/Hash.lean`, but not in the core package.)
4. **Inconsistency is invisible.** OWL 2 RL's rules that conclude `false` (`cax-dw`, `cls-nothing2`, `prp-irp`, `prp-asyp`, `prp-pdw`, `eq-diff1`, `cls-com`, …) are left out ([Simplifications § OWL 2 RL without list rules](../tg.md/simplifications.md)). If the knowledge base has no model, every certified ENTAILED is still true, but vacuously so. An agent then acts on "proven" facts that carry no information. **This is the most dangerous gap for agents.**
5. **No certified "no".** Every reasoning verdict is ENTAILED or NOT DERIVED. Agents need REFUTED (a countermodel exists) to tell "I do not know" apart from "no". Without it, either they treat unknown as no (unsound) or they never conclude no (useless for policy checks).
6. **Reasoning and querying do not compose.** The proven SPARQL evaluator runs over asserted data. SPARQL under RDFS or OWL entailment, the question agents actually ask, has no guarantee.
7. **Datatype values stay out of entailment.** `LeanRDF.Xsd` computes values, but the semantics recognises only three datatypes. Rules such as "age ≥ 18" or "expires before now" cannot be certified, and 9 W3C RDF 1.2 semantics tests are not run.
8. **No write path.** Patterns 3 ("gate the write") and 5 ("memory that knows when") are built by hand from separate tools. Nothing admits a delta atomically with its SHACL report, its certificates and its statement record.
9. **The compiled path trusts the compiler.** `native_decide` (28 uses) puts the Lean compiler and runtime in the trusted base of every theorem about concrete data. CertifyingDatalog is a second checker, but it is not run in CI, and it cannot check certificates that use the rdfs14 rules.
10. **Distribution.** Using LeanRDF needs elan and a `lake build` of several packages. Agent frameworks (Python, TypeScript, MCP clients) cannot adopt it as a dependency.
11. **Traceability debt.** `tg trace --gaps` lists ADR 0001 as unimplemented and undocumented. This is trivial, but it is the only red line in an otherwise clean trace.

## 3. Ranking criteria

Every feature is scored from 1 (low) to 5 (high) on six criteria. The weights reflect the product focus: agentic AI first, then verifiable, then certifiable.

| Criterion | Weight | Question it answers |
|---|---|---|
| **A** Agentic impact | 25% | Does it change what an agent can safely do, or how cheaply it can do it? |
| **V** Verifiability gain | 20% | Does it extend what is proven, or close a soundness or vacuity hole? |
| **C** Certifiability | 15% | Does it help a third party (auditor, regulator, another agent) accept the result without trusting us? |
| **G** Gap severity | 15% | How wrong is an agent's behaviour today without it? |
| **U** Unlock | 10% | How many later features depend on it? |
| **E** Ease (inverse effort) | 15% | 5 means days with existing pieces; 1 means new theory and a quarter of work |

Score = 0.25·A + 0.20·V + 0.15·C + 0.15·G + 0.10·U + 0.15·E.

## 4. Features, ranked

| Rank | ID | Feature | A | V | C | G | U | E | **Score** | Closes gap |
|---:|---|---|---:|---:|---:|---:|---:|---:|---:|---|
| 1 | F1 | `leanrdf-check`: a standalone verifier | 5 | 4 | 4 | 5 | 5 | 5 | **4.65** | 1 |
| 2 | F2 | Certificate envelope v2 with RDFC-1.0 digests | 5 | 4 | 5 | 4 | 5 | 3 | **4.35** | 2, 3 |
| 2 | F4 | Certified inconsistency detection | 5 | 5 | 4 | 5 | 3 | 3 | **4.35** | 4 |
| 4 | F5 | Certified "no": countermodel certificates | 5 | 5 | 4 | 5 | 4 | 2 | **4.30** | 5 |
| 5 | F7 | Proof-carrying memory: certified as of time t | 5 | 4 | 5 | 4 | 2 | 3 | **4.05** | 8 |
| 6 | F6 | `leanrdf-gate`: admission control for agent writes | 5 | 3 | 4 | 3 | 3 | 4 | **3.80** | 8 |
| 7 | F9 | Certified policy decisions (tool-call guard) | 5 | 4 | 4 | 3 | 2 | 2 | **3.60** | 5, 7 |
| 8 | F3 | Agent surface: `--json` verdicts and an MCP server | 5 | 2 | 2 | 4 | 4 | 4 | **3.55** | 10 |
| 9 | F10 | SPARQL under entailment regimes | 4 | 4 | 3 | 3 | 3 | 3 | **3.45** | 6 |
| 9 | F12 | Assurance pack: trust-base manifest, signed reproducible releases | 3 | 3 | 5 | 3 | 3 | 4 | **3.45** | 9, 10 |
| 11 | F14 | Domain rules as declared axioms | 4 | 3 | 3 | 3 | 3 | 3 | **3.25** | — |
| 12 | F8 | D-entailment over XSD values | 4 | 3 | 3 | 3 | 3 | 2 | **3.10** | 7 |
| 12 | F13 | Prebuilt binaries and Python/TypeScript wrappers | 4 | 1 | 2 | 4 | 4 | 4 | **3.10** | 10 |
| 14 | F11 | Shrink the trusted base: kernel path, LF terms, a second checker in CI | 2 | 4 | 5 | 2 | 2 | 2 | **2.85** | 9 |
| 14 | F16 | Minimal certificates and faithful explanations | 4 | 2 | 3 | 2 | 1 | 4 | **2.85** | — |
| 16 | F17 | Scale: checker benchmarks, streaming check, compact certificates | 3 | 2 | 2 | 3 | 3 | 3 | **2.65** | — |
| 17 | F15 | OWL 2 RL list rules (keys, property chains, n-ary intersections) | 3 | 3 | 2 | 2 | 2 | 3 | **2.60** | — |
| 18 | F18 | SHACL recursion, SHACL-SPARQL, SHACL rules | 3 | 3 | 2 | 2 | 1 | 2 | **2.35** | — |
| — | F19 | Close ADR 0001 in the trace | — | — | — | — | — | — | chore | 11 |

## 5. Feature cards

### F1 · `leanrdf-check`: a standalone verifier (4.65)

**What.** An executable and a library entry point that read a certificate, the data and a rule-set name, run the verified checker, and print a verdict with the usual exit codes. `leanrdf-check --data g.nt --query q.nt --rules rdfs|rdf|simple|owl --cert c.json`.

**Why first.** It turns the published Pattern 6 claim into a shipped tool, it costs days (`checkQuery` and `Certificate.parse` already exist), and it is the receiving side of every other feature. It is also the smallest trusted program in the product, which makes it the right thing for agents and auditors to install.

**Done when.** Round-trip tests pass: every certificate written by `leanrdf-demo`, `leanrdf-oxilite` and `leanrdf-classify` is accepted. Tampered certificates (wrong premise, wrong rule, fact not in the graph, wrong mapping) are rejected with exit 2, and the theorem the check stands for is named in the output.

### F2 · Certificate envelope v2 with RDFC-1.0 digests (4.35)

**What.** `version: 2` adds a header that binds the proof to its context: a `graph` digest (SHA-256 over RDFC-1.0 canonical N-Quads), a `query` digest, the `rules` identifier with a digest of the rule list, the `regime`, the checker version, the Lean toolchain, and the theorem name (`checkQuery_sound`, `owl_sound`, …). F1 recomputes every digest and rejects any mismatch. The header is untrusted metadata, and the checker never relies on it for soundness. It exists so that a second party knows exactly *what* was proven.

**Also.** Move SHA-256 from `leanrdf-sparql` to the core. Implement RDFC-1.0 (a W3C Recommendation, with a test suite) and prove the easy half: the canonical form is isomorphic to the input. Leave canonicity, "isomorphic inputs get equal outputs", as a tested claim recorded in `simplifications.md` until it is proven.

**Why.** Without binding, a certificate is a proof of *something* about *some* graph. With binding, it becomes a portable claim: "graph `sha256:…` RDFS-entails query `sha256:…`". Agents can cache it, log it, sign it and exchange it. Every later feature (memory, gate, policy, audit) carries this envelope.

### F4 · Certified inconsistency detection (4.35)

**What.** A new certificate goal kind, `clash`. It is a derivation whose last node fires a rule with head `false`. The theorem is `checkClash_sound : … → ¬ ∃ I, I ⊨ g`. Add the fixed-arity OWL 2 RL `false` rules and the RDF D-clash, an ill-typed literal of a recognised datatype. Every reasoning tool first asks Elpi for a clash and reports `INCONSISTENT` (a new exit code, 4) before anything else.

**Why.** It closes the vacuity hole. Today LeanRDF can hand an agent a correct but meaningless theorem. The rules are already Horn-shaped, and soundness proofs follow the existing pattern, so the risk lies in the semantic statement (`OWLConds` must expose the disjointness and irreflexivity conditions), not in the machinery.

**Done when.** The W3C OWL 2 RL inconsistency cases that fall in the fixed-arity fragment are certified. The classifier's two unsatisfiable classes are reported through the same mechanism.

### F5 · Certified "no": countermodel certificates (4.30)

**What.** For RDF, RDFS and simple entailment, the finder emits a *finite interpretation*: domain, `IR`/`IP`/`IEXT` tables, the literal and triple-term maps, and a blank-node assignment for `g`. A verified model checker confirms that the interpretation satisfies the regime's conditions and `g`, and that no assignment makes `q` true. The theorem is `checkCountermodel_sound : … → ¬ g.RDFSEntails q`. The verdict becomes `REFUTED`. The canonical model built from the saturated closure is the obvious candidate, and the existing small-model family (vacuity tests) is the starting code.

**Why.** It turns LeanRDF's verdicts from two values into four: PROVEN / REFUTED / UNKNOWN / INCONSISTENT. That is the minimum an agent needs to make a decision instead of only an assertion. It follows the house rule, *untrusted finds, Lean checks*, so no completeness proof for the rule set is required.

**Risk.** The infinite conditions (`rdf:_n` container axioms, all literals) need a finite representation with an "everything else" element. Prototype on simple entailment first, then RDF, then RDFS. OWL countermodels are out of scope.

### F7 · Proof-carrying memory: certified as of time t (4.05)

**What.** Join `leanrdf-statements` and certificates. A `fact` node may cite a statement record `eid`. A check takes a view (now, as of transaction `t`, valid at time `v`) and proves `(view g).RDFSEntails q`. Retraction impact is the set of certificates that cite a record no longer live in the view. It is computed exactly, because certificates name their premises.

**Why.** This is the "what did the agent know, and when" story with proofs attached. When a premise is corrected in tiramemsu, the agent learns exactly which conclusions lost their support. This is truth maintenance without trusting the store. It is also the strongest audit artifact the product can offer: a decision, its proof, and the bitemporal state the proof held in.

**Depends on.** F2 (the envelope carries the view and the export digest).

### F6 · `leanrdf-gate`: admission control for agent writes (3.80)

**What.** One command with one verdict for a proposed delta: SHACL-validate the post-state (proven validator), require an F2 certificate for every triple marked as derived, run the F4 clash check on the post-state, and on success emit tiramemsu statement records whose provenance cites the certificates. On failure, return the SHACL results and the rejected nodes as a repair target.

**Why.** "No proof, no entry" stops being an essay and becomes a single call that agent frameworks put in front of memory.

### F9 · Certified policy decisions as a tool-call guard (3.60)

**What.** A small policy profile: permissions, prohibitions and duties as RDF, with rules and shapes. A decision procedure returns `PERMIT` with a permission certificate *and* certified absence of a matching prohibition (F5 or the proven SPARQL evaluator over a certified closure), `DENY` with a prohibition certificate, or `NOT DECIDED`. Ship it with an example agent whose tool calls go through the guard.

**Why.** It is the flagship agentic demo: an agent that cannot call a tool unless a theorem says it may. It exercises F1, F2, F4 and F5 end to end. An ODRL subset is the natural target vocabulary. Start with a minimal vocabulary and map to ODRL later.

### F3 · Agent surface: `--json` verdicts and an MCP server (3.55)

**What.** Every CLI gets `--json`: `{verdict, exit, theorem, envelope, certificate | countermodel | report}`. `leanrdf-mcp` exposes `entail`, `check`, `validate`, `query`, `classify`, `gate` and `explain` as MCP tools whose results are those JSON verdicts.

**Why.** It is cheap, and it removes the step where an LLM parses human text, the place where certified results would turn back into untrusted ones. Ship `--json` together with F1, and the MCP server after F4 and F5, so the tool contract carries all four verdicts from day one.

### F10 · SPARQL under entailment regimes (3.45)

The proven evaluator runs over a closure whose every triple is certified. Answers are then sound under RDFS or OWL 2 RL. With F5, absence-sensitive operators (`MINUS`, `NOT EXISTS`, aggregates) become correct for the regime on the closure fragment.

### F12 · Assurance pack (3.45)

Per release: a machine-readable trust-base manifest (each main theorem, its axioms, `native_decide` usage, the trusted executables and their source digests), the simplifications with their impact, the W3C pass report, reproducible builds, signed binaries with SLSA provenance, and a short mapping to EU AI Act record-keeping and accuracy obligations (Art. 12, 15) and ISO/IEC 42001 controls. Most of the content exists already. This feature packages it so that a third party can read it.

### F14 · Domain rules as declared axioms (3.25)

Agents run on business rules ("a contractor with an active NDA may read design docs") that no W3C semantics covers. Let users declare Horn rules, in Datalog or N3 syntax, as *named axioms*. The certificate theorem is then `g ∪ R ⊨ q`, with `R` listed in the envelope. This also covers oxilite's Datalog programs, an item already on the "Later" list. It is honest about where trust moves: to the rules the user wrote.

### F8 · D-entailment over XSD values (3.10)

Recognise `xsd:integer`, `decimal`, `boolean`, `dateTime` and `string` in the semantics, using the proven `LeanRDF.Xsd` value spaces. Add value-comparison guards. This unlocks numeric and temporal conditions in F9 and the 9 W3C tests that are not run today.

### F13 · Distribution (3.10)

Release binaries for macOS and Linux, a container image, and thin Python and TypeScript wrappers over the `--json` CLIs. No Lean toolchain is needed to *check*.

### F11 · Shrink the trusted base (2.85)

A kernel-reducible path for small certificates (`decide` instead of `native_decide`, working around [String hash is opaque to the kernel](../tg.md/constraints.md)). Run the CertifyingDatalog cross-check in CI on every recorded certificate. Then lean-elpi LF proof terms as a second backend. This matters most to the certification audience, less to agents.

### F15–F18 · Coverage

These are completeness work, each recorded today as a simplification: list rules and property chains for OWL 2 RL, arbitrary-length EL intersections, recursive shapes, SHACL-SPARQL, checker benchmarks and compact certificates at oxilite scale. Schedule them when a user's ontology needs them, not before.

## 6. Plan

```
v0.4  Proof-carrying answers     F1 + F2 + --json (F3, part)        ← build next
v0.5  Four-valued verdicts       F4 + F5                            ← the agentic safety release
v0.6  Agent surface              F3 (MCP) + F6 + F13
v0.7  Proof-carrying memory      F7 (with tiramemsu)
v0.8  Certified decisions        F9 + F8 + F14 (+ F10)
cont. Certifiability track       F12 every release; F11 when an auditor asks
later Coverage                   F15–F18 on demand
```

Each line is one OpenSpec change (two for v0.5), following the project's existing practice: a proposal, specs with scenarios, tasks, `tg.md/` decisions and simplifications, archive, release.

## 7. What to build next, and why

**Build v0.4: `leanrdf-check` with certificate envelope v2 (F1 + F2), and `--json` output on the way.**

1. **It makes the published claim true.** The agentic article sells certificates as messages between agents. Today half of that exchange has no tool. Shipping F1 closes the distance between the story and the product before anyone else notices it.
2. **It is the cheapest high-value step.** The checker, the parser, SHA-256 and canonical N-Triples all exist. The new proof obligation (RDFC-1.0 output is isomorphic to its input) is modest, and the hard part (canonicity) can be recorded as a simplification first.
3. **Everything else depends on it.** Memory (F7), the gate (F6), policy (F9), the MCP tools (F3) and the assurance pack (F12) all carry the envelope and end in `leanrdf-check`. Building them first would mean retrofitting the format later.

**Then v0.5 (F4 + F5), immediately.** It is the release that matters most for safety. Until LeanRDF can say INCONSISTENT and REFUTED, an agent that uses it can still be confidently wrong: through a vacuous proof, or by reading "not derived" as "no". If only one proof-heavy feature can be funded this year, it is F4. It is smaller than F5, and it closes the only hole through which a *certified* answer can mislead.

**Deliberately not next:** more OWL or SHACL coverage (F15, F18), and scale work (F17). They make LeanRDF a better reasoner. The roadmap above makes it a better *proof layer for agents*, which is the gap no other project fills.
