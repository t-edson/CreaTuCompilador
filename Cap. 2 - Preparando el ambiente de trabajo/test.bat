@echo off
    REM *** Set path and files ***
    SET THIS_DIR=%~dp0
    SET THIS_UNIT=%~d0
    SET OBJ_FILE=%THIS_DIR%input.obj
    SET ASM_FILE=%THIS_DIR%input.asm
    SET EXE_FILE=%THIS_DIR%input.exe

    %THIS_UNIT%
    cd %THIS_DIR%

    REM *** Compile ***
    cls
    titan.exe
    if errorlevel 1 goto TheEnd

    REM *** Assemble and link ***

    if exist "input.obj" del %OBJ_FILE%
    if exist "input.exe" del %EXE_FILE%

    \masm32\bin\ml /c /coff %ASM_FILE%
    if errorlevel 1 goto errasm

    \masm32\bin\PoLink /SUBSYSTEM:CONSOLE %OBJ_FILE%
    if errorlevel 1 goto errlink
    goto success

:errlink
    echo _
    echo !!!Link error
    goto TheEnd

:errasm
    echo _
    echo !!!Assembly Error
    goto TheEnd
    
:success
    del %OBJ_FILE%
    echo "Executing..."
    %EXE_FILE%

:TheEnd
