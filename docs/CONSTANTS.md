# SYNAPSE COMPILER CONSTANTS & MAGIC NUMBERS

**Version:** 3.6.0-OUROBOROS  
**Purpose:** Documentation of hardcoded values (Magic Numbers) used in `synapse_full.syn` (Gen 1/2/3)  
**Status:** Pre-Refactoring Reference (Phase 70)  
**Next Step:** Phase 71 will add `const` keyword support to eliminate these literals

---

## 📖 Why This Document Exists

During Phase 69 (The Ouroboros), we discovered 6 critical "Magic Numbers" that enabled true self-hosting. However, the compiler is full of hardcoded values like `4194304`, `8232`, `0x1000` which make the code unreadable and fragile.

**Problem:** SYNAPSE currently has no global scope or `const` keyword support.  
**Solution:** Document → Implement Feature → Refactor (Phases 70→71→72)

---

## 1. PE HEADER CONSTANTS (Windows Executable)

### 1.1 Core PE Settings

| Value (Dec) | Value (Hex) | Name | Description | Location |
|-------------|-------------|------|-------------|----------|
| **4194304** | `0x400000` | **PE_IMAGE_BASE** | Standard EXE load address. Critical for absolute addressing. | `emit_pe_header` |
| **4096** | `0x1000` | **PE_SECT_ALIGN** | Section alignment in memory. Windows requires minimum 4KB for page mapping. | `emit_pe_header` |
| **512** | `0x200` | **PE_FILE_ALIGN** | Section alignment on disk. PE standard. | `emit_pe_header` |
| **34** | `0x22` | **PE_CHARS** | `IMAGE_FILE_EXECUTABLE_IMAGE` (0x02) \| `IMAGE_FILE_LARGE_ADDRESS_AWARE` (0x20). **Must be 0x22, NOT 0x23!** | `emit_pe_header` |
| **5** | `0x05` | **PE_MAJOR_SUBSYS_VER** | Windows XP+ compatibility. Version 0 is blocked by Win10/11 loader. | `emit_pe_header` |

### 1.2 Memory Sizes

| Value (Dec) | Value (Hex) | Name | Description | Location |
|-------------|-------------|------|-------------|----------|
| **1048576** | `0x100000` | **STACK_COMMIT** | Stack size (1MB). Prevents Stack Overflow during deep recursion. | `emit_pe_header` |
| **65536** | `0x10000` | **STACK_RESERVE** | Stack reserve (64KB). Initial committed pages. | `emit_pe_header` |
| **1048576** | `0x100000` | **HEAP_COMMIT** | Heap reserve (1MB). | `emit_pe_header` |
| **4096** | `0x1000` | **HEAP_RESERVE** | Heap commit (4KB). Initial pages. | `emit_pe_header` |

### 1.3 Section Virtual Sizes

| Value (Dec) | Value (Hex) | Name | Description | Location |
|-------------|-------------|------|-------------|----------|
| **262144** | `0x40000` | **PE_TEXT_VSIZE** | Virtual size of `.text` section (256KB). Must fit all code + heap. | `emit_pe_header` |
| **256** | `0x100` | **PE_IDATA_VSIZE** | Virtual size of `.idata` section (256 bytes). Import directory. | `emit_pe_header` |
| **1048576** | `0x100000` | **PE_BSS_VSIZE** | Virtual size of `.bss` section (1MB). Uninitialized data. | `emit_pe_header` |

### 1.4 File Raw Sizes

| Value (Dec) | Value (Hex) | Name | Description | Location |
|-------------|-------------|------|-------------|----------|
| **65536** | `0x10000` | **TEXT_RAW_SIZE** | `.text` raw data on disk (64KB). | `emit_pe_header` |
| **512** | `0x200` | **IDATA_RAW_SIZE** | `.idata` raw data on disk (512 bytes). | `emit_pe_header` |

### 1.5 PE Structure Sizes

| Value (Dec) | Value (Hex) | Name | Description | Location |
|-------------|-------------|------|-------------|----------|
| **1318912** | `0x142000` | **SIZE_OF_IMAGE** | Total virtual memory size (.text + .idata + .bss + headers). | `emit_pe_header` |
| **512** | `0x200` | **SIZE_OF_HEADERS** | DOS header + PE header + section headers. | `emit_pe_header` |
| **200** | `0xC8` | **SIZE_IMPORT_DIR** | Import Directory size. | `emit_pe_header` |
| **88** | `0x58` | **SIZE_IAT** | Import Address Table size (11 entries × 8 bytes). | `emit_pe_header` |

---

## 2. MEMORY LAYOUT & ALLOCATOR

### 2.1 BSS Section (Uninitialized Data)

| Value (Dec) | Value (Hex) | Name | Description | Location |
|-------------|-------------|------|-------------|----------|
| **4464640** | `0x442000` | **BSS_ADDR** | Address of `.bss` section. Stores heap pointer. | `my_alloc` |
| **4464648** | `0x442008` | **HEAP_DATA_START** | Start of heap data (BSS_ADDR + 8). | `my_alloc` |

