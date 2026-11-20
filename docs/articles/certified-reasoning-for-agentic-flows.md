# No Proof, No Entry: Certified RDF Reasoning for Agentic Flows

### An agent chains inferences it cannot check. LeanRDF turns each link of the chain into a theorem, and that changes how agentic flows should be built.

*[header image: the LeanRDF pipeline — untrusted engine → certificate → verified checker → theorem]*

---

Picture an ordinary agentic flow. A planner agent receives a request: *give Ada access to the compilers repository.* It asks the knowledge graph whether Ada is staff. The reasoner says yes. The planner writes "Ada is staff" into the shared memory. A second agent reads that memory an hour later, sees a staff member, and grants the access. A third agent summarises the day and reports that everything went according to policy.

Nobody in that chain checked anything. Each agent trusted the step before it, and the first step trusted a reasoner that gave an answer and no reason to believe it.

This is the normal state of agentic systems in 2026. We spend a lot of energy on the LLM's hallucinations and almost none on the hallucinations of everything around it: the retriever, the reasoner, the triple store, the memory. A symbolic component is not automatically a trustworthy one. It is just a different kind of black box.

For the last months I have been building **[LeanRDF](https://volland.github.io/rdf-lean/)**, a set of Lean 4 libraries that make RDF reasoning *certified*: every answer the system gives you comes with a proof that a small, verified checker accepted. I have written about the mechanics before ([Certified answers for knowledge graphs](https://volodymyrpavlyshyn.substack.com/p/certified-answers-for-knowledge-graphs), [Certified RDF: Bridging Triples and Dependent Types](https://volodymyrpavlyshyn.substack.com/p/certified-rdf-bridging-triples-and)). This essay is about the other question: **what does certified reasoning mean for agentic flows?** What do you build differently when every inference your agent consumes is a theorem?

My answer is short, and the rest of the essay defends it:

> **In an agentic flow, an unchecked inference is not a single error. It is an error with descendants.**

---

### Why agents make the problem worse

A chatbot that gets a fact wrong produces one wrong answer, and a human reads it. An agent that gets a fact wrong *acts* on it, writes it down, and hands it to the next agent. Three properties of agentic flows turn small reasoning errors into large ones.

**Errors compound.** If each step of a ten-step flow is right 95% of the time, and the steps fail independently, the whole flow is right about 60% of the time. Agents run long chains, and nobody multiplies the probabilities until something breaks.

**Errors persist.** An agent with memory writes its conclusions down. A wrong inference that enters memory is no longer an inference. It becomes a "fact", and the next query retrieves it with the same confidence as the data it was wrongly derived from. I called this [an agent that remembers things that never happened](https://volodymyrpavlyshyn.substack.com/p/your-agent-remembers-things-that).

**Nobody is watching.** The point of an agent is that a human is not in the loop for every step. The checks a human would do, glancing at an answer and thinking "that is odd", disappear.

The usual response is more testing, more evaluation, more LLM judges. All of these sample behaviour. They tell you the system was right on the cases somebody tried. An agent will meet the cases nobody tried within a week.

There is a better response for the symbolic part of the stack, and it is old: **do not trust the answer, check the proof.**

---

### I found a bad explanation in my own engine

Here is the story that convinced me this is not academic.

I also maintain [oxilite](https://oxilitedb.com), a SPARQL store on SQLite that does RDFS and OWL 2 RL reasoning and can explain its inferences with a `why` tool. The `why` tool returns a proof tree: this triple holds because of this rule, applied to these premises. That is exactly the kind of explanation agent builders ask for. *Show me why.*

When I pointed LeanRDF at oxilite's explanations, one of them came back unusable. The question was which units are part of Acme. `partOf` is transitive and has an inverse `hasPart`. oxilite answered correctly: `:research` and `:compilers`. But its explanation for `:compilers` was circular. It explained `:compilers :partOf :acme` from `:acme :hasPart :compilers` by the inverse rule, and explained `:acme :hasPart :compilers` from the first triple again by the same rule. It also leaned on a premise that oxilite itself marked as absent.

The answer was right. The explanation was not a proof.

```
[1] ?unit = <http://example.org/org#compilers>
    elpi: certified
    why:  untranslated (oxilite gave no rule: explained above)
    verdict: CERTIFIED
```

LeanRDF refused to translate oxilite's tree, found an independent derivation through the transitivity rule with its own search, and certified the answer from that. The answer is proven. The explanation was rejected. Both facts are reported.

Think about what an agent would have done with oxilite's explanation alone. It would have stored a circular argument as justification, and shown it to a user as evidence. An explanation feels like accountability. **An explanation that nobody checks is just more output.**

---

### What "certified" means, precisely

"Certified" is a word that marketing loves, so let me be exact about what LeanRDF does.

**1. The meaning is written down as Lean definitions.** RDF 1.1 Semantics is a W3C Recommendation that defines entailment model-theoretically: graph `g` entails graph `q` when every interpretation that makes `g` true also makes `q` true. LeanRDF transcribes that text into Lean 4, condition by condition, so you can read the definitions side by side with the specification. The same is done for RDF 1.2 (triple terms and reification included), the OWL 2 RDF-Based conditions, SPARQL 1.1 §18 and SHACL Core.

**2. The finders are untrusted.** Searching for derivations is the expensive part, and it changes often. LeanRDF keeps it outside the trusted base. The search runs in Elpi, a λProlog engine, through [lean-elpi](https://github.com/Volland/lean-elpi). Or it runs in oxilite. Or in any engine that can emit a derivation.

**3. A small checker decides.** Every finder must hand over a **certificate**: a proof DAG where each node is a triple, the rule that produced it and the premises it used. A verified Lean function checks the certificate. Its soundness theorem says that if the checker accepts, the entailment holds:

```lean
theorem g_entails_q : g.RDFSEntails q :=
  checkQueryB_sound (c := cert) (by native_decide)
```

`g.RDFSEntails q` is not a log message. It is a proposition in Lean's logic: *every RDFS interpretation that satisfies the data satisfies the query.*

Here is what that looks like from the command line, on a small university graph, when the agent asks whether Kurt is a person:

```
Certificate: 7 nodes, goals [6]
  [0] uni:Lecturer rdfs:subClassOf uni:Staff           (fact)
  [1] uni:Professor rdfs:subClassOf uni:Lecturer       (fact)
  [2] uni:Staff rdfs:subClassOf uni:Person             (fact)
  [3] uni:kurt rdf:type uni:Professor                  (fact)
  [4] uni:kurt rdf:type uni:Lecturer                   (rdfs9 [1, 3])
  [5] uni:Lecturer rdfs:subClassOf uni:Person          (rdfs11 [0, 2])
  [6] uni:kurt rdf:type uni:Person                     (rdfs9 [5, 4])
Verdict: ENTAILED. The certificate was accepted by the verified checker (compiled).
```

Every line names a rule from the W3C specification, and every rule is proven sound against the semantics. That is the whole idea, and I wrote it on the project's front page: **Elpi finds, Lean checks.**

The consequence for an agent builder is the important part. **A bug in the search can produce a rejected certificate. It cannot produce a wrong answer.** You can replace the engine, optimise it, rewrite it with an LLM's help at 2 a.m., and the guarantee does not move, because the guarantee lives in the checker, and the checker is small.

> **The engine proposes. The certificate travels. The checker decides.**

---

### Where certificates are not enough, the engine is proven

A certificate proves that something *follows*. It cannot prove that nothing is *missing*. For some jobs that difference matters a lot. A query that silently drops half its rows is wrong even if every returned row is correct. A validator that says "conforms" is making a claim about the absence of violations.

So for those jobs LeanRDF proves the engine itself:

| What the agent asks | Package | What Lean proves |
|---|---|---|
| Does this follow under RDFS? | `leanrdf` | `checkQuery_sound`: an accepted certificate gives `g.RDFSEntails q`, under 80 RDFS rules each proven sound |
| Does this follow under OWL? | `leanrdf-owl` | 60 OWL 2 RL rules and 10 EL rules proven sound for the OWL 2 RDF-Based conditions |
| What is the class hierarchy? | `leanrdf-elpi` (`leanrdf-classify`) | every printed subsumption between named classes is certified |
| What are the answers to this SPARQL query? | `leanrdf-sparql` | the evaluator's solutions are the SPARQL 1.1 semantics, up to order |
| Does this data obey my shapes? | `leanrdf-shacl` | "conforms" exactly when the data conforms, and every reported result is a real violation |
| What did memory hold, and when? | `leanrdf-statements` | bitemporal statement records export to RDF 1.2 and decode back exactly |

The library has no `sorry` and no new axioms. It uses only `propext`, `Quot.sound` and `Classical.choice`, and the tests pin the axioms of every main theorem. It has no Mathlib dependency. It passes the W3C test suites for RDF 1.1 and RDF 1.2 syntax, 97 syntax and 257 evaluation tests of SPARQL 1.1 Query, and 98 out of 98 SHACL Core tests. The statement-graph theorems are also checked exhaustively on all 406,901 graphs of at most four records.

That table is a toolbox. The rest of this essay is about how to use it in an agentic flow.

---

### Pattern 1: Exit codes are a protocol

Most tools give an agent text and let the LLM interpret it. LeanRDF gives every tool the same four exit codes, and each one maps to a different action:

| Exit | Meaning | What the agent should do |
|---|---|---|
| `0` | everything claimed was proven | act on it |
| `1` | not derived, or does not conform | abstain, ask, or gather more data |
| `2` | a certificate was rejected | stop, because the untrusted side has a bug, and alert a human |
| `3` | input error | repair the input and retry |

This turns a reasoning tool into a control-flow primitive. The agent does not have to judge whether an answer *sounds* right. It branches on a fact about a proof.

Exit `1` is the subtle one, and the tools are honest about it:

```
Verdict: NOT DERIVED (no instance of the query is derived).
This is not a claim of non-entailment: completeness is not proven.
```

"Not derived" is not "false". The rules are proven sound, not complete, so the absence of a derivation tells you that the search found nothing, not that the opposite holds. For an agent this is exactly the right signal: **I do not know** is a legitimate output, and it is very different from **no**. An agent that cannot tell those apart will turn every gap in its knowledge into a confident denial.

---

### Pattern 2: The LLM proposes, the graph certifies

The most direct use in an agentic flow is a claim filter. The LLM drafts an answer that contains factual claims about your domain. Each claim is turned into a small query graph, and LeanRDF is asked whether the knowledge graph entails it. Only certified claims reach the user, each with the certificate attached. Claims that are not derived are marked as unsupported or sent back for revision.

```
LLM draft ──► claims as triples ──► leanrdf-demo DATA QUERY --cert claim.json
                                          │
                     exit 0 ──► keep the claim, attach the certificate
                     exit 1 ──► mark "unsupported", ask the LLM to revise
                     exit 2 ──► stop and report a bug
```

Blank nodes in the query are existential, so the agent can ask *is there someone who teaches Logic 101 and is staff?* and get back not just "yes" but the bindings and the derivation that justify them.

This is the slogan from my book *Bulletproof Knowledge* applied to the standard semantic web stack: **No proof, no answer.**

---

### Pattern 3: Gate the write, not just the read

Reads are where we usually put the checks. Writes are where the damage is done. An agent's memory is only as good as the worst thing it was allowed to write.

LeanRDF gives you two gates for writes.

**Shape gate.** Before an agent commits new facts, validate them with `leanrdf-shacl` against the shapes of your memory. The validator is proven against the SHACL Core semantics in both directions: "conforms" means the data conforms, and every violation it reports is a real one. A typical rejected write looks like this:

```
sh:focusNode   hr:kid ;
sh:resultPath  hr:age ;
sh:value       "12"^^xsd:integer ;
sh:sourceConstraintComponent sh:MinInclusiveConstraintComponent
```

The agent gets a precise, machine-readable reason to refuse the write, and a repair target. This is what I mean by memory that [can say no](https://volodymyrpavlyshyn.substack.com/p/your-agents-memory-should-be-able).

**Entailment gate.** For derived facts, require a certificate before the write is accepted. If the planner in my opening story had to attach a certificate to "Ada is staff", the memory would contain the derivation, the rules used, and the premises. When a premise later changes, you know exactly which derived facts to revisit.

> **No proof, no entry.**

---

### Pattern 4: Audit the closure, do not trust it

Many agent stacks materialise inferences ahead of time: run the reasoner over the graph, store everything it derives, and let agents query the result as plain data. It is fast, and it hides every reasoning bug inside data that looks authoritative.

`leanrdf-oxilite --materialized` certifies every inferred triple a store wrote, one by one. On the small organisation example, oxilite materialised 31 inferences. LeanRDF certified 16. The other 15 were all of the form `x rdf:type owl:Thing`. No OWL 2 RL rule derives those, so LeanRDF reports them as not derived rather than pretending to prove them.

That is not a dramatic bug. It is something better for agent builders: an exact inventory of what in your memory is proven and what is merely stored. You can run the audit in CI, on every ontology change, and treat a new exit `2` as a failing build.

The same idea works for ontologies themselves. `leanrdf-classify` prints the class hierarchy of an OWL 2 EL ontology, and it prints *only* certified subsumptions. On a SNOMED-style anatomy example it prints 36 certified subsumptions and two unsatisfiable classes. If your agent routes decisions through a taxonomy, such as a medical one, a product catalogue or a permission hierarchy, the taxonomy it routes through can now be a certified one.

---

### Pattern 5: Memory that knows when

Agents do not just need to know *what* is true. They need to know what they believed, when they believed it, and what changed. I wrote about this in [What did the system know, and when?](https://volodymyrpavlyshyn.substack.com/p/what-did-the-system-know-and-when) and built it into [tiramemsu](https://github.com/Volland/tiramemsu), my bitemporal statement store.

`leanrdf-statements` gives that memory a precise RDF 1.2 form. Each statement record becomes a reifier with `rdf:reifies` pointing at a triple term, plus its transaction and validity clocks. The base triple is asserted only when the record is live in the view you ask for: now, as of a past transaction, or valid at a given time. Two theorems, `decode_toRDF` and `toRDF_decode`, say the export and the decoding are exact inverses on well-formed statement graphs.

Why does an agent care about a round-trip theorem? Because it makes tampering visible. Delete one base triple from an exported history and decoding refuses it, naming the statement:

```
statement 5: triple <urn:tiramemsu:stmt:4> <http://example.org/source>
             <http://example.org/airlineDB> is missing
# exit 2
```

An agent that reads its memory through the decoder cannot silently reason over a corrupted history. Retractions stay visible as retractions. "We used to think the distance was 665 km, and we corrected it to 655 km in transaction 4" stays a recoverable fact instead of an overwritten one. That is the difference between an audit trail and a log.

---

### Pattern 6: Certificates as messages between agents

Multi-agent systems have a trust problem that is mostly ignored. When agent B receives a conclusion from agent A, it has two options: trust A, or redo A's work. Trusting does not scale to agents you do not control. Redoing does not scale at all.

Certificates offer a third option. Finding a derivation is expensive. **Checking one is cheap.** If agent A sends its conclusion together with the certificate (`--cert` writes it as JSON, and `--datalog` exports it for an independent checker), agent B can check the certificate against the same data and rules with the verified checker, without redoing the search or trusting A.

That is a different architecture for agent collaboration. Agents stop exchanging opinions and start exchanging proofs. The only thing they need to agree on is the semantics, and the semantics is a W3C specification written down in Lean. I explored the social side of this in [Trust, Typed](https://volodymyrpavlyshyn.substack.com/p/trust-typed-a-social-trust-graph). Certified RDF gives it a standard data format.

---

### What this does not give you

I promised myself that every piece I write about this work includes the limits, so here they are.

**Soundness, not completeness.** A certified answer follows. Answers the engine did not give are not covered. "Not derived" is never a proof that something is false. Completeness questions are answered by the proven SPARQL evaluator, not by certificates.

**Consistency with your axioms, not truth about the world.** If your ontology says penguins fly, LeanRDF will certify that Pingu flies. A checker guarantees that conclusions follow from what you wrote. Deciding what to write is still your job, and the LLM's job is still to be checked.

**Recorded simplifications.** The datatype map covers `xsd:string` and `rdf:langString` in the entailment semantics. OWL 2 RL runs without the list rules and the inconsistency rules. EL intersections are limited to two or three classes. Every such gap is recorded, with its effect, in the project's design graph.

**Reference speed, not production speed.** The proven SPARQL evaluator and SHACL validator are references for test-sized data. The intended architecture is the one in my opening section: a fast engine such as oxilite does the work, and LeanRDF checks what it claims.

**The trusted base is small but not empty.** It is the Lean kernel, the transcribed W3C semantics, the statements of the rules and, for the compiled tools, the Lean compiler and runtime. Everything else, including lean-elpi, oxilite and all the parsing and translation code, is outside it.

I think this list is a feature. An agent that knows exactly what its guarantees cover can tell a user the truth about them.

---

### Where this comes from: *Bulletproof Knowledge*

LeanRDF did not start as an RDF project. It started as the practical half of an argument I make in my book **[Bulletproof Knowledge: Building Hallucination-Resistant Neurosymbolic Agents with Lean and Logic Programming](https://leanpub.com/bulletproofknowledge-aiagents)**.

The book's thesis is that an agent needs a small, fixed checker that decides what it may remember and what it may claim. The LLM proposes. Lean decides. Facts enter memory only with a proof, and every accepted fact carries a certificate the kernel has checked. The book builds this from first principles: neurosymbolic AI and the case for provable reasoning, higher-order logic and logic programming, knowledge graphs and metagraphs, ontologies as types, closed and open worlds, Lean 4 essentials, certified ontologies, type-class hierarchies, proving the ontology, lean-elpi as logic programming inside Lean, and finally a hallucination-resistant agent built from all of it.

*Bulletproof Knowledge* works with ontologies you write as Lean types. LeanRDF asks the follow-up question: **what if your knowledge already lives in RDF, OWL, SPARQL and SHACL?** Most organisations will not rewrite their knowledge graphs in Lean. They can, however, keep their triple store and put a verified checker in front of it. The pattern is the same. The surface is the standard semantic web stack.

If you read the book, LeanRDF is its worked case study at production scale. If you start from LeanRDF, the book explains why the architecture looks the way it does, and how to apply it to knowledge that is not RDF.

Two companions complete the picture:

- **[Logic for Agents: Building Neurosymbolic AI with Elpi](https://leanpub.com/logic4agenticai)** teaches the *finding* side: λProlog from zero, for AI engineers who have never seen Prolog. LeanRDF's search is written in exactly this language.
- **[Metagraph for AI Agents](https://leanpub.com/metagraphforaiagents)** covers the structures that plain triples cannot express: statements about statements, edges as nodes, graphs of graphs. RDF 1.2 triple terms and reification, which LeanRDF models natively, are the standard's answer to that problem.

---

### Try it

Everything is open source, under MIT or Apache-2.0, and pins Lean 4.35.0:

```bash
git clone https://github.com/Volland/rdf-lean && cd rdf-lean
lake build && lake test
cd elpi && lake build
lake exe leanrdf-demo examples/pets.nt examples/query-mammal-owner.nt
```

The [`examples/`](https://github.com/Volland/rdf-lean/tree/main/examples) folder has a runnable example for every tool with recorded outputs, including the oxilite explanation that LeanRDF rejects, the certified EL classification and the tampered statement history. The [LeanRDF book](https://volland.github.io/rdf-lean/book/) on the website walks from triples to model theory, certificates, oxilite, SPARQL, OWL, SHACL and statement graphs in sixteen short chapters.

---

### Get the books

- **[Bulletproof Knowledge](https://leanpub.com/bulletproofknowledge-aiagents)**: the architecture of hallucination-resistant agents, with Lean 4 and lean-elpi. Leanpub (PDF, EPUB, web, free updates). Companion code: [github.com/Volland/bulletproof-knowledge](https://github.com/Volland/bulletproof-knowledge).
- **[Logic for Agents](https://leanpub.com/logic4agenticai)**: λProlog for AI engineers, one question at a time.
- **[The Neurosymbolic AI bundle](https://leanpub.com/b/neurosymbolicai)**: *Bulletproof Knowledge*, *Logic for Agents*, *Little Elpier* and *Dependent Types & Logic for AI Agent Ready Knowledge Graphs* together, for less than buying them separately.

---

### Closing

Agentic flows will not become trustworthy because LLMs stop making mistakes. They will become trustworthy when every component around the LLM stops asking to be trusted.

For the reasoning layer, that is now possible with the standards you already use. Let the engine be fast. Let it be clever. Let it be rewritten every week. Ask it for a certificate, and let a small checker decide.

**The LLM proposes. The engine finds. Lean decides.**

*If you know someone whose agents act on inferences nobody checked, forward this to them.*
