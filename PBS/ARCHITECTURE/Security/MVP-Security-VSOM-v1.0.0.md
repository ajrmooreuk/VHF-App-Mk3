# MVP Security VSOM — PF-Core Ontology Platform

**Version:** 1.0.0 | **Date:** 2026-02-09 | **Status:** Draft
**Epic:** E10A: Security MVP | **Aligned to:** RRR-ONT v4.0.0, MCSB-ONT v2.0.0

---

## Vision

**Deliver multi-PFI-aware security foundations for the Azlan Ontology Platform** — starting with the Ontology Manager/Visualiser as the first secured application, then extending progressively as Design Director (E8), PE E2E (E10), and PFI instance builds (E12-E16) come online.

Walk before run: simple database, simple schema, simple logins — but multi-PFI-scoped from day 1.

---

## Strategy — 3 Layers (Progressive)

| Layer | Name | Scope | When |
|-------|------|-------|------|
| **S1** | Foundation | Auth + PFI scoping + JSONB store + audit | E10A (now) |
| **S2** | Design Integration | DS tokens, Shadcn micro-components, Figma Make login/landing | E8B + E8 |
| **S3** | Agentic Expansion | Agent-led security ops, MCSB compliance automation, PFI lifecycle gates | E10 + E12+ |

---

## Objectives & Metrics

| # | Objective | Key Results | Metric | Target |
|---|-----------|-------------|--------|--------|
| O1 | Secure Ont Manager access | Users authenticate via Supabase Auth (email) | Login success rate | 99%+ |
| O2 | PFI-scoped data isolation | Users only see ontologies for their assigned PFI(s) | RLS policy violations | 0 |
| O3 | Audit trail compliance | All CRUD actions logged to append-only audit_log | Audit completeness | 100% |
| O4 | Multi-PFI readiness | Platform supports N PFI instances without schema changes | PFI count | 3+ (PF-CORE, BAIV-AIV, AIRL-AIR) |
| O5 | MCSB alignment | Security controls traceable to MCSB domains | Control coverage | IM, PA, DP, LT, NS, GS |

---

## Role Model (4 Roles)

Derived from RRR-ONT `rbac:Permission` and `rbac:AccessPolicy` entities, minimised for MVP.

| Role | Scope | Permissions | RRR-ONT Alignment |
|------|-------|-------------|-------------------|
| `pf-owner` | PF-Core + all PFIs | Full CRUD + admin + user management | PFI-OWNER L1 |
| `pfi-admin` | Assigned PFI(s) | Full CRUD within PFI + user invite | PFI-ADMIN L2 |
| `pfi-member` | Assigned PFI(s) | Read/Write ontologies within PFI | AGENCY-ANALYST L4 |
| `viewer` | Assigned PFI(s) | Read-only access | CLIENT-VIEWER L5 |

**Multi-PFI access:** A user may be `pfi-admin` for BAIV-AIV and `viewer` for AIRL-AIR simultaneously via the `user_pfi_access` junction table.

---

## Supabase Schema (5 Tables)

### Table: pfi_instances
The product/brand boundary. Every ontology belongs to exactly one PFI.

```sql
CREATE TABLE public.pfi_instances (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code        TEXT UNIQUE NOT NULL,   -- 'BAIV-AIV', 'AIRL-AIR', 'W4M-CORE', 'PF-CORE'
  name        TEXT NOT NULL,
  brand_config JSONB,                 -- DS token overrides per PFI (future S2)
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- Seed PF-Core as the shared instance
INSERT INTO public.pfi_instances (code, name) VALUES
  ('PF-CORE', 'Platform Foundation Core'),
  ('BAIV-AIV', 'Be AI Visible'),
  ('AIRL-AIR', 'AI Readiness Lab');
```

### Table: profiles
User identity with platform-level role.

```sql
CREATE TABLE public.profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id),
  display_name TEXT NOT NULL,
  role        TEXT NOT NULL CHECK (role IN ('pf-owner','pfi-admin','pfi-member','viewer')),
  created_at  TIMESTAMPTZ DEFAULT now()
);
```

### Table: user_pfi_access
Many-to-many user-to-PFI membership. Users may access 1 PFI, multiple PFIs, or PF-Core.

```sql
CREATE TABLE public.user_pfi_access (
  user_id     UUID REFERENCES public.profiles(id),
  pfi_id      UUID REFERENCES public.pfi_instances(id),
  granted_at  TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, pfi_id)
);
```

### Table: ontologies
Replaces IndexedDB for persistent, PFI-scoped ontology storage. JSONB field holds the full ontology.

```sql
CREATE TABLE public.ontologies (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pfi_id      UUID REFERENCES public.pfi_instances(id),
  name        TEXT NOT NULL,
  version     TEXT,
  ont_type    TEXT,             -- 'pfc' (shared) or 'pfi' (instance-specific)
  data        JSONB NOT NULL,
  created_by  UUID REFERENCES public.profiles(id),
  updated_by  UUID REFERENCES public.profiles(id),
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);
```

