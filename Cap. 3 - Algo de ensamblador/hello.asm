    include \masm32\include\masm32rt.inc
.data         
    AppName db "GUI Assembler Hello", 0
.code
start:
    invoke MessageBox, 0, chr$("Hola Windows"), addr AppName, MB_OK
    exit
end start