# VHF Ontology Visualiser Tools

Interactive NetworkX visualization for VE ontologies with browser-based demos.

## Quick Start

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Run browser demo (sample data)
python demo.py

# 3. Run tests
python test_ontology_tools.py
```

## Deployment

### Option A: Local Python

```bash
cd tools/
pip install -r requirements.txt
python demo.py
```

### Option B: Virtual Environment (Recommended)

```bash
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
python demo.py
```

### Option C: Jupyter Notebook

```bash
pip install -r requirements.txt
jupyter notebook ../notebooks/ontology_explorer.ipynb
```

## Browser Testing

The visualiser generates interactive HTML files using PyVis (vis.js wrapper).

### Run Demo

```bash
# Sample ontology (auto-opens browser)
python demo.py

# W4M Framework only
python demo.py --framework

# Specific ontology file
python demo.py path/to/ontology.json
```

### Output

Files are generated in `demo_output/`:
- `ontology_demo.html` - Interactive ontology graph
- `w4m_framework.html` - 8-layer business framework

Open any `.html` file in a browser for:
- **Zoom/Pan** - Mouse scroll and drag
- **Node selection** - Click to highlight
- **Physics simulation** - Nodes respond to forces
- **Tooltips** - Hover for details

## Test Plan

### Unit Tests

```bash
# Run all tests
python test_ontology_tools.py

# Run with pytest (more detail)
pip install pytest
pytest test_ontology_tools.py -v
```

### Test Coverage

| Module | Tests | Coverage |
|--------|-------|----------|
| ontology_loader.py | 6 | Entity/Relationship parsing, file loading |
| graph_builder.py | 4 | Graph construction, metadata, stats |
| visualiser.py | 3 | Domain filtering, path highlighting, HTML output |
| ve_domain_graphs.py | 3 | W4M framework, value flow analysis |
| Integration | 1 | End-to-end pipeline |

### Manual Browser Tests

1. **Load Test**: Open `demo_output/ontology_demo.html` - should render graph
2. **Interaction Test**: Zoom, pan, click nodes - should respond
3. **Framework Test**: Run `python demo.py --framework` - should show 8 layers
4. **Custom Ontology**: Run `python demo.py <your-file.json>` - should parse and render

## File Structure

```
tools/
├── ontology_loader.py      # CC-102: JSON-LD parsing
├── graph_builder.py        # CC-103: NetworkX graph construction
├── visualiser.py           # CC-104: PyVis/Matplotlib rendering
├── ve_domain_graphs.py     # CC-106: W4M framework, VSOM
├── demo.py                 # CC-107: Browser demo script
├── test_ontology_tools.py  # CC-108: Unit test suite
├── requirements.txt        # Python dependencies
└── README.md               # This file

notebooks/
└── ontology_explorer.ipynb # CC-105: Interactive Jupyter notebook

demo_output/                # Generated HTML files (gitignored)
└── *.html
```

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| networkx | >=3.0 | Graph data structures |
| pyvis | >=0.3.1 | Interactive HTML visualization |
| matplotlib | >=3.7 | Static image export |
| rdflib | >=7.0 | JSON-LD parsing (optional) |
| jupyter | >=1.0 | Notebook support |
| ipywidgets | >=8.0 | Interactive widgets |

## Usage Examples

### Load and Visualize Ontology

```python
from ontology_loader import load_ontology
from graph_builder import build_ontology_graph
from visualiser import render_interactive

# Load
ontology = load_ontology('my_ontology.json')
print(f"Entities: {len(ontology.entities)}")

# Build graph
G = build_ontology_graph('my_ontology.json')

# Visualize
render_interactive(G, 'output.html')
```

### W4M Framework Analysis

```python
from ve_domain_graphs import VEDomainGraphBuilder

builder = VEDomainGraphBuilder()
G = builder.build_w4m_framework_graph()

# Analyze value flow
analysis = builder.analyze_value_flow(G, source_layer=0, target_layer=7)
print(f"Paths: {len(analysis['paths'])}")
print(f"Bottlenecks: {analysis['bottlenecks']}")
```

### Domain Filtering

```python
from visualiser import OntologyVisualiser

vis = OntologyVisualiser()

# Filter to VE domain only
ve_graph = vis.filter_by_domain(G, 'VE', include_connected=True)

# Highlight path
highlighted = vis.highlight_path(G, 'start_node', 'end_node')
```

## Troubleshooting

### PyVis not rendering

```bash
pip install --upgrade pyvis
```

### Import errors

```bash
# Ensure you're in the tools directory
cd tools/
python -c "from ontology_loader import load_ontology; print('OK')"
```

### Browser doesn't open

```bash
# Manually open the HTML file
open demo_output/ontology_demo.html  # macOS
xdg-open demo_output/ontology_demo.html  # Linux
start demo_output\ontology_demo.html  # Windows
```

---

**Version:** 1.0.0
**CC Items:** CC-102 through CC-108
**Last Updated:** January 2026
