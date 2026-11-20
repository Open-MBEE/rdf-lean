import LeanRDF.Canon.Hash
import LeanRDF.Canon.Label

/-!
# RDFC-1.0 canonicalization

`canonicalLabels` runs the RDFC-1.0 canonicalization algorithm (§4.4.3) and returns the
canonical issue order of the blank nodes, with the relabeling that sends the `i`-th of them to
`_:c14n<i>`. `canonicalNQuads` writes the relabeled dataset as sorted canonical N-Quads (§4.4.3
step 6, §4.3).

The relabeling is applied as a composition of swaps (`LeanRDF.Canon.Label`), so it is a
bijection however the order was chosen: `canonicalLabels_injective` and `canonical_iso` hold for
every labeling, and need no proof about the hashing. That isomorphic datasets get the same
output is tested on the W3C rdf-canon suite.
-- SIMPLIFICATION: [[simplifications#Canonicity is tested, not proven]]
-/

namespace LeanRDF.Canon

/-- The canonical label of the `i`-th blank node: `c14n<i>`. -/
def c14n (i : Nat) : BlankNode := ⟨"c14n" ++ toString i⟩

/-- The swaps that send the `i`-th blank node of `order` to `c14n i`: the `i`-th swap exchanges
`c14n i` with the image of the `i`-th blank node under the swaps before it. -/
def swapsFor (order : List BlankNode) : List (BlankNode × BlankNode) :=
  (order.zip (List.range order.length)).foldl
    (fun acc (b, i) => acc ++ [(applySwaps acc b, c14n i)]) []

/-- A canonical labeling: the canonical issue order and the relabeling it gives. -/
structure Labeling where
  order : List BlankNode
  swaps : List (BlankNode × BlankNode) := swapsFor order

/-- The relabeling of blank nodes. -/
def Labeling.rename (σ : Labeling) : BlankNode → BlankNode := applySwaps σ.swaps

/-- The labeling as a list from input label to canonical label, in issue order. -/
def Labeling.toList (σ : Labeling) : List (String × String) :=
  σ.order.map fun b => (b.label, (σ.rename b).label)

/-- The default work limit: Hash N-Degree Quads calls and permutations together, for a dataset
with `n` blank nodes that share a first-degree hash. -/
def defaultLimit (n : Nat) : Nat := 10000 + 100 * n

/-- Run RDFC-1.0 (§4.4.3) with a hash function and a work limit. -/
def canonicalLabelsWith (hash : HashFn) (limit : Nat → Nat) (d : Dataset) :
    Except String Labeling := do
  let quads := d.toList
  -- Step 2: the blank node to quads map, each quad once per blank node.
  let mut quadsOf : Std.HashMap BlankNode (List Quad) := {}
  let mut nodes : Array BlankNode := #[]
  for q in quads do
    for b in (quadBNodes q).eraseDups do
      match quadsOf.get? b with
      | some qs => quadsOf := quadsOf.insert b (q :: qs)
      | none =>
        quadsOf := quadsOf.insert b [q]
        nodes := nodes.push b
  -- Step 3: first-degree hashes, and the hash to blank nodes map.
  let mut firstDegree : Std.HashMap BlankNode String := {}
  let mut byHash : Std.HashMap String (Array BlankNode) := {}
  for b in nodes do
    let h := hashFirstDegree hash ((quadsOf.getD b []).reverse) b
    firstDegree := firstDegree.insert b h
    byHash := byHash.insert h ((byHash.getD h #[]).push b)
  -- Step 4: blank nodes with a unique first-degree hash, in hash order.
  let mut canonical : Issuer := { pfx := "c14n" }
  let hashes := sortStrings (byHash.toList.map (·.1))
  for h in hashes do
    if let #[b] := byHash.getD h #[] then
      canonical := (canonical.issue b).2
  -- Step 5: the shared hashes, in hash order, by N-degree hashing.
  let shared := (hashes.filterMap fun h => let bs := byHash.getD h #[]; if bs.size > 1 then some bs else none)
  let nShared := shared.foldl (· + ·.size) 0
  for bs in shared do
    let ctx : Ctx := { hash, quadsOf, firstDegree, canonical, limit := limit nShared }
    let mut results : Array (String × Issuer) := #[]
    let mut work := 0
    for b in bs do
      if (canonical.find? b).isSome then continue
      let temp := (({ pfx := "b" } : Issuer).issue b).2
      let ctx := { ctx with canonical }
      let ((r, iss), w) ← (hashNDegree ctx b temp).run work
      work := w
      results := results.push (r, iss)
    for (_, iss) in results.toList.mergeSort (fun a b => decide (a.1 ≤ b.1)) do
      for b in iss.order do
        canonical := (canonical.issue b).2
  return { order := canonical.order.toList }

-- @tg: implements:: [[openspec:rdf-canonicalization#Canonical labeling]]
-- @tg: implements:: [[openspec:rdf-canonicalization#Triple terms in canonicalization]]
/-- RDFC-1.0 with SHA-256 and the default work limit. -/
def canonicalLabels (d : Dataset) : Except String Labeling :=
  canonicalLabelsWith LeanRDF.Hash.sha256 defaultLimit d

/-- The canonical dataset: the input relabeled by its canonical labeling. -/
def canonicalize (σ : Labeling) (d : Dataset) : Dataset := d.renameBNodes σ.rename

/-- A relabeled dataset as canonical N-Quads lines in code-point order. -/
def nquadsSorted (d : Dataset) : String :=
  String.join (sortStrings (d.toList.map (quadWith (·.label))))

-- @tg: implements:: [[openspec:rdf-canonicalization#Canonical N-Quads]]
/-- The canonical N-Quads of a dataset under a hash function (RDFC-1.0 §4.4.3 step 6). -/
def canonicalNQuadsWith (hash : HashFn) (d : Dataset) : Except String String := do
  let σ ← canonicalLabelsWith hash defaultLimit d
  return nquadsSorted (canonicalize σ d)

/-- The canonical N-Quads of a dataset: RDFC-1.0 with SHA-256. -/
def canonicalNQuads (d : Dataset) : Except String String :=
  canonicalNQuadsWith LeanRDF.Hash.sha256 d

-- @tg: implements:: [[openspec:rdf-canonicalization#Canonical isomorphism]]
/-- Every canonical labeling is injective on blank nodes (indeed a bijection), in particular on
the blank nodes of its input. -/
theorem canonicalLabels_injective (σ : Labeling) :
    ∀ a b, σ.rename a = σ.rename b → a = b :=
  (applySwaps_bijective σ.swaps).1

/-- The canonical dataset is isomorphic to its input. -/
theorem canonical_iso (σ : Labeling) (d : Dataset) : Dataset.Iso d (canonicalize σ d) :=
  Dataset.iso_renameBNodes (applySwaps_bijective σ.swaps) d

end LeanRDF.Canon
