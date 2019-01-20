    include \masm32\include\masm32rt.inc
    .data
    _regstr DB 256 dup(0)
    cad DB 12800 dup(0)
    .code
start:
    .data
    _ctestr0 db "Hola",0
    .code
    invoke szCopy,addr _ctestr0, addr cad + 256
    invoke szCopy,addr cad+256, addr _regstr
    print addr _regstr,13,10
    exit
end start
