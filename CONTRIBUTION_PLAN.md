# GXR v0.2 Contribution Plan

## Phase 1: Deep Discovery & Audit Results

This document outlines the findings from an architectural audit of the GXR framework, identifying critical issues and proposed improvements for v0.2.

---

## Executive Summary

The current GXR v0.1 implementation provides a solid foundation for Go x React SSR with partial hydration. However, the audit identified several issues that should be addressed before v0.2:

| Priority | Category | Issue | Severity |
|----------|----------|-------|----------|
| 1 | Stability | No recursive directory scanning for components | High |
| 2 | Correctness | Brittle "use client" directive detection | High |
| 3 | Developer Experience | Insufficient build error handling and messaging | Medium |

---

## Issue #1: No Recursive Directory Scanning (Stability)

### Problem
The `findClientComponents()` function in `build.ts` only scans the top-level of the `componentsDir`. This breaks for any real-world project with nested component directories.

**Current Code (build.ts:25-26):**
```typescript
const files = fs.readdirSync(componentsDir);
for (const file of files) {
  if (!file.endsWith(".tsx") && !file.endsWith(".ts")) continue;
```

### Impact
- Components in subdirectories like `components/forms/Button.tsx` are silently ignored
- No warning is given to developers that nested components aren't being processed
- This leads to "why isn't my component hydrating?" confusion

### Proposed Solution
Implement recursive directory traversal with proper handling for:
- Nested directories (e.g., `components/forms/LoginForm.tsx`)
- Symlinks (avoid infinite loops)
- Hidden directories (skip `.` prefixed)
- Component name collision detection (two `Button.tsx` in different dirs)

**Implementation Approach:**
```typescript
function findClientComponentsRecursive(
  dir: string, 
  basePath: string = ""
): ClientComponent[] {
  const components: ClientComponent[] = [];
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  
  for (const entry of entries) {
    if (entry.name.startsWith(".")) continue;
    
    const fullPath = path.join(dir, entry.name);
    
    if (entry.isDirectory()) {
      components.push(...findClientComponentsRecursive(
        fullPath, 
        path.join(basePath, entry.name)
      ));
    } else if (entry.isFile() && isReactFile(entry.name)) {
      if (hasUseClientDirective(fullPath)) {
        components.push({
          name: generateUniqueName(basePath, entry.name),
          path: fullPath,
        });
      }
    }
  }
  
  return components;
}
```

### Testing Strategy
- Add test fixtures with nested component directories
- Verify components at all nesting levels are discovered
- Verify proper error handling for edge cases

---

## Issue #2: Brittle "use client" Directive Detection (Correctness)

### Problem
The current `"use client"` detection is brittle and will fail in several legitimate scenarios:

**Current Code (build.ts:34-35):**
```typescript
const trimmed = content.trimStart();
if (trimmed.startsWith('"use client"') || trimmed.startsWith("'use client'")) {
```

### Edge Cases Not Handled
1. **Semicolon after directive:** `"use client";` (common pattern)
2. **BOM marker:** Files with UTF-8 BOM (common from Windows editors)
3. **Comments before directive:** Some tools add comments before directives
4. **Backtick strings:** `` `use client` `` (unlikely but valid)
5. **Additional whitespace:** `"use client" ;` (spaces before semicolon)

### Impact
- Components with valid `"use client";` pattern may not be detected
- Silent failures lead to debugging confusion
- Framework behaves differently from Next.js (which is the mental model)

### Proposed Solution
Replace string-based detection with a more robust regex pattern:

```typescript
/**
 * Check if a file has the "use client" directive at the start.
 * Handles various edge cases:
 * - Semicolon after directive
 * - BOM markers
 * - Comments before directive (not standard, but defensive)
 */
function hasUseClientDirective(filePath: string): boolean {
  const content = fs.readFileSync(filePath, "utf-8");
  
  // Remove BOM if present
  const cleanContent = content.replace(/^\uFEFF/, "");
  
  // Pattern: Start of file, optional whitespace, "use client" or 'use client', 
  // optional semicolon, followed by newline or end
  const useClientPattern = /^\s*["']use client["']\s*;?\s*(?:\n|$)/;
  
  return useClientPattern.test(cleanContent);
}
```

