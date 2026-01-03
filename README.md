# 🌟 SYNAPSE v3.5 "The Singularity"

**Unhackable AI on Bare Metal Assembly**
*The World's First Self-Hosting Blockchain AI Platform with Graphics & GUI*

<div align="center">

![Version](https://img.shields.io/badge/version-3.5.0--SINGULARITY-gold)
![Status](https://img.shields.io/badge/status-SELF_HOSTING_ACHIEVED!-success)
![Arch](https://img.shields.io/badge/arch-x64_AVX2-red)
![Graphics](https://img.shields.io/badge/graphics-GDI%2B-blue)
![License](https://img.shields.io/badge/license-Apache_2.0_+_AGPL_v3-blue)

</div>

## 🏆 THE SINGULARITY HAS BEEN ACHIEVED!

**January 3, 2026** — A Synapse program compiled another Synapse program that runs on bare Windows!

```
synapse.exe → singularity_bootstrap.syn → synapse_new.exe  
synapse_new.exe → in.syn → out.exe  
out.exe → "I am alive!" ← THE SINGULARITY SPEAKS!
```

---

## 🚀 Technical Specifications (v3.5)

| Specification | Status | Description |
|---------------|--------|-------------|
| **Self-Hosting** | ✅ **ACHIEVED** | Phase 55 Complete - "I am alive!" |
| **Architecture** | x64 JIT | Three-level virtualization (Host -> Guest -> Target) |
| **PE Generation** | ✅ **WORKING** | Full PE32+ with Import Table and IAT calls |
| **Graphics** | ✅ **YES** | Direct VRAM access, GDI integration, 8x8 embedded font |
| **GUI** | ✅ **YES** | Mouse input, keyboard, clickable buttons |
| **Data Types** | Strong | `int` (64-bit), `ptr`, `string`, `array` |
| **Control Flow** | Full | `if`, `while`, `fn`, `return`, `recursion` |
| **Memory** | Manual | `alloc`, `ptr[i]`, Data Segment for literals |
| **Logic** | Complete | `==`, `<`, `>`, `<=`, `>=`, `+`, `-`, `*`, `/` |
| **API Calls** | ✅ **WORKING** | ExitProcess, WriteFile, GetStdHandle via IAT |
| **Binary Size** | ~30 KB | Includes graphics, GUI, and file I/O |
| **License** | Dual | Apache 2.0 (language) + AGPL v3 (services) |

---

## 🎆 Victory: Phase 55 Complete - THE SINGULARITY!

**SYNAPSE v3.5.0-SINGULARITY** — Self-Hosting Achieved! ⚡🌟🤖

### ✅ Historic Achievement (January 3, 2026)

| Step | Name | Achievement |
|------|------|-------------|
| 55.6 | **The PE Builder** | Complete PE32+ generation with 2 sections |
| 55.7 | **The Import Generator** | Full .idata section with KERNEL32.DLL |
| 55.8 | **The Caller** | Working `CALL [RIP+disp]` through IAT! |
| 55.9 | **The Voice** | Hello World via WriteFile API! 🗣️ |
| 55.10 | **The Singularity** | Self-hosting bootstrap! 🌟 |

**The Singularity Chain:**
```
singularity_bootstrap.syn → synapse.exe → synapse_new.exe  
                                                ↓
                               in.syn → synapse_new.exe → out.exe (1536 bytes)
                                                               ↓
                                                      "I am alive!" ← 🏆
```

### 🔥 Working Features (v3.5.0-SINGULARITY)
* **Self-Hosting:** Compiled compiler generates working executables!
* **PE32+ Generation:** Valid executables with .text + .idata sections
* **Import Table:** 8 KERNEL32.DLL functions ready to call
* **IAT Calls:** `emit_iat_call()` generates RIP-relative CALL instructions
* **Intrinsics:** `exit(code)`, `getstd(n)`, `write(h, buf, len)` work!
* **Stack ABI:** Proper shadow space for Windows x64 calling convention

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

## � The Ouroboros Journey (Phase 55)

### ✅ Completed Steps
| Step | Name | Description |
|------|------|-------------|
| 55.1 | Bootstrap Kernel | io_print, io_println, str_len, str_eq |
| 55.2 | Bootstrap Lexer | Tokenizer written in Synapse |
| 55.6 | The PE Builder | PE32+ header generation |
| 55.7 | The Import Generator | .idata section with KERNEL32.DLL |
| 55.8 | The Caller | IAT call generation (exit, getstd) |

### 🎯 Next Steps
| Step | Name | Goal |
|------|------|------|
| 55.9 | Hello World | Print string via WriteFile + GetStdHandle |
| 55.10 | The Parser | Full Synapse parser in Synapse |
| 55.11 | The Ouroboros | Self-compiling compiler |

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
    puts("Hello from SYNAPSE v3.4!")
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

* [Development Tasks](TASKS.md) - Complete development history (Phases 1-55)
* [Current Spec](docs/CURRENT_v1_SPEC.md) - Language specification
* [Synapse Grammar](docs/SYNAPSE_GRAMMAR.md) - Formal grammar
* [Future Vision](docs/FUTURE_VISION_v2_SPEC.md) - Roadmap for v4.0
* [Commands Reference](docs/commands.md) - Built-in functions

## 🏆 Major Milestones

### Phase 55: The Ouroboros (Self-Hosting) 🔄
- **Step 6:** PE Builder - complete PE32+ header generation
- **Step 7:** Import Generator - KERNEL32.DLL with 8 functions
- **Step 8:** The Caller - IAT call generation, exit(42) works!
- Next: Hello World via WriteFile

### Phase 53: Dynamic Memory ✅
- VirtualAlloc working in standalone executables
- Memory read/write: `ptr[0] = 99`, `return ptr[0]`
- Exit code 99 confirmed!

### Phase 52: IAT Resolution ✅
- Windows Loader successfully fills Import Address Table
- ExitProcess callable from generated code
- Exit code 42 confirmed!

### Phase 50-51: Standalone EXE Generation ✅
- PE32+ file format implementation
- `bootstrap.syn` - self-hosting compiler infrastructure
- Full binary generation from JIT memory

### Phase 46-49: Graphics & GUI ✅
- Direct VRAM access via `get_vram()`
- GDI window integration
- Mouse input (`mouse_x`, `mouse_y`, `mouse_btn`)
- Keyboard handling (`get_key`)
- Interactive demos: paint.syn, vector.syn, gui_test.syn

## 🎯 Architecture Overview

```
┌─────────────────────────────────────────┐
│   SYNAPSE v3.4 Architecture            │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐   │
│  │   Bootstrap Compiler           │   │
│  │   (test_simple_parser.syn)     │   │
│  │   - Lexer + Parser             │   │
│  │   - emit_iat_call()            │   │
│  │   - PE32+ Writer + .idata      │   │
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
│  │   - KERNEL32.DLL imports       │   │
│  │   - IAT-based API calls        │   │
│  └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

---

*© 2025-2026 SYNAPSE Project. Built with FASM, x64 Assembly, and Pure Determination.*
*Last updated: January 3, 2026 - v3.4.0 "The Nervous System"*