**Why 0x442000?**
- `.text` at 0x401000 + 256KB (0x40000) = 0x441000
- `.idata` at 0x441000 + 4KB padding = 0x442000

### 2.2 Legacy Heap (Padding-based, Phase 55-69)

| Value (Dec) | Value (Hex) | Name | Description | Status |
|-------------|-------------|------|-------------|--------|
| **4251648** | `0x40E000` | **HEAP_PTR_ADDR_OLD** | Legacy heap pointer in `.text` padding. | ⚠️ Deprecated |
| **4251656** | `0x40E008` | **HEAP_DATA_START_OLD** | Legacy heap data start. | ⚠️ Deprecated |

**Note:** Early versions (Phase 55-69) stored heap pointer in padding area of `.text` section. Phase 70+ uses proper `.bss` section.

---

## 3. RVA (RELATIVE VIRTUAL ADDRESSES)

### 3.1 Section Start Addresses

| Value (Dec) | Value (Hex) | Name | Description |
|-------------|-------------|------|-------------|
| **4096** | `0x1000` | **RVA_TEXT** | Start of `.text` section (code). |
| **4096** | `0x1000` | **RVA_ENTRY** | Entry point (same as `.text` start). |
| **266240** | `0x41000` | **RVA_IDATA** | Start of `.idata` (imports). *Depends on .text size!* |
| **270336** | `0x42000` | **RVA_BSS** | Start of `.bss` (uninitialized data). |

### 3.2 Import Address Table (IAT)

| Value (Dec) | Value (Hex) | Name | Description | Critical? |
|-------------|-------------|------|-------------|-----------|
| **266280** | `0x41028` | **RVA_IAT** | IAT start address (IDATA + 40 bytes offset). | ✅ YES! |

**Why 0x41028?**
- Import Directory: 0x41000 (RVA_IDATA)
- Import Lookup Table (ILT): +0 bytes
- Import Directory Entry: +20 bytes
- Import Name Table (INT): +20 bytes
- **IAT offset:** +40 bytes (0x28)
- Result: 0x41000 + 0x28 = **0x41028**

**Critical:** Incorrect IAT RVA → `VirtualAlloc` / `ExitProcess` calls fail → Program crashes!

---

## 4. SECTION CHARACTERISTICS

| Value (Dec) | Value (Hex) | Name | Flags | Section |
|-------------|-------------|------|-------|---------|
| **3758096416** | `0xE0000020` | **SECT_CHARS_TEXT** | `CODE | EXECUTE | READ | WRITE` | `.text` |
| **3221225536** | `0xC0000040` | **SECT_CHARS_IDATA** | `INITIALIZED_DATA | READ | WRITE` | `.idata` |
| **3221225600** | `0xC0000080` | **SECT_CHARS_BSS** | `UNINITIALIZED_DATA | READ | WRITE` | `.bss` |

---

## 5. IAT FUNCTION INDICES

The Import Address Table (IAT) contains pointers to Windows API functions. These are called via `emit_iat_call(state, index)`.

| Index | Function | DLL | Usage | Working? |
|-------|----------|-----|-------|----------|
| **0** | `ExitProcess` | KERNEL32.DLL | Program termination | ✅ Phase 69 |
| **1** | `VirtualAlloc` | KERNEL32.DLL | Memory allocation | ✅ Phase 69 |
| **2** | `VirtualFree` | KERNEL32.DLL | Memory deallocation | ⏳ Not tested |
| **3** | `WriteFile` | KERNEL32.DLL | File/console output | ⏳ Phase 70 target |
| **4** | `ReadFile` | KERNEL32.DLL | File input | ⏳ Phase 71 target |
| **5** | `CreateFileA` | KERNEL32.DLL | File operations | ⏳ Phase 71 target |
| **6** | `CloseHandle` | KERNEL32.DLL | Handle cleanup | ⏳ Phase 71 target |
| **7** | `GetStdHandle` | KERNEL32.DLL | Console handles | ⏳ Phase 70 target |
| **8** | `GetCommandLineA` | KERNEL32.DLL | Command line args | ⏳ Future |
| **9** | `GetFileSize` | KERNEL32.DLL | File size query | ⏳ Future |
| **10** | `SetFilePointer` | KERNEL32.DLL | File seeking | ⏳ Future |

**Usage Example:**
```synapse
emit_iat_call(state, 0)  // Call ExitProcess
```

---

## 6. THE MAGIC NUMBERS (PHASE 69 BREAKTHROUGH)

These 6 values enabled true multi-generation self-hosting:

