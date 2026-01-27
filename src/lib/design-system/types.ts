// Design System E2E Types
// Generic - works with any token set following the 3-tier ontology

export interface PrimitivesSchema {
  colors: Record<string, Record<string, string>>;
  typography: {
    fontFamilies: Record<string, string>;
    fontSizes: Record<string, string>;
    lineHeights: Record<string, string>;
    fontWeights: Record<string, number>;
  };
  spacing: Record<string, string>;
  borderRadius: Record<string, string>;
}

export interface SemanticTokenRef {
  ref: string;   // path to primitive e.g. "teal.500"
  value: string;  // resolved value e.g. "#00a4bf"
}

export interface SemanticIntent {
  surface: {
    default: SemanticTokenRef;
    darker: SemanticTokenRef;
    lighter: SemanticTokenRef;
  };
  border: {
    default: SemanticTokenRef;
  };
  text: {
    label: SemanticTokenRef;
    body: SemanticTokenRef;
  };
}

export interface SemanticsSchema {
  primary: SemanticIntent;
  secondary: SemanticIntent;
  success: SemanticIntent;
  error: SemanticIntent;
  warning: SemanticIntent;
  information: SemanticIntent;
  neutral: SemanticIntent;
  [key: string]: SemanticIntent;
}

export interface ComponentTokenBundle {
  background: SemanticTokenRef;
  backgroundHover: SemanticTokenRef;
  text: SemanticTokenRef;
  border: SemanticTokenRef;
  borderRadius: SemanticTokenRef;
  [key: string]: SemanticTokenRef;
}

export interface ComponentsSchema {
  button: Record<string, ComponentTokenBundle>;
  card: Record<string, ComponentTokenBundle>;
  input: Record<string, ComponentTokenBundle>;
  alert: Record<string, ComponentTokenBundle>;
  badge: Record<string, ComponentTokenBundle>;
  [key: string]: Record<string, ComponentTokenBundle>;
}

export interface DesignSystemDocument {
  version: string;
  sourceFile: string;
  primitives: PrimitivesSchema;
  semantics: SemanticsSchema;
  components: ComponentsSchema;
}
