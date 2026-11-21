# An inconsistent graph (hand-written replay)

`results.json` is written by hand, in the format of the recorded runs beside it, because no
oxilite binary was available when this case was added: it is the answer oxilite gives to
`_:x a ex:Cat` under OWL 2 RL, `ex:tom` through `ex:Kitten rdfs:subClassOf ex:Cat`. The data is
inconsistent (`ex:tom` is a cat and a dog, and the classes are disjoint), so `leanrdf-oxilite
--profile owl` reports INCONSISTENT and certifies no answer; the answer itself is never read.
Re-record it with `scripts/examples-record.sh` when oxilite is at hand.
