Markdown · rea_reverse_engineering.md

# REA (Reverse Engineer Anything) - Complete Reverse Engineering Analysis

## Project Overview

**REA** is an open-source MCP (Model Context Protocol) server and CLI tool that enables reverse engineering of applications across multiple platforms and architectures. It provides a unified interface for analyzing binaries, applications, and runtime behavior without requiring their source code.

**Repository**: [https://github.com/morluto/rea](https://github.com/morluto/rea)\
**License**: MIT\
**Current Version**: 6.9.0\
**Node.js Requirements**: 22.23.4+, 24.22.1+, or 26.12.1+

---

## 1. Project Architecture

### High-Level Flow

```
User Request (CLI/Agent)
    ↓
REA CLI/MCP Adapter Layer
    ↓
Application Workflows Layer
    ↓
Provider Adapters (Hopper, Ghidra, IDA, etc.)
    ↓
Analysis Engines & Tools
    ↓
Domain Semantics & Contracts
    ↓
Results with Evidence
```

### Core Design Principles

1. **Local-Only Analysis**: All reverse engineering happens locally; no cloud uploads
2. **Evidence-Driven**: Every finding includes proof and limitations
3. **Multi-Provider Support**: Works with Hopper, Ghidra, IDA, Kuna, and open-source tools
4. **Dependency Flow**: Domain → Providers → Application → CLI/MCP

---

## 2. Directory Structure

### Root Organization

```
rea/
├── src/                    # Main TypeScript source code
├── bridge/                 # Integration bridges for external tools
├── scripts/                # CLI entry points and utilities
├── docs/                   # Comprehensive documentation
├── tests/                  # Test suites (acceptance, boundary, composition)
├── native/                 # Native bindings (Windows x64)
├── website/                # REA website and documentation site
├── examples/               # Example workflows and integrations
├── third_party/            # Bundled third-party tools
└── .agents/                # Agent plugin configurations
```

### Main Source Code (`src/`)

```
src/
├── main/                   # Main CLI/MCP entry points
├── cli/                    # CLI command implementations
├── server/                 # MCP server implementation
├── composition/            # Application workflow orchestration
├── domain/                 # Core business logic and contracts
├── contracts/              # Type definitions and interfaces
├── providers/              # Analysis engine adapters
├── artifacts/              # File format parsers (ELF, PE, WASM, etc.)
├── android/                # Android APK analysis
├── javascript/             # JavaScript/Electron analysis
├── browser/                # Website and browser analysis
├── native/                 # Native binary analysis
├── dotnet/                 # .NET assembly analysis
├── electron/               # Electron app analysis
├── firmware/               # Firmware analysis
├── process/                # Process management and supervision
├── captures/               # Network capture analysis (HAR, PCAP)
├── config/                 # Configuration management
├── filesystem/             # File system utilities
└── inspector/              # Generic inspection utilities
```

---

## 3. Key Components

### 3.1 Analysis Targets

REA can analyze **30+ target types**:

| Category | Targets |
| --- | --- |
| **Binaries** | Native ELF, PE, Mach-O, Go, Rust, WASM, BEAM |
| **Mobile** | Android APKs, APK Signatures, APK Resources, Flutter |
| **Desktop** | Electron, JavaScript, .NET Assemblies, PyInstaller |
| **Code Objects** | CUDA/HIP kernels, GPU code, IL2CPP metadata, Godot PCK |
| **Models** | GGUF, safetensors tensors |
| **Data** | SQLite, HAR captures, PCAP packets, IPS crashes |
| **Runtime** | Process behavior, Android devices via ADB, Deno binaries |

### 3.2 Provider Ecosystem

```
Analysis Providers:
├── Hopper (primary for macOS, ARM binaries)
├── Ghidra (primary for Linux, multi-arch)
├── IDA Pro (optional, read-only)
├── Kuna Decompiler (specialized)
├── JADX (Android APK decompilation)
├── Objdump (fallback, GNU tools)
└── Rizin (experimental, FOSS)

Helper Tools:
├── Binwalk/Unblob (firmware extraction)
├── TShark (packet analysis)
├── Sigrok-cli (signal decoding)
├── ADB (Android device access)
└── Apktool (Android resources)
```

### 3.3 MCP Server

The project exposes **40+ tools** through the Model Context Protocol:

**Static Analysis Tools**:

- `analyze_javascript_application` - Module mapping, imports, routes
- `inspect_apk` - Manifest, classes, methods, decompiled code
- `inspect_native_binary` - Pseudocode, assembly, symbols, strings
- `inspect_wasm_artifact` - Validation, sections, WAT decoding
- `inspect_dotnet_assembly` - Metadata, CIL instructions

**Runtime Tools**:

- `run_process_capture` - Execute and observe behavior
- `connect_adb_device` - Access Android devices
- `observe_website` - Browser automation and screenshots

**Helper Tools**:

- `inspect_model_artifact` - GGUF/safetensors metadata
- `inspect_sqlite_database` - Tables, rows, indexes
- `analyze_pcap` - Network traffic analysis

---

## 4. TypeScript Architecture

### Entry Points

**CLI**: `scripts/rea.mjs`

```javascript
bin.rea → scripts/rea.mjs → src/cli/ → composition workflows
```

**MCP Server**: `src/server/`

```
MCP Client → MCP Server → REA Tools → Analysis Workflows
```

### Core Interfaces

#### Evidence System

```typescript
// Every finding includes provenance
interface Evidence {
  value: unknown;
  source: string;        // Where it came from
  confidence: "certain" | "probable" | "uncertain";
  limitations: string[]; // Known constraints
}
```

#### Contracts

```typescript
// Typed tool results
interface InspectionResult<T> {
  findings: Evidence<T>[];
  summary: string;
  unknowns: string[];
  nextSteps: string[];
}
```

#### Provider Abstraction

```typescript
interface AnalysisProvider {
  analyzeNativeBinary(path: string): Promise<PseudoCode>;
  extractSymbols(path: string): Promise<SymbolTable>;
  getStrings(path: string): Promise<StringTable>;
}
```

### Key Workflows

#### JavaScript Analysis Workflow

1. Extract ASAR or directory contents
2. Parse package.json and source maps
3. Build module dependency graph
4. Identify Electron IPC boundaries
5. Detect native addons
6. Return module inventory with connections

#### Android Analysis Workflow

1. Parse APK structure and manifest
2. Use JADX to decompile bytecode
3. Extract resources and strings
4. Trace dependencies and permissions
5. Identify sensitive operations
6. Build call graphs

#### Native Binary Analysis Workflow

1. Parse binary headers (ELF/PE/Mach-O)
2. Select analysis provider (Hopper/Ghidra/IDA)
3. Launch provider headlessly
4. Extract pseudocode and assembly
5. Build symbol tables and references
6. Trace function calls and data flow

---

## 5. Important Files & Functions

### Core Entry Points

| File | Purpose |
| --- | --- |
| `scripts/rea.mjs` | CLI bootstrap |
| `src/main/` | Main interface (CLI + MCP) |
| `src/cli/command.ts` | Command execution engine |
| `src/server/` | MCP protocol handler |

### Analysis Modules

| Module | Key Files | Responsibility |
| --- | --- | --- |
| **JavaScript** | `src/javascript/` | Module analysis, imports, sources |
| **Android** | `src/android/` | APK parsing, JADX integration |
| **Native** | `src/native/` | Binary format parsing |
| **Electron** | `src/electron/` | IPC tracing, preload analysis |
| **Firmware** | `src/firmware/` | Extraction and region mapping |

### Provider Adapters

| Provider | Location | Capabilities |
| --- | --- | --- |
| **Hopper** | `src/hopper/` | Pseudocode, assembly, symbols |
| **Ghidra** | `src/ghidra/` + `bridge/ghidra/` | Full decompilation, scripting |
| **IDA** | `src/ida/` | Python scripting interface |
| **JADX** | `third_party/jadx-headless-mcp/` | Android bytecode decompilation |

### Important Functions

```typescript
// Main analysis entry
async analyzeTarget(path: string, targetType: string)

// Provider orchestration
async selectProvider(binaryPath: string): Promise<AnalysisProvider>

// Evidence collection
async collectEvidence(findings: unknown[]): Promise<Evidence[]>

// Workflow composition
async executeWorkflow(workflow: AnalysisWorkflow): Promise<WorkflowResult>

// Result formatting
formatForAgent(result: AnalysisResult): AgentReadableOutput
```

---

## 6. Build & Release System

### Build Configuration

**Turborepo Monorepo**: Multi-workspace setup

```bash
npm run build:cached  # Incremental build with caching
npm run test:local    # Fast local testing
npm run check:fast    # TypeScript + ESLint
npm run check:pr      # Full CI validation
```

**TypeScript**: Modern ES modules, strict mode

- Multiple tsconfig files for different compilation targets
- Tree-shaking for CLI optimization
- Worker threads for parallel analysis

### Packaging

**Distribution Methods**:

1. **npm**: `rea-agents` package on npm registry
2. **Skills.sh**: Integrated skill for Claude Code
3. **Plugins**: Agent-specific plugins (Claude, Cursor, Codex)
4. **Releases**: GitHub releases with binaries

---

## 7. Plugin & Integration Layer

### Agent Integrations (`.agents/`)

```
.agents/
├── plugins/
│   ├── claude/      # Claude.ai plugin
│   ├── cursor/      # Cursor IDE plugin
│   └── codex/       # Codex plugin
└── skills/
    └── reverse-engineer-anything/  # Skill instructions
```

### Key Concepts

- **Skills**: Workflow guidance for AI agents
- **MCP Server**: Model Context Protocol interface
- **CLI**: Terminal-based interface
- **Bridges**: Language-specific integrations (Python, Java, Swift)

---

## 8. Bridge & Integration Code

### External Tool Bridges

```
bridge/
├── hopper_bridge.py          # Hopper automation
├── ghidra/                   # Ghidra Java extensions
├── android/ReaJadxBridge.java # JADX integration
├── native/                   # macOS native UI
├── process/                  # Process management
├── pwntools/                 # Binary tools
├── mitmproxy/                # Network interception
└── agentenv/                 # RL environment generation
```

**Key Bridge Features**:

- Launches external tools headlessly
- Parses and normalizes output
- Handles process lifecycle
- Manages temporary resources

---

## 9. Configuration & Setup

### Dynamic Configuration

```typescript
// REA Configuration
interface ReaConfig {
  providers: {
    hopper?: HopperConfig;
    ghidra?: GhidraConfig;
    ida?: IdaConfig;
  };
  analysis: {
    timeout: number;
    maxConcurrency: number;
    cacheResults: boolean;
  };
  mcp?: MCPConfig;
}
```

### Setup Process

1. Detects agent environment
2. Registers MCP server in agent config
3. Installs matching workflow instructions
4. Optionally installs Hopper (with approval)
5. Creates backups of existing config

---

## 10. Testing Strategy

### Test Organization

```
tests/
├── acceptance/      # Full end-to-end workflows
├── boundary/        # Provider/tool boundaries
├── composition/     # Workflow orchestration
├── conformance/     # Contract validation
├── evaluation/      # Performance benchmarks
└── process-global/  # Process isolation
```

### Test Patterns

- **Golden files**: Expected output comparisons
- **Fixture data**: Sample binaries and archives
- **Lifecycle tests**: Initialization, cleanup, cancellation
- **Provider mocks**: Simulated analysis engines

---

## 11. Documentation

### Documentation Structure

```
docs/
├── getting-started/      # Installation, setup, CLI
├── guides/               # Worked examples per target type
├── reference/            # MCP contracts, tools catalog
├── providers/            # Tool-specific guides
├── architecture/         # Design decisions (ADRs)
└── development/          # Contribution guidelines
```

### Key Documentation

- **README.md**: Quick start, features, showcases
- **AGENTS.md**: Repository guidelines, architecture principles
- **CONTRIBUTING.md**: Development workflow, standards
- **Tool Design**: Guidelines for adding new analysis capabilities

---

## 12. Security & Limitations

### Security Model

1. **Local-Only**: No cloud uploads or external services
2. **Read-Only**: Analyses don't modify target binaries
3. **Evidence-Based**: Clear attribution of findings
4. **Containment**: External tools run in isolated processes

### Important Limitations

- Requires legal authorization for commercial decompilers (IDA, Hopper)
- Some targets need external tools (JADX, Ghidra)
- Results depend on provider quality
- Can't recover obfuscated or stripped code

---

## 13. Performance Considerations

### Optimization Strategy

**Priority Order**:

1. Agent tokens (return smallest sufficient answer with evidence)
2. Analysis time (reuse validated results, cache keys)
3. CPU/Memory (bound concurrency, avoid copies)

### Caching

- Results validated for freshness
- Cache keys cover all result-affecting inputs
- Cached results include invalidation metadata

---

## 14. Workflow Examples

### Example 1: Analyze Electron App

```
1. User: "Analyze how search works in Notes app"
2. REA finds: /Applications/Notes.app
3. Extracts: ASAR archive, preload scripts, IPC handlers
4. Traces: Renderer → IPC → Main process search handler
5. Returns: Code structure, entry points, API surface
6. Agent: Implements similar feature using findings
```

### Example 2: Decompile Native Binary

```
1. User: "Understand the DX-Ball sound-pan calculation"
2. REA launches: Hopper/Ghidra headlessly
3. Parses: x86 assembly, function parameters
4. Returns: Pseudocode with confidence levels
5. Agent: Reconstructs C++ implementation
6. Validates: 3,205 test cases pass
```

### Example 3: Inspect Android APK

```
1. User: "What permissions does this app request?"
2. REA extracts: APK manifest and decompiles with JADX
3. Parses: Permission declarations, sensitive API calls
4. Returns: Manifest structure, permission usage patterns
5. Agent: Generates security report
```

---

## 15. Extension Points

### Adding New Analysis Targets

1. **Create Parser**: `src/artifacts/<format>/`
2. **Define Contracts**: `src/contracts/<domain>.ts`
3. **Implement Workflow**: `src/composition/<workflow>.ts`
4. **Add Tests**: `tests/<domain>/`
5. **Document Guide**: `docs/guides/<domain>.md`

### Adding New Providers

1. **Create Adapter**: `src/<provider>/`
2. **Implement Interface**: Conform to `AnalysisProvider`
3. **Add Bridge**: `bridge/<provider>/` if needed
4. **Setup Instructions**: `docs/providers/<provider>.md`

---

## 16. Key Statistics

- **400,000+ GitHub stars**
- **30+ analysis targets**
- **40+ MCP tools**
- **6+ provider integrations**
- **8,000+ source files in repository**
- **MIT Licensed**
- **Active development** with monthly releases

---

## 17. Quick Reference

### CLI Commands

```bash
# Setup
npx rea-agents setup

# Analyze JavaScript app
rea analyze-javascript-application /path/to/app --json

# Analyze APK
rea inspect-apk /path/to/app.apk

# Inspect binary
rea inspect-native-binary /path/to/binary

# Show help
rea --help
```

### Key npm Scripts

```bash
npm run build:cached       # Build with caching
npm run test:local PATH    # Run specific tests
npm run check:fast         # Quick validation
npm run docs:check         # Validate documentation
rea update                 # Update CLI
```

---

## 18. Community & Resources

- **Website**: [https://rea.tools/](https://rea.tools/)
- **Discord**: Community Q&A and showcases
- **GitHub Issues**: Bug reports and feature requests
- **Documentation**: Comprehensive guides and API reference
- **Showcases**: Real-world reverse engineering case studies

---

## 19. Technical Stack

- **Language**: TypeScript (ESM)
- **Runtime**: Node.js 22+
- **CLI**: Custom CLI framework
- **MCP**: Model Context Protocol server
- **Process Management**: Node.js child processes
- **Analysis Engines**: Hopper, Ghidra, IDA, JADX
- **Testing**: Custom test framework
- **Build**: Turborepo monorepo
- **Packaging**: npm distribution

---

## 20. Future Directions

Based on `docs/development/roadmap.md`:

- Enhanced browser analysis capabilities
- GPU code analysis improvements
- Extended firmware support
- Better RL environment generation
- New provider integrations
- Performance optimizations

---

## Summary

REA is a sophisticated, well-architected reverse engineering platform that:

✅ Supports **30+ target types** across multiple architectures\
✅ Integrates **6+ analysis engines** transparently\
✅ Provides **evidence-driven results** with clear provenance\
✅ Works **locally without cloud uploads**\
✅ Scales from **CLI to MCP server** seamlessly\
✅ Maintains **code quality** with comprehensive testing\
✅ Enables **agent-assisted** reverse engineering

The codebase demonstrates professional software architecture with clear separation of concerns, well-defined interfaces, and strong emphasis on reliability and user control.