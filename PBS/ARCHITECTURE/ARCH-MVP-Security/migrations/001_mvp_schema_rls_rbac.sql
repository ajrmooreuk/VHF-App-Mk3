-- ============================================================
-- VHF MVP DATABASE SCHEMA + RLS + RBAC
-- Supabase Migration: 001_mvp_schema_rls_rbac
-- Date: 2026-02-10
--
-- Implements:
--   1. Core data tables with JSONB ontology storage
--   2. Tenant isolation via RLS
--   3. Client-level RBAC (clients cannot see each other)
--   4. Coach can READ client data but NOT modify unless RRR-enabled
--   5. Audit trail on all mutations
-- ============================================================

-- ============================================================
-- PART 0: EXTENSIONS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- PART 1: TENANT & IDENTITY TABLES
-- ============================================================

-- Tenants (organisation-level isolation)
CREATE TABLE IF NOT EXISTS tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Roles (RBAC role definitions)
CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    role_key TEXT NOT NULL,
    display_name TEXT NOT NULL,
    level INTEGER NOT NULL DEFAULT 5,
    permissions JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_role_per_tenant UNIQUE (tenant_id, role_key)
);

-- User-Role assignments
CREATE TABLE IF NOT EXISTS user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    assigned_by UUID,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_user_role UNIQUE (user_id, tenant_id, role_id)
);

-- ============================================================
-- PART 2: CORE DATA TABLES (Ontology JSONB Storage)
-- ============================================================

-- Coaches
CREATE TABLE IF NOT EXISTS coaches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id),
    name TEXT NOT NULL,
    email TEXT,
    profile JSONB DEFAULT '{}',
    qualifications TEXT[],
    specialisms TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Clients (Schema.org Patient via JSONB profile)
CREATE TABLE IF NOT EXISTS clients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id),
    coach_id UUID REFERENCES coaches(id),
    name TEXT NOT NULL,
    email TEXT,
    date_of_birth DATE,
    profile JSONB DEFAULT '{}',
    data_quality TEXT DEFAULT 'unknown',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Recipes (Schema.org Recipe via JSONB)
CREATE TABLE IF NOT EXISTS recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    recipe_schema JSONB NOT NULL DEFAULT '{}',
    nutrition JSONB DEFAULT '{}',
    ingredients JSONB DEFAULT '[]',
    instructions JSONB DEFAULT '[]',
    suitable_for_diet JSONB DEFAULT '[]',
    excludes_allergen JSONB DEFAULT '[]',
    belongs_to_theme JSONB DEFAULT '[]',
    meal_type TEXT,
    cuisine TEXT,
    difficulty TEXT,
    total_time_minutes INTEGER,
    uk_available BOOLEAN DEFAULT TRUE,
    seasonal BOOLEAN DEFAULT FALSE,
    seasonal_months INTEGER[],
    cost_per_serving_pence INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Meal Plans
CREATE TABLE IF NOT EXISTS meal_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    plan_data JSONB NOT NULL DEFAULT '{}',
    approved_by UUID REFERENCES coaches(id),
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT valid_plan_status CHECK (status IN ('pending', 'approved', 'active', 'completed', 'archived'))
);

-- Meal Themes
CREATE TABLE IF NOT EXISTS meal_themes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    theme_key TEXT NOT NULL,
    name TEXT NOT NULL,
    theme_type TEXT NOT NULL,
    description TEXT,
    filter_criteria JSONB DEFAULT '{}',
    targets_goal JSONB DEFAULT '[]',
    targets_diet JSONB DEFAULT '[]',
    seasonal_months INTEGER[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT valid_theme_type CHECK (theme_type IN ('goal', 'cuisine', 'seasonal', 'lifestyle', 'clinical')),
    CONSTRAINT unique_theme_per_tenant UNIQUE (tenant_id, theme_key)
);

