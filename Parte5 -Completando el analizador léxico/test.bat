@echo off
    cls
    if exist "input.obj" del "input.obj"
    if exist "input.exe" del "input.exe"

    \masm32\bin\ml /c /coff "input.asm"
    if errorlevel 1 goto errasm

    \masm32\bin\PoLink /SUBSYSTEM:CONSOLE "input.obj"
    if errorlevel 1 goto errlink
    goto success

:errlink
    echo _
    echo Link error
    goto TheEnd

:errasm
    echo _
    echo Assembly Error
    goto TheEnd
    
:success
    del "input.obj"
    echo "Executing..."
    input.exe

:TheEnd
