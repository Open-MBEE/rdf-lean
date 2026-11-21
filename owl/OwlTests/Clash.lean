import LeanRDFOwl

/-! Scenarios of `owl-rl#OWL 2 RL clash rules`, `#OWL clash soundness` and of the clash checker
under the OWL regime: an accepted and a tampered certificate for every clash rule, the theorems
they give, and the axioms. -/

namespace LeanRDF.Owl.Tests.Clash

open Vocab LeanRDF.Cert

private def ex (n : String) : Term := .iri ⟨"http://example.org/" ++ n⟩
private def o (i : IRI) : Term := .iri i
private def T (s p o : Term) : Triple := ⟨s, p, o⟩
private def ty : Term := .iri rdf.type
private def z : Term := .lit zero

/-- A clash certificate whose nodes are the facts `ts`, all of them premises of `rule`. -/
private def clashCert (rule : String) (ts : List Triple) : Certificate :=
  { nodes := (ts.zip (List.range ts.length)).map fun (t, i) => ⟨i, t, "fact", []⟩, goals := [],
    clash := some ⟨rule, List.range ts.length⟩ }

/-- Every clash rule with a graph that triggers it, its facts in body order. -/
private def cases : List (String × List Triple) :=
  [("eq-diff1", [T (ex "a") (o sameAs) (ex "b"), T (ex "a") (o differentFrom) (ex "b")]),
   ("prp-irp", [T (ex "parentOf") ty (o IrreflexiveProperty), T (ex "a") (ex "parentOf") (ex "a")]),
   ("prp-asyp", [T (ex "p") ty (o AsymmetricProperty), T (ex "a") (ex "p") (ex "b"), T (ex "b") (ex "p") (ex "a")]),
   ("prp-pdw", [T (ex "p1") (o propertyDisjointWith) (ex "p2"), T (ex "a") (ex "p1") (ex "b"),
     T (ex "a") (ex "p2") (ex "b")]),
   ("prp-npa1", [T (ex "n") (o sourceIndividual) (ex "a"), T (ex "n") (o assertionProperty) (ex "p"),
     T (ex "n") (o targetIndividual) (ex "b"), T (ex "a") (ex "p") (ex "b")]),
   ("prp-npa2", [T (ex "n") (o sourceIndividual) (ex "a"), T (ex "n") (o assertionProperty) (ex "p"),
     T (ex "n") (o targetValue) (.lit (.typed "v" xsd.string)), T (ex "a") (ex "p") (.lit (.typed "v" xsd.string))]),
   ("cls-nothing2", [T (ex "a") ty (o Nothing)]),
   ("cls-com", [T (ex "C") (o complementOf) (ex "D"), T (ex "a") ty (ex "C"), T (ex "a") ty (ex "D")]),
   ("cls-maxc1", [T (ex "R") (o maxCardinality) z, T (ex "R") (o onProperty) (ex "p"), T (ex "a") ty (ex "R"),
     T (ex "a") (ex "p") (ex "b")]),
   ("cls-maxqc1", [T (ex "R") (o maxQualifiedCardinality) z, T (ex "R") (o onProperty) (ex "p"),
     T (ex "R") (o onClass) (ex "C"), T (ex "a") ty (ex "R"), T (ex "a") (ex "p") (ex "b"), T (ex "b") ty (ex "C")]),
   ("cls-maxqc2", [T (ex "R") (o maxQualifiedCardinality) z, T (ex "R") (o onProperty) (ex "p"),
     T (ex "R") (o onClass) (o Thing), T (ex "a") ty (ex "R"), T (ex "a") (ex "p") (ex "b")]),
   ("cax-dw", [T (ex "Cat") (o disjointWith) (ex "Dog"), T (ex "tom") ty (ex "Cat"), T (ex "tom") ty (ex "Dog")])]

private def accepted (rule : String) (ts : List Triple) : Bool :=
  checkClashB owlRules owlClashRules (Graph.ofList ts) (clashCert rule ts)

/-- The premises in reverse order, or a premise id that is not a node for a one-premise rule. -/
private def tampered (rule : String) (ts : List Triple) : Certificate :=
  let c := clashCert rule ts
  if ts.length == 1 then { c with clash := some ⟨rule, [7]⟩ }
  else { c with clash := some ⟨rule, (List.range ts.length).reverse⟩ }