### Table: audit_log
Append-only. The non-negotiable.

```sql
CREATE TABLE public.audit_log (
  id          BIGSERIAL PRIMARY KEY,
  user_id     UUID REFERENCES public.profiles(id),
  pfi_id      UUID REFERENCES public.pfi_instances(id),
  action      TEXT NOT NULL,
  resource    TEXT,
  detail      JSONB,
  created_at  TIMESTAMPTZ DEFAULT now()
);
```

---

## Row-Level Security (RLS)

```sql
-- Ontologies: users see their PFI(s) + PF-CORE shared + pf-owner sees all
ALTER TABLE public.ontologies ENABLE ROW LEVEL SECURITY;

CREATE POLICY ont_read ON public.ontologies FOR SELECT USING (
  pfi_id IN (SELECT pfi_id FROM public.user_pfi_access WHERE user_id = auth.uid())
  OR pfi_id = (SELECT id FROM public.pfi_instances WHERE code = 'PF-CORE')
  OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'pf-owner')
);

CREATE POLICY ont_write ON public.ontologies FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.profiles p
    JOIN public.user_pfi_access a ON a.user_id = p.id
    WHERE p.id = auth.uid()
    AND a.pfi_id = ontologies.pfi_id
    AND p.role IN ('pf-owner','pfi-admin','pfi-member')
  )
);

-- Audit log: append-only (insert only, no update/delete)
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY audit_insert ON public.audit_log FOR INSERT WITH CHECK (
  auth.uid() IS NOT NULL
);

CREATE POLICY audit_read ON public.audit_log FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('pf-owner','pfi-admin'))
);
```

---

## MCSB Alignment

| MCSB Domain | Control | E10A Implementation |
|-------------|---------|---------------------|
| IM (Identity Management) | IM-1, IM-3 | Supabase Auth (email), JWT tokens |
| PA (Privileged Access) | PA-1, PA-7 | pf-owner/pfi-admin scoped roles |
| DP (Data Protection) | DP-1, DP-2 | JSONB + RLS per PFI, PF-CORE shared |
| LT (Logging & Threat Detection) | LT-1, LT-4 | audit_log append-only |
| NS (Network Security) | NS-1 | Supabase managed (HTTPS/TLS) |
| GS (Governance & Strategy) | GS-1 | PFI boundaries, user_pfi_access |

---

## RRR-ONT Correlation

The 4-role model maps to the RRR-ONT v4.0.0 RBAC entities:

| MVP Role | RRR-ONT rbac:Role | RRR-ONT rbac:Permission Actions |
|----------|--------------------|---------------------------------|
| pf-owner | PFI-OWNER (Level 1) | Create, Read, Update, Delete, Execute, Approve, Share, Export, Import, Publish |
| pfi-admin | PFI-ADMIN (Level 2) | Create, Read, Update, Delete, Execute, Share, Export, Import |
| pfi-member | AGENCY-ANALYST (Level 4) | Create, Read, Update, Export |
| viewer | CLIENT-VIEWER (Level 5) | Read |

---

## Progressive Build Path

### Sprint 1: Foundation (E10A)
- Supabase project setup
- 5-table schema + RLS policies
- Email auth integration in Ont Visualiser
- PFI selector (users see their PFIs)
- Ontology CRUD with PFI scoping (replace IndexedDB)
- Audit log writes on all mutations

### Sprint 2: Minimal UI (E10A)
- Login form (Supabase Auth UI)
- PFI context switcher in header bar
- Protected routes (viewer vs member vs admin)
- User profile display
- Audit log viewer (admin only)

### S2: Design Integration (E8B + E8)
- Shadcn micro-components extending DS tokens
- Figma Make login page + landing page
- Brand-aware theming via PFI brand_config
- Token cascade for auth UI components

### S3: Agentic Expansion (E10 + E12+)
- SA (Security Agent) for automated compliance checks
- MCSB control validation automation
- PFI lifecycle gates (create/activate/suspend/archive)
- Cross-PFI audit aggregation
- Agent execution audit trail

---

## Key Principles

1. **Multi-PFI from day 1** — not single-tenant, not BAIV-only
2. **PF-Core is the shared layer** — all PFIs inherit PFC ontologies
3. **Walk before run** — 5 tables, 4 roles, email auth, no OAuth complexity yet
4. **Append-only audit** — the non-negotiable foundation for compliance
5. **RLS not application logic** — security at the database layer, not just the UI
6. **Co-brandable** — Azlan tool works across all PFI instances via EMC brand resolution
7. **Progressive** — S1 Foundation enables S2 Design enables S3 Agentic

---

*MVP Security VSOM v1.0.0 | 09 February 2026*
*Azlan-EA-AAA Platform Foundation — Security Architecture*
