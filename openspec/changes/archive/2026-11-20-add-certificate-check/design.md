## Context

The checker (`LeanRDF.Cert.checkQuery`) and its soundness theorems exist for three regimes in the core, and `Derives.owl_sound_graph` and `Derives.el_sound_graph` lift them to OWL in `leanrdf-owl`. Certificates are written by `leanrdf-demo --cert` and parsed by `Certificate.parse`. What is missing is a program that does only the checking. The agentic article (`docs/articles/certified-reasoning-for-agentic-flows.md`, Pattern 6) already describes one.

## Goals / Non-Goals

**Goals:**
- A tool whose trusted code is the checker, the parsers and nothing that searches.
- One soundness theorem the tool stands for, over all five regimes.
- A machine-readable verdict whose vocabulary later changes extend without renaming.

**Non-Goals:**
- Binding a certificate to its data by digest: that is `add-certificate-envelope`.
- New verdicts (`inconsistent`, `refuted`): they come with `add-inconsistency-certificates` and `add-countermodels`.
- Checking SHACL reports or SPARQL answers, which come from proven engines, not certificates.

## Decisions

### A checker package without the search

`leanrdf-check` is a new package in `check/` that requires `leanrdf` and `leanrdf-owl` and not lean-elpi. Building it builds no search code. Its executable is the program an agent or auditor installs to check other people's certificates.

- motivated_by:: [[decisions#Elpi finds, Lean checks]] {weight: primary}
- motivated_by:: [[decisions#Layers as packages in one repository]]

Rejected: an executable in the core (the OWL rules live in `leanrdf-owl`, and the core must not depend on it); an executable in `elpi/` (it would drag lean-elpi into the trusted tool's build, and blur which code is trusted).

### Regimes as a closed inductive with a soundness theorem

`inductive Regime | simple | rdf | rdfs | owl | el`, with `rules`, `Entails : Regime → Graph → Graph → Prop` and `theoremName`. `checkRegime` dispatches to `checkQuery (r.rules)`. For `simple` it also decides `∀ t ∈ q, t.WellFormed`, which `checkQuery_sound_simple` needs. `checkRegime_sound` is a case split over the five existing theorems.

Rejected: passing a rule list by name from the command line to `checkQuery` and reporting `Derives` only. The point of the tool is to state *which entailment* holds, not only derivability under some rules.

### One verdict vocabulary for every tool

The JSON `verdict` field takes `proven`, `refuted`, `unknown`, `inconsistent`, `rejected` or `input-error`, mapped to exit codes 0, 5, 1, 4, 2 and 3. `leanrdf-check` only ever produces `proven`, `rejected` and `input-error`. The full vocabulary is fixed here so that later changes and other tools add verdicts without renaming any.

- motivated_by:: [[decisions#Demo never claims non-entailment]] {note: "unknown is never false"}

### Turtle by extension

Data and query files ending in `.ttl` are read with the Turtle parser, and everything else with N-Triples. Certificates refer to terms in N-Triples syntax either way. Parsing is untrusted in the sense that a wrong parse can only make the checker reject, or prove a statement about the parsed graph, which is the graph the output reports.

## Constraints

- [[constraints#Lean toolchain 4.35]] binds the package's `lean-toolchain`.
- [[constraints#Lake requires per package]]: `check/` requires `..` and `../owl`.

## Risks / Trade-offs

- [The theorem is about the parsed graph] → The output prints the triple counts. The next change binds the graph by an RDFC-1.0 digest.
- [`native_decide` is not involved: the executable runs the compiled checker] → Its trust base includes the compiler and runtime, as for every LeanRDF tool. The release notes say so.