-- @tg: verifies:: [[openspec:owl-rl#OWL 2 RL clash rules#The twelve clash rules are present]] {level: unit}
#guard owlClashRules.map (·.name) ==
  ["eq-diff1", "prp-irp", "prp-asyp", "prp-pdw", "prp-npa1", "prp-npa2", "cls-nothing2", "cls-com",
   "cls-maxc1", "cls-maxqc1", "cls-maxqc2", "cax-dw"]
#guard (owlClashRules.map (·.body.length)) == [2, 2, 3, 3, 4, 4, 1, 3, 4, 6, 5, 3]

-- @tg: verifies:: [[openspec:inconsistency#Clash rules#A clash rule has no head]] {level: unit}
#guard caxDw.body == [⟨.var "c1", .const (o disjointWith), .var "c2"⟩, ⟨.var "x", .const ty, .var "c1"⟩,
  ⟨.var "x", .const ty, .var "c2"⟩]

-- @tg: verifies:: [[openspec:inconsistency#Inconsistency test corpus#Every clash rule is exercised]] {level: unit}
#guard cases.map (·.1) == owlClashRules.map (·.name)
#guard cases.all fun (r, ts) => accepted r ts
#guard cases.all fun (r, ts) => !(checkClashB owlRules owlClashRules (Graph.ofList ts) (tampered r ts))

private def irp := (cases.find? (·.1 == "prp-irp")).map (·.2) |>.getD []
-- @tg: verifies:: [[openspec:owl-rl#OWL 2 RL clash rules#An irreflexive self-loop clashes]] {level: unit}
#guard accepted "prp-irp" irp

/-! ## The cat and the dog -/

private def cats : List Triple :=
  [T (ex "Cat") (o disjointWith) (ex "Dog"), T (ex "tom") ty (ex "Cat"), T (ex "tom") ty (ex "Dog")]
private def catsG : Graph := Graph.ofList cats

-- @tg: verifies:: [[openspec:inconsistency#Clash checker#A disjointness clash is accepted]] {level: unit}
#guard checkClashB owlRules owlClashRules catsG (clashCert "cax-dw" cats)

-- @tg: verifies:: [[openspec:inconsistency#Clash checker soundness#An accepted clash proves unsatisfiability]] {level: unit}
theorem cats_unsat : ¬ ∃ I : DInterp, I.IsOWL ∧ I.Satisfies catsG :=
  checkClash_sound_owl (c := clashCert "cax-dw" cats) (checkClashB_ok (by native_decide))

-- @tg: verifies:: [[openspec:inconsistency#Clash checker soundness#Explosion is a theorem]] {level: unit}
theorem cats_moon : catsG.OWLEntails (Graph.ofList [T (ex "moon") ty (ex "Cheese")]) :=
  checkClash_explodes_owl (c := clashCert "cax-dw" cats) (checkClashB_ok (by native_decide)) _

/-- A derived clash: `ex:tom` is a cat through `rdfs9`. -/
private def kittens : Graph := Graph.ofList
  [T (ex "Cat") (o disjointWith) (ex "Dog"), T (ex "Kitten") (.iri rdfs.subClassOf) (ex "Cat"),
   T (ex "tom") ty (ex "Kitten"), T (ex "tom") ty (ex "Dog")]
private def kittenCert : Certificate :=
  { goals := [], clash := some ⟨"cax-dw", [0, 4, 3]⟩,
    nodes := [⟨0, T (ex "Cat") (o disjointWith) (ex "Dog"), "fact", []⟩,
              ⟨1, T (ex "Kitten") (.iri rdfs.subClassOf) (ex "Cat"), "fact", []⟩,
              ⟨2, T (ex "tom") ty (ex "Kitten"), "fact", []⟩,
              ⟨3, T (ex "tom") ty (ex "Dog"), "fact", []⟩,
              ⟨4, T (ex "tom") ty (ex "Cat"), "rdfs9", [1, 2]⟩] }
#guard checkClashB owlRules owlClashRules kittens kittenCert

-- @tg: verifies:: [[openspec:owl-rl#OWL conditions#differentFrom excludes identity]] {level: unit}
example {I : SimpleInterp} (h : OWLConds I) {x : I.Dom} : ¬ I.IEXT (I.IS differentFrom) x x :=
  fun hd => differentFrom_ne h hd rfl

/-! ## Axioms -/

-- @tg: verifies:: [[openspec:owl-rl#OWL clash soundness#Clash soundness theorem]] {level: unit}
/-- info: 'LeanRDF.Owl.owlClashRules_sound' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms owlClashRules_sound

-- @tg: verifies:: [[openspec:inconsistency#Clash checker soundness#Clash theorems are axiom-clean]] {level: unit}
/-- info: 'LeanRDF.Cert.checkClash_sound_owl' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms checkClash_sound_owl

/-- info: 'LeanRDF.Cert.checkClash_explodes_owl' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms checkClash_explodes_owl

end LeanRDF.Owl.Tests.Clash
