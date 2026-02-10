# RBAC Permission Matrix — PF-Core & PF-Instance

## Version: 1.0.0 | Date: 2026-02-09 | Epic: 9B

---

## 1. Core Role Hierarchy

```
Level 0: SuperAdmin (Platform-wide)
  └── Level 1: PlatformAdmin (Cross-instance)
        └── Level 2: InstanceAdmin (Tenant-scoped)
              └── Level 3: InstanceUser (Feature-scoped)
                    └── Level 5: ReadOnly (View-only)

Level 2: AgentOperator (Agent-scoped, parallel track)
Level 4: ExternalAPI (API-scoped, parallel track)
```

---

## 2. Core Permission Matrix

### Data Permissions (CRUD by Table Category)

| Table Category | SuperAdmin | PlatformAdmin | InstanceAdmin | InstanceUser | ReadOnly | AgentOperator | ExternalAPI |
|---------------|:----------:|:-------------:|:-------------:|:------------:|:--------:|:-------------:|:-----------:|
| **Platform Config** | CRUD | CRU | R | — | — | R | — |
| **Instance Config** | CRUD | CRU | CRUD | R | R | R | — |
| **Tenant Data** | CRUD | R (cross) | CRUD (own) | CRUD (own) | R (own) | R (scoped) | R (scoped) |
| **User Management** | CRUD | CRU | CRUD (own tenant) | R (own) | R (own) | — | — |
| **Role Definitions** | CRUD | R | CRU (instance roles) | R | R | R | — |
| **Security Config** | CRUD | R | R | — | — | R | — |
| **Audit Logs** | CRUD | R | R (own tenant) | — | — | W (append) | — |
| **Security Events** | CRUD | R | R (own tenant) | — | — | W (append) | — |
| **Agent Identities** | CRUD | R | R | — | — | R (own) | — |
| **Ontology Registry** | CRUD | CRU | R | R | R | R | R |
| **Workflow State** | CRUD | R | CRUD (own tenant) | CRUD (assigned) | R | CRU (scoped) | — |

**Legend:** C=Create, R=Read, U=Update, D=Delete, — = No Access

### Function Permissions

| Function | SuperAdmin | PlatformAdmin | InstanceAdmin | InstanceUser | AgentOperator |
|----------|:----------:|:-------------:|:-------------:|:------------:|:-------------:|
| `set_tenant_context()` | ✓ (any) | ✓ (any) | ✓ (own) | ✓ (own) | ✓ (assigned) |
| `advance_cycle_stage()` | ✓ | ✓ | ✓ | ✓ (if authorised) | ✓ (if workflow allows) |
| `provision_instance()` | ✓ | ✓ | — | — | — |
| `manage_roles()` | ✓ | — | ✓ (instance roles) | — | — |
| `manage_agent_trust()` | ✓ | — | — | — | — |
| `view_audit_logs()` | ✓ | ✓ | ✓ (own tenant) | — | — |
| `invoke_agent()` | ✓ | ✓ | ✓ | ✓ (permitted agents) | ✓ (per trust matrix) |
| `export_data()` | ✓ | ✓ | ✓ (own tenant) | ✓ (own data) | — |
| `modify_security_policy()` | ✓ | — | — | — | — |

### Navigation Permissions

| UI Section | SuperAdmin | PlatformAdmin | InstanceAdmin | InstanceUser | ReadOnly |
|-----------|:----------:|:-------------:|:-------------:|:------------:|:--------:|
| Platform Dashboard | ✓ | ✓ | — | — | — |
| Instance Dashboard | ✓ | ✓ | ✓ | ✓ | ✓ |
| User Management | ✓ | ✓ | ✓ | — | — |
| Role Management | ✓ | — | ✓ | — | — |
| Security Settings | ✓ | ✓ | ✓ (limited) | — | — |
| Audit Viewer | ✓ | ✓ | ✓ | — | — |
| Agent Manager | ✓ | ✓ | ✓ | — | — |
| Instance Config | ✓ | ✓ | ✓ | — | — |
| Product Features | ✓ | ✓ | ✓ | ✓ | ✓ (view) |
| Reports & Analytics | ✓ | ✓ | ✓ | ✓ | ✓ |
| API Management | ✓ | ✓ | ✓ | — | — |

---

## 3. PF-Instance Role Extensions (BAIV Example)

### BAIV Instance-Specific Roles

