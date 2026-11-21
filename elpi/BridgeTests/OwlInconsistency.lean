import LeanRDFElpi

/-! The W3C OWL 2 inconsistency tests in the fixed-arity fragment
(`BridgeTests/data/owl2-inconsistency`), run at build time: each premise is saturated in Elpi,
the clash search must find a clash, and `checkClash owlRules owlClashRules` must accept it, which
proves by `checkClash_sound_owl` that the premise has no OWL model. The other inconsistency tests
are listed in `index.tsv` with the reason they are not run. -/

namespace LeanRDF.BridgeTests.OwlInconsistency

open LeanRDF Cert Bridge

private def dir : System.FilePath := "BridgeTests/data/owl2-inconsistency"

/-- Run every `inconsistent` line: the count, the clash rules used, and the failures. -/
-- @tg: implements:: [[openspec:inconsistency#Inconsistency test corpus]]
def runSuite : IO (Nat × Nat × List String × Array String) := do
  let mut fails : Array String := #[]
  let mut rulesUsed : List String := []
  let mut (ran, skipped) := (0, 0)
  for line in ← IO.FS.lines (dir / "index.tsv") do
    if line.startsWith "#" || line.isEmpty then continue
    match line.splitOn "\t" with
    | "inconsistent" :: test :: _ =>
      ran := ran + 1
      let g ← match NTriples.parse (← IO.FS.readFile (dir / s!"{test}.nt")) with
        | .ok g => pure g
        | .error e => fails := fails.push s!"{test}: {e}"; continue
      match saturate Owl.owlRules g with
      | .error e => fails := fails.push s!"{test}: search failed: {e}"
      | .ok c =>
        match clashCertificate c Owl.owlClashRules with
        | .ok (some cert) =>
          match checkClash Owl.owlRules Owl.owlClashRules g cert with
          | .ok () =>
            let r := (cert.clash.map (·.rule)).getD ""
            unless rulesUsed.contains r do rulesUsed := rulesUsed ++ [r]
          | .error e => fails := fails.push s!"{test}: clash certificate rejected: {e}"
        | .ok none => fails := fails.push s!"{test}: no clash found"
        | .error e => fails := fails.push s!"{test}: {e}"
    | "skipped" :: _ => skipped := skipped + 1
    | _ => fails := fails.push s!"bad line: {line}"
  return (ran, skipped, rulesUsed.mergeSort (· ≤ ·), fails)

-- @tg: verifies:: [[openspec:inconsistency#Inconsistency test corpus#W3C inconsistency cases in the fragment]] {level: integration}
/--
info: (27, 101,
  ["cax-dw", "cls-com", "cls-maxc1", "cls-maxqc1", "cls-nothing2", "eq-diff1", "prp-asyp", "prp-irp", "prp-npa1",
    "prp-npa2", "prp-pdw"])
-/
#guard_msgs in
#eval show IO _ from do
  let (ran, skipped, rules, fails) ← runSuite
  unless fails.isEmpty do throw (IO.userError ("\n".intercalate fails.toList))
  return (ran, skipped, rules)

end LeanRDF.BridgeTests.OwlInconsistency
