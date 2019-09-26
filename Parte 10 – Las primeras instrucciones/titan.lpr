{Proyecto de un compilador con implementación mínima para ser autocontenido.
                               Por Tito Hinostroza 04/01/2019
                               Derechos Reservados.
El compilador tiene una implementación simple, porque el obejtivo final es poder
hacer a este compilAdor, autocontenido, es decir que se pueda compilar a si mismo.
Por ello, no se usarán opciones avanzadas del lenguaje, solo las funciones básicas,
y las estructuras más simples. No se implementan los bucles REPEAT, o FOR.

los tipos de datos son solamente dos:
- Enteros. Con signo, ocupan 32 bits.
- Cadenas. Ocupan 255 bytes.
Además se soportan arreglos de hasta 255 elementos de estos tipos de datos.

Se consideran 3 tipos de almacenamiento:
1. Constante. Se guarda directamente el valor de la expresión.
2. Variables. Se guarda la dirección de la variables.
3. Expresión. Se guarda el resultado en un registro de trabajo.

Adicionalmente se permite manejar, en algunos casos, los almacenamientos:
4. Variable referenciada por constante.
5. Variable referenciada por variable.

Estos almacenamientos se usan para implementar arreglos.

Los registros de trabajo, son los que se usan para devolver el resultado de las
expresiones. Son dos:
* El registro EAX, para devolver valores numéricos.
* La variable _regstr para devolver valores de cadena.
}
program titan;
uses sysutils;
var
  //Manejo de código fuente
  inFile   : Text;    //Archivo de entrada
  outFile  : Text;    //Archivo de salida
  idxLine  : integer;
  srcLine  : string[255]; //Línea leída actualmente
  srcRow   : integer;  //Número de línea áctual
  //Campos relativos a la lectura de tokens
  srcChar  : byte;      //Caracter leído actualmente

  srcToken : string;
  srcToktyp: integer; // Tipo de token:
                      //0-> Fin de línea
                      //1-> Espacio
                      //2-> Identificador: "var1", "VARIABLE"
                      //3-> Literal numérico: 123, -1
                      //4-> Literal cadena: "Hola", "hey"
                      //5-> Comentario
                      //9-> Desconocido.
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
  //Variable a asignar
  asgVarName: string;
  asgVarType: integer;
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
procedure FindVariable;
{Busca la variable con el nombre que está en "srcToken", y actualiza las variables:
"curVarName", "curVarType", y "curVarArSiz".
Si no encuentra, devuelve cadena vacía en "curVarName".}
var
  tmp: string;
  contin: integer;
  curVar    : integer;
