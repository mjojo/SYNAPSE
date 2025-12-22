@echo off
echo ============================================
echo SYNAPSE SHELL - Automated Test
echo ============================================
echo.
echo [TEST 1] Command: help
echo help| bin\synapse.exe examples\shell.syn
echo.
echo ============================================
echo [TEST 2] Command: unknown
echo unknown| bin\synapse.exe examples\shell.syn
echo.
echo ============================================
echo [TEST 3] Command: exit
echo exit| bin\synapse.exe examples\shell.syn
echo.
echo ============================================
echo Tests completed!
