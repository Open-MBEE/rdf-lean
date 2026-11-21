import LeanRDFOwl.Clash
import LeanRDFOwl.Soundness
import LeanRDFOwl.ELSoundness

/-!
# Soundness of the OWL 2 RL clash rules

Every rule of `owlClashRules` is sound in every interpretation satisfying `OWLCore`: no such
interpretation makes all of its premises true. With the soundness of `owlRules`, an accepted
clash certificate proves that the graph has no OWL model (`checkClash_sound_owl`), and so
OWL-entails every graph (`checkClash_explodes_owl`).
-/

namespace LeanRDF.Owl

open Vocab RDFS Semantics SimpleInterp Cert

private theorem b0 {α : Type} {x : α} {l : List α} : x ∈ x :: l := .head _
private theorem b1 {α : Type} {x y : α} {l : List α} : y ∈ x :: y :: l := .tail _ b0
private theorem b2 {α : Type} {x y z : α} {l : List α} : z ∈ x :: y :: z :: l := .tail _ b1
private theorem b3 {α : Type} {x y z w : α} {l : List α} : w ∈ x :: y :: z :: w :: l := .tail _ b2
private theorem b4 {α : Type} {x y z w a : α} {l : List α} : a ∈ x :: y :: z :: w :: a :: l := .tail _ b3
private theorem b5 {α : Type} {x y z w a b : α} {l : List α} : b ∈ x :: y :: z :: w :: a :: b :: l :=
  .tail _ b4

theorem eqDiff1_sound : eqDiff1.SoundIn OWLCore := by
  intro I hI A σ _ hb
  obtain ⟨x, y, hx, hy, h1⟩ := holds_iri (hb _ b0)
  obtain ⟨x', y', hx', hy', h2⟩ := holds_iri (hb _ b1)
  cases same hx hx'; cases same hy hy'
  obtain ⟨rfl, -⟩ := (hI.2.sameAs x y).1 h1
  exact hI.2.differentFrom x x h2 rfl

theorem prpIrp_sound : prpIrp.SoundIn OWLCore := by
  intro I hI A σ _ hb
  obtain ⟨p, hp, hc⟩ := holds_type (hb _ b0)
  obtain ⟨x, p', x', hx, hp', hx', h⟩ := holds_any (hb _ b1)
  cases same hp hp'; cases same hx hx'
  exact hI.2.irreflexive _ hc x h

theorem prpAsyp_sound : prpAsyp.SoundIn OWLCore := by
  intro I hI A σ _ hb
  obtain ⟨p, hp, hc⟩ := holds_type (hb _ b0)
  obtain ⟨x, p₁, y, hx, hp₁, hy, h1⟩ := holds_any (hb _ b1)
  obtain ⟨y', p₂, x', hy', hp₂, hx', h2⟩ := holds_any (hb _ b2)
  cases same hp hp₁; cases same hp hp₂; cases same hx hx'; cases same hy hy'
  exact hI.2.asymmetric _ hc x y h1 h2

theorem prpPdw_sound : prpPdw.SoundIn OWLCore := by
  intro I hI A σ _ hb
  obtain ⟨p1, p2, hp1, hp2, hd⟩ := holds_iri (hb _ b0)
  obtain ⟨x, q1, y, hx, hq1, hy, h1⟩ := holds_any (hb _ b1)
  obtain ⟨x', q2, y', hx', hq2, hy', h2⟩ := holds_any (hb _ b2)
  cases same hp1 hq1; cases same hp2 hq2; cases same hx hx'; cases same hy hy'
  exact hI.2.propDisjoint _ _ hd x y h1 h2

