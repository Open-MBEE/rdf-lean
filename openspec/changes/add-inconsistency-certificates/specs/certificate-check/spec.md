## ADDED Requirements

### Requirement: Clash certificate checking
`leanrdf-check` SHALL accept clash certificates: given `--rules owl` or `--rules rdfs` and a certificate with a `clash` member, it SHALL run `checkClash` with the matching rule list and clash rule list, verify the envelope as for any certificate, and name `checkClash_sound_owl` or `checkClash_sound_rdfs` as the theorem the check stands for. An accepted clash certificate SHALL exit 4 with verdict `inconsistent`, and a rejected one SHALL exit 2 with verdict `rejected`. A clash certificate given with `--query` SHALL be an input error (exit 3).

#### Scenario: A clash certificate is verified
- **WHEN** `leanrdf-check --data cats.nt --rules owl --cert clash.json` runs on the cat-and-dog graph and the certificate written by `leanrdf-demo --profile owl --cert clash.json`
- **THEN** it prints `INCONSISTENT`, names `checkClash_sound_owl`, and exits 4

#### Scenario: A tampered clash certificate is rejected
- **WHEN** the same certificate is checked after its `clash` premises are reordered
- **THEN** `leanrdf-check` exits 2 with verdict `rejected`

#### Scenario: JSON verdict for a clash
- **WHEN** the verified clash certificate is checked with `--json`
- **THEN** the output has `"verdict": "inconsistent"`, `"exit": 4` and `"theorem": "checkClash_sound_owl"`
