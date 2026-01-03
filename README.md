# 🧠 SYNAPSE v3.2 "Ouroboros Returns"

**Unhackable AI on Bare Metal Assembly**
*The World's First Self-Hosting Blockchain AI Platform with Graphics & GUI*

<div align="center">

![Version](https://img.shields.io/badge/version-3.2.0--ouroboros--returns-gold)
![Status](https://img.shields.io/badge/status-PHASE_52_BLOCKED-orange)
![Arch](https://img.shields.io/badge/arch-x64_AVX2-red)
![Graphics](https://img.shields.io/badge/graphics-GDI%2B-blue)
![License](https://img.shields.io/badge/license-MIT-yellow)

</div>

## 🚀 Technical Specifications (v3.2)

| Specification | Status | Description |
|---------------|--------|-------------|
| **Self-Hosting** | ⚠️ **BLOCKED** | Compiler generates PE32+, but IAT resolution fails (Phase 52) |
| **Architecture** | x64 JIT | Three-level virtualization (Host -> Guest -> Target) |
| **Graphics** | ✅ **YES** | Direct VRAM access, GDI integration, 8x8 embedded font |
| **GUI** | ✅ **YES** | Mouse input, keyboard, clickable buttons |
| **Data Types** | Strong | `int` (64-bit), `ptr`, `string`, `array` |
| **Control Flow** | Full | `if`, `while`, `fn`, `return`, `recursion` |
| **Memory** | Manual | `alloc`, `ptr[i]`, Data Segment for literals |
| **Logic** | Complete | `==`, `<`, `>`, `+`, `-`, `*`, `/`, bitwise ops |
| **EXE Generation** | ⚠️ **BLOCKED** | PE32+ format created, but Windows Loader fails on IAT |
| **Binary Size** | ~30 KB | Includes graphics, GUI, and file I/O |

---

## 🎆 The Ouroboros Returns

**SYNAPSE v3.2** represents ambitious bootstrap compiler technology with graphics capabilities and PE32+ generation.

### ⚠️ Current Status (Phase 52 - CRITICAL BLOCKER)
**Issue:** All generated executables crash with Access Violation (0xC0000005)  
**Cause:** Windows Loader not resolving Import Address Table (IAT)  
**Impact:** Cannot test VirtualAlloc, file I/O, or any API calls in generated .exe files  
**Details:** See `docs/PHASE52_BLOCKER.md` for technical analysis

### 🔥 Working Features (v3.2)
* **JIT Compilation:** Real-time x64 code generation and execution
* **Graphics Engine:** Direct pixel manipulation, window management
* **Mouse & Keyboard:** Real-time input handling for interactive apps
* **File I/O:** Read source files, write binary data (in JIT mode)
* **PE32+ Structure:** Valid DOS/PE headers, sections, entry point
* **Code Generation:** Correct machine code for all intrinsics

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
