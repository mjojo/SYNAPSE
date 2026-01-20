# Analyze VirtualAlloc call in synapse_new.exe

$bytes = [System.IO.File]::ReadAllBytes("synapse_new.exe")

# Find the code sequence for alloc
# MOV RDX, RAX (48 89 C2)
# XOR ECX, ECX (31 C9)
# MOV R8D, 0x3000 (41 B8 00 30 00 00)
# MOV R9D, 4 (41 B9 04 00 00 00)
# CALL [REL] (FF 15 ...)

$pattern = "48-89-C2-31-C9-41-B8-00-30-00-00-41-B9-04-00-00-00-FF-15"
$hex = [BitConverter]::ToString($bytes)

if ($hex -match $pattern) {
    Write-Host "Found alloc sequence!" -ForegroundColor Green
    $index = $hex.IndexOf($pattern) / 3
    Write-Host "Offset: 0x$($index.ToString('X'))"
    
    # Check the CALL offset (last 4 bytes of FF 15 xx xx xx xx)
    $callOffset = $index + 17 + 2 # +17 bytes prefix, +2 bytes FF 15
    $relAddr = [BitConverter]::ToInt32($bytes, $callOffset)
    Write-Host "Relative Address: 0x$($relAddr.ToString('X'))"
    
    # Calculate Target RVA
    # RVA of instruction after CALL = (Offset - 0x200 + 0x1000) + 17 + 6
    # Wait, offset in file -> RVA
    # .text starts at 0x200 (file) -> 0x1000 (RVA)
    $instrRVA = ($callOffset + 4) - 0x200 + 0x1000
    $targetRVA = $instrRVA + $relAddr
    Write-Host "Instruction RVA (next): 0x$($instrRVA.ToString('X'))"
    Write-Host "Target RVA (IAT entry): 0x$($targetRVA.ToString('X'))"
    
    # Expected IAT[1] RVA = 0x11028 + 8 = 0x11030
    if ($targetRVA -eq 0x11030) {
        Write-Host "Target RVA matches VirtualAlloc IAT entry!" -ForegroundColor Green
    } else {
        Write-Host "Target RVA MISMATCH! Expected 0x11030" -ForegroundColor Red
    }
} else {
    Write-Host "Alloc sequence not found!" -ForegroundColor Red
}
