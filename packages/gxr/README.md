# GXR - Go x React

A lightweight SSR framework that brings React Server Components patterns to Go. Write `"use client"` components and let the framework handle hydration automatically.

## Overview

GXR (Go x React) is a server-side rendering framework that combines the power of Go's performance with React's component model. It provides automatic partial hydration for interactive components while keeping the rest of your app as static HTML.

## Features

- 🚀 **Go-powered SSR** - Render React components on the server using Go
- ⚡ **Automatic Hydration** - Just add `"use client"` directive, framework handles the rest
- 🏝️ **Island Architecture** - Only interactive components are hydrated, reducing JavaScript bundle size
- 🔧 **Zero Config** - No manual wrapper components or hydration scripts needed
- 📦 **Simple CLI** - Build with `npx gxr build`

## Installation

### Go Package

```bash
go get github.com/salihguru/gxr-go
```

### TypeScript/Build Tools

```bash
npm install gxr
```

## Quick Start

### 1. Create a Client Component

```tsx
// components/Counter.tsx
"use client";

import { useState } from "react";

export default function Counter({ initialCount }: { initialCount: number }) {
  const [count, setCount] = useState(initialCount);
  
  return (
    <div>
      <button onClick={() => setCount(count - 1)}>-</button>
      <span>{count}</span>
      <button onClick={() => setCount(count + 1)}>+</button>
    </div>
  );
}
```

### 2. Use in Your Page

```tsx
// pages/index.tsx
import Counter from "../components/Counter";

export default function Home({ initialCount }) {
  return (
    <html>
      <body>
        <h1>Welcome to GXR</h1>
        <Counter initialCount={initialCount} />
      </body>
    </html>
  );
}
```

### 3. Create Go Server

```go
package main

import (
    "net/http"
    gxr "github.com/salihguru/gxr-go"
)

func main() {
    g, _ := gxr.New()
    
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        html, _ := g.Render("pages/index.tsx", map[string]interface{}{
            "initialCount": 0,
        })
        w.Write([]byte(html))
    })
    
    http.ListenAndServe(":8080", nil)
}
```

### 4. Build & Run

```bash
npx gxr build
go run .
```

## How It Works

1. **Build Time**: The CLI scans for `"use client"` components and generates a hydration bundle
2. **SSR**: Go renders the full page, wrapping client components with hydration markers
3. **Client**: The hydration script finds markers and makes components interactive

```
┌─────────────────────────────────────────────────────────────┐
│                        Browser                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Static HTML (from SSR)                                  │ │
│  │  ┌─────────┐  ┌─────────────┐  ┌─────────┐             │ │
│  │  │ Header  │  │   Counter   │  │ Footer  │             │ │
│  │  │ (static)│  │ (hydrated)  │  │ (static)│             │ │
│  │  └─────────┘  └──────┬──────┘  └─────────┘             │ │
│  └──────────────────────┼─────────────────────────────────┘ │
│                         │                                    │
│                    hydrate.js                                │
│                   (only Counter)                             │
└─────────────────────────────────────────────────────────────┘
```

## Project Structure

```
gxr/
├── packages/
│   ├── gxr/                 # TypeScript package (CLI + hydration)
│   │   ├── src/
│   │   │   ├── cli/         # npx gxr build command
│   │   │   └── index.ts
│   │   └── package.json
│   │
│   └── gxr-go/              # Go package
│       ├── gxr.go           # Main API
│       ├── transformer.go   # "use client" wrapper
│       └── go.mod
│
└── examples/
    └── basic/               # Basic example app
        ├── client/
        │   ├── components/
        │   └── pages/
        ├── main.go
        └── package.json
```

## CLI Commands

### `npx gxr build`

Scans for `"use client"` components and generates the hydration bundle.

```bash
npx gxr build [options]

Options:
  --components <dir>   Components directory (default: ./client/components)
  --output <dir>       Output directory (default: ./public)
  --watch              Watch mode for development
```

## Roadmap

### Current (v0.1)
- [x] Basic SSR with gojsx
- [x] `"use client"` directive support
- [x] Automatic hydration injection
- [x] Partial hydration (island architecture)
- [x] CLI build tool

### Planned (v0.2)
- [ ] File-based routing
- [ ] API routes
- [ ] Development server with hot reload
- [ ] TypeScript types for Go props

### Future (v1.0)
- [ ] Streaming SSR
- [ ] Suspense support
- [ ] Server Actions (like Next.js)
- [ ] Edge runtime support
- [ ] Built-in CSS/Tailwind support

## Philosophy

GXR aims to bring the best parts of modern React frameworks to the Go ecosystem:

1. **Go for the Server**: Leverage Go's performance, simplicity, and deployment story
2. **React for the UI**: Use React's component model and ecosystem
3. **Minimal JavaScript**: Only ship JavaScript for interactive parts
4. **Simple Mental Model**: `"use client"` is the only API you need to learn

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## License

MIT
