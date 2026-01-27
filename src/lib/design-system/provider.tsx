'use client';

import { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { createClient } from '@supabase/supabase-js';

interface DesignSystem {
  id: string;
  version: string;
  primitives: Record<string, any>;
  semantics: Record<string, any>;
  components: Record<string, any>;
  typography: Record<string, any>;
  spacing: Record<string, any>;
  figma_file_key: string | null;
  is_active: boolean;
}

interface DesignSystemContextValue {
  designSystem: DesignSystem | null;
  loading: boolean;
  resolveToken: (path: string) => string | undefined;
}

const DesignSystemContext = createContext<DesignSystemContextValue>({
  designSystem: null,
  loading: true,
  resolveToken: () => undefined,
});

export function useDesignSystem() {
  return useContext(DesignSystemContext);
}

export function useToken(path: string): string | undefined {
  const { resolveToken } = useDesignSystem();
  return resolveToken(path);
}

export function useComponentTokens(component: string, variant: string = 'primary') {
  const { designSystem } = useDesignSystem();
  if (!designSystem) return null;
  return designSystem.components?.[component]?.[variant] || null;
}

function resolve(obj: Record<string, any>, path: string): any {
  const parts = path.split('.');
  let current: any = obj;
  for (const part of parts) {
    if (current === null || current === undefined) return undefined;
    current = current[part];
  }
  // If result has a $ref, resolve it recursively
  if (current && typeof current === 'object' && current.$ref) {
    return resolve(obj, current.$ref);
  }
  // If result has a value property, return it
  if (current && typeof current === 'object' && current.value) {
    return current.value;
  }
  return current;
}

function injectCSSVariables(ds: DesignSystem) {
  const root = document.documentElement;

  // Inject primitive colors as CSS vars
  if (ds.primitives?.colors) {
    for (const [palette, scales] of Object.entries(ds.primitives.colors)) {
      if (typeof scales === 'object') {
        for (const [scale, value] of Object.entries(scales as Record<string, string>)) {
          root.style.setProperty(`--color-${palette}-${scale}`, value);
        }
      }
    }
  }

  // Inject spacing
  if (ds.spacing) {
    for (const [token, value] of Object.entries(ds.spacing)) {
      root.style.setProperty(`--spacing-${token}`, value as string);
    }
  }

  // Inject border radius
  if (ds.primitives?.borderRadius) {
    for (const [token, value] of Object.entries(ds.primitives.borderRadius)) {
      root.style.setProperty(`--radius-${token}`, value as string);
    }
  }
}

interface ProviderProps {
  children: ReactNode;
  supabaseUrl: string;
  supabaseAnonKey: string;
}

export function DesignSystemProvider({ children, supabaseUrl, supabaseAnonKey }: ProviderProps) {
  const [designSystem, setDesignSystem] = useState<DesignSystem | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const supabase = createClient(supabaseUrl, supabaseAnonKey);

    async function load() {
      const { data, error } = await supabase
        .from('design_system')
        .select('*')
        .eq('is_active', true)
        .single();

      if (data && !error) {
        setDesignSystem(data);
        injectCSSVariables(data);
      }
      setLoading(false);
    }

    load();
  }, [supabaseUrl, supabaseAnonKey]);

  const resolveToken = (path: string): string | undefined => {
    if (!designSystem) return undefined;
    const allTokens = {
      ...designSystem.primitives,
      ...designSystem.semantics,
      ...designSystem.components,
      ...designSystem.typography,
      ...designSystem.spacing,
    };
    return resolve(allTokens, path);
  };

  return (
    <DesignSystemContext.Provider value={{ designSystem, loading, resolveToken }}>
      {children}
    </DesignSystemContext.Provider>
  );
}
