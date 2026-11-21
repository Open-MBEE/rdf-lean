import LeanRDF
import LeanRDFOwl

/-!
# Regimes

The five entailment regimes a certificate can be checked under, each with its rule list, the
entailment its acceptance proves, and the theorem that proves it. `checkRegime_sound` is the one
theorem `leanrdf-check` stands for.
-/

namespace LeanRDF.Check

open Cert

-- @tg: implements:: [[openspec:certificate-check#Regimes]]
/-- An entailment regime. `owl` is OWL 2 RL over RDFS; `el` adds the EL completion rules. -/
inductive Regime where
  | simple | rdf | rdfs | owl | el
  deriving Repr, DecidableEq, Inhabited

namespace Regime

/-- Every regime, in order. -/
def all : List Regime := [.simple, .rdf, .rdfs, .owl, .el]

/-- The name used on the command line and in verdicts. -/
def name : Regime → String
  | .simple => "simple" | .rdf => "rdf" | .rdfs => "rdfs" | .owl => "owl" | .el => "el"

/-- Read a regime name, case-sensitively. -/
def ofName? (s : String) : Option Regime := all.find? (·.name == s)

/-- The rule list a certificate is checked against. -/
def rules : Regime → List Rule
  | .simple => RDFS.simpleRules
  | .rdf => RDFS.rdfRules
  | .rdfs => RDFS.rdfsRules
  | .owl => Owl.owlRules
  | .el => Owl.owlELRules

/-- The entailment an accepted certificate proves. -/
def Entails : Regime → Graph → Graph → Prop
  | .simple, g, q => g.SimpleEntails q
  | .rdf, g, q => g.RDFEntails q
  | .rdfs, g, q => g.RDFSEntails q
  | .owl, g, q => g.OWLEntails q
  | .el, g, q => g.OWLEntails q

/-- The theorem of the library that proves `Entails` from an accepted certificate. -/
def theoremName : Regime → String
  | .simple => "checkQuery_sound_simple"
  | .rdf => "checkQuery_sound_rdf"
  | .rdfs => "checkQuery_sound"
  | .owl => "Derives.owl_sound_graph"
  | .el => "Derives.el_sound_graph"

/-- The entailment as a sentence, for reports. -/
def entailsName : Regime → String
  | .simple => "SimpleEntails" | .rdf => "RDFEntails" | .rdfs => "RDFSEntails"
  | .owl => "OWLEntails" | .el => "OWLEntails"

end Regime

/-- Simple entailment needs a well-formed query (`checkQuery_sound_simple`). -/
def queryWellFormed (q : Graph) : Bool := q.toList.all (fun t => decide t.WellFormed)

theorem queryWellFormed_spec {q : Graph} (h : queryWellFormed q = true) :
    ∀ t ∈ q, t.WellFormed := fun t ht =>
  of_decide_eq_true (List.all_eq_true.1 h t (Graph.mem_toList.2 ht))

-- @tg: implements:: [[openspec:certificate-check#Regime checker soundness]]
/-- Check a certificate for the query `q` over the data `g` under a regime. -/
def checkRegime (r : Regime) (g q : Graph) (c : Certificate) : Except String Unit :=
  match r with
  | .simple =>
    if queryWellFormed q then checkQuery r.rules g q c
    else .error "the query is not well-formed RDF, which simple entailment requires"
  | _ => checkQuery r.rules g q c

/-- Soundness: an accepted certificate proves the regime's entailment of the query. -/
theorem checkRegime_sound {r : Regime} {g q : Graph} {c : Certificate}
    (h : checkRegime r g q c = .ok ()) : r.Entails g q := by
  cases r with
  | simple =>
    simp only [checkRegime] at h
    split at h
    · rename_i hwf
      exact checkQuery_sound_simple (queryWellFormed_spec hwf) h
    · cases h
  | rdf => exact checkQuery_sound_rdf h
  | rdfs => exact checkQuery_sound h
  | owl => exact Derives.owl_sound_graph c.mu (checkQuery_derives h)
  | el => exact Derives.el_sound_graph c.mu (checkQuery_derives h)

/-- `checkRegime` as a Boolean, for `native_decide` on concrete certificates. -/
def checkRegimeB (r : Regime) (g q : Graph) (c : Certificate) : Bool :=
  (checkRegime r g q c).toBool

theorem checkRegimeB_sound {r : Regime} {g q : Graph} {c : Certificate}
    (h : checkRegimeB r g q c = true) : r.Entails g q := by
  apply checkRegime_sound
  unfold checkRegimeB at h
  cases hc : checkRegime r g q c with
  | ok u => rfl
  | error e => rw [hc] at h; simp [Except.toBool] at h

/-! ## Countermodels -/

/-- The countermodel regime of a regime: simple, RDF and RDFS only. -/
def Regime.countermodel? : Regime → Option Model.CRegime
  | .simple => some .simple
  | .rdf => some .rdf
  | .rdfs => some .rdfs
  | .owl | .el => none

/-- The recognized datatypes a refutation is relative to. -/
def datatypesNote : String := "D = {xsd:string, rdf:langString, rdf:dirLangString}"

/-! ## Clash certificates -/

/-- The clash rules of a regime: the datatype clash under RDFS, the OWL 2 RL clash rules under
OWL and EL. Simple and RDF entailment have none. -/
def Regime.clashRules? : Regime → Option (List ClashRule)
  | .rdfs => some rdfsClashRules
  | .owl | .el => some Owl.owlClashRules
  | .simple | .rdf => none

/-- What an accepted clash certificate proves: the data has no model of the regime. -/
def Regime.Inconsistent : Regime → Graph → Prop
  | .rdfs, g => ¬ ∃ I : DInterp, I.IsRDFS ∧ I.IsWellTyped ∧ I.Satisfies g
  | .owl, g | .el, g => ¬ ∃ I : DInterp, I.IsOWL ∧ I.Satisfies g
  | .simple, _ | .rdf, _ => True

/-- The theorem an accepted clash certificate stands for. -/
def Regime.clashTheoremName : Regime → String
  | .rdfs => "checkClash_sound_rdfs"
  | .owl => "checkClash_sound_owl"
  | .el => "checkClash_sound_el"
  | .simple | .rdf => ""

-- @tg: implements:: [[openspec:certificate-check#Clash certificate checking]]
/-- Check a clash certificate under a regime. -/
def checkRegimeClash (r : Regime) (g : Graph) (c : Certificate) : Except String Unit :=
  match r with
  | .rdfs => checkClash RDFS.rdfsRules rdfsClashRules g c
  | .owl => checkClash Owl.owlRules Owl.owlClashRules g c
  | .el => checkClash Owl.owlELRules Owl.owlClashRules g c
  | .simple | .rdf => .error s!"clash certificates are checked under rdfs, owl or el, not {r.name}"

/-- Soundness: an accepted clash certificate proves that the data has no model of the regime. -/
theorem checkRegimeClash_sound {r : Regime} {g : Graph} {c : Certificate}
    (h : checkRegimeClash r g c = .ok ()) : r.Inconsistent g := by
  cases r with
  | rdfs => exact checkClash_sound_rdfs h
  | owl => exact checkClash_sound_owl h
  | el => exact checkClash_sound_el h
  | simple => trivial
  | rdf => trivial

end LeanRDF.Check
