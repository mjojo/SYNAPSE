# 🧠 SYNAPSE v3.2 "Ouroboros Returns"

**Unhackable AI on Bare Metal Assembly**
*The World's First Self-Hosting Blockchain AI Platform with Graphics & GUI*

<div align="center">

![Version](https://img.shields.io/badge/version-3.2.0--ouroboros--returns-gold)
![Status](https://img.shields.io/badge/status-SELF_HOSTING-brightgreen)
![Arch](https://img.shields.io/badge/arch-x64_AVX2-red)
![Graphics](https://img.shields.io/badge/graphics-GDI%2B-blue)
![License](https://img.shields.io/badge/license-MIT-yellow)

</div>

## 🚀 Technical Specifications (v3.2)

| Specification | Status | Description |
|---------------|--------|-------------|
| **Self-Hosting** | ✅ **YES** | Compiler can compile itself and generate standalone EXE |
| **Architecture** | x64 JIT | Three-level virtualization (Host -> Guest -> Target) |
| **Graphics** | ✅ **YES** | Direct VRAM access, GDI integration, 8x8 embedded font |
| **GUI** | ✅ **YES** | Mouse input, keyboard, clickable buttons |
| **Data Types** | Strong | `int` (64-bit), `ptr`, `string`, `array` |
| **Control Flow** | Full | `if`, `while`, `fn`, `return`, `recursion` |
| **Memory** | Manual | `alloc`, `ptr[i]`, Data Segment for literals |
| **Logic** | Complete | `==`, `<`, `>`, `+`, `-`, `*`, `/`, bitwise ops |
| **EXE Generation** | ✅ **YES** | PE32+ format, standalone executables |
| **Binary Size** | ~30 KB | Includes graphics, GUI, and file I/O |

---

## 🎆 The Ouroboros Returns

**SYNAPSE v3.2** represents the pinnacle of bootstrap compiler technology. Not only does it compile itself,
but it can generate **standalone Windows executables** that run without any dependencies.

### 🔥 New in v3.2 (Phase 51)
* **Bootstrap Infrastructure:** `bootstrap.syn` - full self-hosting compiler
* **PE32+ Generation:** Creates real `.exe` files from Synapse source
* **Enhanced File I/O:** `fopen`, `fread`, `fwrite` for reading source files
* **x64 Codegen:** Proper function prologue/epilogue with stack frames
* **Graphics Engine:** Direct pixel manipulation, drawing primitives
* **Mouse & Keyboard:** Real-time input handling for interactive applications

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
