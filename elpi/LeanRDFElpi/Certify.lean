import LeanRDFElpi.Saturate

/-!
# Certificates from closures

Turn a closure into a certificate for a query graph: find an instance mapping for the query's
blank nodes (a backtracking join over the closure), keep only the entries the goals need, and
number them in closure order so every premise is an earlier node. Untrusted: the checker in
`LeanRDF.Cert` decides.
-/

namespace LeanRDF.Bridge

open Cert

/-- Match a query term against a closure term, extending the blank-node mapping; blank nodes
inside a query triple term match inside the closure's triple term. -/
private def matchTerm (μ : List (BlankNode × Term)) (q c : Term) : Option (List (BlankNode × Term)) :=
  match q, c with
  | .bnode b, _ =>
    match μ.find? (·.1 == b) with
    | some (_, u) => if u == c then some μ else none
    | none => some ((b, c) :: μ)
  | .triple qs qp qo, .triple cs cp co => do
    matchTerm (← matchTerm (← matchTerm μ qs cs) qp cp) qo co
  | _, _ => if q == c then some μ else none

private def matchTriple (μ : List (BlankNode × Term)) (q c : Triple) :
    Option (List (BlankNode × Term)) := do
  matchTerm (← matchTerm (← matchTerm μ q.s c.s) q.p c.p) q.o c.o

/-- An instance mapping under which every query triple is in the closure, if there is one. -/
partial def findMu (closure : List Triple) :
    List Triple → List (BlankNode × Term) → Option (List (BlankNode × Term))
  | [], μ => some μ
  | t :: ts, μ => closure.findSome? fun c => (matchTriple μ t c).bind (findMu closure ts)

/-- The entries of a closure that `goals` need, numbered in closure order so that every premise
is an earlier node, with the id of every kept conclusion. -/
def prune (c : Closure) (goals : List Triple) : Except String (List Node × Std.HashMap Triple Nat) := do
  let byTriple : Std.HashMap Triple Entry := c.foldl (fun m e => m.insert e.conclusion e) {}
  -- the entries the goals need, by walking premises
  let mut needed : Std.HashSet Triple := {}
  let mut todo := goals
  while true do
    match todo with
    | [] => break
    | t :: rest =>
      todo := rest
      unless needed.contains t do
        needed := needed.insert t
        if let some e := byTriple[t]? then todo := e.premises ++ todo
  -- closure order keeps premises first; number the kept entries
  let mut ids : Std.HashMap Triple Nat := {}
  let mut nodes : Array Node := #[]
  for e in c do
    if needed.contains e.conclusion && !ids.contains e.conclusion then
      let premises ← e.premises.mapM fun p =>
        (ids[p]?).elim (throw s!"premise of {e.rule} missing") pure
      ids := ids.insert e.conclusion nodes.size
      nodes := nodes.push { id := nodes.size, conclusion := e.conclusion, rule := e.rule, premises }
  return (nodes.toList, ids)

-- @tg: implements:: [[openspec:certificates#Certificates from Elpi]]
/-- A certificate for `q` from a closure: the needed entries, renumbered, and the mapping. -/
def certify (c : Closure) (q : Graph) : Except String Certificate := do
  let some μ := findMu (c.toList.map (·.conclusion)) q.toList []
    | throw "no instance of the query is derived"
  let base : Certificate := { nodes := [], goals := [], mapping := μ.reverse }
  let goals := q.toList.map (·.instantiate base.mu)
  let (nodes, ids) ← prune c goals
  let goalIds ← goals.mapM fun t => (ids[t]?).elim (throw "a goal is not in the closure") pure
  return { base with nodes, goals := goalIds }

/-! ## Clashes -/

/-- The closure's triples by predicate. -/
abbrev PredIndex := Std.HashMap Term (Array Triple)

/-- The closure triples a pattern can match under a partial substitution: those with its
predicate when the predicate is known, all of them otherwise. -/
private def candidates (idx : PredIndex) (all : Array Triple) (σ : PSubst) (b : TPat) : Array Triple :=
  match b.p with
  | .const t => idx.getD t #[]
  | .var n => match σ.find? n with
    | some t => idx.getD t #[]
    | none => all
  | .triple _ _ _ => all

/-- A substitution under which every body pattern matches a closure triple and every guard
holds, with the matched triples in body order. A backtracking join. -/
partial def matchClash (idx : PredIndex) (all : Array Triple) (guards : List Guard) :
    List TPat → PSubst → List Triple → Option (List Triple)
  | [], σ, acc =>
    if guards.all (·.check σ.toSubst) then some acc.reverse else none
  | b :: bs, σ, acc =>
    (candidates idx all σ b).toList.findSome? fun t =>
      (matchTPat σ b t).bind fun σ' => matchClash idx all guards bs σ' (t :: acc)

-- @tg: implements:: [[openspec:inconsistency#Clash search]]
/-- The first clash found in a closure, as a pruned clash certificate: the premises of the clash
are the goals of the pruning. `none` when no clash rule has an instance, which is no claim of
consistency. Untrusted: `checkClash` decides. -/
def clashCertificate (c : Closure) (clashes : List ClashRule) : Except String (Option Certificate) := do
  let all := c.map (·.conclusion)
  let idx : PredIndex := all.foldl (fun m t => m.insert t.p ((m.getD t.p #[]).push t)) {}
  let found := clashes.findSome? fun r =>
    (matchClash idx all r.guards r.body [] []).map (r, ·)
  match found with
  | none => return none
  | some (r, premises) =>
    let (nodes, ids) ← prune c premises
    let premiseIds ← premises.mapM fun t => (ids[t]?).elim (throw "a clash premise is not in the closure") pure
    return some { nodes, goals := [], clash := some ⟨r.name, premiseIds⟩ }

-- @tg: implements:: [[openspec:certificates#End-to-end]]
/-- Saturate `g` with `rules` (by default `rdfsRules`) in Elpi and certify `q`. -/
def entailmentCertificate (g q : Graph) (fuel : Nat := Elpi.defaultFuel)
    (rules : List Rule := RDFS.rdfsRules) : Except String Certificate := do
  certify (← saturate rules g fuel) q

end LeanRDF.Bridge
