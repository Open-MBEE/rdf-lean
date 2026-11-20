import Lean.Data.Json
import LeanRDFCheck.Regime

/-!
# Verdicts

One verdict vocabulary for every LeanRDF tool, with fixed exit codes. `leanrdf-check` produces
`proven`, `rejected` and `inputError`; `unknown`, `inconsistent` and `refuted` belong to tools
that search (`add-inconsistency-certificates`, `add-countermodels`), and are fixed here so that
no later change renames a verdict.
-/

namespace LeanRDF.Check

open Lean (Json)

/-- A verdict. -/
inductive Verdict where
  | proven | unknown | rejected | inputError | inconsistent | refuted
  deriving Repr, DecidableEq, Inhabited

namespace Verdict

/-- The exit code: `0` proven, `1` unknown (not derived), `2` certificate rejected, `3` input
error, `4` inconsistent, `5` refuted. -/
def exitCode : Verdict → UInt32
  | .proven => 0 | .unknown => 1 | .rejected => 2 | .inputError => 3
  | .inconsistent => 4 | .refuted => 5

/-- The name in JSON verdicts. -/
def name : Verdict → String
  | .proven => "proven" | .unknown => "unknown" | .rejected => "rejected"
  | .inputError => "input-error" | .inconsistent => "inconsistent" | .refuted => "refuted"

end Verdict

/-- What a check reports, as text or JSON. -/
structure Report where
  verdict : Verdict
  regime : Option Regime := none
  dataTriples : Option Nat := none
  queryTriples : Option Nat := none
  nodes : Option Nat := none
  goals : List Nat := []
  mapping : List (BlankNode × Term) := []
  reason : Option String := none
  /-- The digests of the data and the query that were read. -/
  graphDigest : Option String := none
  queryDigest : Option String := none
  /-- `true` when the envelope was verified, `false` for a version-1 certificate (no envelope),
  absent when the envelope did not match. -/
  bound : Option Bool := none
  /-- Where `--emit-envelope` wrote the version-2 certificate. -/
  emitted : Option String := none
  deriving Inhabited

-- @tg: implements:: [[openspec:certificate-check#JSON verdict]]
/-- The report as one JSON object. -/
def Report.toJson (r : Report) : Json :=
  let opt (k : String) (v : Option Json) : List (String × Json) :=
    match v with | some j => [(k, j)] | none => []
  Json.mkObj <|
    [("verdict", Json.str r.verdict.name), ("exit", Lean.toJson r.verdict.exitCode.toNat)]
    ++ opt "regime" (r.regime.map (Json.str ·.name))
    ++ opt "theorem" (if r.verdict == .proven then r.regime.map (Json.str ·.theoremName) else none)
    ++ opt "dataTriples" (r.dataTriples.map Lean.toJson)
    ++ opt "queryTriples" (r.queryTriples.map Lean.toJson)
    ++ opt "nodes" (r.nodes.map Lean.toJson)
    ++ (if r.nodes.isSome then [("goals", Lean.toJson r.goals)] else [])
    ++ (if r.mapping.isEmpty then [] else
        [("mapping", Json.mkObj (r.mapping.map fun (b, t) =>
          ((Term.bnode b).toNTriples, Json.str t.toNTriples)))])
    ++ opt "graph" (r.graphDigest.map Json.str)
    ++ opt "query" (r.queryDigest.map Json.str)
    ++ opt "bound" (r.bound.map Json.bool)
    ++ opt "emitted" (r.emitted.map Json.str)
    ++ opt "reason" (r.reason.map Json.str)

/-- The report as text. -/
def Report.toText (r : Report) : String := Id.run do
  let mut out := ""
  if let (some d, some q) := (r.dataTriples, r.queryTriples) then
    out := out ++ s!"LeanRDF check: {d} data triples, {q} query triples\n"
  if let some n := r.nodes then
    out := out ++ s!"Certificate: {n} nodes, goals {r.goals}\n"
  if let some d := r.graphDigest then out := out ++ s!"Data digest: {d}\n"
  if let some d := r.queryDigest then out := out ++ s!"Query digest: {d}\n"
  match r.bound with
  | some true => out := out ++ "Envelope: verified (data, query, rules and regime match)\n"
  | some false => out := out ++ "Envelope: none; a version-1 certificate is unbound to its data\n"
  | none => pure ()
  for (b, t) in r.mapping do
    out := out ++ s!"Query instance: {(Term.bnode b).toNTriples} ↦ {t.toNTriples}\n"
  if let some p := r.emitted then out := out ++ s!"Wrote the version-2 certificate to {p}\n"
  match r.verdict, r.regime with
  | .proven, some rg =>
    out := out ++ s!"Verdict: PROVEN. The verified checker accepted the certificate under {rg.name}: by {rg.theoremName}, the data {rg.entailsName} the query."
  | .rejected, _ =>
    out := out ++ s!"Verdict: CERTIFICATE REJECTED: {r.reason.getD ""}"
  | _, _ =>
    out := out ++ (r.reason.getD r.verdict.name)
  return out

end LeanRDF.Check
