## ADDED Requirements

### Requirement: Envelope verification
When a certificate has an envelope, `leanrdf-check` SHALL:
- recompute the digests of the data and query it read, and of the regime's rule list, before checking;
- require the envelope's `regime` to equal the regime in use.

Any mismatch SHALL be a rejection with exit `2` and a reason naming the field (`envelope: graph digest mismatch`, `envelope: query digest mismatch`, `envelope: rules digest mismatch`, `envelope: regime mismatch`). The text and JSON verdicts SHALL report the graph and query digests. `--emit-envelope OUT` SHALL write the accepted certificate as version 2, with the envelope filled from the check. A version-1 certificate SHALL be checked as before, and the verdict SHALL say that it is unbound.

#### Scenario: A bound certificate is accepted
- **WHEN** a version-2 certificate written by `leanrdf-demo` is checked against the same data with the triples reordered and blank nodes renamed
- **THEN** it is accepted, and the JSON verdict carries the same `graph` digest as the envelope

#### Scenario: A certificate checked against other data is rejected
- **WHEN** the same certificate is checked against data with one unrelated triple added
- **THEN** it is rejected with `envelope: graph digest mismatch` and exit `2`, although the proof DAG alone would pass

#### Scenario: Version 1 is upgraded
- **WHEN** a version-1 certificate is checked with `--emit-envelope out.json`
- **THEN** the verdict says the input was unbound, and `out.json` is a version-2 certificate that passes envelope verification