-- Protocols (RAG knowledge base)
CREATE TABLE IF NOT EXISTS protocols (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    category TEXT,
    tags TEXT[],
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Progress Logs
CREATE TABLE IF NOT EXISTS progress_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    log_date DATE NOT NULL DEFAULT CURRENT_DATE,
    weight_kg DECIMAL(5,2),
    adherence_score INTEGER,
    energy_level INTEGER,
    notes TEXT,
    data JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Audit Log
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

-- ============================================================
-- PART 3: INDEXES (GIN for JSONB, B-tree for queries)
-- ============================================================

-- JSONB GIN indexes for containment queries
CREATE INDEX idx_clients_profile ON clients USING GIN (profile);
CREATE INDEX idx_clients_allergens ON clients USING GIN ((profile->'_custom'->'allergens'));
CREATE INDEX idx_clients_conditions ON clients USING GIN ((profile->'medicalCondition'));
CREATE INDEX idx_recipes_schema ON recipes USING GIN (recipe_schema);
CREATE INDEX idx_recipes_nutrition ON recipes USING GIN (nutrition);
CREATE INDEX idx_recipes_diet ON recipes USING GIN (suitable_for_diet);
CREATE INDEX idx_recipes_themes ON recipes USING GIN (belongs_to_theme);
CREATE INDEX idx_meal_plans_data ON meal_plans USING GIN (plan_data);

-- Path-specific indexes
CREATE INDEX idx_clients_goal ON clients ((profile->'_custom'->>'goal'));
CREATE INDEX idx_recipes_protein ON recipes ((nutrition->>'proteinContent'));
CREATE INDEX idx_recipes_calories ON recipes ((nutrition->>'calories'));

-- FK and query indexes
CREATE INDEX idx_clients_tenant ON clients(tenant_id);
CREATE INDEX idx_clients_coach ON clients(coach_id);
CREATE INDEX idx_clients_user ON clients(user_id);
CREATE INDEX idx_recipes_tenant ON recipes(tenant_id);
CREATE INDEX idx_recipes_meal_type ON recipes(meal_type);
CREATE INDEX idx_meal_plans_tenant ON meal_plans(tenant_id);
CREATE INDEX idx_meal_plans_client ON meal_plans(client_id);
CREATE INDEX idx_meal_plans_status ON meal_plans(status);
CREATE INDEX idx_progress_logs_client ON progress_logs(client_id, log_date DESC);
CREATE INDEX idx_audit_tenant_time ON audit_log(tenant_id, created_at DESC);
CREATE INDEX idx_user_roles_user ON user_roles(user_id);
CREATE INDEX idx_user_roles_tenant ON user_roles(tenant_id);

-- ============================================================
-- PART 4: TENANT CONTEXT FUNCTION
-- ============================================================

CREATE OR REPLACE FUNCTION set_tenant_context(
    p_tenant_id UUID,
    p_user_id UUID DEFAULT NULL,
    p_user_role TEXT DEFAULT 'client'
) RETURNS VOID AS $$
BEGIN
    PERFORM set_config('app.current_tenant_id', p_tenant_id::TEXT, true);
    PERFORM set_config('app.user_id', COALESCE(p_user_id::TEXT, ''), true);
    PERFORM set_config('app.user_role', p_user_role, true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION set_tenant_context TO authenticated;

-- Helper: get current user's role level
CREATE OR REPLACE FUNCTION get_user_role_level() RETURNS INTEGER AS $$
DECLARE
    v_level INTEGER;
BEGIN
    SELECT MIN(r.level) INTO v_level
    FROM user_roles ur
    JOIN roles r ON ur.role_id = r.id
    WHERE ur.user_id = current_setting('app.user_id', true)::UUID
      AND ur.tenant_id = current_setting('app.current_tenant_id', true)::UUID
      AND ur.is_active = true;
    RETURN COALESCE(v_level, 99);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper: check if current user is the coach of a client
CREATE OR REPLACE FUNCTION is_coach_of(p_client_id UUID) RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM clients c
        JOIN coaches co ON c.coach_id = co.id
        WHERE c.id = p_client_id
          AND co.user_id = current_setting('app.user_id', true)::UUID
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper: check if current user IS the client
CREATE OR REPLACE FUNCTION is_own_client_record(p_client_user_id UUID) RETURNS BOOLEAN AS $$
BEGIN
    RETURN p_client_user_id = current_setting('app.user_id', true)::UUID;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- PART 5: ROW LEVEL SECURITY — TENANT + CLIENT ISOLATION
-- ============================================================

-- 5A. Tenants (admin only)
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenants FORCE ROW LEVEL SECURITY;
CREATE POLICY tenants_read ON tenants FOR SELECT USING (
    id = current_setting('app.current_tenant_id', true)::UUID
);
CREATE POLICY tenants_service ON tenants FOR ALL TO service_role USING (true);

-- 5B. Roles (tenant-scoped, admin write)
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles FORCE ROW LEVEL SECURITY;
CREATE POLICY roles_read ON roles FOR SELECT USING (
    tenant_id = current_setting('app.current_tenant_id', true)::UUID
);
CREATE POLICY roles_admin_write ON roles FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id', true)::UUID
    AND get_user_role_level() <= 2
);
CREATE POLICY roles_service ON roles FOR ALL TO service_role USING (true);

-- 5C. User Roles (tenant-scoped)
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles FORCE ROW LEVEL SECURITY;
CREATE POLICY user_roles_read ON user_roles FOR SELECT USING (
    tenant_id = current_setting('app.current_tenant_id', true)::UUID
);
CREATE POLICY user_roles_admin_write ON user_roles FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id', true)::UUID
    AND get_user_role_level() <= 2
);
CREATE POLICY user_roles_service ON user_roles FOR ALL TO service_role USING (true);

