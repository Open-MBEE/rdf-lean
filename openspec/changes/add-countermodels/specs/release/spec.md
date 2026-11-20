## MODIFIED Requirements

### Requirement: Release version
Every Lake package of the repository (`leanrdf`, `leanrdf-elpi`, `leanrdf-sparql`, `leanrdf-owl`, `leanrdf-shacl`, `leanrdf-statements`, `leanrdf-check`) SHALL declare the version of the latest release, `0.5.0` since `add-countermodels`, together with a `description`, `keywords` and the site as `homepage`. The core package's description SHALL name RDF 1.2.

#### Scenario: Every package has the release version
- **WHEN** the seven lakefiles are inspected
- **THEN** each declares `version := v!"0.5.0"`, a description, keywords and the homepage, and the core description says "RDF 1.2"

## ADDED Requirements

### Requirement: Four-valued verdicts release
`v0.5.0` SHALL be tagged on `main` after `add-inconsistency-certificates` and `add-countermodels` are archived. It SHALL be published as a GitHub release whose notes do all of the following:
- list the four verdicts (PROVEN, REFUTED, UNKNOWN, INCONSISTENT) with their exit codes `0`, `5`, `1` and `4`;
- name the clash and countermodel theorems;
- state that REFUTED is relative to the recognized datatypes, and that OWL countermodels are out of scope;
- state what the version proves and what it trusts.

#### Scenario: Release v0.5.0 exists
- **WHEN** the release page of `Volland/rdf-lean` is opened
- **THEN** `v0.5.0` is listed with its notes, after `v0.4.0`
