import LeanRDFCheck.Cli

/-! `lake exe leanrdf-check`: see `LeanRDFCheck.Cli`. -/

def main (args : List String) : IO UInt32 := do
  let (code, out) ← LeanRDF.Check.Cli.run args
  if code == 3 && !args.contains "--json" then IO.eprintln out else IO.println out
  return code
