## MODIFIED Requirements

### Requirement: Release version
Every Lake package of the repository (`leanrdf`, `leanrdf-elpi`, `leanrdf-sparql`, `leanrdf-owl`, `leanrdf-shacl`, `leanrdf-statements`, `leanrdf-check`, `leanrdf-gate`, `leanrdf-policy`) SHALL declare the version of the latest release, `0.8.0` since `add-policy-decisions`, together with a `description`, `keywords` and the site as `homepage`. The core package's description SHALL name RDF 1.2.

#### Scenario: Every package has the release version
- **WHEN** the nine lakefiles are inspected
- **THEN** each declares `version := v!"0.8.0"`, a description, keywords and the homepage, and the core description says "RDF 1.2"

## ADDED Requirements

### Requirement: Policy decisions release
`v0.8.0` SHALL be tagged on `main` after `add-policy-decisions` is archived, and published as a GitHub release whose notes list the `leanrdf-policy` package, the policy vocabulary, the decision theorems, the guard example, the ODRL subset, what the version proves and what it trusts. CI SHALL build and test `policy/` and run its example.

#### Scenario: Release v0.8.0 exists
- **WHEN** the release page of `Volland/rdf-lean` is opened
- **THEN** `v0.8.0` is listed with its notes, after `v0.7.0`
