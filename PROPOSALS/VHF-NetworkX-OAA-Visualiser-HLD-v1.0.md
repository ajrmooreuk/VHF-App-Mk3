# VHF NetworkX Ontology Visualiser
## High Level Design - Mini Plan v1.0

---

| Document Control | |
|-----------------|---|
| **Feature Branch** | feature/networkx-visualise-ontologies-interactive |
| **Version** | 1.0 |
| **Status** | Draft |
| **Date** | 27 January 2026 |

---

## 1. PURPOSE

Enable on-demand ontology generation using the OAA (Ontology Architect Agent) system prompts, with interactive NetworkX visualization for exploring VE (Value Engineering) domains and agent context graphs.

### Value Hypothesis
**Category:** Labour Efficiency + Capacity Enablement
**Benefit:** Visualize complex ontology relationships interactively, accelerating understanding of VE structures and agent domain contexts without manual diagramming.

---

## 2. COMPONENTS

```
┌─────────────────────────────────────────────────────────────────────┐
│  OAA System Prompts (v4.0.0 + v4.0.2)                               │
│  ══════════════════════════════════════                             │
│  • Ontology generation rules                                         │
│  • 12 Competency Questions (CQ1-CQ12)                               │
│  • 5 Quality Gates (G1-G5)                                          │
│  • UniRegistry v1.0 format                                          │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Ontology Generator                                                  │
│  ══════════════════                                                  │
│  • Parse OAA prompts for generation patterns                        │
│  • Load existing JSON-LD ontologies                                 │
│  • Generate VE domain ontologies on demand                          │
│  • Extract entities, relationships, business rules                   │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│  NetworkX Graph Builder                                              │
│  ══════════════════════                                              │
│  • Entities → Nodes (with attributes)                               │
│  • Relationships → Edges (with cardinality)                         │
│  • Agent bindings → Context edges                                   │
│  • VE value chains → Weighted paths                                 │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Interactive Visualiser                                              │
│  ══════════════════════                                              │
│  • PyVis for interactive HTML graphs                                │
│  • Matplotlib for static exports                                    │
│  • Jupyter widgets for exploration                                  │
│  • Domain filtering (VE, CE, Agent contexts)                        │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 3. DELIVERABLES

| CC-### | Artifact | Description |
|--------|----------|-------------|
| CC-101 | OAA prompts | Copy OAA v4.0.0 + v4.0.2 to PBS/ONTOLOGIES/OAA/ |
| CC-102 | ontology_loader.py | Load JSON-LD ontologies from PBS/ONTOLOGIES |
| CC-103 | graph_builder.py | Convert ontology → NetworkX graph |
| CC-104 | visualiser.py | PyVis/Matplotlib rendering functions |
| CC-105 | ontology_explorer.ipynb | Jupyter notebook for interactive exploration |
| CC-106 | ve_domain_graphs.py | VE-specific graph templates |

---

## 4. IMPLEMENTATION PHASES

### Phase 1: Foundation (CC-101, CC-102)
```
□ Copy OAA v4.0.0 system prompt to PBS/AGENTS/OAA/
□ Copy OAA v4.0.2 system prompt to PBS/AGENTS/OAA/
□ Create tools/ directory for Python scripts
□ Implement ontology_loader.py
  - Load JSON-LD files
  - Parse @graph entities
  - Extract relationships
  - Return structured dict
```

### Phase 2: Graph Builder (CC-103)
```
□ Implement graph_builder.py
  - create_graph(ontology_dict) → nx.DiGraph
  - add_entity_nodes(graph, entities)
  - add_relationship_edges(graph, relationships)
  - add_business_rules(graph, rules) as edge attributes
  - add_agent_context(graph, agent_bindings)
```

### Phase 3: Visualisation (CC-104, CC-105)
```
□ Implement visualiser.py
  - render_pyvis(graph) → interactive HTML
  - render_matplotlib(graph) → PNG/SVG
  - filter_by_domain(graph, domain) → subgraph
  - highlight_path(graph, start, end) → VE value chains
□ Create ontology_explorer.ipynb
  - Load ontology selector widget
  - Interactive graph display
  - Node/edge inspector
  - Export controls
```

### Phase 4: VE Integration (CC-106)
```
□ Implement ve_domain_graphs.py
  - VE 8-layer business framework templates
  - Value chain path analysis
  - Agent context integration
  - Cross-domain relationship mapping
```

---

## 5. TECHNICAL STACK

| Component | Technology | Rationale |
|-----------|------------|-----------|
| Graph Engine | NetworkX 3.x | Python standard, rich algorithms |
| Interactive Viz | PyVis 0.3.x | Vis.js wrapper, HTML export |
| Static Viz | Matplotlib + NetworkX draw | Publication-quality exports |
| Notebook | Jupyter + ipywidgets | Interactive exploration |
| Ontology Format | JSON-LD (UniRegistry v1.0) | OAA standard output |

---

## 6. FILE STRUCTURE

```
VHF-App-Mk3/
├── PBS/
│   └── ONTOLOGIES/
│       └── OAA/                          # NEW
│           ├── OAA_System_Prompt_v4.0.0.md
│           └── OAA_System_Prompt_v4.0.2.md
├── tools/                                 # NEW
│   ├── requirements.txt
│   ├── ontology_loader.py
│   ├── graph_builder.py
│   ├── visualiser.py
│   └── ve_domain_graphs.py
├── notebooks/                             # NEW
│   └── ontology_explorer.ipynb
└── PROPOSALS/
    └── VHF-NetworkX-OAA-Visualiser-HLD-v1.0.md
```

---

## 7. DEPENDENCIES

```txt
# tools/requirements.txt
networkx>=3.0
pyvis>=0.3.1
matplotlib>=3.7
jupyter>=1.0
ipywidgets>=8.0
rdflib>=7.0          # JSON-LD parsing
```

---

## 8. ACCEPTANCE CRITERIA

| Test | Criteria |
|------|----------|
| Load | Can load any JSON-LD ontology from PBS/ONTOLOGIES |
| Graph | NetworkX graph has correct node/edge counts |
| Visual | PyVis renders interactive HTML with zoom/pan |
| Filter | Can filter graph by domain (VE, CE, Agent) |
| Path | Can trace VE value chain paths through graph |
| Export | Can export static PNG/SVG for documentation |

---

## 9. NEXT STEPS

1. **Approve plan** → Proceed with implementation
2. **Copy OAA prompts** → CC-101
3. **Create tools/ structure** → CC-102
4. **Iterate on graph builder** → CC-103, CC-104
5. **Build notebook** → CC-105
6. **VE integration** → CC-106
7. **PR for merge** → feature/networkx-visualise-ontologies-interactive

---

**--- END OF HIGH LEVEL DESIGN ---**

*Version 1.0 | Draft*
*27 January 2026*
