## ADDED Requirements

### Requirement: Canonical labeling
`canonicalLabels` SHALL implement the RDFC-1.0 algorithm (W3C Recommendation, 2024) over a dataset:
- first-degree hashes;
- the N-degree hash for shared first-degree hashes;
- the canonical issuer assigning `c14n0`, `c14n1`, … in the order RDFC-1.0 prescribes;
- SHA-256 as the hash.

It SHALL fail with an error, not loop, when the work limit on N-degree hashing is exceeded, as RDFC-1.0 §4.4 permits.

#### Scenario: Two isomorphic graphs get the same labels
- **WHEN** a graph and a copy with every blank-node label renamed are canonicalized
- **THEN** both give the same canonical N-Quads

#### Scenario: Poison graphs are refused
- **WHEN** a dataset that needs more N-degree hash calls than the work limit is canonicalized
- **THEN** canonicalization returns an error naming the limit

### Requirement: Canonical N-Quads
`canonicalNQuads` SHALL write the dataset with canonical blank-node labels, one quad per line in canonical N-Quads form, in code-point order of the lines, each line ending in a line feed.

#### Scenario: Output is sorted canonical N-Quads
- **WHEN** a three-quad dataset with two blank nodes is canonicalized
- **THEN** the output is three canonical N-Quads lines in code-point order using `_:c14n0` and `_:c14n1`

### Requirement: Canonical isomorphism
`canonicalLabels_injective` SHALL prove that the canonical labeling is injective on the blank nodes of its input. `canonical_iso` SHALL prove that relabeling the input by it gives a dataset isomorphic to the input. Both SHALL use no axiom beyond `propext`, `Classical.choice` and `Quot.sound`. That isomorphic inputs give equal outputs is tested, not proven, and is recorded as a simplification.

#### Scenario: Isomorphism theorems are axiom-clean
- **WHEN** the axioms of `canonicalLabels_injective` and `canonical_iso` are printed
- **THEN** they are among `propext`, `Classical.choice` and `Quot.sound`

### Requirement: Triple terms in canonicalization
For a blank node that occurs inside a triple term, the hash-related quads SHALL be the quads in which it occurs at any depth. The serialization of such a quad for hashing SHALL replace the reference blank node by `_:a` and every other blank node by `_:z` at every depth.

#### Scenario: A blank node only inside a triple term is labeled
- **WHEN** `ex:r rdf:reifies <<( _:x ex:p ex:o )>> .` and the same triple with `_:y` are canonicalized
- **THEN** both give `<<( _:c14n0 <http://example.org/p> <http://example.org/o> )>>` in their output

### Requirement: Graph digests
`Graph.digest` and `Dataset.digest` SHALL return `sha256:` followed by the lower-case hexadecimal SHA-256 of the canonical N-Quads, with a graph treated as a dataset with only a default graph.

#### Scenario: Digests ignore blank-node labels and order
- **WHEN** a graph is read from two files that differ in triple order and blank-node labels
- **THEN** both give the same digest, and adding one triple changes it

### Requirement: RDFC-1.0 conformance
The W3C rdf-canon test suite SHALL be vendored. Every evaluation test SHALL produce the expected canonical N-Quads, and every negative test SHALL produce an error.

#### Scenario: The W3C rdf-canon suite passes
- **WHEN** the core test driver runs the vendored suite
- **THEN** all evaluation and negative tests pass, and the count is printed
