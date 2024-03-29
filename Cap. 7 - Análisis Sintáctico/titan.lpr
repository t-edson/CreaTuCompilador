{Proyecto de un compilador con implementación mínima para ser autocontenido.}
program titan;
uses sysutils;
  //Manejo de código fuente
var inFile     : Text;     //Archivo de entrada
var outFile    : Text;     //Archivo de salida
var idxLine    : integer;  //Índice al siguiente token.
var srcLine    : string;   //Línea leída actualmente
var srcRow     : integer;  //Número de línea actual

  //Campos relativos a la lectura de tokens
var srcChar    : integer;  //Caracter leído actualmente
var srcToken   : string;   //Token actual
var srcToktyp  : integer;  //Tipo de token
var MsjError   : string;

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
function NextCharIs(car: string): integer;
//Devuelve TRUE(1) si el siguiente caracter (no el actual) es "car".
begin
  if idxLine > length(srcLine)-1 then begin exit(0); end;
  if srcLine[idxLine+1] = car then begin exit(1); end;
  exit(0);
end;
function IsAlphaUp(): integer;
//Indica si el caracter en "srcChar" es alfabético mayúscula.
begin
   if srcChar>=ord('A') then begin
     if srcChar<=ord('Z') then begin
       exit(1);
     end else begin
       exit(0);
     end;
   end else begin
     exit(0);
   end;
end;
function IsAlphaDown(): integer;
//Indica si el caracter en "srcChar" es alfabético minúscula.
begin
   if srcChar=ord('_') then begin exit(1); end;
   if srcChar>=ord('a') then begin
     if srcChar<=ord('z') then begin
       exit(1);
     end else begin
       exit(0);
     end;
   end else begin
     exit(0);
   end;
end;
function IsNumeric(): integer;
//Indica si el caracter en "srcChar" es numérico.
begin
   if srcChar>=ord('0') then begin
     if srcChar<=ord('9') then begin
       exit(1);
     end else begin
       exit(0);
     end;
   end else begin
     exit(0);
   end;
end;
procedure ExtractIdentifier();
var
  IsToken: integer;  //Variable temporal
begin
  srcToken := '';
  srcToktyp := 2;
  IsToken := 1;
  while IsToken=1 do begin
    srcToken := srcToken + chr(srcChar);   //Acumula
    NextChar();  //Pasa al siguiente
    if next_is_EOL()=1 then begin     //No hay más caracteres
      exit;
    end;
    IsToken := IsAlphaUp() or IsAlphaDown();
    IsToken := IsToken or IsNumeric();
  end;
end;
procedure ExtractSpace();
var
  IsToken: integer;  //Variable temporal
begin
  srcToken := '';
  srcToktyp := 1;
  IsToken := 1;
  while IsToken=1 do begin
    srcToken := srcToken + chr(srcChar);   //Acumula
    NextChar();  //Pasa al siguiente
    if next_is_EOL()=1 then begin     //No hay más caracteres
      exit;
    end;
    if srcChar = ord(' ') then begin
      IsToken := 1;
    end else if srcChar = 9 then begin
      IsToken := 1;
    end else begin
      IsToken := 0;
    end;
  end;
end;
procedure ExtractNumber();
var
  IsToken: integer;  //Variable temporal
begin
  srcToken := '';
  srcToktyp := 3;
  IsToken := 1;
  while IsToken=1 do begin
    srcToken := srcToken + chr(srcChar);   //Acumula
    NextChar();  //Pasa al siguiente
    if next_is_EOL()=1 then begin     //No hay más caracteres
      exit;
    end;
    IsToken := IsNumeric();
  end;
end;
procedure ExtractString();
var
  IsToken: integer;  //Variable temporal
begin
  srcToken := '';
  srcToktyp := 4;
  IsToken := 1;
  while IsToken=1 do begin
    srcToken := srcToken + chr(srcChar);   //Acumula
    NextChar();  //Pasa al siguiente
    if next_is_EOL()=1 then begin     //No hay más caracteres
      exit;
    end;
    if srcChar <> ord('"') then begin
      IsToken := 1;        //True
    end else begin
      IsToken := 0;        //False
    end;
  end;
  NextChar();  //Toma la comilla final
  srcToken := srcToken + '"';   //Acumula
end;
procedure ExtractComment();
begin
  srcToken := '';
  srcToktyp := 5;
  while next_is_EOL()=0 do begin
    srcToken := srcToken + chr(srcChar);   //Acumula
    NextChar();  //Toma caracter
  end;