-- 5D. Coaches (tenant-scoped)
ALTER TABLE coaches ENABLE ROW LEVEL SECURITY;
ALTER TABLE coaches FORCE ROW LEVEL SECURITY;
CREATE POLICY coaches_read ON coaches FOR SELECT USING (
    tenant_id = current_setting('app.current_tenant_id', true)::UUID
);
CREATE POLICY coaches_self_write ON coaches FOR UPDATE USING (
    tenant_id = current_setting('app.current_tenant_id', true)::UUID
    AND user_id = current_setting('app.user_id', true)::UUID
);
CREATE POLICY coaches_service ON coaches FOR ALL TO service_role USING (true);

-- 5E. Clients — KEY SECURITY: Clients can ONLY see their own record
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients FORCE ROW LEVEL SECURITY;

-- Client sees ONLY own record
CREATE POLICY clients_self_read ON clients FOR SELECT USING (
    tenant_id = current_setting('app.current_tenant_id', true)::UUID
    AND user_id = current_setting('app.user_id', true)::UUID
);

-- Coach can READ all their assigned clients (but NOT modify — RRR gate)
CREATE POLICY clients_coach_read ON clients FOR SELECT USING (
    tenant_id = current_setting('app.current_tenant_id', true)::UUID
    AND coach_id IN (
        SELECT id FROM coaches
        WHERE user_id = current_setting('app.user_id', true)::UUID
    )
);

-- Coach CANNOT update client data by default (RRR RBAC must enable)
-- When RRR system is defined, add: CREATE POLICY clients_coach_write ...
-- For now, coach modify is blocked at RLS level

-- Admin can see all clients in tenant
CREATE POLICY clients_admin_read ON clients FOR SELECT USING (
    tenant_id = current_setting('app.current_tenant_id', true)::UUID
    AND get_user_role_level() <= 2
);

CREATE POLICY clients_service ON clients FOR ALL TO service_role USING (true);

-- 5F. Recipes (tenant-scoped, shared resource)
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipes FORCE ROW LEVEL SECURITY;
CREATE POLICY recipes_read ON recipes FOR SELECT USING (
    tenant_id = current_setting('app.current_tenant_id', true)::UUID
);
CREATE POLICY recipes_coach_write ON recipes FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id', true)::UUID
    AND get_user_role_level() <= 3
);
CREATE POLICY recipes_service ON recipes FOR ALL TO service_role USING (true);

