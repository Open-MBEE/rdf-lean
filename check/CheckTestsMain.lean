import LeanRDFCheck
import CheckTests
import Lean.Data.Json

/-! `lake test` for `leanrdf-check`: the recorded certificate corpus and the JSON verdicts, run
through the command line. The build-time scenarios are in `CheckTests/`. -/

open LeanRDF.Check Lean

def dataDir : System.FilePath := "CheckTests/data"

-- @tg: implements:: [[openspec:certificate-check#Certificate corpus]]
-- @tg: verifies:: [[openspec:certificate-check#Certificate corpus#The corpus passes]] {level: integration}
/-- Run every corpus line; return the failures and the count per regime. -/
def runCorpus : IO (List String × List (String × Nat)) := do
  let lines := (← IO.FS.readFile (dataDir / "corpus.tsv")).splitOn "\n"
    |>.filter (fun l => !l.isEmpty && !l.startsWith "#")
  let mut fails := []
  let mut counts : List (String × Nat) := []
  for l in lines do
    match l.splitOn "\t" with
    | [r, d, q, c, e] =>
      let (code, out) ← Cli.run ["--rules", r, "--data", (dataDir / d).toString,
        "--query", (dataDir / q).toString, "--cert", (dataDir / c).toString]
      if code.toNat.repr != e then fails := fails ++ [s!"{l}: exit {code}\n{out}"]
      counts := match counts.find? (·.1 == r) with
        | some _ => counts.map fun (k, n) => if k == r then (k, n + 1) else (k, n)
        | none => counts ++ [(r, 1)]
    | _ => fails := fails ++ [s!"bad corpus line: {l}"]
  return (fails, counts)

def jsonField (out : String) (k : String) : Option Json :=
  (Json.parse out).toOption.bind (·.getObjVal? k |>.toOption)

-- @tg: verifies:: [[openspec:certificate-check#Certificate check command#A demo certificate is accepted]] {level: e2e}
-- @tg: verifies:: [[openspec:certificate-check#JSON verdict#A proven verdict as JSON]] {level: integration}
def provenJson : IO (List String) := do
  let (code, out) ← Cli.run ["--data", (dataDir / "pets.nt").toString, "--query",
    (dataDir / "query-mammal-owner.nt").toString, "--cert", (dataDir / "pets-mammal-owner.json").toString, "--json"]
  let ok := code == 0 && jsonField out "verdict" == some (.str "proven") &&
    jsonField out "theorem" == some (.str "checkQuery_sound") && jsonField out "regime" == some (.str "rdfs") &&
    (jsonField out "mapping").bind (·.getObjVal? "_:pet" |>.toOption) == some (.str "<http://example.org/tom>") &&
    (jsonField out "mapping").bind (·.getObjVal? "_:owner" |>.toOption) == some (.str "<http://example.org/bob>")
  return if ok then [] else [s!"proven JSON verdict: {out}"]

-- @tg: verifies:: [[openspec:certificate-check#Certificate check command#A tampered certificate is rejected]] {level: e2e}
-- @tg: verifies:: [[openspec:certificate-check#JSON verdict#A rejected verdict as JSON]] {level: integration}
def rejectedJson : IO (List String) := do
  let (code, out) ← Cli.run ["--data", (dataDir / "pets.nt").toString, "--query",
    (dataDir / "query-mammal-owner.nt").toString, "--cert",
    (dataDir / "pets-mammal-owner-swapped.json").toString, "--json"]
  let reason := (jsonField out "reason").bind (·.getStr? |>.toOption)
  let ok := code == 2 && jsonField out "verdict" == some (.str "rejected") &&
    jsonField out "exit" == some (toJson 2) && reason.any (!·.isEmpty)
  return if ok then [] else [s!"rejected JSON verdict: {out}"]

-- @tg: verifies:: [[openspec:certificate-check#Certificate check command#Bad input exits 3]] {level: integration}
def badInput : IO (List String) := do
  let mut fails := []
  for args in [["--rules", "owl2", "--data", "x", "--query", "y", "--cert", "z"],
               ["--data", (dataDir / "simple.nt").toString, "--query", (dataDir / "simple-query.nt").toString],
               ["--data", (dataDir / "simple.nt").toString, "--query", (dataDir / "simple-query.nt").toString,
                "--cert", (dataDir / "bad-version.json").toString, "--json"]] do
    let (code, out) ← Cli.run args
    if code != 3 then fails := fails ++ [s!"{args}: exit {code}\n{out}"]
  return fails

private def args (data cert : String) (extra : List String := []) : List String :=
  ["--data", (dataDir / data).toString, "--query", (dataDir / "query-mammal-owner.nt").toString,
   "--cert", (dataDir / cert).toString, "--json"] ++ extra

private def envelopeGraph (cert : String) : IO (Option Json) := do
  let j := (Json.parse (← IO.FS.readFile (dataDir / cert))).toOption
  return j.bind fun j => (j.getObjVal? "envelope" >>= (·.getObjVal? "graph")).toOption

-- @tg: verifies:: [[openspec:certificate-check#Envelope verification#A bound certificate is accepted]] {level: e2e}
def boundAccepted : IO (List String) := do
  let (code, out) ← Cli.run (args "pets-bnode-relabeled.nt" "pets-bnode-mammal-owner.json")
  let ok := code == 0 && jsonField out "bound" == some (.bool true) &&
    jsonField out "graph" == (← envelopeGraph "pets-bnode-mammal-owner.json") &&
    (jsonField out "graph").isSome
  return if ok then [] else [s!"bound certificate on relabeled data: {out}"]

-- @tg: verifies:: [[openspec:certificate-check#Envelope verification#A certificate checked against other data is rejected]] {level: e2e}
def otherDataRejected : IO (List String) := do
  let (code, out) ← Cli.run (args "pets-extended.nt" "pets-mammal-owner.json")
  let (code1, _) ← Cli.run (args "pets-extended.nt" "pets-mammal-owner-v1.json")
  let ok := code == 2 && code1 == 0 &&
    jsonField out "reason" == some (.str "envelope: graph digest mismatch")
  return if ok then [] else [s!"bound certificate on extended data: {out}"]

-- @tg: verifies:: [[openspec:certificate-check#Envelope verification#Version 1 is upgraded]] {level: e2e}
def upgraded : IO (List String) := do
  let out2 : System.FilePath := ".lake/upgraded.json"
  IO.FS.createDirAll ".lake"
  let (code, out) ← Cli.run (args "pets.nt" "pets-mammal-owner-v1.json" ["--emit-envelope", out2.toString])
  let (code2, again) ← Cli.run ["--data", (dataDir / "pets.nt").toString, "--query",
    (dataDir / "query-mammal-owner.nt").toString, "--cert", out2.toString, "--json"]
  let v2 := (Json.parse (← IO.FS.readFile out2)).toOption.bind (·.getObjVal? "version" |>.toOption)
  let ok := code == 0 && jsonField out "bound" == some (.bool false) && code2 == 0 &&
    jsonField again "bound" == some (.bool true) && v2 == some (toJson 2)
  return if ok then [] else [s!"version-1 upgrade: {out}\n{again}"]

def main : IO UInt32 := do
  let (fails, counts) ← runCorpus
  let fails := fails ++ (← provenJson) ++ (← rejectedJson) ++ (← badInput) ++
    (← boundAccepted) ++ (← otherDataRejected) ++ (← upgraded)
  for f in fails do IO.eprintln s!"FAIL {f}"
  IO.println s!"certificate corpus: {", ".intercalate (counts.map fun (r, n) => s!"{r} {n}")}"
  IO.println (if fails.isEmpty then "leanrdf-check tests: ok" else s!"leanrdf-check tests: {fails.length} failure(s)")
  return if fails.isEmpty then 0 else 1
