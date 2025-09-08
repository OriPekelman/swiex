---
marp: true
---
# 🧠 Prolog and Logic Programming for Elixir Developers
## Paris Elixir User Group Presentation

---

## Prolog and Logic Programming for Elixir Developers
**Bridging Functional and Logical Programming with Swiex**

- **Speaker:** Ori Pekelman
- **Date:** 11/09/2025
- **GitHub:** https://github.com/OriPekelman/swiex

---

## How did I get into this mess?
**Blame Edmund**

* So the thing was we were working on a project.
* And I was like: hey this sounds distributed I'll do Elixir.
* And Edmund was like: I am too bored and have too little patience so I'll express it in Prolog.
* Afterwards, I have been writing a unchronic science-fiction novel, with quite a complex backstory. And a couple hundred pages in I really wanted to be able to do some sanity checks on the coherence of my world.
* And I already knew some prolog. So WTF. Why not?
---

## 🎯 **What We'll Cover Today**

1. **🤔 What is Logic Programming?** - The paradigm shift
2. **🔄 Prolog vs Elixir** - Compare and contrast
3. **💡 The Sweet Spot** - Where Prolog shines
4. **🚀 Swiex Integration** - Bringing Prolog to Elixir
5. **🧠 Live Demo** - CauseNet + Prolog in action
6. **🎯 Real-World Applications** - Why this matters

---

## 🎯 **The Programming Paradigm Spectrum**

```
Imperative Programming    Functional Programming    Logic Programming
      "HOW?"                   "WHAT?"               "WHAT THE FUCK??"
        |                        |                        |
        |                        |                        |
 Do this, then that,   Transform this reality       What is reality?
 hopefully reality     representation to that       Does anything make
 conforms              reality representation       Sense?
        |                        |                        |
        |                        |                        |
    C, Java, Python         Elixir, Haskell, F#        Prolog, Datalog
```

**Logic programming sits at the extreme "what" end of declarative programming**

---

## 🎯 **What Makes Logic Programming Different?**

### **From Functions to Relations**

**Elixir (Functional):**
```elixir
def find_grandparents(person, family_tree) do
  family_tree
  |> get_parents(person)
  |> Enum.flat_map(&get_parents(&1, family_tree))
end
```

**Prolog (Logic):**
```prolog
grandparent(X, Z) :- parent(X, Y), parent(Y, Z).
```

**Same code works in ALL directions!**

---

## 🎯 **Bidirectional Programming**
### **One Rule, Multiple Uses**

```prolog
% Define the relationship
grandparent(X, Z) :- parent(X, Y), parent(Y, Z).

% Find all grandparents of John
?- grandparent(X, john).
X = mary ; X = bob ; X = alice.

% Find all grandchildren of Mary
?- grandparent(mary, X).
X = john ; X = sarah ; X = tom.

% Check if Alice is John's grandparent
?- grandparent(alice, john).
true.
```

**The same 1-line rule answers 3 different types of questions!**

---

## 🎯 **Core Prolog Concepts for Elixir Developers**

### **1. Facts and Rules (Not Functions)**
```prolog
% Facts - unconditional truths
parent(john, mary).
parent(mary, bob).

% Rules - conditional relationships
grandparent(X, Z) :- parent(X, Y), parent(Y, Z).
```

### **2. Unification (Bidirectional Pattern Matching)**
```prolog
% Works both ways!
append([1,2], [3,4], X).     % X = [1,2,3,4]
append(X, Y, [1,2,3,4]).     % X = [], Y = [1,2,3,4] ; X = [1], Y = [2,3,4] ; ...
```

### **3. Automatic Backtracking**
```prolog
% Finds ALL solutions automatically
?- member(X, [1,2,3]).
X = 1 ; X = 2 ; X = 3 ; false.
```

---

## 🎯 **Slide 7: Mental Model Shifts for Elixir Developers**

| **Elixir Thinking** | **Prolog Thinking** |
|---------------------|---------------------|
| "How do I compute X from Y?" | "What relationships exist between X and Y?" |
| Functions return one result | Queries explore all possible solutions |
| Explicit recursion management | Automatic backtracking handles search |
| Pattern matching binds left to right | Unification works bidirectionally |
| Error handling with tuples | Failure triggers backtracking |

