## MODIFIED Requirements

### Requirement: Release version
Every Lake package of the repository (`leanrdf`, `leanrdf-elpi`, `leanrdf-sparql`, `leanrdf-owl`, `leanrdf-shacl`, `leanrdf-statements`, `leanrdf-check`, `leanrdf-gate`) SHALL declare the version of the latest release, `0.6.0` since `add-write-gate`, together with a `description`, `keywords` and the site as `homepage`. The core package's description SHALL name RDF 1.2.

#### Scenario: Every package has the release version
- **WHEN** the eight lakefiles are inspected
- **THEN** each declares `version := v!"0.6.0"`, a description, keywords and the homepage, and the core description says "RDF 1.2"

## ADDED Requirements

### Requirement: Write gate release
`v0.6.0` SHALL be tagged on `main` after `add-write-gate` is archived, and published as a GitHub release whose notes list the `leanrdf-gate` package, the admission theorems, the consistency policies, the command line, what the version proves and what it trusts. CI SHALL build and test `gate/` and run its example.

#### Scenario: Release v0.6.0 exists
- **WHEN** the release page of `Volland/rdf-lean` is opened
- **THEN** `v0.6.0` is listed with its notes, after `v0.5.0`
