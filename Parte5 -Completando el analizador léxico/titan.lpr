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

  srcToken : string;
  srcToktyp: integer; // Tipo de token:

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
function NextCharIsSlash: integer;
{Incrementa "idxLine". Pasa al siguiente caracter.}
begin
  if idxLine > length(srcLine)-1 then exit(0);
  if srcLine[idxLine+1] = '/' then exit(1);
  exit(0);
end;
function IsAlphaUp: integer;
{Indica si el caracter en "srcChar" es alfabético mayúscula.}
begin
   if chr(srcChar)>='A' then begin
     if chr(srcChar)<='Z' then begin
       exit(1);
     end else begin
       exit(0);
     end;
   end else begin
     exit(0);
   end;
end;
function IsAlphaDown: integer;
{Indica si el caracter en "srcChar" es alfabético nimúscula.}
begin
   if chr(srcChar)>='a' then begin
     if chr(srcChar)<='z' then begin
       exit(1);
     end else begin
       exit(0);
     end;
   end else begin
     exit(0);
   end;
end;
function IsNumeric: integer;
{Indica si el caracter en "srcChar" es alfabético nimúscula.}
begin
   if chr(srcChar)>='0' then begin
     if chr(srcChar)<='9' then begin
       exit(1);
     end else begin
       exit(0);
     end;
   end else begin
     exit(0);
   end;
end;
procedure ExtractIdentifier;
var
  IsToken: integer;  //Variable temporal
begin
  srcToken := '';
  srcToktyp := 2;
  IsToken := 1;
  while IsToken=1 do begin
    srcToken := srcToken + chr(srcChar);   //Acumula
    NextChar;  //Pasa al siguiente
    if EndOfLine=1 then begin     //No hay más caracteres
      exit;
    end;
    ReadChar;  //Lee sigte. en "srcChar"
    IsToken := IsAlphaUp or IsAlphaDown;
    IsToken := IsToken or IsNumeric;
  end;
end;
procedure ExtractSpace;
var
  IsToken: integer;  //Variable temporal
begin
  srcToken := '';
  srcToktyp := 1;
  IsToken := 1;
  while IsToken=1 do begin
    srcToken := srcToken + chr(srcChar);   //Acumula
    NextChar;  //Pasa al siguiente
    if EndOfLine=1 then begin     //No hay más caracteres
      exit;
    end;
    ReadChar;  //Lee sigte. en "srcChar"
    IsToken := ord(srcChar = ord(' '));
  end;
end;
procedure ExtractNumber;
var
  IsToken: integer;  //Variable temporal
begin
  srcToken := '';
  srcToktyp := 3;
  IsToken := 1;
  while IsToken=1 do begin
    srcToken := srcToken + chr(srcChar);   //Acumula
    NextChar;  //Pasa al siguiente
    if EndOfLine=1 then begin     //No hay más caracteres
      exit;
    end;
    ReadChar;  //Lee sigte. en "srcChar"
    IsToken := IsNumeric;
  end;
end;
procedure ExtractString;
var
  IsToken: integer;  //Variable temporal
begin
  srcToken := '';
  srcToktyp := 4;
  IsToken := 1;
  while IsToken=1 do begin
    srcToken := srcToken + chr(srcChar);   //Acumula
    NextChar;  //Pasa al siguiente
    if EndOfLine=1 then begin     //No hay más caracteres
      exit;
    end;
    ReadChar;  //Lee sigte. en "srcChar"
    IsToken := ord(srcChar <> ord('"'));
  end;
  NextChar;  //Toma la comilla final
  srcToken := srcToken + '"';   //Acumula
end;
procedure ExtractComment;
begin
  srcToken := '';
  srcToktyp := 5;
  while EndOfLine=0 do begin
    srcToken := srcToken + chr(srcChar);   //Acumula
    NextChar;  //Toma caracter
  end;
end;
procedure NextToken;
//Lee un token y devuelve el texto en "srcToken" y el tipo en "srcToktyp".
//Mueve la posición de lectura al siguiente token.
begin
   srcToktyp := 9;  //Desconocido por defecto
   if EndOfFile=1 then begin
     srcToken := '';
     srcToktyp := 0;  //Fin de línea
     exit;
   end;
   if EndOfLine=1 then begin
     srcToken := '';
     srcToktyp := 0;  //Fin de línea
     NextLine;
   end else begin
     //Hay caracteres por leer en la línea
     ReadChar;  //Lee en "srcChar"
     if IsAlphaUp=1then begin
       ExtractIdentifier;
       exit;
     end;
     if IsAlphaDown=1 then begin
       ExtractIdentifier;
       exit;
     end;
     if srcChar = ord('_') then begin
       ExtractIdentifier;
       exit;
     end;
     if IsNumeric=1 then begin
       ExtractNumber;
       exit;
     end;
     if srcChar = ord(' ') then begin
       ExtractSpace;
       exit;
     end;
     if srcChar = ord('"') then begin
       ExtractString;
       exit;
     end;
     if srcChar = ord('/') then begin
         if NextCharIsSlash = 1 then begin
         ExtractComment;
         exit;
       end;
     end;
     srcToken := chr(srcChar);   //Acumula
     srcToktyp := 9;
     NextChar;  //Pasa al siguiente
   end;
end;
begin
  //Abre archivo de entrada
  AssignFile(inFile, 'input.tit');
  Reset(inFile);
  NextLine;  //Para hacer la primera lectura.
  while EndOfFile<>1 do begin
    NextToken;
    writeln(srcToken);
  end;
  Close(inFile);
  ReadLn;
end.

