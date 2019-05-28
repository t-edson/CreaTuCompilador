    include \masm32\include\masm32rt.inc
    .data
    _regstr DB 256 dup(0)
    x DD 10 dup(0)
    a DB 256 dup(0)
    .code
start:
    exit
end start
