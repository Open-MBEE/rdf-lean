# Inconsistent data

A graph with no model entails every query, so an ENTAILED verdict on it carries no information.
`leanrdf-demo` therefore looks for a clash first. A clash is an instance of a rule whose
conclusion is `false`, checked by the verified clash checker. When it finds one it reports
INCONSISTENT and exits 4, and reports no entailment.

- `cats-owl`: `ex:tom` is a `ex:Kitten`, kittens are cats, and `ex:Cat owl:disjointWith ex:Dog`, yet `ex:tom` is a dog. The clash is `cax-dw` on a derived premise (`rdfs9`). By `checkClash_sound_owl` the graph has no OWL model. The query, "is Tom a fish?", is never answered. Exit 4.
- `cats-rdfs`: the same data under RDFS. `owl:disjointWith` means nothing there, so there is no clash, and a checked countermodel refutes the fish query: REFUTED, exit 5.
- `parent`: `ex:parentOf` is irreflexive and `ex:ann ex:parentOf ex:ann` (`prp-irp`). Exit 4.
- `bad-string`: a literal `"a\u0000b"` is not in the lexical space of `xsd:string`, a datatype clash under RDFS (`checkClash_sound_rdfs`). Exit 4.
- `check-clash`: `leanrdf-check` verifies the clash certificate the demo wrote for `cats-owl`, with no query. Exit 4.
- `check-clash-json`: the same verdict as JSON: `"verdict": "inconsistent"`, `"exit": 4`.

"No clash found" is not a claim of consistency. Clash rules over lists and datatype values are not
implemented.
