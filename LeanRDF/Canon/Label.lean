import LeanRDF.Core.Iso
import LeanRDF.Core.Dataset

/-!
# Relabelings and dataset isomorphism

The canonical labeling of RDFC-1.0 is applied as a composition of swaps of blank nodes: the
`i`-th blank node of the issue order is swapped with `_:c14n<i>`. A composition of swaps is a
bijection on all blank nodes (`applySwaps_bijective`), so relabeling a dataset by it gives an
isomorphic dataset (`Dataset.iso_renameBNodes`), whatever order the algorithm chose. That is the
part of canonicalization soundness that is proven; that isomorphic inputs get equal labels
(canonicity) is tested on the W3C suite.
-/

namespace LeanRDF

/-! ## Swaps -/

/-- Exchange `a` and `b`, fixing every other blank node. -/
def swapB (a b x : BlankNode) : BlankNode :=
  if x = a then b else if x = b then a else x

theorem swapB_swapB (a b x : BlankNode) : swapB a b (swapB a b x) = x := by
  unfold swapB
  by_cases ha : x = a
  · subst ha; by_cases hb : b = x <;> simp [hb]
  · by_cases hb : x = b
    · subst hb; simp [ha]
    · simp [ha, hb]

/-- Apply the swaps of a list, first to last. -/
def applySwaps (l : List (BlankNode × BlankNode)) (x : BlankNode) : BlankNode :=
  l.foldl (fun y p => swapB p.1 p.2 y) x

/-- Undo `applySwaps`: the swaps last to first. -/
def unapplySwaps (l : List (BlankNode × BlankNode)) (y : BlankNode) : BlankNode :=
  l.foldr (fun p y => swapB p.1 p.2 y) y

theorem unapply_apply (l : List (BlankNode × BlankNode)) (x : BlankNode) :
    unapplySwaps l (applySwaps l x) = x := by
  induction l generalizing x with
  | nil => rfl
  | cons p l ih =>
    show swapB p.1 p.2 (unapplySwaps l (applySwaps l (swapB p.1 p.2 x))) = x
    rw [ih, swapB_swapB]

theorem apply_unapply (l : List (BlankNode × BlankNode)) (y : BlankNode) :
    applySwaps l (unapplySwaps l y) = y := by
  induction l generalizing y with
  | nil => rfl
  | cons p l ih =>
    show applySwaps l (swapB p.1 p.2 (swapB p.1 p.2 (unapplySwaps l y))) = y
    rw [swapB_swapB, ih]

/-- A composition of swaps is a bijection on blank nodes. -/
theorem applySwaps_bijective (l : List (BlankNode × BlankNode)) : Bijective (applySwaps l) :=
  ⟨fun a b h => by rw [← unapply_apply l a, h, unapply_apply],
   fun y => ⟨unapplySwaps l y, apply_unapply l y⟩⟩

/-! ## Renaming is injective -/

theorem Term.renameBNodes_injective {f : BlankNode → BlankNode} (hf : ∀ a b, f a = f b → a = b) :
    ∀ s t : Term, s.renameBNodes f = t.renameBNodes f → s = t := by
  intro s
  induction s with
  | iri i => intro t h; cases t <;> simp_all [Term.renameBNodes]
  | bnode b =>
    intro t h
    cases t <;> simp [Term.renameBNodes] at h
    exact congrArg Term.bnode (hf _ _ h)
  | lit l => intro t h; cases t <;> simp_all [Term.renameBNodes]
  | triple s p o hs hp ho =>
    intro t h
    cases t with
    | triple s' p' o' =>
      simp only [Term.renameBNodes, Term.triple.injEq] at h
      rw [hs _ h.1, hp _ h.2.1, ho _ h.2.2]
    | _ => simp [Term.renameBNodes] at h

/-! ## Datasets -/

/-- Rename the blank nodes of a quad in every position, the graph name included. -/
def Quad.renameBNodes (f : BlankNode → BlankNode) (q : Quad) : Quad :=
  ⟨q.s.renameBNodes f, q.p.renameBNodes f, q.o.renameBNodes f, q.g.map (·.renameBNodes f)⟩

theorem Quad.renameBNodes_injective {f : BlankNode → BlankNode} (hf : ∀ a b, f a = f b → a = b)
    (q r : Quad) (h : q.renameBNodes f = r.renameBNodes f) : q = r := by
  obtain ⟨s, p, o, g⟩ := q
  obtain ⟨s', p', o', g'⟩ := r
  simp only [Quad.renameBNodes, Quad.mk.injEq] at h
  obtain ⟨h1, h2, h3, h4⟩ := h
  have hi := Term.renameBNodes_injective hf
  have hg : g = g' := by
    cases g <;> cases g' <;> simp at h4 ⊢
    exact hi _ _ h4
  rw [hi _ _ h1, hi _ _ h2, hi _ _ h3, hg]

namespace Dataset

/-- Rename the blank nodes of every quad. -/
def renameBNodes (f : BlankNode → BlankNode) (d : Dataset) : Dataset :=
  ofList (d.toList.map (Quad.renameBNodes f))

theorem mem_renameBNodes {f : BlankNode → BlankNode} {d : Dataset} {q : Quad} :
    q ∈ d.renameBNodes f ↔ ∃ r ∈ d, r.renameBNodes f = q := by
  simp [renameBNodes]

/-- Dataset isomorphism up to blank-node renaming (RDF 1.1 Concepts §4): a bijection on blank
nodes that maps the quads of one dataset onto the quads of the other, graph names and triple
terms included. -/
def Iso (d e : Dataset) : Prop :=
  ∃ f : BlankNode → BlankNode, Bijective f ∧ ∀ q : Quad, q ∈ d ↔ q.renameBNodes f ∈ e

/-- Renaming a dataset by a bijection gives an isomorphic dataset. -/
theorem iso_renameBNodes {f : BlankNode → BlankNode} (hf : Bijective f) (d : Dataset) :
    Iso d (d.renameBNodes f) := by
  refine ⟨f, hf, fun q => ⟨fun h => mem_renameBNodes.2 ⟨q, h, rfl⟩, fun h => ?_⟩⟩
  obtain ⟨r, hr, he⟩ := mem_renameBNodes.1 h
  rwa [← Quad.renameBNodes_injective hf.1 r q he]

end Dataset

end LeanRDF
