import LeanRDF

/-! Scenarios of `rdf-canonicalization`, checked at build time. -/

namespace LeanRDF.Tests.Canon

open LeanRDF.Canon

private def nq (src : String) : Dataset := (NQuads.parse src).toOption.getD (Dataset.ofList [])
private def nt (src : String) : Graph := (NTriples.parse src).toOption.getD (Graph.ofList [])
private def out (d : Dataset) : String := (canonicalNQuads d).toOption.getD "error"

private def people := nq "
_:alice <http://xmlns.com/foaf/0.1/knows> _:bob .
_:bob <http://xmlns.com/foaf/0.1/knows> _:alice .
_:alice <http://xmlns.com/foaf/0.1/name> \"Alice\" .
"
private def peopleRenamed := nq "
_:n2 <http://xmlns.com/foaf/0.1/name> \"Alice\" .
_:n7 <http://xmlns.com/foaf/0.1/knows> _:n2 .
_:n2 <http://xmlns.com/foaf/0.1/knows> _:n7 .
"

-- @tg: verifies:: [[openspec:rdf-canonicalization#Canonical labeling#Two isomorphic graphs get the same labels]] {level: unit}
#guard out people == out peopleRenamed
#guard out people != "error"

-- @tg: verifies:: [[openspec:rdf-canonicalization#Canonical N-Quads#Output is sorted canonical N-Quads]] {level: unit}
/-- info: "_:c14n0 <http://xmlns.com/foaf/0.1/knows> _:c14n1 .\n_:c14n1 <http://xmlns.com/foaf/0.1/knows> _:c14n0 .\n_:c14n1 <http://xmlns.com/foaf/0.1/name> \"Alice\" .\n" -/
#guard_msgs in
#eval out people

/-- A 10-node clique of blank nodes, every node related to every other (W3C test074). -/
private def clique : Dataset := Id.run do
  let mut l : List Quad := []
  for i in List.range 10 do
    for j in List.range 10 do
      if i != j then
        l := ⟨.bnode ⟨s!"n{i}"⟩, .iri ⟨"http://example.org/p"⟩, .bnode ⟨s!"n{j}"⟩, none⟩ :: l
  return Dataset.ofList l

-- @tg: verifies:: [[openspec:rdf-canonicalization#Canonical labeling#Poison graphs are refused]] {level: unit}
/-- info: "RDFC-1.0 work limit of 11000 exceeded: the dataset needs too much N-degree hashing" -/
#guard_msgs in
#eval match canonicalNQuads clique with
  | .error e => e
  | .ok _ => "canonicalized"

private def reif (b : String) := nq s!"
<http://example.org/r> <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies> <<( _:{b} <http://example.org/p> <http://example.org/o> )>> .
"

-- @tg: verifies:: [[openspec:rdf-canonicalization#Triple terms in canonicalization#A blank node only inside a triple term is labeled]] {level: unit}
/-- info: "<http://example.org/r> <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies> <<( _:c14n0 <http://example.org/p> <http://example.org/o> )>> .\n" -/
#guard_msgs in
#eval out (reif "x")
#guard out (reif "x") == out (reif "y")

private def petsA := nt "
_:d <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://example.org/Dog> .
<http://example.org/alice> <http://example.org/hasDog> _:d .
_:d <http://example.org/name> \"Rex\" .
"
private def petsB := nt "
_:pet <http://example.org/name> \"Rex\" .
<http://example.org/alice> <http://example.org/hasDog> _:pet .
_:pet <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://example.org/Dog> .
"
private def petsC := nt "
_:pet <http://example.org/name> \"Rex\" .
<http://example.org/alice> <http://example.org/hasDog> _:pet .
_:pet <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://example.org/Dog> .
<http://example.org/alice> <http://example.org/name> \"Alice\" .
"

-- @tg: verifies:: [[openspec:rdf-canonicalization#Graph digests#Digests ignore blank-node labels and order]] {level: unit}
#guard petsA.digest.toOption == petsB.digest.toOption
#guard petsA.digest.toOption != petsC.digest.toOption
#guard (petsA.digest.toOption.map (·.startsWith "sha256:")) == some true
#guard (petsA.digest.toOption.map (·.length)) == some (7 + 64)

-- @tg: verifies:: [[openspec:rdf-canonicalization#Canonical isomorphism#Isomorphism theorems are axiom-clean]] {level: unit}
/-- info: 'LeanRDF.Canon.canonicalLabels_injective' depends on axioms: [propext] -/
#guard_msgs in
#print axioms canonicalLabels_injective

/-- info: 'LeanRDF.Canon.canonical_iso' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms canonical_iso

end LeanRDF.Tests.Canon