| Instance Role | Extends Core Role | Additional Permissions |
|--------------|-------------------|----------------------|
| `baiv:BrandStrategist` | InstanceUser | CRUD on brand_strategies, CRU on campaigns, R on analytics |
| `baiv:ContentCreator` | InstanceUser | CRUD on content_assets, R on brand_strategies, CRU on content_workflows |
| `baiv:AnalyticsViewer` | ReadOnly | R on all analytics tables, R on reports, R on dashboards |
| `baiv:CampaignManager` | InstanceUser | CRUD on campaigns, CRU on budgets, R on all content, invoke campaign agents |
| `baiv:ClientAdmin` | InstanceAdmin | Full instance admin + CRUD on client-specific configs |

### BAIV Permission Matrix (Additive to Core)

| BAIV Table | BrandStrategist | ContentCreator | AnalyticsViewer | CampaignManager |
|-----------|:--------------:|:--------------:|:---------------:|:---------------:|
| brand_strategies | CRUD | R | R | R |
| content_assets | R | CRUD | R | R |
| campaigns | R | R | R | CRUD |
| analytics_data | R | R | R | R |
| ai_visibility_scores | R | R | R | R |
| budgets | R | — | R | CRU |

---

## 4. Agent Permission Matrix

| Agent | Trust Level | Can Read | Can Write | Can Invoke | Audit Required |
|-------|:----------:|----------|-----------|------------|:--------------:|
| PF Manager | Full | All ontologies, all instance configs | Workflow state, agent assignments | All PF agents | ✓ |
| PF Architect | Full | All ontologies, architecture defs | Architecture decisions, ADRs | PF Builder, PF OAA, Gap Analysis | ✓ |
| PF Builder | Scoped | Assigned work items, tech specs | Code artifacts, build state | PF Designer | ✓ |
| PF Security Manager | Advisory | Security config, audit logs, events | Security events, advisory reports | PF Architect (advisory only) | ✓ |
| PF VE (Value Engineer) | Scoped | Value props, metrics, KPIs | Value assessments, recommendations | PF CE | ✓ |
| PF CE (Context Engineer) | Scoped | Context data, ontologies | Context maps, entity relations | — | ✓ |
| PF OAA | Readonly | All ontologies | Ontology recommendations (not commits) | — | ✓ |
| PF Designer | Scoped | Design system, UI components | Design artifacts | — | ✓ |
| PF Gap Analysis | Scoped | All assessments, maturity data | Gap reports, recommendations | — | ✓ |
| PE Process Engineer | Advisory | Process defs, workflow state | Process improvements (pending approval) | PF Security Manager (advisory) | ✓ |

---

## 5. RLS Policy Definitions (Supabase)

### Universal Tenant Isolation Pattern

```sql
-- Applied to ALL tenant-scoped tables
CREATE POLICY "tenant_isolation" ON {table_name}
  USING (tenant_id = current_setting('app.tenant_id')::uuid)
  WITH CHECK (tenant_id = current_setting('app.tenant_id')::uuid);
```

### Role-Based Read/Write Policies

```sql
-- Example: instance_config table
CREATE POLICY "instance_admin_rw" ON instance_config
  FOR ALL
  USING (
    tenant_id = current_setting('app.tenant_id')::uuid
    AND EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN pf_roles pr ON ur.role_id = pr.id
      WHERE ur.user_id = auth.uid()
        AND ur.tenant_id = current_setting('app.tenant_id')::uuid
        AND pr.level <= 2  -- InstanceAdmin or above
        AND ur.is_active = true
    )
  );

-- ReadOnly users
CREATE POLICY "readonly_read" ON instance_config
  FOR SELECT
  USING (
    tenant_id = current_setting('app.tenant_id')::uuid
    AND EXISTS (
      SELECT 1 FROM user_roles ur
      WHERE ur.user_id = auth.uid()
        AND ur.tenant_id = current_setting('app.tenant_id')::uuid
        AND ur.is_active = true
    )
  );
```

### Audit Log Write Policy

```sql
-- Only system triggers can write to audit_log
CREATE POLICY "system_write_only" ON audit_log
  FOR INSERT
  USING (true)  -- Trigger-based, not user-invoked
  WITH CHECK (true);

-- Admins can read their tenant's logs
CREATE POLICY "admin_read" ON audit_log
  FOR SELECT
  USING (
    tenant_id = current_setting('app.tenant_id')::uuid
    AND EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN pf_roles pr ON ur.role_id = pr.id
      WHERE ur.user_id = auth.uid()
        AND pr.level <= 2
    )
  );
```

---

## 6. DB Schema DDL (Security Tables)

