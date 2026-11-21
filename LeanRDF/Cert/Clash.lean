import LeanRDF.Cert.Check
import LeanRDF.Entailment.Clash

/-!
# The clash checker

A clash certificate is a proof DAG, checked node by node as any certificate, with a `clash`
member: a clash rule and the ids of its premise nodes. `checkClash` accepts it when every node
is accepted, the clash rule is in the list, and the premises match the rule's body in order,
with every guard true. `checkClash_sound` turns acceptance into "no interpretation of the class
satisfies the graph"; for the OWL regime the theorem is in `leanrdf-owl`.
-/

namespace LeanRDF.Cert

-- @tg: implements:: [[openspec:inconsistency#Clash checker]]
/-- Check a clash certificate against a graph, under derivation rules and clash rules. -/
def checkClash (rules : List Rule) (clashes : List ClashRule) (g : Graph) (c : Certificate) :
    Except String Unit :=
  match checkCert rules g c with
  | .error e => .error e
  | .ok done =>
    match c.clash with
    | none => .error "not a clash certificate"
    | some k =>
      match clashes.find? (·.name == k.rule) with
      | none => .error s!"clash: unknown clash rule {k.rule}"
      | some r =>
        match premiseTriples done k.premises with
        | .error e => .error s!"clash: {e}"
        | .ok ps =>
          match matchBody [] r.body ps with
          | none => .error s!"clash: premises do not match the body of {r.name}"
          | some σ =>
            if r.guards.all (·.check σ.toSubst) then .ok ()
            else .error s!"clash: a guard of {r.name} fails"

-- @tg: implements:: [[openspec:inconsistency#Clash checker soundness]]
/-- Soundness of the clash checker: when every rule and clash rule is sound in `C`, an accepted
clash certificate proves that no interpretation of `C` makes the graph true under any
blank-node mapping. -/
theorem checkClash_sound {C : SimpleInterp → Prop} {rules : List Rule} {clashes : List ClashRule}
    {g : Graph} {c : Certificate} (hr : ∀ r ∈ rules, r.SoundIn C)
    (hc : ∀ r ∈ clashes, r.SoundIn C) (h : checkClash rules clashes g c = .ok ()) :
    ¬ ∃ I, C I ∧ ∃ A : BlankNode → I.Dom, ∀ t ∈ g, I.Holds A t := by
  rintro ⟨I, hI, A, hg⟩
  unfold checkClash at h
  split at h
  · cases h
  rename_i done hdone
  split at h
  · cases h
  rename_i k _
  split at h
  · cases h
  rename_i r hfind
  split at h
  · cases h
  rename_i ps hps
  split at h
  · cases h
  rename_i σ hσ
  split at h
  · rename_i hguards
    refine hc r (List.mem_of_find?_eq_some hfind) I hI A σ.toSubst
      (fun gd hgd => Guard.check_sound (List.all_eq_true.1 hguards gd hgd)) (fun b hb => ?_)
    obtain ⟨p, hp, hfit⟩ := (matchBody_spec hσ).2 b hb
    rw [hfit.apply]
    exact Derives.holdsIn hr I hI A hg (checkCert_sound hdone p (premiseTriples_mem hps p hp))
  · cases h

/-- No interpretation of `C` satisfies a graph with an accepted clash certificate. -/
theorem checkClash_unsat {C : SimpleInterp → Prop} {rules : List Rule} {clashes : List ClashRule}
    {g : Graph} {c : Certificate} (hr : ∀ r ∈ rules, r.SoundIn C)
    (hc : ∀ r ∈ clashes, r.SoundIn C) (h : checkClash rules clashes g c = .ok ())
    {I : SimpleInterp} (hI : C I) : ¬ I.Satisfies g :=
  fun ⟨A, _, hg⟩ => checkClash_sound hr hc h ⟨I, hI, A, hg⟩

/-- The RDFS regime: an accepted clash certificate under `rdfsRules` and `rdfsClashRules` proves
that no RDFS interpretation with well-typed strings satisfies the graph. -/
theorem checkClash_sound_rdfs {g : Graph} {c : Certificate}
    (h : checkClash RDFS.rdfsRules rdfsClashRules g c = .ok ()) :
    ¬ ∃ I : DInterp, I.IsRDFS ∧ I.IsWellTyped ∧ I.Satisfies g := by
  rintro ⟨I, hI, hw, hg⟩
  exact checkClash_unsat (fun r hr => (rdfsRules_sound r hr).mono fun _ h => h.1)
    rdfsClashRules_sound h ⟨hI.toCore, hw⟩ hg

/-- `checkClash` as a Boolean, for `native_decide` on concrete certificates. -/
def checkClashB (rules : List Rule) (clashes : List ClashRule) (g : Graph) (c : Certificate) : Bool :=
  (checkClash rules clashes g c).toBool

theorem checkClashB_ok {rules : List Rule} {clashes : List ClashRule} {g : Graph} {c : Certificate}
    (h : checkClashB rules clashes g c = true) : checkClash rules clashes g c = .ok () := by
  unfold checkClashB at h
  cases hq : checkClash rules clashes g c with
  | ok u => rfl
  | error e => rw [hq] at h; simp [Except.toBool] at h

end LeanRDF.Cert
