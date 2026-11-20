## MODIFIED Requirements

### Requirement: Release version
Every Lake package of the repository (`leanrdf`, `leanrdf-elpi`, `leanrdf-sparql`, `leanrdf-owl`, `leanrdf-shacl`, `leanrdf-statements`, `leanrdf-check`) SHALL declare the version of the latest release, `0.4.0` since `add-certificate-envelope`, together with a `description`, `keywords` and the site as `homepage`. The core package's description SHALL name RDF 1.2.

#### Scenario: Every package has the release version
- **WHEN** the seven lakefiles are inspected
- **THEN** each declares `version := v!"0.4.0"`, a description, keywords and the homepage, and the core description says "RDF 1.2"

## ADDED Requirements

### Requirement: Proof-carrying answers release
`v0.4.0` SHALL be tagged on `main` after `add-certificate-check` and `add-certificate-envelope` are archived, and published as a GitHub release whose notes list:
- `leanrdf-check` and its verdicts;
- certificate version 2 and its envelope;
- RDFC-1.0 and digests;
- what the version proves and what it trusts.

CI SHALL build and test `check/` and run its example.

#### Scenario: Release v0.4.0 exists
- **WHEN** the release page of `Volland/rdf-lean` is opened
- **THEN** `v0.4.0` is listed with its notes, after `v0.3.1`