end;
procedure NextToken();
//Lee un token y devuelve el texto en "srcToken" y el tipo en "srcToktyp".
//Mueve la posición de lectura al siguiente token.
begin
   srcToktyp := 9;  //Desconocido por defecto
   if next_is_EOF()=1 then begin
     srcToken := '';
     srcToktyp := 10;  //Devuelve token EOF
     exit;
   end;
   if next_is_EOL()=1 then begin
     //Estamos al fin de una línea.
     srcToken := '';
     srcToktyp := 0;  //Devolvemos Fin de línea
     NextLine();        //Movemos cursor al siguiente token.
   end else begin
     srcChar := ord(srcLine[idxLine]);
     //Hay caracteres por leer en la línea
     if IsAlphaUp()=1then begin
       ExtractIdentifier();
       exit;
     end else if IsAlphaDown()=1 then begin
       ExtractIdentifier();
       exit;
     end else if srcChar = ord('_') then begin
       ExtractIdentifier();
     end else if IsNumeric()=1 then begin
       ExtractNumber();
     end else if srcChar = ord(' ') then begin
       ExtractSpace();
     end else if srcChar = 9 then begin  //Tab
       ExtractSpace();
     end else if srcChar = ord('"') then begin
       ExtractString();
     end else if srcChar = ord('>') then begin
       srcToktyp := 6;   //Operador
       NextChar();  //Pasa al siguiente
       if srcChar = ord('=') then begin  //Es >=
         srcToken := '>=';
         NextChar();  //Pasa al siguiente
       end else begin      //Es ">"
         srcToken := '>';
       end;
     end else if srcChar = ord('<') then begin
       srcToktyp := 6;   //Operador
       NextChar();  //Pasa al siguiente
       if srcChar = ord('=') then begin  //Es <=
         srcToken := '<=';
         NextChar();  //Pasa al siguiente
       end else if srcChar = ord('>') then begin  //Es <>
         srcToken := '<>';
         NextChar();  //Pasa al siguiente
       end else begin      //Es ">"
         srcToken := '<';
       end;
     end else if srcChar = ord('/') then begin
       if NextCharIs('/') = 1 then begin  //Es comentario
         ExtractComment();
       end else begin
         srcToken := '/';   //Acumula
         srcToktyp := 9;   //Desconocido
         NextChar();  //Pasa al siguiente
       end;
     end else begin  //Cualquier otro caso
       srcToken := chr(srcChar);   //Acumula
       srcToktyp := 9;   //Desconocido
       NextChar();  //Pasa al siguiente
     end;
   end;
end;
//Análisis sintáctico
procedure TrimSpaces();
//Extrae espacios o comentarios o saltos de línea
begin
  while (srcToktyp = 1) or (srcToktyp = 5) or (srcToktyp = 0) do begin
    NextToken();   //Pasa al siguiente
  end;
end;
function Capture(c: string): integer ;
//Toma la cadena indicada. Si no la encuentra, genera mensaje de error y devuelve 0.
begin
  TrimSpaces();
  if srcToken<>c then begin
    MsjError := 'Se esperaba: "' + c + '"';
    exit(0);
  end;
  NextToken();  //Toma el caracter
  exit(1);
end;
function EndOfBlock(): integer;
//Indica si estamos en el fin de un bloque.
begin
  TrimSpaces();    //Quita espacios y comentarios.
  if srcToktyp = 10    then begin exit(1); end;  //Fin de archivo
  if srcToken = 'end'  then begin exit(1); end;
  if srcToken = 'else' then begin exit(1); end;
  exit(0);
end;
function EndOfInstruction(): integer;
//Indica si estamos en el fin de una instrucción.
begin
  if EndOfBlock() = 1 then begin exit(1); end;
  if srcToken = ';' then begin exit(1); end; //Delimitador
  exit(0);
end;
function EndOfExpression(): integer;
begin
  if EndOfInstruction() = 1 then begin exit(1); end;
  if srcToken = ',' then begin exit(1); end; //Terminó la expresión
  if srcToken = ')' then begin exit(1); end; //Terminó la expresión
  if srcToken = ']' then begin exit(1); end; //Terminó la expresión
  exit(0);
end;

procedure ProcessBlock;
//Procesa un bloque de código.
begin
  while EndOfBlock()<>1 do begin
    //Procesa la instrucción

    // ...
    //Verifica delimitador de instrucción
    Capture(';');
    if MsjError<>'' then begin exit; end;
  end;
end;
begin
  //Abre archivo de entrada
  AssignFile(inFile, 'input.tit');
  Reset(inFile);

  MsjError := '';
  NextLine();        //Prepara primera lectura.
  NextToken();       //Lee primer token

  ProcessBlock();   //Procesa programa.

  if MsjError<>'' then begin
    //Genera mensaje en un formato apropiado para la detección.
    WriteLn('ERROR: input.tit' + ' ('+IntToStr(srcRow) + ',' + IntToStr(idxLine)+'): ' + MsjError);
  end;

  Close(inFile);

  ReadLn;
  if MsjError='' then ExitCode:=0 else ExitCode := 1;
end.
