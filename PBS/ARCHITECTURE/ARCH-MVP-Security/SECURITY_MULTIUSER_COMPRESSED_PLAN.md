# Security + Multi-User MVP: Compressed Implementation Plan

## Realistic Timeline with Prep Work Done

**Total Effort:** 2-3 days (not weeks)  
**Prerequisite:** All SQL templates, patterns, and architecture already defined

---

## Day 1: Core Security (4-6 hours)

### Morning (2-3 hrs)

| Task | Time | Deliverable |
|------|------|-------------|
| Run table inventory query | 15 min | List of tables needing RLS |
| Generate RLS migration from template | 30 min | Single SQL file |
| Add `set_tenant_context()` | 15 min | Copy from template |
| Add `audit_log` + trigger | 30 min | Copy from template |
| Apply migration to Supabase | 15 min | Execute in SQL Editor |
| Run RLS audit verification | 15 min | Confirm 100% coverage |

### Afternoon (2-3 hrs)

| Task | Time | Deliverable |
|------|------|-------------|
| Backend context middleware | 45 min | `setTenantContext.ts` |
| Integrate into API routes | 45 min | All routes call context |
| Quick security test | 30 min | Cross-tenant blocked |
| Commit + document | 30 min | PR ready |

**Day 1 Exit:** MVP Security complete ✅

---

## Day 2: Multi-User Foundation (4-6 hours)

### Morning (2-3 hrs)

| Task | Time | Deliverable |
|------|------|-------------|
| Create `organization_cycle_state` table | 20 min | Migration file |
| Create `user_presence` table | 20 min | Migration file |
| Create `dataset_edit_locks` table | 20 min | Migration file |
| Create `organization_activity` table | 20 min | Migration file |
| Apply RLS to all 4 tables (template) | 20 min | Same pattern as Day 1 |
| Apply migration | 15 min | Execute |

### Afternoon (2-3 hrs)

| Task | Time | Deliverable |
|------|------|-------------|
| `advance_cycle_stage()` function | 30 min | Copy from plan |
| Basic presence API (2 endpoints) | 45 min | `/presence`, `/presence/heartbeat` |
| Lock acquire/release API | 45 min | `/locks` endpoints |
| Quick integration test | 30 min | Verify flows |

**Day 2 Exit:** Multi-User foundation complete ✅

---

## Day 3: Polish + Ship (2-4 hours)

| Task | Time | Deliverable |
|------|------|-------------|
| Dashboard status component | 1-2 hrs | Shows cycle state |
| "Who's online" indicator | 30 min | Basic presence UI |
| Activity logging triggers | 30 min | Auto-log key actions |
| Final testing | 30 min | End-to-end verify |
| Deploy to production | 30 min | Ship it |

**Day 3 Exit:** Live in production ✅

---

## Combined Migration File (Day 1 + Day 2)

