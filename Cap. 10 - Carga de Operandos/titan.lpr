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

//Información sobre variables
var nVars      : integer;      //Número de variables.
var varNames   : array[0..255] of string;
var varType    : array[0..255] of integer;
var varArrSiz  : array[0..255] of integer;
//Variable de trabajo
var curVarName : string;
var curVarType : integer;  //Tipo de dato: 1->integer. 2->string.
var curVarArSiz: integer;

//Expresiones
var resType    : integer;  //Tipo de dato: 1->integer. 2->string.
var constrName : string;   //Nombre de constante string usada actualmente
var nconstr    : integer;  //Número de constante string creada
//Análisis léxico
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
//Salida a archivo
procedure asmout(lin: string);
//Escribe una línea de ensamblador sin salto de línea.
begin
  Write(outFile, lin);
end;
procedure asmline(lin: string);
//Escribe una línea de ensamblador con un salto de línea al final.
begin
  WriteLn(outFile, '    ' + lin);
end;
//Análisis sintáctico-semántico.
procedure RegisterVar(vName: String; vType: integer; arrSiz: integer);
//Registra una variable en los arreglos correspondientes.
begin
  varNames[nVars] := vName;
  varType[nVars]  := vType;
  varArrSiz[nVars]:= arrSiz;
  nVars := nVars + 1;
end;
procedure ParserVar();
//Hace el análisis sintáctico para la declaración de variables.
var
  varName, typName: String;
  arrSize: string;     //Como cadena para concatenar
  arrSizeN: integer;   //Como número
  arrSize256: string;  //Tamaño por 256.
begin
  NextToken();   //Toma el "var"
  TrimSpaces();  //Quita espacios
  if srcToktyp<>2 then begin
    MsjError := 'Se esperaba un identificador.';
    exit;
  end;
  varName := srcToken;
  NextToken();  //Toma nombre de variable
  TrimSpaces();
  //Lee tipo
  if srcToken = '[' then begin
    //Es un arreglo de algún tipo
    NextToken();   //Toma el token
    TrimSpaces();
    if srcToktyp<>3 then begin
      MsjError:='Se esperaba número.';
      exit;
    end;
    arrSize := srcToken;  //Tamaño del arreglo
    arrSizeN := StrToInt(srcToken);  //Tamaño del arreglo
    arrSize256 := IntToStr(arrSizeN*256);
    NextToken();
    Capture(']');
    if MsjError<>'' then begin exit; end;
    //Se espera ":"
    Capture(':');
    if MsjError<>'' then begin exit; end;
    //Debe seguir tipo común
    TrimSpaces();
    typName := srcToken;
    if typName = 'integer' then begin
      NextToken();  //Toma token
      asmline(varName + ' DD ' + arrSize + ' dup(0)');
      RegisterVar(varName, 1, arrSizeN) //Registra arreglo Integer
    end else if typName = 'string' then begin
      //Debe terminar la línea
      NextToken();  //Toma token
      asmline(varName + ' DB '+ arrSize256 + ' dup(0)');
      RegisterVar(varName, 2, arrSizeN) //Registra arreglo String
    end else begin
      MsjError := 'Tipo desconocido: ' + typName;
      exit;
    end;
  end else if srcToken = ':' then begin  //Es declaración de tipo común
    NextToken();  //Toma ":"
    TrimSpaces();
    typName := srcToken;
    if typName = 'integer' then begin
      NextToken();  //Toma token
      asmline(varName + ' DD 0');
      RegisterVar(varName, 1, 0) //Registra Integer
    end else if typName = 'string' then begin
      NextToken();  //Toma token
      asmline(varName + ' DB 256 dup(0)');
      RegisterVar(varName, 2, 0) //Registra String
    end else begin
      MsjError := 'Tipo desconocido: ' + typName;
      exit;
    end;
  end else begin
    MsjError := 'Se esperaba ":" o "[".';
    exit;
  end;
end;
procedure FindVariable();
// Busca la variable con el nombre que está en "srcToken", y actualiza las variables:
// "curVarName", "curVarType", y "curVarArSiz".
// Si no encuentra, devuelve cadena vacía en "curVarName".
var
  tmp   : string;
  contin: integer;  //Bandera para continuar bucle.
  curVar: integer;  //Índice de variable.
begin
  curVar := 0;
  tmp := varNames[curVar];
  if tmp=srcToken then begin contin:=0; end else begin contin:=1; end;
  while contin=1 do begin
    curVar := curVar + 1;
    if curVar = 256 then begin break; end;
    tmp := varNames[curVar];
    if tmp=srcToken then begin contin:=0; end else begin contin:=1; end;
  end;
  //Verifica si encontró
  if contin=0 then begin
    curVarName := varNames[curVar];
    curVarType := varType[curVar];
    curVarArSiz := varArrSiz[curVar];
    exit;  //"curVar" contiene el índice
  end;
  //No encontró
  curVarName := '';
