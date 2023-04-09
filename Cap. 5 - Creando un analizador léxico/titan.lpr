{Proyecto de un compilador con implementación mínima para ser autocontenido.}
program titan;
var
  //Manejo de código fuente
  inFile   : Text;     //Archivo de entrada
  outFile  : Text;     //Archivo de salida
  idxLine  : integer;
  srcLine  : string;   //Línea leída actualmente
  srcRow   : integer;  //Número de línea áctual
  srcChar  : byte;     //Carácter leído actualmente

function next_is_EOL(): integer;
//Devuelve 1 si el siguiente token corresponde a un Fin de Línea (EOL).
begin
  if idxLine > length(srcLine) then begin
    exit(1);
  end else begin
    exit(0);
  end;
end;
function next_is_EOF(): integer;
//Devuelve 1 si el siguiente token corresponde a un Fin de Archivo (EOF).
begin
  if eof(inFile) then begin
    //Ya no hay más líneas pero aún hay que asegurarse de que estamos al
    //final de la línea anterior.
    if next_is_EOL()=1 then begin exit(1)
    end else begin exit(0); end;
  end else begin
    exit(0);
  end;
end;
procedure NextLine();
//Pasa a la siguiente línea del archivo de entrada
begin
  if eof(inFile) then begin exit; end;
  readln(inFile, srcLine);  //Lee nueva línea
  srcRow := srcRow + 1;
  idxLine:=1;    //Apunta a primer caracter
end;
procedure NextChar();
//Incrementa "idxLine". Pasa al siguiente caracter.
begin
  idxLine := idxLine + 1;  //Pasa al siguiente caracter
  //Actualiza "srcChar"
  if next_is_EOL()=1 then begin     //No hay más caracteres
    srcChar := 0;
  end else begin
    srcChar := ord(srcLine[idxLine]);
  end;
end;
begin
  //Abre archivo de entrada
  AssignFile(inFile, 'input.tit');
  Reset(inFile);
  NextLine();  //Lee primera línea en "srcLine"s
  idxLine := 0;  //Para empezar a leer en el caracter 1
  while next_is_EOL()=0 do begin
      NextChar();  //Toma caracter
      write(chr(srcChar)); //Hace algo con "scrChar"
    end;
  Close(inFile);
  ReadLn;
end.