---

## 🎯 **Slide 8: Prolog's Sweet Spots**

### **🎯 Where Prolog Provides Dramatic Simplification**

1. **Constraint Satisfaction Problems** - N-Queens, Sudoku, Graph Coloring
2. **Expert Systems & Rule Engines** - Medical diagnosis, business rules
3. **Natural Language Processing** - Parsing, semantic analysis
4. **Causal Reasoning** - What we'll demo today!
5. **Graph Traversal** - Finding paths, cycles, relationships

---

## 🎯 ****N-Queens Problem in 15 Lines**

**Prolog (15 lines):**
```prolog
n_queens(N, Queens) :-
    length(Queens, N),
    Queens ins 1..N,
    safe_queens(Queens),
    label(Queens).

safe_queens([]).
safe_queens([Q|Qs]) :-
    safe_queens(Qs),
    safe_queen(Q, Qs, 1).

safe_queen(_, [], _).
safe_queen(Q, [Q1|Qs], D) :-
    Q #\= Q1,
    abs(Q - Q1) #\= D,
    D1 is D + 1,
    safe_queen(Q, Qs, D1).
```

---

## 🎯 **Anyone using Prolog**

- **Airlines:** SICStus Prolog handles crew scheduling for 1/3 of global tickets
- **NASA:** Voice-controlled systems on International Space Station
- **IBM Watson:** Question-answering system uses Prolog for parsing
- **TerminusDB:** Modern graph database written entirely in Prolog
- **Medical Systems:** Expert systems for diagnosis and treatment planning

---

## 🎯 **Swiex**

Why did I not use ex_prolog ? 

1. Because I was too lazy/stupid to imagine someone else would have already done this.
2. Learning by doing is nice.
3. I did implement some bells and whistles that would have been difficult with the existing seemingly not really maintained basis... 

- **Seamless Integration:** Use Prolog from Elixir code
- **Variable Sharing:** Pass data between languages
- **Hot Code Loading:** Update Prolog rules without restarting
- **Session management:** Have multiple long running processes each with its own facts context

---

## 🎯 **Architecture**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Phoenix App   │    │   Swiex MQI     │    │  SWI-Prolog     │
│                 │◄──►│   Interface     │◄──►│   Engine        │
│ • Web UI       │    │                 │    │ • Facts         │
│ • API Endpoints│    │ • Session Mgmt  │    │ • Rules         │
│ • Business     │    │ • Query Exec    │    │ • Inference     │
│   Logic        │    │ • Result Proc   │    │ • Backtracking  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

**Elixir handles system coordination, Prolog handles reasoning**

---

## 🎯 **Swiex Code Example**

### **Simple Integration**

```elixir
defmodule CausalReasoning do
  def find_causal_paths(start, end) do
    with {:ok, session} <- Swiex.MQI.start_session() do
      # Load knowledge base
      load_causenet_data(session)
      
      # Execute Prolog query
      case Swiex.MQI.query(session, "causal_path('#{start}', '#{end}', Path)") do
        {:ok, results} -> 
          paths = Enum.map(results, &(&1["Path"]))
          Swiex.MQI.stop_session(session)
          {:ok, paths}
        {:error, reason} -> 
          Swiex.MQI.stop_session(session)
          {:error, reason}
      end
    end
  end
end
```

---

## 🎯 **Live Demo: CauseNet + Prolog**

### **🧠 Real-World Causal Knowledge Graph**

**What is CauseNet?**
- **199K+ causal relationships** from scientific literature, wikipedia
- **Real-world data** about health, environment, society, technology

**What we'll explore:**
1. **Causal Pathways** - How does smoking lead to death?
2. **Constraint Solving** - N-Queens and Sudoku
3. **Interactive Exploration** - Audience-driven queries

---

## 🎯 **Slide 15: Demo: Causal Reasoning**

### **🔍 Finding Causal Pathways**

**Query:** "How does smoking lead to death?"

In 4 lines of code.

---

## 🎯 ** Demo: Constraint Solving**

### **🧩 N-Queens Puzzle**

**Problem:** Place 8 queens on 8x8 chessboard so no queen attacks another

