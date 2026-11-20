## Why

"No proof, no entry" is LeanRDF's answer to agent memory that fills up with wrong facts. Today an agent framework has to assemble that answer from separate tools: `leanrdf-shacl` for shapes, `leanrdf-check` for certificates, a clash check from `add-inconsistency-certificates`, and its own code to write statement records. Each integration is untested glue, and the glue decides what enters memory.

This change ships the gate as one command with one verdict. A proposed delta, meaning triples to add and triples to remove, is admitted only when:

- the post-state conforms to the memory's shapes, by the proven SHACL validator;
- every triple the agent marks as *derived* comes with a certificate that the verified checker accepts against the post-state;
- no supplied clash certificate shows the post-state to be inconsistent, and, when the gate's policy asks for it, a model certificate shows that it is consistent.

On success, the gate emits tiramemsu statement records whose provenance cites the certificate digests. On failure, it returns the SHACL report and the rejected items as a repair target. This is feature F6 of `docs/ROADMAP.md`. It ships v0.6.0, the agent-surface release.

## What Changes

- New Lake package `gate/` (`leanrdf-gate`), requiring `leanrdf`, `leanrdf-shacl`, `leanrdf-statements` and `leanrdf-check`. It has no Elpi: the gate never searches. Finders (Elpi through `leanrdf-demo`, oxilite, another agent) supply the certificates.
- A **delta** format: `add.nt` and `remove.nt` (RDF 1.2 N-Triples), plus a JSON manifest that marks derived triples and maps each one to a version-2 certificate file.
- `admit`, a pure decision function over (pre-state, delta, shapes, certificates, clash and model certificates, policy). It returns `Admitted records` or `Rejected reasons`.
- Theorems:
  - `admit_conforms`: an admitted post-state conforms to the shapes (`DataConforms`, through `validate_conforms`);
  - `admit_derived`: every admitted derived triple is entailed by the post-state's asserted part under the certificate's regime, through `checkQuery_sound*`;
  - `admit_consistent`: under the `require-model` policy, the post-state has a model, through the model checker of `add-countermodels`;
  - `reject_sound`: every SHACL result in a rejection is a real violation (`validate_sound`).
- Record emission:
  - one JSON-lines record per added triple, with the transaction `--tx T` and eids from `--first-eid E`;
  - a retraction for each removed triple matched against `--store`;
  - for each derived triple, a provenance record `(e', {eid e}, urn:leanrdf:certifiedBy, "sha256:…")`.
- `leanrdf-gate admit --store S.jsonl --add A.nt --remove R.nt --shapes SH.ttl --manifest M.json --tx T --first-eid E [--policy require-model] [--json]`, with exit codes 0 admitted, 1 rejected by shapes or by a missing or failed derivation, 2 a certificate was rejected, 3 input error, and 4 inconsistent.
- `examples/write-gate/`: an agent's admitted write and three rejected ones (a shape violation, a forged derivation, an inconsistent write).
- Release v0.6.0.

## Capabilities

### New Capabilities

- `write-gate`: the delta format, the admission decision and its theorems, record emission with provenance, the command line, and the example.

### Modified Capabilities

- `release`: version 0.6.0, and the `v0.6.0` release.

## Impact

**Roadmap:** F6. It needs `add-certificate-check` (F1), `add-certificate-envelope` (F2), `add-inconsistency-certificates` (F4) and, for `require-model`, `add-countermodels` (F5). It ships as v0.6.0, before `add-proof-carrying-memory` (F7, v0.7.0), which adds retraction impact.

**Code:**
- new package: `gate/` (`lakefile.lean`, `LeanRDFGate/{Delta,Manifest,Admit,Records,Cli}.lean`, `GateMain.lean`, `GateTests/`);
- CI: `.github/workflows/ci.yaml` gains the `gate/` job;
- `examples/write-gate/`, `scripts/examples.sh`;
- docs: `site/content/docs/gate.md`, a book section on gating writes.

**tg.md sections touched:**
- binding decisions: [[decisions#Layers as packages in one repository]], [[decisions#Dependency-free core package]], [[decisions#Elpi finds, Lean checks]], [[decisions#SHACL Core with a validator proven against its semantics]], [[decisions#Bitemporal records with eid references]], [[decisions#Demo never claims non-entailment]];
- binding constraints: [[constraints#SHACL Core]], [[constraints#tiramemsu record model]];
- new decisions: *The gate checks and never searches*, *A gate package above shacl, statements and check*, *Provenance as statements about statements*, *Consistency is a policy, not a default*.

**Requirements:**
- added: `write-gate#Delta format`, `#Admission decision`, `#Admission soundness`, `#Rejection reports`, `#Consistency policy`, `#Record emission`, `#Gate command line`, `#Write gate example`; `release#Write gate release`;
- modified: [[openspec:release#Release version]];
- depends on: [[openspec:shacl-core#Proven validator]], [[openspec:statement-graphs#Statement records]], [[openspec:statement-graphs#Statement graph command line]], [[openspec:certificates#Checker soundness]], and the requirements of `certificate-check`, the version-2 envelope, `inconsistency` and `countermodels`.