### Alternative: AST-Based Detection
For future robustness, consider using TypeScript's parser or a lightweight parser like `@babel/parser` to detect the directive via AST. This would be more accurate but adds dependencies.

### Testing Strategy
- Create test fixtures for each edge case
- Include files with BOM markers
- Include files with/without semicolons
- Verify detection matches Next.js behavior

---

## Issue #3: Insufficient Build Error Handling (Developer Experience)

### Problem
The build process lacks proper error handling and informative messaging:

1. **esbuild errors not caught gracefully**
2. **No validation before build starts**
3. **Silent failures when components don't export defaults**
4. **No progress indication for large component sets**

### Current Code (build.ts:150-160):**
```typescript
// esbuild errors will crash the process with no context
await esbuild.build({
  entryPoints: [hydrateEntryPath],
  bundle: true,
  // ...
});
```

### Impact
- Build failures show raw esbuild errors without context
- Developers don't know which component caused the failure
- No guidance on how to fix issues

### Proposed Solution

**A. Wrap esbuild with try-catch and contextual errors:**
```typescript
try {
  await esbuild.build({
    entryPoints: [hydrateEntryPath],
    bundle: true,
    outfile: path.join(outputDir, "hydrate.js"),
    format: "esm",
    target: "es2020",
    jsx: "automatic",
    minify: process.env.NODE_ENV === "production",
    sourcemap: process.env.NODE_ENV !== "production",
    logLevel: "warning",
  });
} catch (error) {
  console.error("\n❌ Build failed!\n");
  
  if (error instanceof Error) {
    // Provide helpful context
    console.error("The following error occurred while bundling:");
    console.error(`   ${error.message}\n`);
    console.error("Common causes:");
    console.error("   - Missing peer dependencies (react, react-dom)");
    console.error("   - Invalid JSX/TSX syntax in client components");
    console.error("   - Missing default export in component file\n");
  }
  
  throw error;
}
```

**B. Pre-validate components before build:**
```typescript
function validateComponent(component: ClientComponent): string[] {
  const errors: string[] = [];
  const content = fs.readFileSync(component.path, "utf-8");
  
  // Check for default export
  if (!content.includes("export default")) {
    errors.push(`Missing default export in ${component.name}`);
  }
  
  return errors;
}
```

**C. Add verbose/debug mode:**
```bash
npx gxr build --verbose
```

### Testing Strategy
- Simulate esbuild failures with invalid component files
- Verify error messages are helpful and actionable
- Test component validation catches common issues

---

## Additional Findings (Lower Priority)

### 4. Missing React Type Import in Generated Hydration File
The generated `hydrate.tsx` uses `React.ComponentType<any>` without importing React:
```typescript
const clientComponents: Record<string, React.ComponentType<any>> = {
```

**Fix:** Add `import type React from "react";` to the generated file.

### 5. Component Name Collision Risk
If two files exist: `components/Button.tsx` and `components/forms/Button.tsx`, the generated registry will have duplicate keys.

**Fix:** Use fully qualified names or detect collisions with warnings.

### 6. No .gitignore for Generated Files
The `.gxr` temp directory should be in `.gitignore`.

**Fix:** Add `.gxr/` to default `.gitignore` or document this requirement.

### 7. Watch Mode Race Condition
The debounce in `watch.ts` is very short (100ms), which could cause race conditions with file saves that trigger multiple events.

**Fix:** Increase debounce to 300-500ms and add a "build in progress" lock.

---

## Recommended Implementation Order

1. **Issue #2 (Correctness)** - Quick fix, high impact, minimal risk
2. **Issue #1 (Stability)** - More involved, but critical for real projects
3. **Issue #3 (DX)** - Nice to have, can be done incrementally

---

## Implementation Notes

When implementing these fixes:

1. **Maintain backward compatibility** - Existing projects should continue to work
2. **Add TypeScript strict typing** - All new code should be strictly typed
3. **Add JSDoc comments** - Document all public functions
4. **Consider test infrastructure** - Set up Jest/Vitest if implementing Issue #3

---

## Next Steps

Please review this plan and select which issue you'd like me to implement first. I recommend starting with **Issue #2** (Brittle "use client" detection) as it's the quickest fix with immediate impact on correctness.
