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
  //Expresiones: "res"
  resType  : integer;  //Tipo de dato:
                       //1 -> integer
                       //2 -> string
  resStorag: integer;  // Almacenamiento del resultado:
                       //0 -> Constante
                       //1 -> Variable
                       //2 -> Expresión
                       //1000 -> Sin almacenamiento
  //resVarIdx: integer;  //Índice al resultado cuando es variable
  resVarNam: string[255]; //Nombre de la variable cuando el resultado es variable
  resCteInt: integer;     //Resultado entero cuando es constante
  resCteStr: string[255]; //Resultado cadena cuando es constante
  //Operador: "Op1"
  op1Type  : integer;    //Tipo de dato:
  op1Storag: integer;    // Almacenamiento del resultado:
  op1VarNam: string[255]; //Nombre de la variable cuando el resultado es variable
  op1CteInt: integer;     //Resultado entero cuando es constante
  op1CteStr: string[255]; //Resultado cadena cuando es constante
  //Operador: "Op2"
  op2Type  : integer;    //Tipo de dato:
  op2Storag: integer;    // Almacenamiento del resultado:
  op2VarNam: string[255]; //Nombre de la variable cuando el resultado es variable
  op2CteInt: integer;     //Resultado entero cuando es constante
  op2CteStr: string[255]; //Resultado cadena cuando es constante

  //Variables internas
  _regstr  : string[255];  //Registro para cadenas
  constr   : string;     //Nombre de constanet string usada actualmente
  nconstr  : integer;    //Número de constante string creada
procedure EvaluateExpression; forward;
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
procedure GetOperand;
{Extrae un operando. Acatualiza variables "resXXX".}
var
  n: integer;
begin
  TrimSpaces;
  //Captura primer operando, asumiendo que es el único
  if srcToktyp = 3 then begin  //Literal Número
    n := StrToInt(srcToken);  //Falta verifiación de error
    resStorag := 0; //Constante
    resType := 1;   //Integer
    resCteInt := n; //Valor
    NextToken;
  end else if srcToktyp = 4 then begin  //Literal Cadena
    resStorag := 0; //Constante
    resType := 2;   //Integer
    resCteStr := copy(srcToken,2,length(srcToken)-2); //Valor
    NextToken;
  end else if srcToktyp = 2 then begin  //Identificador
    //Es identificador

  end else begin
    MsjError := 'Error de sintaxis: ' + srcToken;
    exit;
  end;
end;
procedure GetOperand1;
begin
  GetOperand;
  op1Type   := resType;
  op1Storag := resStorag;
  op1VarNam := resVarNam;
  op1CteInt := resCteInt;
  op1CteStr := resCteStr;
end;
procedure GetOperand2;
begin
  GetOperand;
  op2Type   := resType;
  op2Storag := resStorag;
  op2VarNam := resVarNam;
  op2CteInt := resCteInt;
  op2CteStr := resCteStr;
end;
procedure DeclareConstantString(constStr: string);
{Inserta la declaración de una constante string, en la sección de datos, para
poder trabajarla.}
var
  tmp: String;
begin
  tmp := IntToStr(nconstr);
  constr := '_ctestr' + tmp;  //Nomrbe de constante
  WriteLn(outFile, '    .data');
  WriteLn(outFile, '    ' + constr+ ' db "'+constStr+'",0');
  WriteLn(outFile, '    .code');
  inc(nconstr);