begin
  curVar := 0;
  tmp := varNames[curVar];
  contin := ord(tmp <> srcToken);
  while contin=1 do begin
    inc(curVar);
    if curVar = 256 then break;
    tmp := varNames[curVar];
    contin := ord(tmp <> srcToken);
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
procedure ReadArrayIndex;
{Lee el índice de un arreglo. Es decir, lo que va entre corchetes: [].
Devuelve información en las variables: idxStorag, idxCteInt, y idxVarNam.
No genera código y no usa ningún registro adicional, porque restringe que el
índice sea una constante o una variable simple.
Se asume que el token actual es '['.
Si encuentra algún error, devuelve el mensaje en "MsjError"}
begin
  //Es acceso a arreglo
  NextToken;  //Toma '['
  EvaluateExpression;
  if MsjError<>'' then exit;
  if resStorag = 2 then begin
    {Se restringe el uso de expresiones aquí, por simplicidad, para no complicar la
    generación de código. Así solo tendremos constantes o variables como índice.}
    MsjError := 'No se permiten expresiones aquí.';
    exit;
  end;
  if resStorag = 1 then begin
    //Es variable. Solo puede ser entera.
    if resType <> 1 then begin
      MsjError := 'Se esperaba varaible entera.';
      exit;
    end;
  end;
  CaptureChar(ord(']'));
  if MsjError<>'' then exit;
  //Sí, es un arreglo. Guarda información sobre el índice.
  //Solo puede ser entero o variable entera.
  idxStorag := resStorag;   //Guarda almacenamiento del índice.
  idxCteInt := resCteInt;   //Valor entero
  idxVarNam := resVarNam;   //Nombre de varaible
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
    //Verifica función del sistema
    if srcToken = 'length' then begin
      NextToken;
      CaptureChar(ord('('));
      if MsjError<>'' then exit;
      EvaluateExpression;  //Llamada recursiva
      if MsjError<>'' then exit;
      CaptureChar(ord(')'));
      if MsjError<>'' then exit;
      if resType<>2 then begin
        MsjError := 'Se esperaba una cadena.';
        exit;
      end;
      if resStorag = 0 then begin
        //Constante cadena
        resType := 1;  //Devuelve constante numérica
        resCteInt := length(resCteStr);
      end else if resStorag = 1 then begin
        //Variable cadena
        WriteLn(outFile, '    invoke szLen, addr '+resVarNam);
        resType := 1;  //Devuelve número en EAX
        resStorag := 2;  //Expresión
      end else if resStorag = 2 then begin
        //Expresión cadena
        WriteLn(outFile, '    invoke szLen, addr _regstr');
        resType := 1;  //Devuelve número en EAX
        resStorag := 2;  //Expresión
      end else begin
        MsjError := 'Almacenamiento no soportado';
        exit;
      end;
    end else begin
      //Busca variable
      FindVariable;
      if curVarName = '' then begin
        MsjError := 'Identificador desconocido: ' + srcToken;
        exit;
      end;
      //Es una variable. Podría ser un arreglo.
      NextToken;
      TrimSpaces;
      if srcToken = '[' then begin
        //Es acceso a arreglo
        ReadArrayIndex;  //Actualiza idxStorag, idxCteInt, y idxVarNam.
        //Valida si la variable es arreglo
        if curVarArSiz = 0 then begin
          MsjError := 'Esta variable no es un arreglo.';
          exit;
        end;
        //Extraemos valor y devolvemos como expresión
        resStorag := 2; //Expresión
        resType := curVarType;  //Devuelve el mismo tipo que la variable.
        if resType = 1 then begin
          //Arreglo de enteros
          WriteLn(outFile, '    mov eax, DWORD PTR [',curVarName,'+',idxCteInt*4,']');
        end else begin
          //Arreglo de cadenas
          WriteLn(outFile, '    invoke szCopy,addr '+curVarName+'+',idxCteInt*256,', addr _regstr');

        end;
      end else begin
        //Es una variable común
        resStorag := 1; //Variable
        resType := curVarType;   //Tipo
        resVarNam := curVarName;
      end;
    end;
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
  //Extrae operador y operando
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
procedure ProcessAssigment;
begin
  NextToken;
  TrimSpaces;
  if srcToken = '[' then begin
    ReadArrayIndex;  //Actualiza idxStorag, idxCteInt, y idxVarNam.
    //Valida si la variable es arreglo
    if curVarArSiz = 0 then begin
      MsjError := 'Esta variable no es un arreglo.';
      exit;
    end;
  end else begin
    idxStorag := 1000;  //Sin almacenamiento
  end;
  TrimSpaces;
  if srcToken<>'=' then begin
    MsjError := 'Se esperaba "=".';
    exit;
  end;
  NextToken;  //Toma "="
  //Evalúa expresión
  EvaluateExpression;
  if MsjError<>'' then begin
    exit;
  end;
  //Codifica la asignación
  if resType = 1 then begin
    //Integer
    if asgVarType<>1 then begin
      MsjError := 'No se puede asignar un entero a esta variable.';
      exit;
    end;
    if resStorag = 0 then begin
      //Constante
      if idxStorag = 1000 then begin  //Sin arreglo
        WriteLn(outFile, '    mov DWORD PTR ',asgVarName,', ', resCteInt);  //
      end else if idxStorag = 0 then begin  //Indexado por constante
        WriteLn(outFile, '    mov DWORD PTR [',asgVarName,'+',idxCteInt*4,'], ', resCteInt);
      end else begin
        MsjError := 'No se soporta este tipo de expresión.';
        exit;
      end;
    end else if resStorag = 1 then begin
      //Variable
      if idxStorag = 1000 then begin  //Sin arreglo
        WriteLn(outFile, '    mov eax, ', resVarNam);
        WriteLn(outFile, '    mov ' + asgVarName + ', eax');
      end else begin
        MsjError := 'No se soporta este tipo de expresión.';
        exit;
      end;
    end else begin
      //Expresión. Ya está en EAX
      if idxStorag = 1000 then begin  //Sin arreglo
        WriteLn(outFile, '    mov ' + asgVarName + ', eax');
      end else begin
        MsjError := 'No se soporta este tipo de expresión.';
        exit;
      end;
    end;
  end else begin
    //String
    if asgVarType<>2 then begin
      MsjError := 'No se puede asignar una cadena a esta variable.';
    end;
    if resStorag = 0 then begin
      //<variable> <- Constante
      if idxStorag = 1000 then begin  //Sin arreglo
        DeclareConstantString(resCteStr);
        WriteLn(outFile, '    invoke szCopy,addr '+constr+', addr '+ asgVarName);
      end else if idxStorag = 0 then begin  //Indexado por constante
        DeclareConstantString(resCteStr);
        WriteLn(outFile, '    invoke szCopy,addr '+constr+', addr ',asgVarName, ' + ',
                         idxCteInt*256);
      end else begin
        MsjError := 'No se soporta este tipo de expresión.';
        exit;
      end;
    end else if resStorag = 1 then begin
      //<variable> <- Variable
      WriteLn(outFile, '    invoke szCopy,addr '+resVarNam+', addr '+ asgVarName);
    end else begin
      //Expresión. Ya está en "_regstr"
      WriteLn(outFile, '    invoke szCopy,addr _regstr'+', addr '+asgVarName);
    end;
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
        //Estamos dentro de un bloque de variables
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
      //y ya no se deben permitir más declaraciones.
      if srcToktyp = 2 then begin
        //Es un identificador, puede ser una asignación
        FindVariable;
        asgVarName := curVarName;
        asgVarType := curVarType;
        if curVarName = '' then begin
          MsjError := 'Se esperaba variable: ' + srcToken;
          break;
        end;
        //Debe ser una asignación
        ProcessAssigment;
        if MsjError<>'' then break;
      end else begin
        MsjError := 'Instrucción desconocida: ' + srcToken;
        break;
      end;
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

