import LeanRDF

/-! Scenarios of `certificates#Certificate format` for version 2: the envelope round-trips,
version 1 still reads, and the checker's verdict does not depend on the envelope. -/

namespace LeanRDF.Tests.CertEnvelope

open Vocab LeanRDF.Cert RDFS

private def ex (n : String) : Term := .iri ⟨"http://example.org/" ++ n⟩
private def T (s p o : Term) : Triple := ⟨s, p, o⟩
private def sc : Term := .iri rdfs.subClassOf
private def ty : Term := .iri rdf.type

private def g : Graph :=
  Graph.ofList [T (ex "A") sc (ex "B"), T (ex "x") ty (ex "A")]
private def q : Graph := Graph.ofList [T (.bnode ⟨"who"⟩) ty (ex "B")]

private def v1 : Certificate :=
  { nodes := [ ⟨0, T (ex "A") sc (ex "B"), "fact", []⟩, ⟨1, T (ex "x") ty (ex "A"), "fact", []⟩,
               ⟨2, T (ex "x") ty (ex "B"), "rdfs9", [0, 1]⟩ ]
    goals := [2], mapping := [(⟨"who"⟩, ex "x")] }

private def env : Envelope :=
  match Envelope.build g q "rdfs" rdfsRules "rdfs" "checkQuery_sound" s!"leanrdf {release}" with
  | .ok e => e
  | .error _ => default

private def v2 : Certificate := { v1 with version := 2, envelope := some env }

-- @tg: verifies:: [[openspec:certificates#Certificate format#Version 2 round-trips]] {level: unit}
#guard (Certificate.parse v2.render).toOption == some v2
#guard (Certificate.parse v1.render).toOption == some v1
#guard ((Certificate.parse v1.render).toOption.map (·.envelope.isNone)) == some true
#guard env.graph.startsWith "sha256:" && env.query.startsWith "sha256:" && env.rules.digest.startsWith "sha256:"
#guard (Certificate.parse "{\"version\": 3, \"nodes\": [], \"goals\": []}").toOption.isNone
#guard (Certificate.parse "{\"version\": 2, \"nodes\": [], \"goals\": []}").toOption.isNone

-- @tg: verifies:: [[openspec:certificates#Certificate format#The envelope does not change the checker's verdict]] {level: unit}
private def wrong : Certificate :=
  { v1 with version := 2, envelope := some { env with graph := "sha256:00", query := "sha256:00" } }
#guard (checkQuery rdfsRules g q v1).toBool && (checkQuery rdfsRules g q wrong).toBool
#guard (env.verify g q rdfsRules "rdfs").toBool
#guard (match (wrong.envelope.getD env).verify g q rdfsRules "rdfs" with
  | .error e => e == "envelope: graph digest mismatch" | .ok _ => false)

/- The rules digest changes with any rule and with the order. -/
#guard rulesDigest rdfsRules != rulesDigest rdfsRules.reverse
#guard rulesDigest rdfsRules != rulesDigest (rdfsRules.take (rdfsRules.length - 1))
#guard rulesDigest rdfsRules == rulesDigest rdfsRules

end LeanRDF.Tests.CertEnvelope