end;
//Análisis de expresiones
procedure DeclareConstantString(constStr: string);
{Inserta la declaración de una constante string, en la sección de datos, para
poder trabajarla.}
var
  tmp: String;
begin
  tmp := IntToStr(nconstr);
  constrName := '_cstr' + tmp;  //Nombre de constante
  asmline('.data');
  if constStr='' then begin
    asmline(constrName+ ' db 0');
  end else begin
    asmline(constrName+ ' db "'+constStr+'",0');
  end;
  asmline('.code');
  nconstr := nconstr + 1;
end;

procedure GetOperand();
{Extrae un operando. Actualiza la variable "resType".
Genera el código ensamblador necesario para que el operando siempre quede en un
registro.}
var
  resCteStr: string;
  vName    : string;
  vType    : Integer;
begin
  TrimSpaces();
  //Captura primer operando, asumiendo que es el único
  if srcToktyp = 3 then begin  //Literal Número
    resType := 1;   //Integer
    asmline('mov eax, ' + srcToken);
    NextToken();
  end else if srcToktyp = 4 then begin  //Literal Cadena
    resType := 2;   //Tipo cadena
    resCteStr := copy(srcToken,2,length(srcToken)-2); //Valor
    DeclareConstantString(resCteStr);
    //Carga en registro de cadena
    asmline('invoke szCopy, addr ' + constrName + ', addr _strA');
    NextToken();
  end else if srcToktyp = 2 then begin  //Identificador
    //Busca variable
    FindVariable();   //Actualiza "curVarName", "curVarType" y "curVarArSiz".
    if curVarName = '' then begin
      MsjError := 'Identificador desconocido: ' + srcToken;
      exit;
    end;
    //Es una variable. Podría ser un arreglo.
    vName := curVarName;  //Guarda porque se puede modificar con ReadArrayIndex().
    vType := curVarType;  //Guarda porque se puede modificar con ReadArrayIndex().
    NextToken();
    TrimSpaces();

    if vType= 1 then begin         //Variable entera
      asmline('mov eax, ' + vName); //Carga en registro
    end else begin                 //Variable cadena
      asmline('invoke szCopy, addr ' + vName + ', addr _strA');
    end;
    resType := vType;   //Tipo del resultado
  end else begin
    MsjError := 'Error de sintaxis: ' + srcToken;
    exit;
  end;
end;
procedure ProcessBlock;
//Procesa un bloque de código.
begin
  while EndOfBlock()<>1 do begin
    //Procesa la instrucción
    GetOperand();

    //Verifica delimitador de instrucción
    Capture(';');
    if MsjError<>'' then begin exit; end;
  end;
end;
procedure ParserProgram();
{Procesa las declaraciones e instrucciones de un programa.}
begin
  if EndOfBlock() = 1 then begin exit; end;
  //Procesa sección de declaraciones
  WriteLn(outFile, '    .data');
  while srcToken = 'var' do begin   //Declaración de variable
    ParserVar();
    if MsjError<>'' then begin exit; end;
    //Verifica delimitador de instrucción
    Capture(';');
    if MsjError<>'' then begin exit; end;
    TrimSpaces();
  end;
  //Procesa sección de procedimientos.
  WriteLn(outFile, '    .code');
  //Procedimientos
  TrimSpaces;
  while srcToken = 'procedure' do begin
    //Procesamiento de declaración de procedimientos.
  end;
  //Procesa cuerpo principal (instrucciones).
  WriteLn(outFile, 'start:');
  ProcessBlock;   //Procesamos el bloque de código.
  WriteLn(outFile, '    exit');
  WriteLn(outFile, 'end start');
end;
begin
  //Abre archivo de entrada
  AssignFile(inFile, 'input.tit');
  Reset(inFile);
  //Abre archivo de salida
  AssignFile(outFile, 'input.asm');
  Rewrite(outFile);
  //Inicia banderas
  nVars := 0;     //Número inicial de variables
  srcRow := 0;    //Número de línea
  nconstr := 0;
  //Escribe encabezado de archivo
  WriteLn(outFile, '    include \masm32\include\masm32rt.inc');
  WriteLn(outFile, '    .data');
  WriteLn(outFile, '    _strA DB 256 dup(0)');
  WriteLn(outFile, '    _strB DB 256 dup(0)');
  MsjError := '';
  NextLine();        //Prepara primera lectura.
  NextToken();       //Lee primer token
  ParserProgram();   //Procesa programa.
  if MsjError<>'' then begin
    //Genera mensaje en un formato apropiado para la detección.
    WriteLn('ERROR: input.tit' + ' ('+IntToStr(srcRow) + ',' + IntToStr(idxLine)+'): ' + MsjError);
  end;
  //Terminó la compilación.
  CloseFile(outFile);
  CloseFile(inFile);
  if MsjError='' then ExitCode:=0 else ExitCode:=1;
end.

