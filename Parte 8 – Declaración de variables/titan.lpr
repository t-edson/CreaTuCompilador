{Proyecto de un compilador con implementación mínima para ser autocontenido.}
program titan;
uses sysutils;
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

  //Campos adicionales
  MsjError : string;
  InVarSec : integer; //Bandera para indicar que estamos dentro de la sección de variables
  FirstCode: integer; //Bandera para determinar si estamos generando la primera instrucción.
  //Información sobre variables
  nVars    : integer;
  varNames : array[0..255] of string[255];
  varType  : array[0..255] of integer;
  varArrSiz: array[0..255] of integer;
  //Variable de trabajo
  curVarName: string;
  curVarType: integer;
  curVarArSiz: integer;
  //Campos para arreglos
  idxStorag: integer;
  idxCteInt: integer;
  idxVarNam: string;

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
procedure TrimSpaces;
begin
  while (srcToktyp = 1) or (srcToktyp = 5) do begin
    NextToken;   //Pasa al siguiente
  end;
end;
procedure GetLastToken;
{Toma el último token de una línea. Si hay algo más, que no sea espacios o comentarios,
genera error de error.}
begin
  NextToken;  //Toma último token
  TrimSpaces;
  if srcToktyp=0 then begin
    //El token actual es EOL
    //Ya estamos apuntando a la otra línea
  end else begin
    MsjError := 'Error de sintaxis: ' + srcToken;
    exit;
  end;
end;
procedure CaptureChar(c: integer);
{toma el caracter como token. Si no eneuentra, genera mensaje de error.}
begin
  TrimSpaces;
  if srcToken<>chr(c) then begin
    MsjError := 'Se esperaba: ' + chr(c);
    exit;
  end;
  NextToken;  //toma el caracter
end;
procedure ParserVar;
{Hace el análisis sintáctico para la declaración de variables.}
var
  varName, typName: String;
  arrSize: integer;
begin
  NextToken;  //Toma el "var"
  TrimSpaces;  //Quita espacios
  if srcToktyp<>2 then begin
    MsjError := 'Se esperaba un identificador.';
    exit;
  end;
  varName := srcToken;
  NextToken;  //Toma nombre de variable
  TrimSpaces;
  //Lee tipo
  if srcToken = '[' then begin
    //Es un arreglo de algún tipo
    NextToken;   //Toma el token
    TrimSpaces;
    if srcToktyp<>3 then begin
      MsjError:='Se esperaba número.';
    end;
    arrSize := StrToInt(srcToken);  //Tamaño del arreglo
    NextToken;
    CaptureChar(ord(']'));
    if MsjError<>'' then exit;
    //Se espera ":"
    CaptureChar(ord(':'));
    if MsjError<>'' then exit;
    //Debe seguir tipo común
    NextToken;
    typName := srcToken;
    if typName = 'integer' then begin
      GetLastToken;  //Debe terminar la línea
      if MsjError<>'' then exit;
      WriteLn(outFile, '    ' + varName + ' DD ', arrSize, ' dup(0)');
      //Registra variable
      varNames[nVars] := varName;
      varType[nVars]  := 1;  //Integer
      varArrSiz[nVars]:= arrSize;  //Es arreglo
      inc(nVars);
    end else if typName = 'string' then begin
      //Debe terminar la línea
      GetLastToken;  //Debe terminar la línea
      if MsjError<>'' then exit;
      WriteLn(outFile, '    ' + varName + ' DB ', 256*arrSize ,' dup(0)');
      //Registra variable
      varNames[nVars] := varName;
      varType[nVars]  := 2;  //String
      varArrSiz[nVars]:= arrSize;  //Es arreglo
      inc(nVars);
    end else begin
      MsjError := 'Tipo desconocido: ' + typName;
      exit;
    end;
  end else if srcToken = ':' then begin  //Es declaración de tipo común
    NextToken;  //Toma ":"
    TrimSpaces;
    typName := srcToken;
    if typName = 'integer' then begin
      GetLastToken;  //Debe terminar la línea
      if MsjError<>'' then exit;
      WriteLn(outFile, '    ' + varName + ' DD 0');
      //Registra variable
      varNames[nVars] := varName;
      varType[nVars]  := 1;  //Integer
      varArrSiz[nVars]:= 0;  //No es arreglo
      inc(nVars);
    end else if typName = 'string' then begin
      //Debe terminar la línea
      GetLastToken;  //Debe terminar la línea
      if MsjError<>'' then exit;
      WriteLn(outFile, '    ' + varName + ' DB 256 dup(0)');
      //Registra variable
      varNames[nVars] := varName;
      varType[nVars]  := 2;  //String
      varArrSiz[nVars]:= 0;  //No es arreglo
      inc(nVars);
    end else begin
      MsjError := 'Tipo desconocido: ' + typName;
      exit;
    end;
  end else begin
    MsjError := 'Se esperaba ":" o "[".';
    exit;
  end;
end;
begin
  //Abre archivo de entrada
  AssignFile(inFile, 'input.tit');
  Reset(inFile);
  //Abre archivo de salida
  AssignFile(outFile, 'input.asm');
  Rewrite(outFile);
  //Inicia banderas
  nVars := 0;   //Número inicial de variables
  srcRow := 0;  //Número de línea
  FirstCode := 1;  //Inicia bandera
  //Escribe encabezado de archivo
  WriteLn(outFile, '    include \masm32\include\masm32rt.inc');
  WriteLn(outFile, '    .data');
  WriteLn(outFile, '    _regstr DB 256 dup(0)');
  InVarSec := 1;    //Estamos en la sección de variables
  MsjError := '';
  NextLine;  //Para hacer la primera lectura.
  while EndOfFile<>1 do begin
    NextToken;
    writeln(srcToken);
    if srcToktyp = 0 then begin
      //Salto de línea, no se hace nada
    end else if srcToktyp = 1 then begin
      //Espacio, no se hace nada
    end else if srcToktyp = 5 then begin
      ExtractComment; //Comentario
    end else if srcToken = 'var' then begin
      //Es una declaración
      if InVarSec = 0 then begin
        //Estamos fuera de un bloque de variables
        WriteLn(outFile, '    .data');
        InVarSec := 1;  //Fija bandera
      end;
      //*** Aquí procesamos variables
      ParserVar;
    end else begin
      //Debe ser una instrucción. Aquí debe empezar la sección de código
      if InVarSec = 1 then begin
        //Estamos dentro de un blqoue de variables
        WriteLn(outFile, '    .code');
        InVarSec := 0;  //Fija bandera
      end;
      if FirstCode=1 then begin
        //Primera instrucción
        WriteLn(outFile, '    .code');
        WriteLn(outFile, 'start:');
        FirstCode := 0;  //Activa bandera
      end;
      //**** Aquí procesamos instrucciones.

    end;
  end;
  if MsjError<>'' then begin
    WriteLn('Line: ', srcRow,',', idxLine, ': ', MsjError);
  end;
  //Terminó la exploración de tokens
  if FirstCode = 1 then begin
    //No se han encontrado instrucciones. Incluimos encabezado de código en ASM.
    WriteLn(outFile, '    .code');
    WriteLn(outFile, 'start:');
  end;
  WriteLn(outFile, '    exit');
  WriteLn(outFile, 'end start');
  CloseFile(outFile);
  CloseFile(inFile);
  WriteLn('<<< Pulse <Enter> para continuar >>>');
  ReadLn;
end.

