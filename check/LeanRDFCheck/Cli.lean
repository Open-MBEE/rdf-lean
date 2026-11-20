import LeanRDFCheck.Verdict

/-!
# The `leanrdf-check` command line

`leanrdf-check --data DATA --query QUERY --cert CERT [--rules REGIME] [--json]
[--emit-envelope OUT]` reads the data and the query (N-Triples, or Turtle when the name ends in
`.ttl`) and a certificate, verifies the certificate's envelope when it has one, checks the
certificate with `checkRegime`, and reports. It never searches: a certificate is accepted or
rejected, so the verdicts are `proven` (exit 0), `rejected` (exit 2) and `input-error` (exit 3).

The envelope is verified beside the proof, by recomputing the digests of what was read; it can
make a check fail, never pass.
-/

namespace LeanRDF.Check.Cli

open Cert

/-- Command-line arguments. -/
structure Args where
  data : Option System.FilePath := none
  query : Option System.FilePath := none
  cert : Option System.FilePath := none
  regime : Regime := .rdfs
  json : Bool := false
  emitEnvelope : Option System.FilePath := none

/-- The usage text. -/
def usage : String :=
  "usage: leanrdf-check --data DATA --query QUERY --cert CERT.json [--rules simple|rdf|rdfs|owl|el] [--json] [--emit-envelope OUT.json]\n" ++
  "Checks a LeanRDF certificate with the verified checker. DATA and QUERY are N-Triples, or\n" ++
  "Turtle when the name ends in .ttl. Exit codes: 0 proven, 2 certificate rejected, 3 input error."

/-- Read the arguments; `.error` carries the message. -/
def parseArgs : List String → Except String Args :=
  go {}
where
  go (a : Args) : List String → Except String Args
    | [] => .ok a
    | "--data" :: p :: rest => go { a with data := some p } rest
    | "--query" :: p :: rest => go { a with query := some p } rest
    | "--cert" :: p :: rest => go { a with cert := some p } rest
    | "--rules" :: r :: rest =>
      match Regime.ofName? r with
      | some rg => go { a with regime := rg } rest
      | none => .error s!"unknown regime {r}: expected simple, rdf, rdfs, owl or el"
    | "--json" :: rest => go { a with json := true } rest
    | "--emit-envelope" :: p :: rest => go { a with emitEnvelope := some p } rest
    | arg :: _ => .error s!"unexpected argument {arg}"

private def readText (what : String) (path : System.FilePath) : ExceptT String IO String := do
  match ← (IO.FS.readFile path).toBaseIO with
  | .ok s => return s
  | .error e => throw s!"cannot read {what} {path}: {e}"

/-- Read a graph: Turtle for `.ttl`, N-Triples otherwise. -/
def readGraph (what : String) (path : System.FilePath) : ExceptT String IO Graph := do
  let src ← readText what path
  if path.extension == some "ttl" then
    match Turtle.parse src with
    | .ok g => return g
    | .error e => throw s!"{what} {path}: {e}"
  else
    match NTriples.parse src with
    | .ok g => return g
    | .error e => throw s!"{what} {path}:{e}"

private def need {α : Type} (what : String) : Option α → ExceptT String IO α
  | some x => pure x
  | none => throw s!"missing --{what}\n{usage}"

/-- The checker that writes envelopes. -/
def checkerName : String := "leanrdf-check " ++ release

-- @tg: implements:: [[openspec:certificate-check#Certificate check command]]
-- @tg: implements:: [[openspec:certificate-check#Envelope verification]]
/-- Check a certificate and build the report: read, digest, verify the envelope, check, and
write the version-2 certificate when asked. -/
def check (a : Args) : IO Report := do
  let r ← (do
    let g ← readGraph "data" (← need "data" a.data)
    let q ← readGraph "query" (← need "query" a.query)
    let certPath ← need "cert" a.cert
    let c ← match Certificate.parse (← readText "certificate" certPath) with
      | .ok c => pure c
      | .error e => throw s!"certificate {certPath}: {e}"
    let gd ← match g.digest with
      | .ok d => pure d
      | .error e => throw s!"data: {e}"
    let qd ← match q.digest with
      | .ok d => pure d
      | .error e => throw s!"query: {e}"
    return (g, q, c, gd, qd) : ExceptT String IO (Graph × Graph × Certificate × String × String)).run
  match r with
  | .error e => return { verdict := .inputError, regime := some a.regime, reason := some e }
  | .ok (g, q, c, gd, qd) =>
    let base : Report := { verdict := .proven, regime := some a.regime, dataTriples := some g.size,
                           queryTriples := some q.size, nodes := some c.nodes.length, goals := c.goals,
                           graphDigest := some gd, queryDigest := some qd,
                           bound := if c.envelope.isSome then none else some false }
    let base ← match c.envelope with
      | none => pure base
      | some e =>
        match e.verify g q a.regime.rules a.regime.name with
        | .error why => return { base with verdict := .rejected, reason := some why }
        | .ok () => pure { base with bound := some true }
    match checkRegime a.regime g q c with
    | .error e => return { base with verdict := .rejected, reason := some e }
    | .ok () =>
      let accepted := { base with mapping := c.mapping }
      let some out := a.emitEnvelope | return accepted
      let rules : RulesRef := ⟨a.regime.name, rulesDigest a.regime.rules⟩
      let env : Envelope :=
        ⟨gd, qd, rules, a.regime.name, checkerName, LeanRDF.toolchain, a.regime.theoremName⟩
      let c2 := { c with version := 2, envelope := some env }
      match ← (IO.FS.writeFile out (c2.render ++ "\n")).toBaseIO with
      | .ok () => return { accepted with emitted := some out.toString }
      | .error e => return { verdict := .inputError, regime := some a.regime,
                             reason := some s!"cannot write {out}: {e}" }

/-- Run the command: the exit code and the output. -/
def run (args : List String) : IO (UInt32 × String) := do
  if args.isEmpty || args.contains "--help" then return (if args.isEmpty then 3 else 0, usage)
  match parseArgs args with
  | .error e =>
    let r : Report := { verdict := .inputError, reason := some e }
    return (3, if args.contains "--json" then r.toJson.compress else s!"{e}\n{usage}")
  | .ok a =>
    let r ← check a
    return (r.verdict.exitCode, if a.json then r.toJson.compress else r.toText)

end LeanRDF.Check.Cli
