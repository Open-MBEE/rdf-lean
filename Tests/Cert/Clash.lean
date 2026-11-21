import LeanRDF

/-! Scenarios of `inconsistency` in the core: clash rules, the datatype clash, clash
certificates and the clash checker. The OWL clash rules are tested in `leanrdf-owl`. -/

namespace LeanRDF.Tests.CertClash

open Vocab LeanRDF.Cert RDFS

private def ex (n : String) : Term := .iri ⟨"http://example.org/" ++ n⟩
private def T (s p o : Term) : Triple := ⟨s, p, o⟩
private def str (s : String) : Term := .lit (.typed s xsd.string)

/-- `ex:a ex:p "a\u0000b"^^xsd:string`, read from N-Triples. -/
private def bad : Graph :=
  (NTriples.parse "<http://example.org/a> <http://example.org/p> \"a\\u0000b\"^^<http://www.w3.org/2001/XMLSchema#string> .\n").toOption.getD (Graph.ofList [])
private def good : Graph := Graph.ofList [T (ex "a") (ex "p") (str "ab")]

private def clashOf (t : Triple) : Certificate :=
  { nodes := [⟨0, t, "fact", []⟩], goals := [], clash := some ⟨"d-clash-string", [0]⟩ }

-- @tg: verifies:: [[openspec:inconsistency#Clash rules#Existing theorems are untouched]] {level: unit}
-- The derivation pipeline is unchanged: a clash rule is not a `Rule`, and `Derives` has no head
-- for it. (`check_sound` and `checkQuery_sound` keep their statements; they are used below.)
example : ∀ r ∈ rdfsRules, r.Sound := rdfsRules_sound

#guard bad.size == 1
#guard Xsd.isStringLexical "ab" && !Xsd.isStringLexical "a\x00b" && !Xsd.isStringLexical "￾"

-- @tg: verifies:: [[openspec:inconsistency#Datatype clash#An ill-typed string literal clashes]] {level: unit}
#guard checkClashB rdfsRules rdfsClashRules bad (clashOf (T (ex "a") (ex "p") (str "a\x00b")))
theorem bad_unsat : ¬ ∃ I : DInterp, I.IsRDFS ∧ I.IsWellTyped ∧ I.Satisfies bad :=
  checkClash_sound_rdfs (c := clashOf (T (ex "a") (ex "p") (str "a\x00b"))) (checkClashB_ok (by native_decide))

-- @tg: verifies:: [[openspec:inconsistency#Datatype clash#A well-typed string does not clash]] {level: unit}
private def errorOf : Except String Unit → String
  | .error e => e
  | .ok () => ""
#guard errorOf (checkClash rdfsRules rdfsClashRules good (clashOf (T (ex "a") (ex "p") (str "ab")))) ==
  "clash: a guard of d-clash-string fails"

-- @tg: verifies:: [[openspec:inconsistency#Clash checker#Tampered clash certificates are rejected]] {level: unit}
private def badCert := clashOf (T (ex "a") (ex "p") (str "a\x00b"))
#guard errorOf (checkClash rdfsRules rdfsClashRules bad { badCert with clash := some ⟨"no-such", [0]⟩ }) ==
  "clash: unknown clash rule no-such"
#guard errorOf (checkClash rdfsRules rdfsClashRules bad { badCert with clash := some ⟨"d-clash-string", [3]⟩ }) ==
  "clash: premise 3 is not an earlier node"
#guard errorOf (checkClash rdfsRules rdfsClashRules bad { badCert with clash := some ⟨"d-clash-string", [0, 0]⟩ }) ==
  "clash: premises do not match the body of d-clash-string"
#guard errorOf (checkClash rdfsRules rdfsClashRules good badCert) == "node 0: not a fact of the graph"
#guard errorOf (checkClash rdfsRules rdfsClashRules bad { badCert with clash := none }) ==
  "not a clash certificate"

/-! ## JSON -/

private def env : Envelope :=
  { graph := "sha256:00", query := "sha256:00", rules := ⟨"owl", "sha256:00"⟩, regime := "owl",
    checker := "test", toolchain := toolchain, thm := "checkClash_sound_owl" }
private def caxDw : Certificate :=
  { version := 2, envelope := some env, goals := [], clash := some ⟨"cax-dw", [0, 1, 2]⟩,
    nodes := [⟨0, T (ex "Cat") (.iri ⟨"http://www.w3.org/2002/07/owl#disjointWith"⟩) (ex "Dog"), "fact", []⟩,
              ⟨1, T (ex "tom") (.iri rdf.type) (ex "Cat"), "fact", []⟩,
              ⟨2, T (ex "tom") (.iri rdf.type) (ex "Dog"), "fact", []⟩] }

-- @tg: verifies:: [[openspec:inconsistency#Clash certificates#Clash certificate JSON round-trips]] {level: unit}
#guard (Certificate.parse caxDw.render).toOption == some caxDw

-- @tg: verifies:: [[openspec:inconsistency#Clash certificates#Version 1 cannot carry a clash]] {level: unit}
#guard (Certificate.parse "{\"version\": 1, \"nodes\": [], \"goals\": [], \"clash\": {\"rule\": \"cax-dw\", \"premises\": []}}").toOption.isNone

/-! ## Axioms -/

-- @tg: verifies:: [[openspec:inconsistency#Clash checker soundness#Clash theorems are axiom-clean]] {level: unit}
/-- info: 'LeanRDF.Cert.checkClash_sound' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms checkClash_sound

/-- info: 'LeanRDF.Cert.checkClash_sound_rdfs' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms checkClash_sound_rdfs

end LeanRDF.Tests.CertClash