**Prolog solution:**
```prolog
?- n_queens(8, Queens).
Queens = [1, 5, 8, 6, 3, 7, 2, 4] ;
Queens = [1, 6, 8, 3, 7, 4, 2, 5] ;
... (92 total solutions)
```
---


## 🎯 **Slide 21: Getting Started with Swiex**

### **🚀 Your Next Steps**

1. **Install SWI-Prolog:**
   ```bash
   # macOS
   brew install swi-prolog
   
   # Ubuntu
   sudo apt-get install swi-prolog
   ```

2. **Add to your Mix project:**
   ```elixir
   def deps do
     [{:swiex, github: "OriPekelman/swiex"}]
   end
   ```

3. **Start exploring:**
   - SWISH online Prolog environment
   - "Learn Prolog Now!" tutorial
   - 99 Prolog Problems for practice

---

## 🎯 **Common Concerns Addressed**

### **🤔 "But I have questions..."**

**Q: "Is Prolog still relevant?"**
A: Probably not.

**Q: "Is it secure?"**
A: Probably not.

**Q: "Does it have anything to do with LLMs"**
A: Probably.

**Q: "Won't it slow down our app?"**
A: It will.

**Q: "Can you use swiex to summon ancient evil spirits"**
A: It does.

**Q: "What about maintenance?"**
A: Prolog rules are often more maintainable than complex imperative code. But I won't probably maintain swiex unless I actually use it long-term.

---

## 🎯 **Resources & Next Steps**

### **📚 Continue Your Journey**

**Immediate Exploration:**
- **SWISH:** https://swish.swi-prolog.org/ (Online Prolog)
- **Learn Prolog Now!:** http://www.learnprolognow.org/
- **99 Problems:** https://www.ic.unicamp.br/~meidanis/courses/mc336/2009s2/prolog/problemas/

**Integration:**
- **Swiex Documentation:** https://github.com/OriPekelman/swiex
- **SWI-Prolog MQI:** https://www.swi-prolog.org/pldoc/man?section=mqi
- **Example Projects:** Check the Swiex examples directory

**Community:**
- **SWI-Prolog Discourse:** https://swi-prolog.discourse.group/

---

## 🎯 **Slide 26: Thank You!**

### **🧠 Prolog + Elixir = Powerful Hybrid Solutions**

**Contact & Resources:**
- **GitHub:** https://github.com/OriPekelman/swiex

---

## 🎯 **Appendix: Live Demo Script**

### **🎬 Your Demo Flow for Maximum Impact**

1. **Start with the question:** "How would you find all ways that smoking can lead to death in Elixir?"
2. **Show the complexity:** Graph traversal, backtracking, cycle detection (60+ lines)
3. **Reveal Prolog:** "Here's the Prolog version..." (4 lines)
4. **Load CauseNet data:** Show real-world causal relationships
5. **Build complexity:** Start with simple queries, build to causal chains
6. **Audience participation:** Let them suggest concepts to explore
7. **Finish with Swiex:** Show it working in Phoenix

**Key "Wow" moments:**
- Bidirectional queries working both ways
- Automatic finding of all causal pathways
- Real data making it immediately relevant
- Dramatic code reduction
- Live audience-driven exploration

---

## 🎯 **Appendix: Technical Setup**

### **🔧 Getting the Demo Running**

1. **Start Phoenix demo (Swiex handles Prolog automatically):**
   ```bash
   cd examples/phoenix_demo
   mix deps.get
   mix phx.server
   ```

2. **Navigate to:** 
   - **Traditional version:** http://localhost:4000/causenet
   - **LiveView version:** http://localhost:4000/causenet-live

3. **Demo features:**
   - Causal reasoning with CauseNet data
   - Medical diagnosis system
   - Constraint solving (N-Queens, Sudoku)
   - Interactive Prolog playground
   - Real-time updates with Phoenix LiveView

**The demo showcases real-world applications, not just toy examples!**

### **🚀 Why LiveView Makes This Better**

- **Real-time interactivity** - No page refreshes needed
- **Elixir-native state management** - All logic stays in Elixir
- **Better user experience** - Instant feedback and updates
- **Cleaner architecture** - No JavaScript/HTML mixing
- **Easier maintenance** - Single language for frontend and backend