```sql
-- ============================================================
-- COMBINED SECURITY + MULTI-USER MVP MIGRATION
-- Execute in Supabase SQL Editor
-- ============================================================

-- ============================================================
-- PART 1: MVP SECURITY (Day 1)
-- ============================================================

-- 1A. Context Function
CREATE OR REPLACE FUNCTION set_tenant_context(
    p_tenant_id UUID,
    p_user_id UUID DEFAULT NULL,
    p_user_role TEXT DEFAULT 'member'
) RETURNS VOID AS $$
BEGIN
    PERFORM set_config('app.current_tenant_id', p_tenant_id::TEXT, false);
    PERFORM set_config('app.user_id', COALESCE(p_user_id::TEXT, ''), false);
    PERFORM set_config('app.user_role', p_user_role, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION set_tenant_context TO authenticated;

-- 1B. Audit Log
CREATE TABLE IF NOT EXISTS audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID,
    user_id UUID,
    action TEXT NOT NULL,
    table_name TEXT,
    record_id UUID,
    old_data JSONB,
    new_data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_tenant_time ON audit_log(tenant_id, created_at DESC);

ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY audit_log_insert ON audit_log FOR INSERT WITH CHECK (true);
CREATE POLICY audit_log_read ON audit_log FOR SELECT USING (
    tenant_id = current_setting('app.current_tenant_id', true)::UUID
    OR current_setting('app.user_role', true) = 'platform_owner'
);

-- 1C. Audit Trigger Function
CREATE OR REPLACE FUNCTION audit_trigger_func() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (tenant_id, user_id, action, table_name, record_id, new_data)
        VALUES (NEW.tenant_id, current_setting('app.user_id', true)::UUID, 'create', TG_TABLE_NAME, NEW.id, to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (tenant_id, user_id, action, table_name, record_id, old_data, new_data)
        VALUES (NEW.tenant_id, current_setting('app.user_id', true)::UUID, 'update', TG_TABLE_NAME, NEW.id, to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (tenant_id, user_id, action, table_name, record_id, old_data)
        VALUES (OLD.tenant_id, current_setting('app.user_id', true)::UUID, 'delete', TG_TABLE_NAME, OLD.id, to_jsonb(OLD));
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 1D. Apply RLS to existing tables (add your tables here)
-- Template for each table:
/*
ALTER TABLE {table_name} ENABLE ROW LEVEL SECURITY;
ALTER TABLE {table_name} FORCE ROW LEVEL SECURITY;
CREATE POLICY {table_name}_tenant_isolation ON {table_name} FOR ALL 
    USING (tenant_id = current_setting('app.current_tenant_id', true)::UUID);
CREATE POLICY {table_name}_service_bypass ON {table_name} FOR ALL TO service_role USING (true);
*/

-- ============================================================
-- PART 2: MULTI-USER FOUNDATION (Day 2)
-- ============================================================

-- 2A. Organization Cycle State
CREATE TABLE IF NOT EXISTS organization_cycle_state (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    current_stage TEXT NOT NULL DEFAULT 'discovery',
    stage_status TEXT NOT NULL DEFAULT 'not_started',
    stage_started_at TIMESTAMPTZ,
    stage_owner_user_id UUID,
    health_indicators JSONB DEFAULT '{}',
    cycle_number INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT valid_stage CHECK (current_stage IN ('discovery','audit','gap_analysis','ideation','planning','execution')),
    CONSTRAINT valid_status CHECK (stage_status IN ('not_started','in_progress','blocked','completed')),
    CONSTRAINT one_per_tenant UNIQUE (tenant_id)
);

ALTER TABLE organization_cycle_state ENABLE ROW LEVEL SECURITY;
CREATE POLICY org_cycle_tenant ON organization_cycle_state FOR ALL 
    USING (tenant_id = current_setting('app.current_tenant_id', true)::UUID);
CREATE POLICY org_cycle_service ON organization_cycle_state FOR ALL TO service_role USING (true);

-- 2B. User Presence
CREATE TABLE IF NOT EXISTS user_presence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    current_view TEXT,
    current_resource_id UUID,
    status TEXT DEFAULT 'online',
    last_heartbeat_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT one_presence_per_user UNIQUE (tenant_id, user_id)
);

CREATE INDEX idx_presence_tenant ON user_presence(tenant_id, status);

ALTER TABLE user_presence ENABLE ROW LEVEL SECURITY;
CREATE POLICY presence_tenant ON user_presence FOR ALL 
    USING (tenant_id = current_setting('app.current_tenant_id', true)::UUID);
CREATE POLICY presence_service ON user_presence FOR ALL TO service_role USING (true);

-- 2C. Dataset Edit Locks
CREATE TABLE IF NOT EXISTS dataset_edit_locks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    dataset_type TEXT NOT NULL,
    dataset_id UUID NOT NULL,
    locked_by_user_id UUID NOT NULL,
    locked_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '30 minutes',
    is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_locks_active ON dataset_edit_locks(tenant_id, dataset_type, dataset_id) WHERE is_active;

ALTER TABLE dataset_edit_locks ENABLE ROW LEVEL SECURITY;
CREATE POLICY locks_tenant ON dataset_edit_locks FOR ALL 
    USING (tenant_id = current_setting('app.current_tenant_id', true)::UUID);
CREATE POLICY locks_service ON dataset_edit_locks FOR ALL TO service_role USING (true);

-- 2D. Organization Activity
CREATE TABLE IF NOT EXISTS organization_activity (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    actor_type TEXT NOT NULL,
    actor_id TEXT,
    actor_name TEXT,
    action_type TEXT NOT NULL,
    action_category TEXT NOT NULL,
    target_type TEXT,
    target_id UUID,
    summary TEXT NOT NULL,
    details JSONB,
    is_highlight BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_activity_feed ON organization_activity(tenant_id, created_at DESC);

ALTER TABLE organization_activity ENABLE ROW LEVEL SECURITY;
CREATE POLICY activity_tenant ON organization_activity FOR ALL 
    USING (tenant_id = current_setting('app.current_tenant_id', true)::UUID);
CREATE POLICY activity_service ON organization_activity FOR ALL TO service_role USING (true);

-- 2E. Cycle Stage Advancement Function
CREATE OR REPLACE FUNCTION advance_cycle_stage(p_tenant_id UUID, p_user_id UUID)
RETURNS TABLE (success BOOLEAN, new_stage TEXT, message TEXT) AS $$
DECLARE
    v_current TEXT;
    v_next TEXT;
    v_role TEXT;
BEGIN
    SELECT current_stage INTO v_current FROM organization_cycle_state WHERE tenant_id = p_tenant_id;
    SELECT role INTO v_role FROM tenant_users WHERE tenant_id = p_tenant_id AND user_id = p_user_id;
    
    IF v_role NOT IN ('owner', 'admin') THEN
        RETURN QUERY SELECT FALSE, v_current, 'Permission denied';
        RETURN;
    END IF;
    
    v_next := CASE v_current
        WHEN 'discovery' THEN 'audit'
        WHEN 'audit' THEN 'gap_analysis'
        WHEN 'gap_analysis' THEN 'ideation'
        WHEN 'ideation' THEN 'planning'
        WHEN 'planning' THEN 'execution'
        WHEN 'execution' THEN 'audit'
        ELSE 'discovery'
    END;
    
    UPDATE organization_cycle_state 
    SET current_stage = v_next, stage_status = 'not_started', 
        stage_started_at = NOW(), updated_at = NOW()
    WHERE tenant_id = p_tenant_id;
    
    INSERT INTO organization_activity (tenant_id, actor_type, actor_id, action_type, action_category, summary, is_highlight)
    VALUES (p_tenant_id, 'user', p_user_id::TEXT, 'advanced', 'cycle', 'Advanced to ' || v_next, TRUE);
    
    RETURN QUERY SELECT TRUE, v_next, 'Advanced to ' || v_next;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- VERIFICATION QUERIES (Run after migration)
-- ============================================================

-- Check RLS coverage
SELECT tablename, rowsecurity FROM pg_tables 
WHERE schemaname = 'public' AND tablename IN (
    'audit_log', 'organization_cycle_state', 'user_presence', 
    'dataset_edit_locks', 'organization_activity'
);

-- Check functions exist
SELECT proname FROM pg_proc WHERE proname IN ('set_tenant_context', 'advance_cycle_stage', 'audit_trigger_func');
```

