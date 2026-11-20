# Checking a certificate

`leanrdf-check` checks a certificate that some other tool wrote. It runs the verified checker and nothing that searches. Here the certificate comes from `leanrdf-demo` on the university example:

```bash
leanrdf-demo university.nt query-kurt-person.nt --cert kurt-person.json   # untrusted: finds
leanrdf-check --data university.nt --query query-kurt-person.nt --cert kurt-person.json   # trusted: checks
```

The demo writes a version-2 certificate. Its envelope names the digests of the data and the query (RDFC-1.0 canonical N-Quads, SHA-256), the rule set and the regime. `leanrdf-check` recomputes the digests from the files it reads before it checks the proof.

- `proven`: the envelope matches and the certificate is accepted under `rdfs`, so by `checkQuery_sound` the data RDFS-entails the query. Exit 0.
- `tampered`: the same certificate with the premises of its last `rdfs9` step swapped is rejected. Exit 2.
- `json`: the proven verdict as one JSON object, with the digests, for agents.
- `other-data`: the certificate checked against `university-extended.nt`, the data with one unrelated triple added, is rejected with `envelope: graph digest mismatch`. The proof itself would still pass, but the certificate was not written for that data. Exit 2.

Agent B can check agent A's conclusion this way without redoing A's search and without trusting A.
