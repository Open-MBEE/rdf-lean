import LeanRDFOwl.Semantics

/-!
# The OWL 2 RL clash rules

The OWL 2 RL/RDF rules of OWL 2 Profiles §4.3 (Tables 4 to 6) whose conclusion is `false` and
whose number of premises is fixed, as `ClashRule` values, each body in the specification's
order. Not included: `eq-diff2`, `eq-diff3`, `prp-adp` and `cax-adc`, which read an `rdf:List`,
and `dt-not-type`, which needs the value spaces of the OWL 2 datatypes.
-- SIMPLIFICATION: [[simplifications#OWL 2 RL without list rules]]
-/

namespace LeanRDF.Owl

open Vocab

private def v (n : String) : Pat := .var n
private def c (i : IRI) : Pat := .const (.iri i)
private def ty : Pat := c rdf.type
private def T (s p o : Pat) : TPat := ⟨s, p, o⟩
private def K (name : String) (body : List TPat) : ClashRule := { name, body }

/-! ## Equality (Table 4) -/

def eqDiff1 := K "eq-diff1" [T (v "x") (c sameAs) (v "y"), T (v "x") (c differentFrom) (v "y")]

/-! ## Properties (Table 5) -/

def prpIrp := K "prp-irp" [T (v "p") ty (c IrreflexiveProperty), T (v "x") (v "p") (v "x")]
def prpAsyp := K "prp-asyp" [T (v "p") ty (c AsymmetricProperty), T (v "x") (v "p") (v "y"),
  T (v "y") (v "p") (v "x")]
def prpPdw := K "prp-pdw" [T (v "p1") (c propertyDisjointWith) (v "p2"), T (v "x") (v "p1") (v "y"),
  T (v "x") (v "p2") (v "y")]
def prpNpa1 := K "prp-npa1" [T (v "x") (c sourceIndividual) (v "i1"),
  T (v "x") (c assertionProperty) (v "p"), T (v "x") (c targetIndividual) (v "i2"),
  T (v "i1") (v "p") (v "i2")]
def prpNpa2 := K "prp-npa2" [T (v "x") (c sourceIndividual) (v "i"),
  T (v "x") (c assertionProperty) (v "p"), T (v "x") (c targetValue) (v "lt"),
  T (v "i") (v "p") (v "lt")]

/-! ## Classes (Table 6) -/

def clsNothing2 := K "cls-nothing2" [T (v "x") ty (c Nothing)]
def clsCom := K "cls-com" [T (v "c1") (c complementOf) (v "c2"), T (v "x") ty (v "c1"),
  T (v "x") ty (v "c2")]
def clsMaxc1 := K "cls-maxc1" [T (v "x") (c maxCardinality) (.const (.lit zero)),
  T (v "x") (c onProperty) (v "p"), T (v "u") ty (v "x"), T (v "u") (v "p") (v "y")]
def clsMaxqc1 := K "cls-maxqc1" [T (v "x") (c maxQualifiedCardinality) (.const (.lit zero)),
  T (v "x") (c onProperty) (v "p"), T (v "x") (c onClass) (v "c"), T (v "u") ty (v "x"),
  T (v "u") (v "p") (v "y"), T (v "y") ty (v "c")]
def clsMaxqc2 := K "cls-maxqc2" [T (v "x") (c maxQualifiedCardinality) (.const (.lit zero)),
  T (v "x") (c onProperty) (v "p"), T (v "x") (c onClass) (c Thing), T (v "u") ty (v "x"),
  T (v "u") (v "p") (v "y")]

/-! ## Class axioms (Table 7) -/

def caxDw := K "cax-dw" [T (v "c1") (c disjointWith) (v "c2"), T (v "x") ty (v "c1"),
  T (v "x") ty (v "c2")]

-- @tg: implements:: [[openspec:owl-rl#OWL 2 RL clash rules]]
/-- The twelve fixed-arity OWL 2 RL rules with conclusion `false`. -/
def owlClashRules : List ClashRule :=
  [eqDiff1, prpIrp, prpAsyp, prpPdw, prpNpa1, prpNpa2, clsNothing2, clsCom, clsMaxc1, clsMaxqc1,
   clsMaxqc2, caxDw]

end LeanRDF.Owl