theorem prpNpa1_sound : prpNpa1.SoundIn OWLCore := by
  intro I hI A σ _ hb
  obtain ⟨z, i1, hz, hi1, hs⟩ := holds_iri (hb _ b0)
  obtain ⟨z', p, hz', hp, ha⟩ := holds_iri (hb _ b1)
  obtain ⟨z'', i2, hz'', hi2, ht⟩ := holds_iri (hb _ b2)
  obtain ⟨j1, p', j2, hj1, hp', hj2, h⟩ := holds_any (hb _ b3)
  cases same hz hz'; cases same hz hz''; cases same hp hp'; cases same hi1 hj1; cases same hi2 hj2
  exact hI.2.npaIndividual _ _ _ _ hs ha ht h

theorem prpNpa2_sound : prpNpa2.SoundIn OWLCore := by
  intro I hI A σ _ hb
  obtain ⟨z, i, hz, hi, hs⟩ := holds_iri (hb _ b0)
  obtain ⟨z', p, hz', hp, ha⟩ := holds_iri (hb _ b1)
  obtain ⟨z'', lt, hz'', hlt, ht⟩ := holds_iri (hb _ b2)
  obtain ⟨j, p', lt', hj, hp', hlt', h⟩ := holds_any (hb _ b3)
  cases same hz hz'; cases same hz hz''; cases same hp hp'; cases same hi hj; cases same hlt hlt'
  exact hI.2.npaValue _ _ _ _ hs ha ht h

theorem clsNothing2_sound : clsNothing2.SoundIn OWLCore := by
  intro I hI A σ _ hb
  obtain ⟨x, _, hc⟩ := holds_type (hb _ b0)
  exact hI.2.nothing x hc

theorem clsCom_sound : clsCom.SoundIn OWLCore := by
  intro I hI A σ _ hb
  obtain ⟨c1, c2, hc1, hc2, hd⟩ := holds_iri (hb _ b0)
  obtain ⟨x, c1', hx, hc1', h1⟩ := holds_iri (hb _ b1)
  obtain ⟨x', c2', hx', hc2', h2⟩ := holds_iri (hb _ b2)
  cases same hc1 hc1'; cases same hc2 hc2'; cases same hx hx'
  exact hI.2.complementOf _ _ hd x h1 h2

theorem clsMaxc1_sound : clsMaxc1.SoundIn OWLCore := by
  intro I hI A σ _ hb
  obtain ⟨x, n, hx, hn, hm⟩ := holds_iri (hb _ b0)
  obtain ⟨x', p, hx', hp, ho⟩ := holds_iri (hb _ b1)
  obtain ⟨u, x'', hu, hx'', ht⟩ := holds_iri (hb _ b2)
  obtain ⟨u', p', y, hu', hp', _, h⟩ := holds_any (hb _ b3)
  cases same hx hx'; cases same hx hx''; cases same hu hu'; cases same hp hp'
  exact hI.2.maxCard0 _ _ _ hn hm ho _ ht _ h

theorem clsMaxqc1_sound : clsMaxqc1.SoundIn OWLCore := by
  intro I hI A σ _ hb
  obtain ⟨x, n, hx, hn, hm⟩ := holds_iri (hb _ b0)
  obtain ⟨x₁, p, hx₁, hp, ho⟩ := holds_iri (hb _ b1)
  obtain ⟨x₂, c, hx₂, hc, hoc⟩ := holds_iri (hb _ b2)
  obtain ⟨u, x₃, hu, hx₃, ht⟩ := holds_iri (hb _ b3)
  obtain ⟨u', p', y, hu', hp', hy, h⟩ := holds_any (hb _ b4)
  obtain ⟨y', c', hy', hc', hyc⟩ := holds_iri (hb _ b5)
  cases same hx hx₁; cases same hx hx₂; cases same hx hx₃; cases same hu hu'; cases same hp hp'
  cases same hy hy'; cases same hc hc'
  exact hI.2.maxQCard0 _ _ _ _ hn hm ho hoc _ ht _ h hyc