| # | Field | Before | After | Impact |
|---|-------|--------|-------|--------|
| 1 | **ImageBase** | 0x140000000 | **0x400000** | Standard x86 addressing |
| 2 | **Characteristics** | 0x23 | **0x22** | Remove RELOC_STRIPPED flag |
| 3 | **SizeOfCode** | dynamic | **0x1000** | Fixed 4KB alignment |
| 4 | **MajorSubsystemVersion** | 0 | **5** | Windows XP+ compatibility |
| 5 | **.text VirtualSize** | 65536 | **262144** | Proper alignment (256KB) |
| 6 | **.idata VirtualSize** | 512 | **256** | Correct size |

**Source:** `SELF_HOSTING_VICTORY.md`, Phase 69 debug logs

---

## 7. BUFFER SIZES (COMPILER INTERNAL)

| Value (Dec) | Name | Description | Location |
|-------------|------|-------------|----------|
| **65536** | **CODE_BUF_SIZE** | Generated machine code buffer (64KB) | `init_compiler` |
| **16384** | **DATA_BUF_SIZE** | String literals and data (16KB) | `init_compiler` |
| **131072** | **EXE_BUF_SIZE** | Final PE executable buffer (128KB) | `init_compiler` |
| **65536** | **TOKENS_BUF_SIZE** | Lexer token storage (64KB) | `tokenize` |
| **16384** | **SOURCE_BUF_SIZE** | Source code input buffer (16KB) | `run_compiler` |

---

## 8. DOS HEADER CONSTANTS

| Value (Dec) | Value (Hex) | Name | Description |
|-------------|-------------|------|-------------|
| **128** | `0x80` | **DOS_PE_OFFSET** | Offset to PE signature (`e_lfanew`) |
| **77** | `0x4D` | **DOS_MAGIC_M** | DOS signature byte 1: 'M' |
| **90** | `0x5A` | **DOS_MAGIC_Z** | DOS signature byte 2: 'Z' |
| **80** | `0x50` | **PE_MAGIC_P** | PE signature byte 1: 'P' |
| **69** | `0x45` | **PE_MAGIC_E** | PE signature byte 2: 'E' |

---

## 9. COFF HEADER CONSTANTS

| Value (Dec) | Value (Hex) | Name | Description |
|-------------|-------------|------|-------------|
| **34404** | `0x8664` | **MACHINE_AMD64** | x86-64 architecture |
| **3** | `0x3` | **NUM_SECTIONS** | `.text`, `.idata`, `.bss` |
| **240** | `0xF0` | **SIZE_OF_OPT_HEADER** | Optional header size (PE32+) |

---

## 10. OPTIONAL HEADER CONSTANTS

| Value (Dec) | Value (Hex) | Name | Description |
|-------------|-------------|------|-------------|
| **523** | `0x20B` | **MAGIC_PE32PLUS** | PE32+ (64-bit) format |
| **3** | `0x3` | **SUBSYSTEM_CONSOLE** | Console application |
| **4** | `0x4` | **OS_VERSION_MAJOR** | Major OS version |
| **16** | `0x10` | **NUM_DATA_DIRS** | Number of data directory entries |

---

## 📋 REFACTORING ROADMAP

### Phase 70: Documentation (CURRENT) ✅
- [x] Create this document
- [x] Identify all magic numbers in codebase
- [x] Document their purpose and origin

### Phase 71: Const Keyword (NEXT) 🔄
- [ ] Add `const` keyword to lexer
- [ ] Implement compile-time substitution in parser
- [ ] Test with simple constants
- [ ] Compile-time constant folding

### Phase 72: The Great Refactoring 🧹
- [ ] Replace all numeric literals with named constants
- [ ] Verify binary equivalence (Gen N == Gen N+1)
- [ ] Update this document to show `const` definitions

---

## 🔍 HOW TO FIND MAGIC NUMBERS

**Search patterns in `synapse_full.syn`:**
```bash
grep -E '[0-9]{5,}' synapse_full.syn  # Large numbers
grep -E 'put_dword\(state, [0-9]+\)' synapse_full.syn  # PE writes
grep -E '0x[0-9A-F]{4,}' synapse_full.syn  # Hex literals
```

**Critical sections:**
- `emit_pe_header()` — PE structure generation
- `emit_import_table()` — IAT setup
- `my_alloc()` — Heap pointer management
- `emit_iat_call()` — RIP-relative call generation

---

## 🎯 SUCCESS CRITERIA

**Phase 72 is complete when:**
1. ✅ No magic numbers in `emit_pe_header()` (except well-commented structure offsets)
2. ✅ All memory addresses use named constants
3. ✅ Binary equivalence test passes: `fc /b synapse_new.exe out.exe` (identical)
4. ✅ Bootstrap cycle works: Gen 1 → Gen 2 → Gen 3 (all 66,560 bytes, functionally identical)

---

**Last Updated:** January 5, 2026  
**Status:** Phase 70 Complete ✅  
**Next:** Phase 71 — Implement `const` keyword support

---

*"Magic numbers are technical debt. Named constants are documentation."* — The Pragmatic Programmer
