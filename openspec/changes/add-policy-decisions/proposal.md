## Why

An agent that calls tools needs one question answered before every call: *may I do this?* Today the answer comes from code that nobody proves, or from an LLM reading a policy document. LeanRDF already has the parts for a better answer:
- certificates prove that a permission applies (F1, F2);
- `clash` certificates expose an inconsistent policy base (F4);
- countermodels prove that something is *not* entailed (F5).

The last one is what makes policy decisions possible. "Permit" needs proof that a permission applies *and* proof that no prohibition does. Until F5, the second half could only be "not derived", which is not a decision.

This change adds certified policy decisions: `PERMIT` with a theorem, `DENY` with a theorem, or `NOT DECIDED`. It ships an example agent whose tool calls go through the guard. This is feature F9 of `docs/ROADMAP.md`, the flagship agentic demo: an agent that cannot call a tool unless a theorem says it may.

## What Changes

- New Lake package `policy/` (`leanrdf-policy`), requiring `leanrdf`, `leanrdf-shacl` and `leanrdf-check`. It has no Elpi.
- A minimal policy vocabulary, `pol:` = `https://volland.github.io/rdf-lean/ns/policy#`:
  - the rule kinds `pol:Permission` and `pol:Prohibition`;
  - the properties `pol:assignee`, `pol:action`, `pol:target` and `pol:purpose`, each naming a *class*;
  - `pol:AnyPurpose`, the class of every purpose.
  
  A shapes graph for well-formed policies (exactly one value for each property) is checked with the proven SHACL validator. A table maps the vocabulary to an ODRL 2.2 subset, for a later ODRL reader.
- A request `(agent, action, target, purpose)` and its *decision graph*, `G_R = g ∪ {purpose rdf:type pol:AnyPurpose}`.
- For each rule kind, a *match pattern*: a query graph with blank nodes for the rule and its four classes. A rule *applies* exactly when `G_R` RDFS-entails the pattern. Class hierarchies, such as `ex:Lecturer rdfs:subClassOf ex:Staff`, therefore apply for free.
- `decide`, a pure function over the policy base, the data, the request and the supplied evidence:
  - `PERMIT` when a permission certificate is accepted *and* a countermodel for the prohibition pattern is accepted;
  - `DENY` when a prohibition certificate is accepted;
  - `NOT DECIDED` otherwise;
  - `INCONSISTENT` when a supplied clash certificate is accepted.
  
  Prohibition overrides permission.
- Theorems:
  - `decide_permit_sound`: `PERMIT` implies `Allowed g R`, which is `G_R ⊨ P⁺(R) ∧ ¬ G_R ⊨ P⁻(R)`;
  - `decide_deny_sound`: `DENY` implies `G_R ⊨ P⁻(R)`;
  - `permit_consistent`: `PERMIT` implies that `G_R` has an RDFS model, so a permit is never vacuous.
- `leanrdf-policy decide --policies P.ttl --data D.nt --agent A --action X --target T --purpose U [--permit C.json] [--absence M.json] [--deny C.json] [--clash C.json] [--json]`. Its exit codes are 0 permit, 1 not decided, 2 evidence rejected, 3 input error, 4 inconsistent and 5 deny. The JSON `verdict` is `proven` for permit, `refuted` for deny and `unknown` for not decided.
- `examples/policy-guard/`: an agent tool-call guard. A script runs the finders (Elpi for certificates, F5's finder for countermodels), calls `leanrdf-policy decide`, and runs the tool only on exit 0. It includes recorded runs for permit, deny and not decided.
- Release v0.8.0.

## Capabilities

### New Capabilities

- `policy-decisions`: the vocabulary and its shapes, requests and decision graphs, match patterns, the decision function and its theorems, the command line, the ODRL mapping table, and the guard example.

### Modified Capabilities

- `release`: version 0.8.0, and the `v0.8.0` release.

## Impact

**Roadmap:** F9, the last of the seven agentic changes. It needs `add-certificate-check` (F1), `add-certificate-envelope` (F2), `add-inconsistency-certificates` (F4) and `add-countermodels` (F5). It ships as v0.8.0. Datatype constraints such as "age ≥ 18" wait for D-entailment (F8, not in this series).

**Code:**
- new package: `policy/` (`lakefile.lean`, `LeanRDFPolicy/{Vocab,Shapes,Request,Pattern,Decide,Cli}.lean`, `PolicyMain.lean`, `PolicyTests/`);
- `examples/policy-guard/` (`policies.ttl`, `data.nt`, `guard.sh`, `expected/`), `scripts/examples.sh`;
- CI: the `policy/` job;
- docs: `site/content/docs/policy.md`, a book section on certified decisions.

**tg.md sections touched:**
- binding decisions: [[decisions#Elpi finds, Lean checks]], [[decisions#Demo never claims non-entailment]], [[decisions#Graph queries with instance mappings]], [[decisions#Layers as packages in one repository]], [[decisions#A proven reference evaluator for SPARQL]];
- binding constraints: [[constraints#Entailed blank nodes are existential]], [[constraints#RDFS interpretation conditions]], [[constraints#SHACL Core]];
- new decisions: *Applicability is entailment of a match pattern*, *Absence by countermodel, not by query*, *Prohibition overrides permission*, *Classes, not individuals, in rules*, *Purpose is the only constraint until datatypes*;
- a new simplification: *Policy constraints limited to purpose classes*.

**Requirements:**
- added: `policy-decisions#Policy vocabulary`, `#Well-formed policies`, `#Requests and decision graphs`, `#Match patterns`, `#Decision function`, `#Decision soundness`, `#Policy command line`, `#ODRL mapping`, `#Tool-call guard example`; `release#Policy decisions release`;
- modified: [[openspec:release#Release version]];
- depends on: [[openspec:certificates#Checker soundness]], [[openspec:shacl-core#Proven validator]], and the requirements of `certificate-check`, the version-2 envelope, `inconsistency` and `countermodels`.
