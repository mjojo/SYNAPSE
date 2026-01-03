# 🧠 SYNAPSE v3.2 "Ouroboros Returns"

**Unhackable AI on Bare Metal Assembly**
*The World's First Self-Hosting Blockchain AI Platform with Graphics & GUI*

<div align="center">

![Version](https://img.shields.io/badge/version-3.2.0--STABLE-green)
![Status](https://img.shields.io/badge/status-PHASE_52_COMPLETE-success)
![Arch](https://img.shields.io/badge/arch-x64_AVX2-red)
![Graphics](https://img.shields.io/badge/graphics-GDI%2B-blue)
![License](https://img.shields.io/badge/license-Apache_2.0_+_AGPL_v3-blue)

</div>

## 🚀 Technical Specifications (v3.2)

| Specification | Status | Description |
|---------------|--------|-------------|
| **Self-Hosting** | 🟡 **PROGRESS** | Phase 52 complete - standalone EXE generation working! |
| **Architecture** | x64 JIT | Three-level virtualization (Host -> Guest -> Target) |
| **Graphics** | ✅ **YES** | Direct VRAM access, GDI integration, 8x8 embedded font |
| **GUI** | ✅ **YES** | Mouse input, keyboard, clickable buttons |
| **Data Types** | Strong | `int` (64-bit), `ptr`, `string`, `array` |
| **Control Flow** | Full | `if`, `while`, `fn`, `return`, `recursion` |
| **Memory** | Manual | `alloc`, `ptr[i]`, Data Segment for literals |
| **Logic** | Complete | `==`, `<`, `>`, `+`, `-`, `*`, `/`, bitwise ops |
| **EXE Generation** | ✅ **WORKING** | PE32+ with IAT resolution - Exit Code 42 achieved! |
| **Binary Size** | ~30 KB | Includes graphics, GUI, and file I/O |
| **License** | Dual | Apache 2.0 (language) + AGPL v3 (services) |

---

## 🎆 Victory: Phase 52 Complete!

**SYNAPSE v3.2.0-STABLE** — First working standalone executable generation with IAT resolution!

### ✅ Breakthrough Achievement (January 3, 2026)
**Success:** Generated `synapse_new.exe` exits with **Exit Code 42** 🎉  
**Bug Fixed:** Data Directory offset error (0x148 vs 0x150) - 100+ debugging iterations  
**Impact:** Windows Loader successfully fills Import Address Table - programs can call APIs!  
**Next Steps:** Phase 53 (Memory), Phase 54 (File I/O), Phase 55 (Self-Hosting)

### 🔥 Working Features (v3.2.0-STABLE)
* **PE32+ Generation:** Valid executables with working IAT resolution
* **JIT Compilation:** Real-time x64 code generation and execution
* **Graphics Engine:** Direct pixel manipulation, window management
* **Mouse & Keyboard:** Real-time input handling for interactive apps
* **File I/O:** Read source files, write binary data (in JIT mode)
* **API Calls:** ExitProcess working via IAT[0] - foundation for VirtualAlloc

---

## 📜 Open Source License

**Synapse** uses a dual licensing strategy to protect the project while maximizing adoption:

### 🟢 Apache License 2.0 (Language & Compiler)
**Free for commercial use** - Create any application without restrictions:
- Synapse Compiler (src/*.asm)
- Standard Library (stdlib/core, io, math, string, crypto)
- JIT Engine and Code Generator
- All language syntax and examples

**Why Apache 2.0?** We want Synapse to become a universal programming language. Zero friction for developers.

### 🔴 AGPL v3 (Network Services)
**Cloud protection** - Prevents exploitation by large corporations:
- SynapseFS (Blockchain Filesystem)
- Synapse Chain (Merkle Tree Allocator)
- Hive Protocol (Swarm Intelligence)
- P2P Synchronization

**Why AGPL v3?** If you run these as a cloud service (like AWS), you must open your source code OR purchase a commercial license. This protects our business model.

**Commercial Licenses Available** - Contact for enterprise deployments without AGPL requirements.

See [LICENSE](LICENSE) for full details. Model inspired by **MongoDB** and **Elastic**.

---

## 🎆 Legacy: The Ouroboros

### 🚧 Blocked Features (Phase 52)
* **Standalone Executables:** Generated .exe files crash immediately
* **API Imports:** ExitProcess, VirtualAlloc not callable in generated code
* **Self-Hosting:** Cannot bootstrap due to IAT issue

---

## ⚡ Quick Start

### Building SYNAPSE

```bash
# Windows x64
cd d:\Projects\SYNAPSE\bin
build_synapse.bat

# This creates synapse.exe - the host compiler
```

### Your First Program

```synapse
// hello.syn
fn main() {
    puts("Hello from SYNAPSE v3.2!")
    return 0
}
```

```bash
# Compile and run
synapse.exe hello.syn

# Or generate standalone EXE
synapse.exe bootstrap.syn  # Creates synapse_new.exe
```

### Graphics Demo

```synapse
// paint.syn - Interactive paint program
fn main() {
    window(800, 600)
    let running = 1
    
    while running > 0 {
        let mx = mouse_x()
        let my = mouse_y()
        
        if mouse_btn() > 0 {
            pixel(mx, my, 0xFF0000)  // Red pixel
        }
        
        update_window()
    }
    return 0
}
```

## 📚 Documentation

* [Development Tasks](TASKS.md) - Complete development history (Phases 1-51)
* [Current Spec](docs/CURRENT_v1_SPEC.md) - Language specification
* [Synapse Grammar](docs/SYNAPSE_GRAMMAR.md) - Formal grammar
* [Future Vision](docs/FUTURE_VISION_v2_SPEC.md) - Roadmap for v4.0
* [Commands Reference](docs/commands.md) - Built-in functions

## 🏆 Major Milestones

### Phase 50: Standalone EXE Generation ✅
- PE32+ file format implementation
- `hello.exe` (1024 bytes) that returns exit code 42
- Full binary generation from JIT memory

### Phase 51: Bootstrap Infrastructure ✅
- `bootstrap.syn` - self-hosting compiler
- File I/O for reading source code
- PE writer with proper headers
- Infrastructure ready for full self-compilation

### Phase 46-49: Graphics & GUI ✅
- Direct VRAM access via `get_vram()`
- GDI window integration
- Mouse input (`mouse_x`, `mouse_y`, `mouse_btn`)
- Keyboard handling (`get_key`)
- Interactive demos: paint.syn, vector.syn, gui_test.syn

## 🎯 Architecture Overview

```
┌─────────────────────────────────────────┐
│   SYNAPSE v3.2 Architecture            │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐   │
│  │   Bootstrap Compiler           │   │
│  │   (bootstrap.syn)              │   │
│  │   - Lexer                      │   │
│  │   - Parser                     │   │
│  │   - x64 Codegen                │   │
│  │   - PE32+ Writer               │   │
│  └─────────────────────────────────┘   │
│                ↓                        │
│  ┌─────────────────────────────────┐   │
│  │   Host Compiler (synapse.exe)  │   │
│  │   - FASM-generated kernel      │   │
│  │   - JIT compilation            │   │
│  │   - Graphics engine            │   │
│  │   - File I/O                   │   │
│  └─────────────────────────────────┘   │
│                ↓                        │
│  ┌─────────────────────────────────┐   │
│  │   Target Executable (.exe)     │   │
│  │   - Standalone Windows binary  │   │
│  │   - No dependencies            │   │
│  │   - Direct OS syscalls         │   │
│  └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

---

*© 2025-2026 SYNAPSE Project. Built with FASM, x64 Assembly, and Pure Determination.*
*Last updated: January 2, 2026 - v3.2.0 "Ouroboros Returns"*