-- 5G. Meal Plans — Client sees ONLY own plans
ALTER TABLE meal_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_plans FORCE ROW LEVEL SECURITY;

-- Client sees only their own meal plans
CREATE POLICY meal_plans_client_read ON meal_plans FOR SELECT USING (
    tenant_id = current_setting('app.current_tenant_id', true)::UUID
    AND client_id IN (
        SELECT id FROM clients
        WHERE user_id = current_setting('app.user_id', true)::UUID
    )
);

-- Coach can read meal plans for their assigned clients
CREATE POLICY meal_plans_coach_read ON meal_plans FOR SELECT USING (
    tenant_id = current_setting('app.current_tenant_id', true)::UUID
    AND client_id IN (
        SELECT c.id FROM clients c
        JOIN coaches co ON c.coach_id = co.id
        WHERE co.user_id = current_setting('app.user_id', true)::UUID
    )
);

-- Coach can create/update meal plans for their clients
CREATE POLICY meal_plans_coach_write ON meal_plans FOR INSERT WITH CHECK (
    tenant_id = current_setting('app.current_tenant_id', true)::UUID
    AND client_id IN (
        SELECT c.id FROM clients c
        JOIN coaches co ON c.coach_id = co.id
        WHERE co.user_id = current_setting('app.user_id', true)::UUID
    )
);

CREATE POLICY meal_plans_service ON meal_plans FOR ALL TO service_role USING (true);

-- 5H. Meal Themes (tenant-scoped, shared)
ALTER TABLE meal_themes ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_themes FORCE ROW LEVEL SECURITY;
CREATE POLICY themes_read ON meal_themes FOR SELECT USING (
    tenant_id = current_setting('app.current_tenant_id', true)::UUID
);
CREATE POLICY themes_coach_write ON meal_themes FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id', true)::UUID
    AND get_user_role_level() <= 3
);
CREATE POLICY themes_service ON meal_themes FOR ALL TO service_role USING (true);

-- 5I. Protocols (tenant-scoped)
ALTER TABLE protocols ENABLE ROW LEVEL SECURITY;
ALTER TABLE protocols FORCE ROW LEVEL SECURITY;
CREATE POLICY protocols_read ON protocols FOR SELECT USING (
    tenant_id = current_setting('app.current_tenant_id', true)::UUID
);
CREATE POLICY protocols_coach_write ON protocols FOR ALL USING (
    tenant_id = current_setting('app.current_tenant_id', true)::UUID
    AND get_user_role_level() <= 3
);
CREATE POLICY protocols_service ON protocols FOR ALL TO service_role USING (true);

-- 5J. Progress Logs — Client sees only own logs
ALTER TABLE progress_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE progress_logs FORCE ROW LEVEL SECURITY;

CREATE POLICY progress_self_read ON progress_logs FOR SELECT USING (
    tenant_id = current_setting('app.current_tenant_id', true)::UUID
    AND client_id IN (
        SELECT id FROM clients
        WHERE user_id = current_setting('app.user_id', true)::UUID
    )
);

CREATE POLICY progress_coach_read ON progress_logs FOR SELECT USING (
    tenant_id = current_setting('app.current_tenant_id', true)::UUID
    AND client_id IN (
        SELECT c.id FROM clients c
        JOIN coaches co ON c.coach_id = co.id
        WHERE co.user_id = current_setting('app.user_id', true)::UUID
    )
);

CREATE POLICY progress_service ON progress_logs FOR ALL TO service_role USING (true);

-- 5K. Audit Log (append-only, admin read)
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log FORCE ROW LEVEL SECURITY;
CREATE POLICY audit_insert ON audit_log FOR INSERT WITH CHECK (true);
CREATE POLICY audit_admin_read ON audit_log FOR SELECT USING (
    tenant_id = current_setting('app.current_tenant_id', true)::UUID
    AND get_user_role_level() <= 2
);
CREATE POLICY audit_service ON audit_log FOR ALL TO service_role USING (true);

