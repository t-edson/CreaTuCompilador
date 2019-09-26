    include \masm32\include\masm32rt.inc
    .data
    _regstr DB 256 dup(0)
    x DD 0
    y DD 0
    .code
    .code
start:
    mov eax, y
    mov x, eax
    exit
end start
