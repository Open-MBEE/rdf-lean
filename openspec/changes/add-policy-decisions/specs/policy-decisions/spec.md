## ADDED Requirements

### Requirement: Policy vocabulary
The vocabulary SHALL be in the namespace `https://volland.github.io/rdf-lean/ns/policy#` (`pol:`). It SHALL define the rule classes `pol:Permission` and `pol:Prohibition`, the properties `pol:assignee`, `pol:action`, `pol:target` and `pol:purpose`, each of whose values is a class, and the class `pol:AnyPurpose`. The vocabulary SHALL be published as a Turtle file in the package and in the example.

#### Scenario: A permission in the vocabulary
- **WHEN** `ex:p1 a pol:Permission ; pol:assignee ex:Staff ; pol:action ex:Read ; pol:target ex:DesignDoc ; pol:purpose pol:AnyPurpose .` is read
- **THEN** it is one permission rule with those four classes

### Requirement: Well-formed policies
A policy base SHALL be validated with the proven SHACL validator against the package's policy shapes before any decision. The shapes require that every `pol:Permission` and `pol:Prohibition` has exactly one IRI value for each of `pol:assignee`, `pol:action`, `pol:target` and `pol:purpose`, and that no `pol:` property is the subject of `rdfs:subPropertyOf`. A non-conforming base SHALL be an input error that carries the SHACL report.

#### Scenario: A rule with two targets is rejected
- **WHEN** a permission has `pol:target ex:DesignDoc, ex:Payroll`
- **THEN** `leanrdf-policy` exits 3 and reports a `sh:MaxCountConstraintComponent` result for that rule

### Requirement: Requests and decision graphs
A request SHALL be an agent, an action, a target and a purpose, each an IRI. Its decision graph SHALL be the union of the policy base, the data and the triple `purpose rdf:type pol:AnyPurpose`.

#### Scenario: The decision graph types the purpose
- **WHEN** the request `(ex:ada, ex:read, ex:spec42, ex:review)` is built over a policy base and data
- **THEN** its decision graph contains `ex:review rdf:type pol:AnyPurpose`

### Requirement: Match patterns
For a rule kind `K` and a request `(a, x, t, u)`, the match pattern SHALL be the query graph `_:r rdf:type K . _:r pol:assignee _:ca . a rdf:type _:ca . _:r pol:action _:cx . x rdf:type _:cx . _:r pol:target _:ct . t rdf:type _:ct . _:r pol:purpose _:cu . u rdf:type _:cu .` A rule of kind `K` SHALL be said to apply to the request exactly when the decision graph RDFS-entails the pattern.

#### Scenario: A permission applies through a class hierarchy
- **WHEN** the data has `ex:ada rdf:type ex:Lecturer`, `ex:Lecturer rdfs:subClassOf ex:Staff`, `ex:read rdf:type ex:Read` and `ex:spec42 rdf:type ex:DesignDoc`, and the policy base has the permission above
- **THEN** an Elpi certificate for the permission pattern of `(ex:ada, ex:read, ex:spec42, ex:review)` is accepted by `checkQuery rdfsRules`

### Requirement: Decision function
`decide` SHALL return:
- `inconsistent` when a supplied clash certificate is accepted on the decision graph;
- otherwise `deny` when a supplied certificate for the prohibition pattern is accepted;
- otherwise `permit` when a supplied certificate for the permission pattern is accepted and a supplied countermodel for the prohibition pattern is accepted;
- otherwise `notDecided`, with the reason for each missing or rejected piece of evidence.

#### Scenario: Permit with a countermodel
- **WHEN** the request above is decided with the permission certificate and a countermodel for the prohibition pattern
- **THEN** `decide` returns `permit`

#### Scenario: Prohibition overrides permission
- **WHEN** the policy base also has `ex:n1 a pol:Prohibition ; pol:assignee ex:Contractor ; pol:action ex:Read ; pol:target ex:DesignDoc ; pol:purpose pol:AnyPurpose`, `ex:ada` is also an `ex:Contractor`, and a prohibition certificate and the permission certificate are both supplied
- **THEN** `decide` returns `deny`

