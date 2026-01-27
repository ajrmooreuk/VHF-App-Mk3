# Design System E2E Implementation Plan

## Epic #173: Design System E2E to Production

---

## 1. Current State: What's Built

```mermaid
flowchart LR
    subgraph DONE["COMPLETED - Specs & Design"]
        direction TB
        F1["Figma Variables v3
        bXCyfNwzc8Z9kEeFIeIB8C
        88 colors / 8 palettes"]
        F2["3-Tier Token Cascade
        Primitives → Semantics → Components"]
        F3["TypeScript Interfaces
        PrimitivesSchema / SemanticsSchema / ComponentsSchema"]
        F4["DB Schema SQL
        10 tables + RLS + resolve_token()"]
        F5["Edge Function Code
        Extraction + Validation + Agent"]
        F6["React Provider + Hooks
        DesignSystemProvider / useToken / useComponentTokens"]
        F7["Agent Tool Definitions
        get_token_value / list_available_tokens"]
    end

    style DONE fill:#c5fff5,stroke:#019587,stroke-width:3px
```

---

## 2. E2E Workflow: Figma → Production

```mermaid
flowchart TB
    subgraph SOURCE["SOURCE OF TRUTH"]
        FIGMA["Figma Variables v3
        8 Palettes × 11 Scales
        Typography / Spacing / Radius"]
    end

    subgraph EXTRACT["EXTRACTION PIPELINE"]
        MCP["MCP get_variable_defs()
        Raw JSON extraction"]
        TRANSFORM["Transformer
        Figma vars → 3-tier schema"]
        VALIDATE["Validator
        Check palettes, scales, $refs"]
    end

    subgraph STORE["SUPABASE RUNTIME STORE"]
        DS_TABLE["design_system table
        primitives JSONB
        semantics JSONB
        components JSONB"]
        RESOLVE["resolve_token() SQL
        3-tier cascade resolution"]
    end

    subgraph CONSUME["CONSUMERS"]
        PROVIDER["DesignSystemProvider
        Fetch active DS on load"]
        CSS["CSS Variable Injection
        :root { --color-primary: value }"]
        HOOKS["useToken / useComponentTokens
        Runtime resolution in React"]
        COMPONENTS["Token-Driven Components
        Button / Card / Input / Alert"]
        AGENT["Agent Tools
        get_token_value
        list_available_tokens"]
    end

    FIGMA -->|"On publish"| MCP
    MCP --> TRANSFORM
    TRANSFORM --> VALIDATE
    VALIDATE -->|"Valid"| DS_TABLE
    DS_TABLE --> RESOLVE
    DS_TABLE --> PROVIDER
    PROVIDER --> CSS
    PROVIDER --> HOOKS
    HOOKS --> COMPONENTS
    DS_TABLE --> AGENT

    style SOURCE fill:#e2f7ff,stroke:#00a4bf,stroke-width:3px
    style EXTRACT fill:#feedeb,stroke:#e84e1c,stroke-width:3px
    style STORE fill:#c5fff5,stroke:#019587,stroke-width:3px
    style CONSUME fill:#f0e7fe,stroke:#6f0eb0,stroke-width:3px
```

---

## 3. Epic → Feature → Story Hierarchy

```mermaid
graph TD
    EPIC["#173 Epic
    Design System E2E to Production"]

    F1["#174 Feature 1
    Supabase Infrastructure Setup"]
    F2["#175 Feature 2
    Figma Token Extraction Pipeline"]
    F3["#176 Feature 3
    Next.js Runtime Integration"]
    F4["#177 Feature 4
    Agent Design System Tools"]
    F5["#178 Feature 5
    Reusable Cross-Repo Template"]

    EPIC --> F1
    EPIC --> F2
    EPIC --> F3
    EPIC --> F4
    EPIC --> F5

    F1S1["Story: Create Supabase project
    + enable extensions"]
    F1S2["Story: Run design_system
    table migration"]
    F1S3["Story: Apply RLS policies
    + create functions"]
    F1S4["Story: Verify with
    test queries"]

    F2S1["Story: Extract vars from
    Figma via MCP"]
    F2S2["Story: Build transformer
    Figma → 3-tier JSONB"]
    F2S3["Story: Deploy extraction
    Edge Function"]
    F2S4["Story: Seed + activate
    token version"]

    F3S1["Story: Scaffold Next.js 14
    + Shadcn"]
    F3S2["Story: Implement Provider
    + hooks + CSS injection"]
    F3S3["Story: Build token-driven
    Button/Card/Input"]
    F3S4["Story: Demo page with
    live resolution"]

    F4S1["Story: Deploy agent-process
    Edge Function"]
    F4S2["Story: Implement design
    system tools"]
    F4S3["Story: Build AgentChat
    component"]
    F4S4["Story: Test multi-turn
    with tool calls"]

    F5S1["Story: Package as
    portable template"]
    F5S2["Story: Create init script
    for new projects"]
    F5S3["Story: Document as
    PBS standard procedure"]
    F5S4["Story: Test on second
    repo/project"]

    F1 --> F1S1 --> F1S2 --> F1S3 --> F1S4
    F2 --> F2S1 --> F2S2 --> F2S3 --> F2S4
    F3 --> F3S1 --> F3S2 --> F3S3 --> F3S4
    F4 --> F4S1 --> F4S2 --> F4S3 --> F4S4
    F5 --> F5S1 --> F5S2 --> F5S3 --> F5S4

    style EPIC fill:#e2f7ff,stroke:#00a4bf,stroke-width:3px
    style F1 fill:#feedeb,stroke:#e84e1c,stroke-width:2px
    style F2 fill:#feedeb,stroke:#e84e1c,stroke-width:2px
    style F3 fill:#feedeb,stroke:#e84e1c,stroke-width:2px
    style F4 fill:#feedeb,stroke:#e84e1c,stroke-width:2px
    style F5 fill:#feedeb,stroke:#e84e1c,stroke-width:2px
```

