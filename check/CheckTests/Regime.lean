import LeanRDFCheck

/-! Scenarios of `certificate-check#Regimes` and `#Regime checker soundness`, checked at build
time. -/

namespace LeanRDF.Check.Tests

open Cert

-- @tg: verifies:: [[openspec:certificate-check#Regimes#Regime names round-trip]] {level: unit}
#guard Regime.all.all fun r => Regime.ofName? r.name == some r
#guard Regime.ofName? "RDFS" == none
#guard Regime.ofName? "owl2" == none

-- @tg: verifies:: [[openspec:certificate-check#Regimes#Each regime names its theorem]] {level: unit}
#guard Regime.all.map Regime.theoremName ==
  ["checkQuery_sound_simple", "checkQuery_sound_rdf", "checkQuery_sound",
   "Derives.owl_sound_graph", "Derives.el_sound_graph"]

private def ex (s : String) : Term := .iri ⟨"http://example.org/" ++ s⟩
private def nt (src : String) : Graph := (NTriples.parse src).toOption.getD (Graph.ofList [])

/-- The pets data and query of `leanrdf-demo`, and the certificate it writes for them. -/
private def pets : Graph := nt "
<http://example.org/Dog> <http://www.w3.org/2000/01/rdf-schema#subClassOf> <http://example.org/Mammal> .
<http://example.org/hasPet> <http://www.w3.org/2000/01/rdf-schema#domain> <http://example.org/Person> .
<http://example.org/hasDog> <http://www.w3.org/2000/01/rdf-schema#subPropertyOf> <http://example.org/hasPet> .
<http://example.org/hasDog> <http://www.w3.org/2000/01/rdf-schema#range> <http://example.org/Dog> .
<http://example.org/alice> <http://example.org/hasDog> <http://example.org/rex> .
"
private def petsQuery : Graph := nt "
_:pet <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://example.org/Mammal> .
"
private def ty : Term := .iri ⟨"http://www.w3.org/1999/02/22-rdf-syntax-ns#type"⟩
private def petsCert : Certificate :=
  { nodes := [
      ⟨0, ⟨ex "hasDog", .iri ⟨"http://www.w3.org/2000/01/rdf-schema#range"⟩, ex "Dog"⟩, "fact", []⟩,
      ⟨1, ⟨ex "alice", ex "hasDog", ex "rex"⟩, "fact", []⟩,
      ⟨2, ⟨ex "rex", ty, ex "Dog"⟩, "rdfs3", [0, 1]⟩,
      ⟨3, ⟨ex "Dog", .iri ⟨"http://www.w3.org/2000/01/rdf-schema#subClassOf"⟩, ex "Mammal"⟩, "fact", []⟩,
      ⟨4, ⟨ex "rex", ty, ex "Mammal"⟩, "rdfs9", [3, 2]⟩],
    goals := [4], mapping := [(⟨"pet"⟩, ex "rex")] }

-- @tg: verifies:: [[openspec:certificate-check#Regime checker soundness#An accepted RDFS certificate gives RDFS entailment]] {level: unit}
theorem pets_rdfs : pets.RDFSEntails petsQuery :=
  checkRegimeB_sound (r := .rdfs) (c := petsCert) (by native_decide)

private def owlData : Graph := nt "
<http://example.org/partOf> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2002/07/owl#TransitiveProperty> .
<http://example.org/a> <http://example.org/partOf> <http://example.org/b> .
<http://example.org/b> <http://example.org/partOf> <http://example.org/c> .
"
private def owlQuery : Graph := nt "
<http://example.org/a> <http://example.org/partOf> <http://example.org/c> .
"
private def owlCert : Certificate :=
  { nodes := [
      ⟨0, ⟨ex "partOf", ty, .iri ⟨"http://www.w3.org/2002/07/owl#TransitiveProperty"⟩⟩, "fact", []⟩,
      ⟨1, ⟨ex "a", ex "partOf", ex "b"⟩, "fact", []⟩,
      ⟨2, ⟨ex "b", ex "partOf", ex "c"⟩, "fact", []⟩,
      ⟨3, ⟨ex "a", ex "partOf", ex "c"⟩, "prp-trp", [0, 1, 2]⟩],
    goals := [3] }

-- @tg: verifies:: [[openspec:certificate-check#Regime checker soundness#An accepted OWL certificate gives OWL entailment]] {level: unit}
theorem partOf_owl : owlData.OWLEntails owlQuery :=
  checkRegimeB_sound (r := .owl) (c := owlCert) (by native_decide)

-- @tg: verifies:: [[openspec:certificate-check#Regime checker soundness#A certificate is checked only under its regime]] {level: unit}
private def errorOf : Except String Unit → String
  | .error e => e
  | .ok () => ""

#guard errorOf (checkRegime .simple pets petsQuery petsCert) == "node 2: unknown rule rdfs3"
#guard errorOf (checkRegime .rdfs owlData owlQuery owlCert) == "node 3: unknown rule prp-trp"

-- @tg: verifies:: [[openspec:certificate-check#Regime checker soundness#The regime theorem is axiom-clean]] {level: unit}
/-- info: 'LeanRDF.Check.checkRegime_sound' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms checkRegime_sound

end LeanRDF.Check.Tests