theorem clsMaxqc2_sound : clsMaxqc2.SoundIn OWLCore := by
  intro I hI A σ _ hb
  obtain ⟨x, n, hx, hn, hm⟩ := holds_iri (hb _ b0)
  obtain ⟨x₁, p, hx₁, hp, ho⟩ := holds_iri (hb _ b1)
  obtain ⟨x₂, hx₂, hoc⟩ := holds_const (hb _ b2)
  obtain ⟨u, x₃, hu, hx₃, ht⟩ := holds_iri (hb _ b3)
  obtain ⟨u', p', y, hu', hp', _, h⟩ := holds_any (hb _ b4)
  cases same hx hx₁; cases same hx hx₂; cases same hx hx₃; cases same hu hu'; cases same hp hp'
  exact hI.2.maxQCard0 _ _ _ _ hn hm ho hoc _ ht _ h
    (hI.2.thing _ (I.IEXT_wt _ _ _ h).2.2)

theorem caxDw_sound : caxDw.SoundIn OWLCore := by
  intro I hI A σ _ hb
  obtain ⟨c1, c2, hc1, hc2, hd⟩ := holds_iri (hb _ b0)
  obtain ⟨x, c1', hx, hc1', h1⟩ := holds_iri (hb _ b1)
  obtain ⟨x', c2', hx', hc2', h2⟩ := holds_iri (hb _ b2)
  cases same hc1 hc1'; cases same hc2 hc2'; cases same hx hx'
  exact hI.2.disjointWith _ _ hd x h1 h2

-- @tg: implements:: [[openspec:owl-rl#OWL clash soundness]]
/-- Every OWL 2 RL clash rule is sound for the OWL conditions. -/
theorem owlClashRules_sound : ∀ r ∈ owlClashRules, r.SoundIn OWLCore := by
  intro r hr
  simp only [owlClashRules, List.mem_cons, List.not_mem_nil, or_false] at hr
  rcases hr with rfl | rfl | rfl | rfl | rfl | rfl | rfl | rfl | rfl | rfl | rfl | rfl
  · exact eqDiff1_sound
  · exact prpIrp_sound
  · exact prpAsyp_sound
  · exact prpPdw_sound
  · exact prpNpa1_sound
  · exact prpNpa2_sound
  · exact clsNothing2_sound
  · exact clsCom_sound
  · exact clsMaxc1_sound
  · exact clsMaxqc1_sound
  · exact clsMaxqc2_sound
  · exact caxDw_sound

/-- An accepted OWL clash certificate proves that no OWL interpretation satisfies the graph. -/
theorem _root_.LeanRDF.Cert.checkClash_sound_owl {g : Graph} {c : Certificate}
    (h : checkClash owlRules owlClashRules g c = .ok ()) :
    ¬ ∃ I : DInterp, I.IsOWL ∧ I.Satisfies g := by
  rintro ⟨I, hI, hg⟩
  exact checkClash_unsat owlRules_sound owlClashRules_sound h hI.toCore hg

/-- Explosion: a graph with an accepted OWL clash certificate OWL-entails every graph. -/
theorem _root_.LeanRDF.Cert.checkClash_explodes_owl {g : Graph} {c : Certificate}
    (h : checkClash owlRules owlClashRules g c = .ok ()) (q : Graph) : g.OWLEntails q :=
  fun I hI hg => absurd ⟨I, hI, hg⟩ (checkClash_sound_owl h)

/-- The EL regime: an accepted clash certificate under `owlELRules` proves that no OWL
interpretation satisfies the graph. -/
theorem _root_.LeanRDF.Cert.checkClash_sound_el {g : Graph} {c : Certificate}
    (h : checkClash owlELRules owlClashRules g c = .ok ()) :
    ¬ ∃ I : DInterp, I.IsOWL ∧ I.Satisfies g := by
  rintro ⟨I, hI, hg⟩
  exact checkClash_unsat owlELRules_sound owlClashRules_sound h hI.toCore hg

end LeanRDF.Owl
