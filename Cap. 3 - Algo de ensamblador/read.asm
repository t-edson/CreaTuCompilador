include     \masm32\include\masm32rt.inc

.data
    str1    db 'Escribe tu nombre: ',13,10, 0
    str2    db '%s',0
    str3    db 'Hola %s. Soy un programa.', 0

.data? ;Datos sin inicializar
    buffer  db 64 dup(?)

.code
start:
    invoke  crt_printf, ADDR str1
    invoke  crt_scanf, ADDR str2, ADDR buffer
    invoke  crt_printf, ADDR str3, ADDR buffer
    invoke  ExitProcess,0
END start