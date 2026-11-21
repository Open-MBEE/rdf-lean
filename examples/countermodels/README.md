# Saying no: countermodels

"Not derived" proves nothing, because the rules are proven sound, not complete. To *refute* a
query, LeanRDF builds a countermodel: an interpretation that satisfies the data and not the query.
The untrusted finder builds one from the Elpi closure. A verified model checker decides it, and
`checkCountermodel_sound_rdfs` turns acceptance into the theorem `¬ g.RDFSEntails q`.

- `refuted`: is Tom a dog? The pets data says Tom is a cat, and nothing makes him a dog. The demo finds a countermodel with 54 sorts, the checker accepts it, and the verdict is REFUTED, exit 5. `--countermodel tom-dog.json` writes it, with an envelope that binds it to the data and the query.
- `check`: `leanrdf-check` verifies the same countermodel on its own. REFUTED, exit 5.
- `check-json`: the same as JSON: `"verdict": "refuted"`, the theorem, and the datatypes the refutation is relative to.
- `forged`: the countermodel with one extra `IEXT` entry that makes Tom a dog. The checker finds the query true in it and rejects it, exit 2.
- `not-refuted`: is Alice 42? The data only reifies the claim. A countermodel exists, but the canonical candidate fails an RDF condition: the rules do not type the predicate inside the triple term as an `rdf:Property`. The verdict stays NOT DERIVED, exit 1, and names the condition.

A refutation is relative to the recognized datatypes D = {xsd:string, rdf:langString,
rdf:dirLangString}. Countermodels exist for simple, RDF and RDFS entailment; OWL countermodels are
not implemented.
