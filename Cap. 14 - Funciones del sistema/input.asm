    include \masm32\include\masm32rt.inc
    .data
    _strA DB 256 dup(0)
    _strB DB 256 dup(0)
    .data
    cad DB 256 dup(0)
    .code
start:
    .data
    _cstr0 db "Hola",0
    .code
    invoke szCopy, addr _cstr0, addr _strA
    invoke szCopy, addr _strA, addr cad
    mov eax, 123
    invoke dwtoa, eax, addr _strA
    print addr _strA,13,10
    exit
end start