```sql
-- Core role definitions
CREATE TABLE pf_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role_key VARCHAR(50) UNIQUE NOT NULL,
  display_name VARCHAR(100) NOT NULL,
  description TEXT,
  level INTEGER NOT NULL CHECK (level >= 0 AND level <= 10),
  scope VARCHAR(20) NOT NULL CHECK (scope IN ('Platform', 'Instance', 'Agent', 'API')),
  ontology_id VARCHAR(200),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Instance-specific role extensions
CREATE TABLE pfi_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instance_id UUID NOT NULL REFERENCES pf_instances(id),
  parent_role_id UUID NOT NULL REFERENCES pf_roles(id),
  role_key VARCHAR(80) UNIQUE NOT NULL,
  display_name VARCHAR(100) NOT NULL,
  description TEXT,
  permissions_json JSONB DEFAULT '{}',
  ontology_id VARCHAR(200),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Permission assignments
CREATE TABLE role_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role_id UUID NOT NULL,
  permission_key VARCHAR(100) NOT NULL,
  resource_type VARCHAR(50) NOT NULL,
  resource_id VARCHAR(200),
  actions JSONB NOT NULL DEFAULT '[]',
  conditions_json JSONB DEFAULT '{}',
  ontology_id VARCHAR(200),
  created_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT fk_role FOREIGN KEY (role_id) REFERENCES pf_roles(id) ON DELETE CASCADE
);

-- User-to-role assignments
CREATE TABLE user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  role_id UUID NOT NULL REFERENCES pf_roles(id),
  tenant_id UUID NOT NULL,
  instance_id UUID,
  assigned_by UUID REFERENCES auth.users(id),
  valid_from TIMESTAMPTZ DEFAULT now(),
  valid_until TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, role_id, tenant_id)
);

-- Agent security identities
CREATE TABLE agent_identities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_type VARCHAR(50) NOT NULL,
  agent_version VARCHAR(20) NOT NULL,
  role_id UUID REFERENCES pf_roles(id),
  trust_level VARCHAR(20) NOT NULL CHECK (trust_level IN ('Full', 'Advisory', 'Scoped', 'Readonly')),
  allowed_actions JSONB DEFAULT '[]',
  denied_actions JSONB DEFAULT '[]',
  ontology_id VARCHAR(200),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Security events
CREATE TABLE security_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type VARCHAR(50) NOT NULL,
  severity VARCHAR(20) NOT NULL CHECK (severity IN ('info', 'warning', 'error', 'critical')),
  principal_id UUID,
  principal_type VARCHAR(20) NOT NULL CHECK (principal_type IN ('human', 'agent', 'system', 'api')),
  tenant_id UUID,
  resource_type VARCHAR(50),
  resource_id VARCHAR(200),
  action VARCHAR(100),
  outcome VARCHAR(20) CHECK (outcome IN ('success', 'denied', 'error', 'escalated')),
  details_json JSONB DEFAULT '{}',
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- General audit log
CREATE TABLE audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  table_name VARCHAR(100) NOT NULL,
  record_id UUID NOT NULL,
  action VARCHAR(10) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
  old_values JSONB,
  new_values JSONB,
  changed_by UUID,
  tenant_id UUID NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for performance
CREATE INDEX idx_security_events_type ON security_events(event_type);
CREATE INDEX idx_security_events_principal ON security_events(principal_id);
CREATE INDEX idx_security_events_tenant ON security_events(tenant_id);
CREATE INDEX idx_security_events_created ON security_events(created_at);
CREATE INDEX idx_audit_log_table ON audit_log(table_name);
CREATE INDEX idx_audit_log_tenant ON audit_log(tenant_id);
CREATE INDEX idx_audit_log_created ON audit_log(created_at);
CREATE INDEX idx_user_roles_user ON user_roles(user_id);
CREATE INDEX idx_user_roles_tenant ON user_roles(tenant_id);
```

---

## 7. Integration Touchpoints

| Integration | Direction | Mechanism |
|------------|-----------|-----------|
| Azlan EA Ontology | sec: → ea: | Ontology `@id` cross-references |
| PF-Core Agent Template v3.0 | sec: → agent: | Agent identity section references security ontology |
| PE-Process Engineer | wf: → sec: | Workflow step `requiredRole` annotations |
| Navigation System | rbac: → nav: | Role-to-route mapping in `navigation_access_control` |
| Existing Security Manager PRD | sec: references | Implementation aligns with existing PRD specifications |
| Existing RLS foundations | DB layer | Extends/formalises existing `set_tenant_context()` pattern |
| RRR-ONT | rrr: → sec: | Role definitions ground in RRR ontology relationships |
