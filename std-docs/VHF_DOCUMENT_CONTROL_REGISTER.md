# VHF DOCUMENT CONTROL REGISTER
## Unified Register of Design & Build Artifacts

---

| Document Control | |
|-----------------|---|
| **Document Number** | VHF-DCR-001 |
| **Version** | 1.0 |
| **Status** | Active |
| **Date** | 26 January 2026 |

---

## 1. PURPOSE

This Document Control Register (DCR) provides a single source of truth for all VHF project documentation. It:

- Tracks all design and build artifacts
- Records version history and approval status
- Ensures document traceability
- Supports governance and audit requirements

### 1.1 Master Change Control Reference

> **IMPORTANT:** This register works alongside the **Master Change Control Register**:
>
> | Document | Location | Purpose |
> |----------|----------|---------|
> | [VHF-NI-App-Mk3-Master-Change-Control-v1.0.md](../VHF-NI-App-Mk3-Master-Change-Control-v1.0.md) | Root | Detailed change tracking, design token verification, brand approval status |
> | This document (VHF_DOCUMENT_CONTROL_REGISTER.md) | std-docs/ | Document inventory and hierarchy |
>
> For **detailed change history**, **design token verification**, and **approval sign-offs**, refer to the Master Change Control Register.

---

## 2. DOCUMENT INVENTORY

### 2.1 Core Project Documents

| Doc ID | Document Name | Version | Status | Location |
|--------|---------------|---------|--------|----------|
| VHF-PRD-001 | VHF-NI-App-Mk3-PRD-Mockup-First-v3.0.md | 3.0 | Active | root |
| VHF-HLD-001 | VHF-NI-App-Mk3-HLD-Architecture-v2.0.md | 2.0 | Active | root |
| VHF-PBS-001 | viridian-product-breakdown-structure.md | 1.0 | Active | root |
| VHF-WBS-001 | viridian-work-breakdown-structure.md | 1.0 | Active | root |
| VHF-CC-001 | VHF-NI-App-Mk3-Master-Change-Control-v1.0.md | 1.0 | Active | root |

### 2.2 Design System Documents

| Doc ID | Document Name | Version | Status | Location |
|--------|---------------|---------|--------|----------|
| VHF-DS-001 | viridian-design-tokens-v2.json | 2.0 | Active | root |
| VHF-DS-002 | VHF-NI-App-Mk3-Design-Tokens-v3.0.json | 3.0 | Active | root |
| VHF-DS-003 | viridian-brand-guidelines-v2.md | 2.0 | Active | root |
| VHF-DS-004 | viridian-component-usage-examples-v2.md | 2.0 | Active | root |

### 2.3 Implementation Documents

| Doc ID | Document Name | Version | Status | Location |
|--------|---------------|---------|--------|----------|
| VHF-IMP-001 | viridian-implementation-guide.md | 1.0 | Active | root |
| VHF-IMP-002 | viridian-figma-to-mvp-workflow-v2.md | 2.0 | Active | root |
| VHF-IMP-003 | viridian-github-claude-code-setup.md | 1.0 | Active | root |

### 2.4 Standard Documents

| Doc ID | Document Name | Version | Status | Location |
|--------|---------------|---------|--------|----------|
| VHF-STD-001 | VHF_DOCUMENT_CONTROL_REGISTER.md | 1.0 | Active | std-docs/ |
| VHF-STD-002 | VHF_CC_GITHUB_WORKFLOW.md | 1.0 | Active | std-docs/ |

---

## 3. DOCUMENT HIERARCHY

```
VHF-App-Mk3/
├── (Root Documents)              Published artifacts
│   ├── *-PRD-*.md               WHAT - Requirements
│   ├── *-HLD-*.md               HOW  - Architecture
│   ├── *-PBS-*.md               Structure breakdown
│   ├── *-WBS-*.md               Work breakdown
│   └── *.json                   Design tokens
├── std-docs/                    Standard documents
│   ├── VHF_DOCUMENT_CONTROL_REGISTER.md
│   └── VHF_CC_GITHUB_WORKFLOW.md
├── .github/
│   └── workflows/               CI/CD workflows
└── PROPOSALS/                   Future proposals
```

---

## 4. VERSION CONTROL POLICY

### 4.1 Document States

| State | Definition |
|-------|------------|
| **Draft** | Work in progress |
| **For Review** | Ready for stakeholder review |
| **Active** | Approved and current |
| **Superseded** | Replaced by newer version |

---

## 5. AUDIT TRAIL

| Date | Action | By | Notes |
|------|--------|-----|-------|
| 26-Jan-2026 | Register created | Technical Adviser | Initial version |

---

**--- END OF DOCUMENT CONTROL REGISTER ---**

*Version 1.0 | Active*
*26 January 2026*
