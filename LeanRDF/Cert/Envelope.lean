import LeanRDF.Entailment.Rule
import LeanRDF.Canon.Digest

/-!
# Certificate envelopes

A version-2 certificate carries an envelope: what the certificate is about and what it was
checked under. The envelope is untrusted metadata. `checkQuery` never reads it, and its
soundness theorem is unchanged. A checker verifies the envelope beside the proof, by
recomputing the digests from the files it read. A wrong envelope can therefore make a check
fail, never pass.

- `graph`, `query`: the digests (`Graph.digest`) of the data and the query;
- `rules`: a rule set's name and the digest of its canonical rendering (`rulesDigest`);
- `regime`, `theorem`: the entailment regime and the theorem an acceptance stands for;
- `checker`, `toolchain`: the package and version that wrote the certificate, and the Lean
  toolchain.
-/

namespace LeanRDF

/-- The release of the LeanRDF packages, as written in envelopes. `scripts/check_release.py`
checks it against the lakefiles. -/
def release : String := "0.5.0"

/-- The Lean toolchain, as written in envelopes. -/
def toolchain : String := "leanprover/lean4:v" ++ Lean.versionString

/-! ## The canonical rendering of rules -/

/-- A pattern: variables as `?name`, constants in N-Triples syntax. -/
def Pat.render : Pat → String
  | .var n => "?" ++ n
  | .const t => t.toNTriples
  | .triple s p o => "<<( " ++ s.render ++ " " ++ p.render ++ " " ++ o.render ++ " )>>"

/-- A triple pattern. -/
def TPat.render (t : TPat) : String := t.s.render ++ " " ++ t.p.render ++ " " ++ t.o.render

/-- A guard. -/
def Guard.render : Guard → String
  | .containerMembership v => "containerMembership(?" ++ v ++ ")"
  | .stringLiteral v => "stringLiteral(?" ++ v ++ ")"
  | .langLiteral v => "langLiteral(?" ++ v ++ ")"
  | .dirLangLiteral v => "dirLangLiteral(?" ++ v ++ ")"
  | .illTypedString v => "illTypedString(?" ++ v ++ ")"

/-- A rule as one line: name, body patterns, head, guards. -/
def Rule.render (r : Rule) : String :=
  r.name ++ ": " ++ " , ".intercalate (r.body.map TPat.render) ++ " => " ++ r.head.render ++
    (if r.guards.isEmpty then "" else " | " ++ " , ".intercalate (r.guards.map Guard.render)) ++ "\n"

/-- The digest of a rule list: SHA-256 of one line per rule, in list order. Any change to a
rule, or to the order, changes it. -/
def rulesDigest (rs : List Rule) : String :=
  "sha256:" ++ Hash.sha256 (String.join (rs.map Rule.render))

namespace Cert

/-- A rule set named in an envelope. -/
structure RulesRef where
  id : String
  digest : String
  deriving Repr, BEq, DecidableEq, Inhabited

-- @tg: implements:: [[openspec:certificates#Certificate format]] {since: "0.4.0"}
/-- The envelope of a version-2 certificate. -/
structure Envelope where
  graph : String
  query : String
  rules : RulesRef
  regime : String
  checker : String
  toolchain : String
  thm : String
  deriving Repr, BEq, DecidableEq, Inhabited

/-- Fill an envelope from the data, the query and the rules a certificate was checked under. -/
def Envelope.build (g q : Graph) (rulesId : String) (rules : List Rule)
    (regime thm checker : String) : Except String Envelope := do
  return { graph := ← g.digest, query := ← q.digest,
           rules := { id := rulesId, digest := rulesDigest rules },
           regime, checker, toolchain := LeanRDF.toolchain, thm }

/-- Verify an envelope against what a checker read: the first field that does not match, as
the reason of a rejection. -/
def Envelope.verify (e : Envelope) (g q : Graph) (rules : List Rule) (regime : String) :
    Except String Unit := do
  unless e.regime == regime do throw "envelope: regime mismatch"
  unless e.graph == (← g.digest) do throw "envelope: graph digest mismatch"
  unless e.query == (← q.digest) do throw "envelope: query digest mismatch"
  unless e.rules.digest == rulesDigest rules do throw "envelope: rules digest mismatch"

end Cert

end LeanRDF
