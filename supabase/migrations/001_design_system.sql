-- ===========================================
-- Design System E2E Schema
-- Generic template - works with any token set
-- ===========================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";

-- Design System (complete ontology as JSONB)
CREATE TABLE design_system (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    version TEXT NOT NULL,
    primitives JSONB NOT NULL DEFAULT '{}',
    semantics JSONB NOT NULL DEFAULT '{}',
    components JSONB NOT NULL DEFAULT '{}',
    typography JSONB NOT NULL DEFAULT '{}',
    spacing JSONB NOT NULL DEFAULT '{}',
    figma_file_key TEXT,
    is_active BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Layouts (page specifications)
CREATE TABLE layouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slug TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    spec JSONB NOT NULL DEFAULT '{}',
    figma_file_key TEXT,
    figma_node_id TEXT,
    version TEXT DEFAULT '1.0.0',
    status TEXT DEFAULT 'draft'
        CHECK (status IN ('draft', 'review', 'approved', 'locked', 'archived')),
    locked_at TIMESTAMPTZ,
    locked_by UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Content (CMS data)
CREATE TABLE content (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    layout_id UUID REFERENCES layouts(id),
    page_slug TEXT NOT NULL,
    locale TEXT DEFAULT 'en',
    data JSONB NOT NULL DEFAULT '{}',
    meta JSONB DEFAULT '{}',
    version INTEGER DEFAULT 1,
    status TEXT DEFAULT 'draft'
        CHECK (status IN ('draft', 'published', 'archived')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    published_at TIMESTAMPTZ,
    UNIQUE(page_slug, locale, version)
);

-- Profiles (extended auth.users)
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    full_name TEXT,
    avatar_url TEXT,
    preferences JSONB DEFAULT '{"theme": "light"}',
    subscription_tier TEXT DEFAULT 'free',
    subscription_data JSONB DEFAULT '{}',
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Conversations
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT,
    status TEXT DEFAULT 'active'
        CHECK (status IN ('active', 'completed', 'archived')),
    context JSONB DEFAULT '{}',
    last_message_preview TEXT,
    message_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Messages
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system', 'tool')),
    content TEXT,
    tool_calls JSONB,
    tool_call_id TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tool Invocations (audit log)
CREATE TABLE tool_invocations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    message_id UUID REFERENCES messages(id),
    user_id UUID REFERENCES auth.users(id),
    tool_name TEXT NOT NULL,
    input JSONB NOT NULL,
    output JSONB,
    status TEXT DEFAULT 'pending'
        CHECK (status IN ('pending', 'running', 'success', 'error')),
    duration_ms INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Conversation Memory (vector embeddings)
CREATE TABLE conversation_memory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    embedding vector(1536),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Prompt Templates
CREATE TABLE prompt_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slug TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    template TEXT NOT NULL,
    parent_slug TEXT REFERENCES prompt_templates(slug),
    variables JSONB DEFAULT '[]',
    version TEXT DEFAULT '1.0.0',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Activity Log
CREATE TABLE activity_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id),
    action TEXT NOT NULL,
    resource_type TEXT,
    resource_id UUID,
    data JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===========================================
-- INDEXES
-- ===========================================
CREATE INDEX idx_design_system_active ON design_system(is_active) WHERE is_active = true;
CREATE INDEX idx_layouts_slug ON layouts(slug);
CREATE INDEX idx_layouts_status ON layouts(status);
CREATE INDEX idx_content_page ON content(page_slug, locale);
CREATE INDEX idx_conversations_user ON conversations(user_id, updated_at DESC);
CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at);
CREATE INDEX idx_memory_embedding ON conversation_memory
    USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX idx_memory_user ON conversation_memory(user_id);

-- ===========================================
-- FUNCTIONS
-- ===========================================

-- Vector search for memory
CREATE OR REPLACE FUNCTION search_memory(
    p_user_id UUID,
    p_embedding vector(1536),
    p_limit INTEGER DEFAULT 5,
    p_threshold FLOAT DEFAULT 0.7
)
RETURNS TABLE (
    id UUID,
    content TEXT,
    conversation_id UUID,
    similarity FLOAT,
    metadata JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        cm.id,
        cm.content,
        cm.conversation_id,
        1 - (cm.embedding <=> p_embedding) as similarity,
        cm.metadata
    FROM conversation_memory cm
    WHERE cm.user_id = p_user_id
    AND 1 - (cm.embedding <=> p_embedding) > p_threshold
    ORDER BY cm.embedding <=> p_embedding
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Auto-update conversation summary
CREATE OR REPLACE FUNCTION update_conversation_summary()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE conversations
    SET
        last_message_preview = LEFT(NEW.content, 100),
        message_count = message_count + 1,
        updated_at = NOW()
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_message_created
AFTER INSERT ON messages
FOR EACH ROW
WHEN (NEW.role IN ('user', 'assistant'))
EXECUTE FUNCTION update_conversation_summary();

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (id, email, full_name)
    VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ===========================================
-- ROW LEVEL SECURITY
-- ===========================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE tool_invocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_memory ENABLE ROW LEVEL SECURITY;
ALTER TABLE content ENABLE ROW LEVEL SECURITY;
ALTER TABLE layouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE design_system ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles_select_own" ON profiles
    FOR SELECT USING (auth.uid() = id);
CREATE POLICY "profiles_update_own" ON profiles
    FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "conversations_all_own" ON conversations
    FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "messages_all_own" ON messages
    FOR ALL USING (
        conversation_id IN (
            SELECT id FROM conversations WHERE user_id = auth.uid()
        )
    );
CREATE POLICY "memory_select_own" ON conversation_memory
    FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "content_read_published" ON content
    FOR SELECT USING (status = 'published');
CREATE POLICY "content_admin_all" ON content
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND (metadata->>'role')::text = 'admin'
        )
    );
CREATE POLICY "layouts_read_approved" ON layouts
    FOR SELECT USING (status IN ('approved', 'locked'));
CREATE POLICY "layouts_admin_all" ON layouts
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND (metadata->>'role')::text = 'admin'
        )
    );
CREATE POLICY "design_system_read_active" ON design_system
    FOR SELECT USING (is_active = true);
CREATE POLICY "design_system_admin_all" ON design_system
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND (metadata->>'role')::text = 'admin'
        )
    );
