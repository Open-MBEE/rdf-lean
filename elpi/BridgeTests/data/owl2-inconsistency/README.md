# W3C OWL 2 inconsistency tests

The `InconsistencyTest` cases of the W3C OWL 2 test suite, from the manifest at
<https://www.w3.org/2009/11/owl-test/all.rdf> (the static archive of the OWL 2 Test Case
Repository). Copyright W3C; W3C test suites are distributed under the W3C Test Suite Licence and
the W3C 3-clause BSD Licence.

`index.tsv` lists all 128 inconsistency tests:
- `inconsistent`: an approved test whose RDF/XML premise is vendored here as `<test>.nt`,
  converted from RDF/XML to N-Triples with oxigraph 0.5.7. `BridgeTests/OwlInconsistency.lean`
  requires a clash certificate that `checkClash owlRules owlClashRules` accepts, so each of these
  graphs is proven to have no OWL model.
- `skipped`: the test, with the reason it is not run. The fixed-arity OWL 2 RL clash rules find
  no clash in the other approved premises: they need list rules, datatype reasoning, or
  inferences outside OWL 2 RL. "No clash found" is not a claim of consistency.

The selection was made by running the clash search over every approved premise; the
`inconsistent` lines are exactly those it found.