end;
procedure OperAdd;
{Realiza la operación "+" sobre los operandos "op1XXX" y "op2XXX". Devuelve resultado en
resXXX"}
begin
  if op1Type<>op2Type then begin
    MsjError := 'No se pueden sumar estos tipos';
    exit;
  end;
  //Son del mismo tipo
  if op1Type = 1 then begin
    //********* Suma de enteros **************
    resType   := 1;  //
    if op1Storag = 0 then begin
      if op2Storag = 0 then begin
        //--- Constante + Constante ---
        resStorag := op1Storag;
        resCteInt := op1CteInt + op2CteInt;
      end else if op2Storag = 1 then begin
        //--- Constante + Variable
        resStorag := 2;  //Expresión
        writeln(outFile, '    mov eax, ' +op2VarNam);
        writeln(outFile, '    add eax, ', op1CteInt);
      end else if op2Storag = 2 then begin
        //--- Constante + Expresión
        resStorag := 2;  //Expresión
        writeln(outFile, '    add eax, ', op1CteInt);
      end else begin
        MsjError := 'Operación no implementada';
        exit;
      end;
    end else if op1Storag = 1 then begin
      if op2Storag = 0 then begin
        //--- Variable + Constante ---
        resStorag := 2;  //Expresión
        writeln(outFile, '    mov eax, ' +op1VarNam);
        writeln(outFile, '    add eax, ', op2CteInt);
      end else if op2Storag = 1 then begin
        //--- Variable + Variable
        resStorag := 2;  //Expresión
        writeln(outFile, '    mov eax, ' + op1VarNam);
        writeln(outFile, '    add eax, ', op2VarNam);
      end else if op2Storag = 2 then begin
        //--- Variable + Expresión
        resStorag := 2;  //Expresión
        writeln(outFile, '    mov ebx, ' + op1VarNam);
        writeln(outFile, '    add eax, ebx');
      end else begin
        MsjError := 'Operación no implementada';
        exit;
      end;
    end else if op1Storag = 2 then begin
      if op2Storag = 0 then begin
        //--- Expresión + Constante ---
        resStorag := 2;  //Expresión
        writeln(outFile, '    add eax, ', op2CteInt);
      end else if op2Storag = 1 then begin
        //--- Expresión + Variable
        resStorag := 2;  //Expresión
        writeln(outFile, '    add eax, ', op2VarNam);
      end else if op2Storag = 2 then begin
        //--- Expresión + Expresión
        resStorag := 2;  //Expresión
        writeln(outFile, '    pop ebx');
        writeln(outFile, '    add eax, ebx');
      end else begin
        MsjError := 'Operación no implementada';
        exit;
      end;
    end else begin
      MsjError := 'Operación no implementada';
      exit;
    end;
  end else if op1Type = 2 then begin
    //********* Suma de cadenas **************
    resType := 2;  //
    if op1Storag = 0 then begin
      if op2Storag = 0 then begin
        //--- Constante + Constante ---
        resStorag := op1Storag;
        resCteStr := op1CteStr + op2CteStr;
      end else if op2Storag = 1 then begin
        //--- Constante + Variable
        resStorag := 2;  //Expresión
        DeclareConstantString(op1CteStr);
        WriteLn(outFile, '    invoke szCopy, addr '+constr+', addr _regstr');
        writeln(outFile, '    invoke szCopy, addr '+op2VarNam+', addr _regstr+', length(resCteStr));
//      end else if op2Storag = 2 then begin
//        //--- Constante + Expresión
//        resStorag := 2;  //Expresión
//        writeln(outFile, '    add eax, ', op1CteInt);
      end else begin
        MsjError := 'Operación no implementada';
        exit;
      end;
    end else if op1Storag = 1 then begin
      if op2Storag = 0 then begin
        //--- Variable + Constante ---
        resStorag := 2;  //Expresión
        WriteLn(outFile, '    invoke szCopy, addr '+op1VarNam+', addr _regstr');
        DeclareConstantString(op2CteStr);
        writeln(outFile, '    invoke szCatStr, addr _regstr, addr ' + constr);
      end else if op2Storag = 1 then begin
        //--- Variable + Variable
        resStorag := 2;  //Expresión
        WriteLn(outFile, '    invoke szCopy, addr '+op1VarNam+', addr _regstr');
        writeln(outFile, '    invoke szCatStr, addr _regstr, addr ' + op2VarNam);
      end else if op2Storag = 2 then begin
        //--- Variable + Expresión
        resStorag := 2;  //Expresión
        WriteLn(outFile, '    invoke szCopy, addr '+op1VarNam+', addr _regstr');
        writeln(outFile, '    invoke szCatStr, addr _regstr, addr ' + op2VarNam);
      end else begin
        MsjError := 'Operación no implementada';
        exit;
      end;
//    end else if op1Storag = 2 then begin
//      if op2Storag = 0 then begin
//        //--- Expresión + Constante ---
//        resStorag := 2;  //Expresión
//        writeln(outFile, '    add eax, ', op2CteInt);
//      end else if op2Storag = 1 then begin
//        //--- Expresión + Variable
//        resStorag := 2;  //Expresión
//        writeln(outFile, '    add eax, ', op2VarNam);
//      end else if op2Storag = 2 then begin
//        //--- Expresión + Expresión
//        resStorag := 2;  //Expresión
//        writeln(outFile, '    pop ebx');
//        writeln(outFile, '    add eax, ebx');
//      end else begin
//        MsjError := 'Operación no implementada';
//        exit;
//      end;
    end else begin
      MsjError := 'Operación no implementada';
      exit;
    end;
  end;
end;
procedure OperSub;
{Realiza la operación "-" sobre los operandos "op1XXX" y "op2XXX". Devuelve resultado en
"resXXX"}
begin
  if op1Type<>op2Type then begin
    MsjError := 'No se pueden restar estos tipos';
    exit;
  end;
  //Son del mismo tipo
  if op1Type = 1 then begin
    //********* Resta de enteros **************
    resType   := 1;  //
    if op1Storag = 0 then begin
      //Constante + algo
      if op2Storag = 0 then begin
        //--- Constante - Constante ---
        resStorag := op1Storag;
        resCteInt := op1CteInt - op2CteInt;
      end else if op2Storag = 1 then begin
        //--- Constante - Variable
        resStorag := 2;  //Expresión
        writeln(outFile, '    mov eax, ', op1CteInt);
        writeln(outFile, '    sub eax, ', op2VarNam);
      end else if op2Storag = 2 then begin
        //--- Constante - Expresión
        resStorag := 2;  //Expresión
        writeln(outFile, '    mov ebx, ', op1CteInt);
        writeln(outFile, '    sub eax, ebx');
      end else begin
        MsjError := 'Operación no implementada';
        exit;
      end;
    end else if op1Storag = 1 then begin
      //Variable + algo
      if op2Storag = 0 then begin
        //--- Variable - Constante ---
        resStorag := 2;  //Expresión
        writeln(outFile, '    mov eax, ' +op1VarNam);
        writeln(outFile, '    sub eax, ', op2CteInt);
      end else if op2Storag = 1 then begin
        //--- Variable - Variable
        resStorag := 2;  //Expresión
        writeln(outFile, '    mov eax, ' +op1VarNam);
        writeln(outFile, '    sub eax, ', op2VarNam);
      end else if op2Storag = 2 then begin
        //--- Variable - Expresión
        resStorag := 2;  //Expresión
        writeln(outFile, '    mov ebx, ' +op1VarNam);
        writeln(outFile, '    sub ebx, eax');
        writeln(outFile, '    mov eax, ebx');
      end else begin
        MsjError := 'Operación no implementada';
        exit;
      end;
    end else if op1Storag = 2 then begin
      //Expresión menos algo
      if op2Storag = 0 then begin
        //--- Expresión - Constante ---
        resStorag := 2;  //Expresión
        writeln(outFile, '    sub eax, ', op2CteInt);
      end else if op2Storag = 1 then begin
        //--- Expresión - Variable
        resStorag := 2;  //Expresión
        writeln(outFile, '    sub eax, ', op2VarNam);
      end else if op2Storag = 2 then begin
        //--- Expresión - Expresión
        resStorag := 2;  //Expresión
        writeln(outFile, '    pop ebx');
        writeln(outFile, '    sub ebx, eax');
        writeln(outFile, '    mov eax, ebx');
      end else begin
        MsjError := 'Operación no implementada';
        exit;
      end;
    end else begin
        MsjError := 'Operación no implementada';
        exit;
    end;
  end;
end;
procedure EvaluateExpression;
{Evalua la expresión actual y actualiza resStorag, resVarNam, resCteInt, resCteStr.
Puede generar código si es necesario.}
begin
  //Toma primer operando
  GetOperand1;
  if MsjError<>'' then exit;
  //Guarda datos del operando
  //Verifica si hay operandos, o la expresion termina aquí
  TrimSpaces;
  //Captura primer operando, asumiendo que es el único
  if srcToktyp = 0 then exit;  //Terminó la línea y la expresión
  if srcToken = ')' then exit; //Terminó la expresión
  if srcToken = ']' then exit; //Terminó la expresión
  //Hay más tokens
  //Extrae operador
  if srcToken = '+' then begin
    NextToken;  //toma token
    GetOperand2;
    if MsjError<>'' then exit;
    OperAdd;  //Puede salir con error
  end else if srcToken = '-' then begin
    NextToken;  //toma token
    GetOperand2;
    if MsjError<>'' then exit;
    OperSub;  //Puede salir con error
  end else begin
    MsjError := 'Error de sintaxis: ' + srcToken;
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

