import Lean.Data.Json
import LeanRDF.Model.Check
import LeanRDF.Cert.Json

/-!
# Countermodel JSON

A countermodel as JSON, terms in RDF 1.2 N-Triples syntax:

```json
{"kind": "countermodel", "regime": "rdfs",
 "sorts": [{"kind": "base", "ir": true, "ip": false}, …],
 "iris": [["<http://example.org/tom>", 3], …], "defaultIri": 0, "defaultCmp": 1,
 "literals": {"string": 4, "lang": 5, "dirLang": 6, "other": 7},
 "overrides": [["\"Tom\"", 8], …], "tripleSort": 9,
 "ext": [[2, 3, 10], …], "assign": [["_:b0", 11], …],
 "envelope": { … }}
```

The optional `envelope` is the envelope of version-2 certificates: it binds the countermodel to
the digests of its data and query. Reading is untrusted: malformed JSON is an error, and a wrong
model fails `checkCountermodel`.
-/

namespace LeanRDF.Model

open Lean (Json)

/-- A countermodel as it travels: the regime, the presentation, and an optional envelope. -/
structure Countermodel where
  regime : CRegime
  model : Presentation
  envelope : Option Cert.Envelope := none
  deriving Repr, BEq, Inhabited

private def termJson (t : Term) : Json := Json.str t.toNTriples

-- @tg: implements:: [[openspec:countermodels#Countermodel format]]
/-- A countermodel as JSON. -/
def Countermodel.toJson (c : Countermodel) : Json :=
  let P := c.model
  let sorts := (List.range P.n).map fun k =>
    Json.mkObj [("kind", Json.str (P.kind k).name), ("ir", Json.bool (P.irB k)), ("ip", Json.bool (P.ipB k))]
  Json.mkObj <|
    [("kind", Json.str "countermodel"), ("regime", Json.str c.regime.name),
     ("sorts", Json.arr sorts.toArray),
     ("iris", Json.arr (P.iris.toArray.map fun (i, k) => Json.arr #[termJson (.iri i), Lean.toJson k])),
     ("defaultIri", Lean.toJson P.defaultIri), ("defaultCmp", Lean.toJson P.defaultCmp),
     ("literals", Json.mkObj [("string", Lean.toJson P.strSort), ("lang", Lean.toJson P.langSort),
       ("dirLang", Lean.toJson P.dirSort), ("other", Lean.toJson P.otherSort)]),
     ("overrides", Json.arr (P.overrides.toArray.map fun (l, k) => Json.arr #[termJson (.lit l), Lean.toJson k])),
     ("tripleSort", Lean.toJson P.tripleSort),
     ("ext", Json.arr (P.ext.toArray.map fun (a, b, c) => Lean.toJson [a, b, c])),
     ("assign", Json.arr (P.assign.toArray.map fun (b, k) => Json.arr #[termJson (.bnode b), Lean.toJson k]))]
    ++ (match c.envelope with | some e => [("envelope", e.toJson)] | none => [])

/-- A countermodel as indented JSON text. -/
def Countermodel.render (c : Countermodel) : String := c.toJson.pretty

private def natOf (j : Json) (k : String) : Except String Nat := do (← j.getObjVal? k).getNat?

private def termOf (j : Json) : Except String Term := do
  (NTriples.parseTerm (← j.getStr?)).mapError toString

private def pairOf {α : Type} (f : Term → Except String α) (j : Json) : Except String (α × Nat) := do
  match (← j.getArr?).toList with
  | [t, k] => return (← f (← termOf t), ← k.getNat?)
  | _ => throw "expected a pair [term, sort]"

/-- Read a countermodel from JSON. -/
def Countermodel.ofJson (j : Json) : Except String Countermodel := do
  unless (j.getObjValAs? String "kind").toOption == some "countermodel" do
    throw "not a countermodel: \"kind\" must be \"countermodel\""
  let regime ← match CRegime.ofName? (← (← j.getObjVal? "regime").getStr?) with
    | some r => pure r
    | none => throw "the regime must be simple, rdf or rdfs"
  let sorts ← (← (← j.getObjVal? "sorts").getArr?).toList.mapM fun s => do
    let kind ← match SortKind.ofName? (← (← s.getObjVal? "kind").getStr?) with
      | some k => pure k
      | none => throw "unknown sort kind"
    return (kind, ← (← s.getObjVal? "ir").getBool?, ← (← s.getObjVal? "ip").getBool?)
  let iris ← (← (← j.getObjVal? "iris").getArr?).toList.mapM (pairOf fun
    | .iri i => pure i
    | _ => throw "an IRI table entry must be an IRI")
  let lits ← j.getObjVal? "literals"
  let overrides ← (← (← j.getObjVal? "overrides").getArr?).toList.mapM (pairOf fun
    | .lit l => pure l
    | _ => throw "an override must be a literal")
  let ext ← (← (← j.getObjVal? "ext").getArr?).toList.mapM fun e => do
    match (← e.getArr?).toList with
    | [a, b, c] => return (← a.getNat?, ← b.getNat?, ← c.getNat?)
    | _ => throw "an IEXT entry must be [p, s, o]"
  let assign ← (← (← j.getObjVal? "assign").getArr?).toList.mapM (pairOf fun
    | .bnode b => pure b
    | _ => throw "an assignment must be a blank node")
  let envelope ← match j.getObjVal? "envelope" with
    | .ok e => some <$> Cert.Envelope.ofJson e
    | .error _ => pure none
  return { regime, envelope, model := {
    kinds := (sorts.map (·.1)).toArray, ir := (sorts.map (·.2.1)).toArray,
    ip := (sorts.map (·.2.2)).toArray, iris, defaultIri := ← natOf j "defaultIri",
    defaultCmp := ← natOf j "defaultCmp", strSort := ← natOf lits "string",
    langSort := ← natOf lits "lang", dirSort := ← natOf lits "dirLang",
    otherSort := ← natOf lits "other", overrides, tripleSort := ← natOf j "tripleSort",
    ext, assign } }

/-- Parse a countermodel from JSON text. -/
def Countermodel.parse (s : String) : Except String Countermodel := do
  Countermodel.ofJson (← Json.parse s)

end LeanRDF.Model