#### Scenario: Missing absence evidence is not a permit
- **WHEN** only the permission certificate is supplied
- **THEN** `decide` returns `notDecided` with the reason `no countermodel for the prohibition pattern`

### Requirement: Decision soundness
`decide_permit_sound` SHALL prove that `permit` implies that the decision graph RDFS-entails the permission pattern and does not RDFS-entail the prohibition pattern. `decide_deny_sound` SHALL prove that `deny` implies that the decision graph RDFS-entails the prohibition pattern. `permit_consistent` SHALL prove that `permit` implies that the decision graph has an RDFS model. `decide_inconsistent_sound` SHALL prove that `inconsistent` implies that it has none. The theorems SHALL use no axiom beyond `propext`, `Classical.choice` and `Quot.sound`.

#### Scenario: Decision theorems are axiom-clean
- **WHEN** the axioms of `decide_permit_sound`, `decide_deny_sound`, `permit_consistent` and `decide_inconsistent_sound` are printed
- **THEN** they are among `propext`, `Classical.choice` and `Quot.sound`

#### Scenario: A permit is a theorem about the example
- **WHEN** the example's permit evidence is checked in a Lean test with `native_decide`
- **THEN** a theorem `Allowed g R` is obtained for the example's decision graph and request

### Requirement: Policy command line
`leanrdf-policy decide --policies P.ttl --data D.nt --agent A --action X --target T --purpose U [--permit C.json] [--absence M.json] [--deny C.json] [--clash C.json] [--json]` SHALL validate the policy base, run `decide`, print the decision with the theorem it stands for, and exit with 0 permit, 1 not decided, 2 evidence rejected by a checker, 3 input error, 4 inconsistent and 5 deny. With `--json`, it SHALL write `{decision, verdict, exit, theorem, reasons}`, where `verdict` is `proven` for permit, `refuted` for deny, `unknown` for not decided, `inconsistent`, `rejected` or `input-error`. `leanrdf-policy patterns` SHALL write the two match patterns of a request as N-Triples, for finders.

#### Scenario: JSON decision for a deny
- **WHEN** the prohibition example is decided with `--json`
- **THEN** the output has `"decision": "deny"`, `"verdict": "refuted"`, `"exit": 5` and `"theorem": "decide_deny_sound"`

#### Scenario: Patterns for finders
- **WHEN** `leanrdf-policy patterns --agent ex:ada --action ex:read --target ex:spec42 --purpose ex:review` is run
- **THEN** it writes the permission and prohibition patterns, each with nine triples

### Requirement: ODRL mapping
The package documentation SHALL include a table that maps each `pol:` term to its ODRL 2.2 counterpart, and SHALL list the ODRL features that are not covered: duties, refinements, logical constraints, conflict strategies, and constraints other than purpose.

#### Scenario: The mapping table is published
- **WHEN** `site/content/docs/policy.md` is built
- **THEN** it contains the mapping table and the list of features that are not covered

### Requirement: Tool-call guard example
`examples/policy-guard/` SHALL hold a policy base, data, and a guard script that, for a tool call:
1. writes the request's patterns;
2. runs the untrusted finders for the permission certificate, the prohibition certificate and the absence countermodel;
3. calls `leanrdf-policy decide`;
4. runs the tool only on exit 0.

Recorded runs SHALL cover permit, deny and not decided, and `scripts/examples.sh` SHALL check them.

#### Scenario: The guard blocks a prohibited call
- **WHEN** the guard is run for `ex:ada` reading `ex:payroll`, which a prohibition covers
- **THEN** the tool is not run, the guard prints the deny decision and its certificate, and the recorded output matches

#### Scenario: The guard runs a permitted call
- **WHEN** the guard is run for `ex:ada` reading `ex:spec42`
- **THEN** the tool is run once, and the recorded output shows the permit decision with `decide_permit_sound`