---

## Summary: Actual Effort

| Phase | Original Estimate | Realistic | Why |
|-------|-------------------|-----------|-----|
| MVP Security | 2 weeks | **4-6 hours** | Templates ready, copy-paste |
| Multi-User Phase 1 | 10 hours | **3-4 hours** | Tables defined, patterns same |
| Multi-User Phase 2 | 16 hours | **2-3 hours** | Simple CRUD endpoints |
| Multi-User Phase 3 | 14 hours | **2-3 hours** | Lock logic straightforward |
| Multi-User Phase 4 | 20 hours | **2-3 hours** | Activity = audit pattern |

**Revised Total: 2-3 days, not 5+ weeks**

The original estimates were enterprise-scale waterfall assumptions. With prep work done and patterns defined, this is sprint-able in a focused push.

---

## Checklist: Can Ship in 3 Days

```markdown
## Day 1 Exit Criteria
- [ ] RLS on all tables
- [ ] set_tenant_context() working
- [ ] audit_log capturing changes
- [ ] Backend middleware integrated

## Day 2 Exit Criteria  
- [ ] 4 new tables created with RLS
- [ ] advance_cycle_stage() working
- [ ] Presence heartbeat API working
- [ ] Lock acquire/release working

## Day 3 Exit Criteria
- [ ] Dashboard shows org status
- [ ] "Online now" indicator works
- [ ] Activity feed populates
- [ ] Deployed to production
```
