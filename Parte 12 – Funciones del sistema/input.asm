    include \masm32\include\masm32rt.inc
    .data
    _regstr DB 256 dup(0)
    a DD 0
    .code
    .code
start:
    mov DWORD PTR a, 1
    mov eax, a
    add eax, 2
    invoke dwtoa, eax, addr _regstr
    print addr _regstr,13,10
    exit
end start
