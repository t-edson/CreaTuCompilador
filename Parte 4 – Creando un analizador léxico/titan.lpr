{Proyecto de un compilador con implementación mínima para ser autocontenido.}
program titan;
var
  //Manejo de código fuente
  inFile   : Text;    //Archivo de entrada
  outFile  : Text;    //Archivo de salida
  idxLine  : integer;
  srcLine  : string[255]; //Línea leída actualmente
  srcRow   : integer;  //Número de línea áctual
  srcChar  : byte;      //Caracter leído actualmente

function EndOfLine: integer;
begin
  if idxLine > length(srcLine) then exit(1) else exit(0);
end;
function EndOfFile: integer;
{Devuelve TRUE si ya no hay caracteres ni líneas por leer.}
begin
  if eof(inFile) then begin
    if EndOfLine<>0 then exit(1) else exit(0);
  end else begin
    exit(0);
  end;
end;
procedure NextLine;
//Pasa a la siguiente línea del archivo de entrada
begin
  if eof(inFile) then exit;
  readln(inFile, srcLine);  //Lee nueva línea
  inc(srcRow);
  idxLine:=1;    //Apunta a primer caracter
end;
procedure ReadChar;
{Lee el caracter actual y actualiza "srcChar".}
begin
   srcChar := ord(srcLine[idxLine]);
end;
procedure NextChar;
{Incrementa "idxLine". Pasa al siguiente caracter.}
begin
   idxLine := idxLine + 1;  //Pasa al siguiente caracter
end;
begin
  //Abre archivo de entrada
  AssignFile(inFile, 'input.tit');
  Reset(inFile);
  NextLine;  //Lee primera línea en "srcLine"s
  while EndOfLine=0 do begin
      ReadChar; //Lee en "scrChar"
      write(chr(srcChar)); //Hace algo con "scrChar"
      NextChar;  //Toma caracter
    end;
  Close(inFile);
  ReadLn;
end.
