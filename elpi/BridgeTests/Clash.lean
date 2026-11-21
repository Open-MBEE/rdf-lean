import LeanRDFElpi

/-! Scenarios of `inconsistency` in the bridge: the clash search on Elpi closures, and the
INCONSISTENT verdict of `leanrdf-demo`, `leanrdf-oxilite` and `leanrdf-classify`. -/

namespace LeanRDF.BridgeTests.Clash

open LeanRDF Cert Bridge

private def expect (cond : Bool) (msg : String) : IO Unit := unless cond do throw (IO.userError msg)
private def contains (s sub : String) : Bool := (s.splitOn sub).length > 1
private def dir : System.FilePath := "BridgeTests/data/clash"
private def ex (n : String) : Term := .iri ⟨"http://example.org/" ++ n⟩

private def readNT (p : System.FilePath) : IO Graph := do
  IO.ofExcept ((NTriples.parse (← IO.FS.readFile p)).mapError toString)

-- @tg: verifies:: [[openspec:inconsistency#Clash search#A derived clash is found]] {level: integration}
#eval show IO Unit from do
  let g ← readNT (dir / "cats.nt")
  let c ← IO.ofExcept (saturate Owl.owlRules g)
  let some cert ← IO.ofExcept (clashCertificate c Owl.owlClashRules)
    | throw (IO.userError "no clash found")
  expect ((cert.clash.map (·.rule)) == some "cax-dw") s!"{repr cert.clash}"
  expect (cert.nodes.any fun n => n.rule == "rdfs9" &&
    n.conclusion == ⟨ex "tom", .iri Vocab.rdf.type, ex "Cat"⟩) "no rdfs9 node for tom a Cat"
  expect (checkClash Owl.owlRules Owl.owlClashRules g cert).toBool "the checker rejects the clash"

-- @tg: verifies:: [[openspec:inconsistency#Clash search#A consistent graph gives no clash]] {level: integration}
#eval show IO Unit from do
  let g ← readNT "examples/pets.nt"
  let c ← IO.ofExcept (saturate Owl.owlRules g)
  let r ← IO.ofExcept (clashCertificate c Owl.owlClashRules)
  expect r.isNone "a clash was found in the pets graph"

-- @tg: verifies:: [[openspec:inconsistency#Inconsistent verdict#The demo reports an inconsistent graph]] {level: e2e}
#eval show IO Unit from do
  let (code, out) ← Demo.run { data := dir / "cats.nt", query := dir / "query-tom-fish.nt", profile := .owl }
  expect (code == 4) s!"exit {code}\n{out}"
  expect (contains out "Verdict: INCONSISTENT" && contains out "cax-dw") out
  expect (!contains out "ENTAILED") out
  -- under RDFS, owl:disjointWith means nothing: the graph has an RDFS model, and a checked
  -- countermodel refutes the fish query there
  let (code, out) ← Demo.run { data := dir / "cats.nt", query := dir / "query-tom-fish.nt" }
  expect (code == 5 && contains out "REFUTED") s!"rdfs profile: exit {code}\n{out}"

/- The datatype clash, found under the RDFS profile. -/
#eval show IO Unit from do
  let (code, out) ← Demo.run { data := dir / "bad-string.nt", query := dir / "query-tom-fish.nt" }
  expect (code == 4 && contains out "d-clash-string" && contains out "checkClash_sound_rdfs") s!"exit {code}\n{out}"

-- @tg: verifies:: [[openspec:inconsistency#Inconsistent verdict#oxilite's answers on an inconsistent graph are not certified]] {level: e2e}
#eval show IO Unit from do
  let d : System.FilePath := "BridgeTests/data/oxilite/inconsistent"
  let a : Oxilite.Args := { data := d / "data.ttl", pattern := d / "pattern.ttl", profile := .owl,
                            results := some (d / "results.json"), mode := .search }
  let (code, out) ← Oxilite.run Owl.owlRules a
  expect (code == 4) s!"exit {code}\n{out}"
  expect (contains out "INCONSISTENT" && contains out "None of oxilite's answers is certified") out
  expect (!contains out "CERTIFIED\n") out

/- The classifier reports an inconsistent ontology before any hierarchy. -/
#eval show IO Unit from do
  let (code, out) ← Classify.run (dir / "cats.nt")
  expect (code == 4 && contains out "INCONSISTENT" && contains out "checkClash_sound_el") s!"exit {code}\n{out}"

end LeanRDF.BridgeTests.Clash
