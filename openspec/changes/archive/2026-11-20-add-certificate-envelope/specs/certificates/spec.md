## MODIFIED Requirements

### Requirement: Certificate format
A certificate SHALL consist of a version, nodes (an id, a conclusion triple, a rule name, premise ids), goal ids and an instance mapping from blank nodes to terms. Its JSON form SHALL write every term in RDF 1.2 N-Triples term syntax, triple terms, directional literals and generalized triples included, and reading JSON SHALL return an error for malformed input.

Version 2 SHALL add an `envelope` object with these fields:
- `graph` and `query`: digests;
- `rules`: an object with `id` and `digest`;
- `regime`;
- `checker`: the package and version that wrote the certificate;
- `toolchain`;
- `theorem`.

Reading SHALL accept versions 1 and 2 and reject every other version. The checker SHALL NOT read the envelope: soundness never depends on it.

#### Scenario: JSON round-trips
- **WHEN** a certificate with a mapping and a certificate with a literal subject are rendered to JSON and parsed back
- **THEN** each parses to itself

#### Scenario: RDF 1.2 terms in certificates
- **WHEN** a certificate whose conclusion has a nested triple-term subject and a directional literal, and whose mapping sends a blank node to a triple term, is rendered to JSON and parsed back
- **THEN** it parses to itself and the checker gives the same verdict on both

#### Scenario: Version 2 round-trips
- **WHEN** a version-2 certificate with every envelope field is rendered and parsed back
- **THEN** it parses to itself, and a version-1 certificate still parses with no envelope

#### Scenario: The envelope does not change the checker's verdict
- **WHEN** the same nodes are checked with no envelope and with an envelope whose digests are wrong
- **THEN** `checkQuery` gives the same result on both