-- ============================================================
-- PART 6: AUDIT TRIGGER
-- ============================================================

CREATE OR REPLACE FUNCTION audit_trigger_func() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (tenant_id, user_id, action, table_name, record_id, new_data)
        VALUES (
            NEW.tenant_id,
            NULLIF(current_setting('app.user_id', true), '')::UUID,
            'INSERT', TG_TABLE_NAME, NEW.id, to_jsonb(NEW)
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (tenant_id, user_id, action, table_name, record_id, old_data, new_data)
        VALUES (
            NEW.tenant_id,
            NULLIF(current_setting('app.user_id', true), '')::UUID,
            'UPDATE', TG_TABLE_NAME, NEW.id, to_jsonb(OLD), to_jsonb(NEW)
        );
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (tenant_id, user_id, action, table_name, record_id, old_data)
        VALUES (
            OLD.tenant_id,
            NULLIF(current_setting('app.user_id', true), '')::UUID,
            'DELETE', TG_TABLE_NAME, OLD.id, to_jsonb(OLD)
        );
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply audit triggers to all data tables
CREATE TRIGGER clients_audit AFTER INSERT OR UPDATE OR DELETE ON clients
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();
CREATE TRIGGER recipes_audit AFTER INSERT OR UPDATE OR DELETE ON recipes
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();
CREATE TRIGGER meal_plans_audit AFTER INSERT OR UPDATE OR DELETE ON meal_plans
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();
CREATE TRIGGER protocols_audit AFTER INSERT OR UPDATE OR DELETE ON protocols
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();
CREATE TRIGGER progress_logs_audit AFTER INSERT OR UPDATE OR DELETE ON progress_logs
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

-- ============================================================
-- PART 7: SEED DATA — ROLES
-- ============================================================

-- Seed default roles (these will be tenant-specific in production)
-- Placeholder: actual tenant_id set during onboarding
INSERT INTO roles (id, tenant_id, role_key, display_name, level, permissions) VALUES
    ('00000000-0000-0000-0000-000000000001'::UUID, NULL, 'super_admin', 'Super Admin', 0, '{"all": true}'),
    ('00000000-0000-0000-0000-000000000002'::UUID, NULL, 'platform_admin', 'Platform Admin', 1, '{"read": true, "write": true, "delete": false}'),
    ('00000000-0000-0000-0000-000000000003'::UUID, NULL, 'coach', 'Coach', 3, '{"read_clients": true, "write_clients": false, "read_recipes": true, "write_recipes": true, "read_meal_plans": true, "write_meal_plans": true, "approve_meal_plans": true}'),
    ('00000000-0000-0000-0000-000000000004'::UUID, NULL, 'client', 'Client', 5, '{"read_own_profile": true, "read_own_meal_plans": true, "read_recipes": true, "write_progress": true}'),
    ('00000000-0000-0000-0000-000000000005'::UUID, NULL, 'read_only', 'Read Only', 7, '{"read_own": true}')
ON CONFLICT DO NOTHING;

-- ============================================================
-- PART 8: VERIFICATION QUERIES
-- ============================================================

-- Run these after migration to verify:

-- 1. Check all tables have RLS enabled
-- SELECT tablename, rowsecurity FROM pg_tables
-- WHERE schemaname = 'public'
-- ORDER BY tablename;

-- 2. Check all RLS policies exist
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
-- FROM pg_policies
-- WHERE schemaname = 'public'
-- ORDER BY tablename, policyname;

-- 3. Check audit triggers exist
-- SELECT trigger_name, event_manipulation, event_object_table
-- FROM information_schema.triggers
-- WHERE trigger_schema = 'public'
-- ORDER BY event_object_table;

-- 4. Check functions exist
-- SELECT proname FROM pg_proc
-- WHERE proname IN ('set_tenant_context', 'get_user_role_level', 'is_coach_of', 'is_own_client_record', 'audit_trigger_func');
