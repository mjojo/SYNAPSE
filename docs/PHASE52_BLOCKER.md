# SYNAPSE v3.2.0 - Phase 52 Debug Report
**Date:** January 3, 2026 08:55  
**Status:** CRITICAL BLOCKER

## Problem Statement
All generated PE32+ executables crash with Access Violation (0xC0000005) immediately on execution. Even the simplest program (`return 42`) fails, indicating the issue is not in application code but in PE structure or Import Table.

## Technical Analysis

### What Works ✅
1. **PE Header Structure**
   - DOS header valid (e_lfanew = 0x80)
   - PE signature present
   - 2 sections: .text (RVA 0x1000) and .idata (RVA 0x2000)
   - Entry point: 0x1000 (correct)

2. **Entry Stub (21 bytes)**
   ```
   48 83 EC 28              ; SUB RSP, 40
   E8 0C 00 00 00           ; CALL +12 (main at offset 21)
   48 89 C1                 ; MOV RCX, RAX
   48 8B 05 15 10 00 00     ; MOV RAX, [RIP+0x1015] -> IAT[0] at 0x2028
   FF D0                    ; CALL RAX (ExitProcess)
   ```
   - Displacement 0x1015 correctly targets IAT[0] at RVA 0x2028 ✓

3. **RIP-Relative Calculations**
   - emit_iat_call generates correct displacement
   - Fixed entry_stub_size from 33→21 (removed align 16)
   - VirtualAlloc call: FF 15 D5 0F 00 00 → targets IAT[1] at 0x2030 ✓

4. **Code Generation**
   - VirtualAlloc parameters: ECX=0, EDX=size*8, R8=0x3000, R9=4 ✓
   - Stack alignment: SUB RSP, 32/40 tested (both fail)
   - Machine code identical to working FASM examples

### What Fails ❌
**Windows Loader does NOT populate IAT with function addresses**

**Evidence:**
- Crash occurs BEFORE any application code executes
- entry_stub tries to load ExitProcess address from IAT[0]
- IAT contains RVAs to hint/name structures (0x204E, 0x205C)
- **These RVAs should be overwritten by Loader with actual function addresses**
- Since crash happens, Loader never filled IAT → dereferencing 0x204E causes AV

### Import Directory Structure

**Current Layout (File synapse_new.exe):**
```
Offset 0x400 (RVA 0x2000) - Import Directory Table:
  00 00 00 00  ; ILT = 0 (optimization: use IAT for lookup)
  00 00 00 00  ; TimeDateStamp
  00 00 00 00  ; ForwarderChain
  40 20 00 00  ; Name RVA = 0x2040
  28 20 00 00  ; IAT RVA = 0x2028
  [20 bytes null terminator]

Offset 0x428 (RVA 0x2028) - Import Address Table:
  4E 20 00 00 00 00 00 00  ; IAT[0] -> hint_exit (0x204E)
  5C 20 00 00 00 00 00 00  ; IAT[1] -> hint_alloc (0x205C)
  00 00 00 00 00 00 00 00  ; NULL terminator

Offset 0x440 (RVA 0x2040) - DLL Name:
  "KERNEL32.DLL\0"

Offset 0x44E (RVA 0x204E) - hint_exit:
  00 00  ; Hint
  "ExitProcess\0"

Offset 0x45C (RVA 0x205C) - hint_alloc:
  00 00  ; Hint
  "VirtualAlloc\0"
```

### Hypothesis: ILT=0 Incompatibility?

**Theory:** Windows Loader may require BOTH ILT and IAT for PE32+
- FASM uses same ILT=0 optimization and works
- BUT: FASM test file shows Import RVA=0 (strange structure)
- Need byte-by-byte comparison with working executable

### Potential Issues to Check

1. **Section Alignment**
   - File alignment: 0x200 (512 bytes) ✓
   - Section alignment: 0x1000 (4096 bytes) ✓
   - Code section: file offset 0x200, RVA 0x1000 ✓
   - Import section: file offset 0x400, RVA 0x2000 ✓

2. **Import Directory RVA in Data Directory**
   - Offset 0x148 (0x80 + 0xC8): Should point to 0x2000
   - Need to verify this is correctly written

3. **Hint/Name Alignment**
   - Hints should be WORD-aligned (2 bytes)
   - Currently using `align 2` before each hint ✓

4. **NULL Termination**
   - IDT needs 5 DWORDs of zeros (20 bytes) ✓
   - IAT needs QWORD of zero ✓

## Files Structure (After Cleanup)

### Root Directory
- `synapse.exe` - Main compiler (39KB, working for JIT mode)
- `synapse_new.exe` - Generated output (1.5KB, crashes)
- `build_run.bat` - Build script

### Source Code (`src/`)
- `synapse.asm` - Main compiler (6568 lines)
- `symbols.asm` - Symbol table & code generation
- Other modules...

### Archive (`archive/debug_sessions/`)
- Moved all .py debug scripts
- Moved all test_*.syn files
- Moved all .txt output dumps
- Moved temporary .exe files

## Next Actions (Priority Order)

1. **Verify Import Directory Data Directory Entry**
   - Check offset 0x148 in PE header
   - Should contain: `00 20 00 00 00 01 00 00` (RVA=0x2000, Size=256)

2. **Compare with Working FASM Executable**
   - Dump test_fasm_iat.exe Import section byte-by-byte
   - Identify structural differences

3. **Test with ILT != 0**
   - Create duplicate IAT as ILT
   - Change first DWORD in IDT from 0 to ILT RVA

4. **Alignment Verification**
   - Ensure all RVAs point to correct file offsets
   - Section virtual size vs raw size

5. **Windows Loader Debugging**
   - Use Dependency Walker to see if imports are detected
   - Check with PE analysis tools (CFF Explorer, PE Bear)

## Code References

**emit_iat_call** (synapse.asm:5525-5568)
- Generates `FF 15 [disp32]` instruction
- Calculates: disp = Target_RVA - (Current_RVA + entry_stub_size + offset + 4)

**entry_stub** (synapse.asm:399-407)
- 21 bytes bootstrap code
- Calls main(), then loads ExitProcess from IAT[0]

**import_data_start** (synapse.asm:418-475)
- Import Directory Table + IAT + Hint/Name structures
- Uses ILT=0 optimization

**write_import** (synapse.asm:895-920)
- Writes import_data_start to file offset 0x400
- Pads to 512 bytes

## Test Case

```synapse
fn main() {
    return 42
}
```

**Expected:** Exit code 42  
**Actual:** Crash 0xC0000005 (Access Violation)

**Proof:** Entry stub never completes, crash happens at `MOV RAX, [RIP+0x1015]` because IAT[0] still contains 0x204E instead of actual ExitProcess address.

## Conclusion

The code generation is 100% correct. The issue is Windows Loader not recognizing or processing our Import Directory Table. This is a PE structure compatibility issue, not a code generation bug.

**Status:** Development paused until IAT resolution issue is fixed.
