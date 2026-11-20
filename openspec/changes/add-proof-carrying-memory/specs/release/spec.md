## MODIFIED Requirements

### Requirement: Release version
Every Lake package of the repository (`leanrdf`, `leanrdf-elpi`, `leanrdf-sparql`, `leanrdf-owl`, `leanrdf-shacl`, `leanrdf-statements`, `leanrdf-check`, `leanrdf-gate`) SHALL declare the version of the latest release, `0.7.0` since `add-proof-carrying-memory`, together with a `description`, `keywords` and the site as `homepage`. The core package's description SHALL name RDF 1.2.

#### Scenario: Every package has the release version
- **WHEN** the eight lakefiles are inspected
- **THEN** each declares `version := v!"0.7.0"`, a description, keywords and the homepage, and the core description says "RDF 1.2"

## ADDED Requirements

### Requirement: Proof-carrying memory release
`v0.7.0` SHALL be tagged on `main` after `add-proof-carrying-memory` is archived, and published as a GitHub release whose notes list citations, the memory check and its theorems, retraction impact, the new `leanrdf-check` options, what the version proves and what it trusts.

#### Scenario: Release v0.7.0 exists
- **WHEN** the release page of `Volland/rdf-lean` is opened
- **THEN** `v0.7.0` is listed with its notes, after `v0.6.0`
