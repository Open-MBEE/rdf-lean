import LeanRDF.Entailment.Soundness

/-!
# Clash rules

A clash rule is a Horn rule with no head: its body can never be true in an interpretation of
the class it is sound in, so a graph that derives an instance of the body has no model there.
The OWL 2 RL rules with conclusion `false` (OWL 2 Profiles §4.3) are clash rules, in
`leanrdf-owl`; this file has the kind, its soundness, and the one datatype clash over the
recognized datatypes: an `xsd:string` literal outside the lexical space of `xsd:string`.

Clash rules are a separate kind, not `Rule` values with a sentinel head, so `Rule`, `Derives`,
`Rule.SoundIn` and every soundness theorem stay as they were.
-/

namespace LeanRDF

open Vocab

-- @tg: implements:: [[openspec:inconsistency#Clash rules]]
/-- A rule with conclusion `false`: a name, body patterns and guards. -/
structure ClashRule where
  name : String
  body : List TPat
  guards : List Guard := []
  deriving Repr

/-- A clash rule is sound in a class `C` of interpretations when, in every interpretation of
`C`, under every blank-node mapping and every substitution whose guards hold, not every body
instance is true. -/
def ClashRule.SoundIn (C : SimpleInterp → Prop) (r : ClashRule) : Prop :=
  ∀ (I : SimpleInterp), C I → ∀ (A : BlankNode → I.Dom) (σ : Subst),
    (∀ gd ∈ r.guards, gd.Holds σ) → ¬ ∀ b ∈ r.body, I.Holds A (b.apply σ)

/-- Soundness carries over to a smaller class of interpretations. -/
theorem ClashRule.SoundIn.mono {C C' : SimpleInterp → Prop} (h : ∀ I, C' I → C I)
    {r : ClashRule} (hr : r.SoundIn C) : r.SoundIn C' :=
  fun I hI => hr I (h I hI)

/-! ## The datatype clash -/

/-- Ill-typed `xsd:string` literals denote nothing (RDF 1.2 Semantics §7.1: `IL` is undefined
on an ill-typed literal of a recognized datatype). `DInterp` states `IL` on `xsd:string` only
through `strVal`, so this is assumed by the RDFS clash theorem rather than added to `DInterp`.
-- SIMPLIFICATION: [[simplifications#Well-typed strings as an assumption of the RDFS clash theorem]] -/
def SimpleInterp.WellTypedStrings (I : SimpleInterp) : Prop :=
  ∀ s, Xsd.isStringLexical s = false → I.IL (.typed s xsd.string) = none

/-- A D-interpretation in which ill-typed `xsd:string` literals denote nothing. -/
def DInterp.IsWellTyped (I : DInterp) : Prop := I.toSimpleInterp.WellTypedStrings

/-- The interpretations of the RDFS clash rules: the core RDFS conditions and well-typed
strings. -/
def RDFSClashCore (I : SimpleInterp) : Prop := RDFSCore I ∧ I.WellTypedStrings

-- @tg: implements:: [[openspec:inconsistency#Datatype clash]]
/-- An ill-typed `xsd:string` literal in object position: `?s ?p ?o` with `?o` ill-typed. -/
def dClashString : ClashRule :=
  { name := "d-clash-string", body := [⟨.var "s", .var "p", .var "o"⟩],
    guards := [.illTypedString "o"] }

theorem dClashString_sound : dClashString.SoundIn RDFSClashCore := by
  intro I hI A σ hg hb
  obtain ⟨s, hs, hlex⟩ := hg (.illTypedString "o") (.head _)
  obtain ⟨_, _, o, _, _, ho, _⟩ := hb _ (.head _)
  simp only [TPat.apply, Pat.apply, hs, SimpleInterp.denote] at ho
  rw [hI.2 s hlex] at ho
  cases ho

/-- The clash rules of the RDFS regime. -/
def rdfsClashRules : List ClashRule := [dClashString]

theorem rdfsClashRules_sound : ∀ r ∈ rdfsClashRules, r.SoundIn RDFSClashCore := by
  intro r hr
  simp only [rdfsClashRules, List.mem_cons, List.not_mem_nil, or_false] at hr
  subst hr; exact dClashString_sound

end LeanRDF