---

## 4. Dependency Chain

```mermaid
flowchart LR
    F1["#174
    Supabase Setup"]
    F2["#175
    Figma Extraction"]
    F3["#176
    Next.js Runtime"]
    F4["#177
    Agent Tools"]
    F5["#178
    Reusable Template"]

    F1 --> F2
    F1 --> F3
    F2 --> F3
    F1 --> F4
    F2 --> F4
    F3 --> F5
    F4 --> F5

    BLOCK{{"BLOCKED
    Awaiting Supabase access
    from team member"}}

    BLOCK -.->|"Unblocks"| F1

    ALT["ALTERNATIVE
    Test on smaller product first
    Own Supabase project"]

    ALT -.->|"Parallel path"| F1

    style BLOCK fill:#ffe9f0,stroke:#cf057d,stroke-width:2px
    style ALT fill:#fffad1,stroke:#cec528,stroke-width:2px
    style F1 fill:#feedeb,stroke:#e84e1c
    style F2 fill:#feedeb,stroke:#e84e1c
    style F3 fill:#c5fff5,stroke:#019587
    style F4 fill:#eaeefb,stroke:#3b6fcc
    style F5 fill:#f0e7fe,stroke:#6f0eb0
```

---

## 5. Recommended Path: Test Product First

Since Supabase access is blocked on the main BAIV project, run the E2E prototype on a smaller test product:

```mermaid
flowchart TB
    subgraph TEST["TEST PRODUCT (Unblocked)"]
        T1["Create own Supabase project
        Free tier sufficient"]
        T2["Use BAIV Figma file
        or create minimal test tokens"]
        T3["Run full E2E:
        Extract → Store → Resolve → Render"]
        T4["Validate the pipeline works
        end-to-end"]
    end

    subgraph MIGRATE["MIGRATE TO BAIV (When unblocked)"]
        M1["Run same migration SQL
        on BAIV Supabase"]
        M2["Point extraction at
        BAIV Figma file"]
        M3["Deploy Edge Functions
        to BAIV project"]
        M4["Production ready"]
    end

    TEST --> MIGRATE

    style TEST fill:#fffad1,stroke:#cec528,stroke-width:3px
    style MIGRATE fill:#c5fff5,stroke:#019587,stroke-width:3px
```

### Test Product Setup

| Item | Value |
|------|-------|
| Supabase | New free-tier project (your own account) |
| Figma | Use existing BAIV file `bXCyfNwzc8Z9kEeFIeIB8C` or subset |
| Repo | New repo e.g. `TeamBAIV/ds-e2e-prototype` or branch in PF-Core-BAIV |
| Scope | Features #174 + #175 + #176 (infra + extraction + runtime) |
| Goal | Prove token cascade resolves from Figma → DB → React component |

### What This Proves

| Question | Validated By |
|----------|-------------|
| Does MCP extraction produce valid JSONB? | Feature #175 |
| Does resolve_token() cascade correctly? | Feature #174 |
| Do components render from DB tokens? | Feature #176 |
| Can we change Figma → see UI update? | Full loop |
| Is the process portable? | Migrating to BAIV proves #178 |

---

## 6. Issue Summary

| # | Type | Title | Status | Blocked By |
|---|------|-------|--------|------------|
| [#173](https://github.com/TeamBAIV/PF-Core-BAIV/issues/173) | Epic | Design System E2E to Production | Open | - |
| [#174](https://github.com/TeamBAIV/PF-Core-BAIV/issues/174) | Feature | Supabase Infrastructure Setup | Open | Supabase access |
| [#175](https://github.com/TeamBAIV/PF-Core-BAIV/issues/175) | Feature | Figma Token Extraction Pipeline | Open | #174 |
| [#176](https://github.com/TeamBAIV/PF-Core-BAIV/issues/176) | Feature | Next.js Runtime Integration | Open | #174, #175 |
| [#177](https://github.com/TeamBAIV/PF-Core-BAIV/issues/177) | Feature | Agent Design System Tools | Open | #174, #175 |
| [#178](https://github.com/TeamBAIV/PF-Core-BAIV/issues/178) | Feature | Reusable Cross-Repo Template | Open | #174-#177 |

---

*Plan Version: 1.0.0*
*Created: 2026-01-27*
*Epic: #173*
*Project: ajrmooreuk/projects/22*
