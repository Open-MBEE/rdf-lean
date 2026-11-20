1/
Your agent asks the knowledge graph "is Ada staff?"
The reasoner says yes.
The agent writes it to memory.
A second agent grants access.
A third reports "all per policy."

Nobody checked anything.

In an agentic flow, an unchecked inference is an error with descendants. 🧵

2/
Agents make reasoning errors worse in 3 ways:

• they compound: 10 steps at 95% each ≈ 60% end to end
• they persist: a wrong inference in memory becomes a "fact"
• nobody watches: no human glances at each step

Evals only sample behaviour. Agents find the cases you didn't try.

3/
Symbolic ≠ trustworthy.

I pointed LeanRDF at my own store, oxilite, and its explanation for one answer was circular: triple A justified by B, B justified by A, plus a premise it marked absent.

The answer was right. The explanation was not a proof.

4/
LeanRDF rejected that tree, found its own derivation, and certified the answer from that.

Answer: proven. Explanation: rejected. Both reported.

An agent would have stored the circular argument as "evidence."

An explanation nobody checks is just more output.

5/
What "certified" means in LeanRDF:

1. W3C semantics of RDF, RDFS, OWL 2 RL/EL, SPARQL, SHACL written as Lean 4 definitions
2. Engines that find answers are untrusted
3. They must hand over a certificate
4. A small verified checker accepts it, or not

Elpi finds. Lean checks.

6/
When the checker accepts, you get a Lean theorem, not a log line:

g.RDFSEntails q

"Every RDFS interpretation that satisfies the data satisfies the query."

A bug in the search can give a rejected certificate. It cannot give a wrong answer.

7/
Where certificates aren't enough, the engine is proven:

• SPARQL evaluator = the SPARQL 1.1 semantics
• SHACL "conforms" exactly when the data conforms
• bitemporal memory exports to RDF 1.2 and decodes back exactly

No sorry, 3 standard axioms, no Mathlib. W3C suites pass.

8/
Pattern 1: exit codes are a protocol.

0 → proven, act
1 → not derived, abstain or ask
2 → certificate rejected, a bug, stop
3 → bad input, repair

Your agent branches on a fact about a proof, not on whether text sounds right. And "not derived" never pretends to mean "false".

9/
Pattern 2: the LLM proposes, the graph certifies.

Turn each claim in a draft into a small query graph. Keep the claims that come back certified, with the certificate attached. Send the rest back as unsupported.

No proof, no answer.

10/
Pattern 3: gate the write, not just the read.

SHACL (proven validator) before anything enters memory. A certificate before a derived fact enters memory.

Your agent's memory is only as good as the worst thing it was allowed to write.

No proof, no entry.

11/
Pattern 4: audit the closure.

oxilite materialised 31 OWL inferences. LeanRDF certified 16. The other 15 were "x a owl:Thing", which no OWL 2 RL rule derives, so they came back "not derived", not dressed up as proven.

Now you know what in memory is proven and what is stored.

12/
Pattern 5: memory that knows when.

Statement records with transaction and validity time export to RDF 1.2 reification. Export and decode are proven inverses.

Delete one triple from the history, and decoding refuses it, naming the statement. Tampering becomes visible.

13/
Pattern 6: agents exchange proofs, not opinions.

Finding a derivation is expensive. Checking one is cheap.

Agent A sends its conclusion plus the certificate. Agent B checks it against the same data and rules, with no need to trust A or redo the search.

14/
The limits, said plainly:

• sound, not complete
• consistent with your axioms ≠ true. If your ontology says penguins fly, it certifies that they fly
• proven evaluators are references, not production engines

An agent that knows its guarantees can tell the truth about them.

15/
This is the practical half of my book Bulletproof Knowledge: a small fixed checker decides what an agent may remember and claim.

The book does it with Lean types. LeanRDF does it on the RDF/OWL/SPARQL/SHACL stack you already run.

https://leanpub.com/bulletproofknowledge-aiagents

16/
Full long read, with outputs and code:
[SUBSTACK LINK]

LeanRDF (MIT/Apache-2.0, Lean 4):
https://github.com/Volland/rdf-lean

Learn the λProlog side: https://leanpub.com/logic4agenticai

The LLM proposes. The engine finds. Lean decides.
