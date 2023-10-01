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
//Datos de variable a asignar
var asgVarName : string;
var asgVarType : integer;
var asgVarArSiz: integer;
var asgIdVarNam: string;   //Nombre de índice variable
var asgIdConVal: string;   //Valor de índice constante. Por practicidad, como cadena.

//Campos para arreglos
var idxVarNam  : string;   //Nombre de índice variable
var idxConVal  : string;   //Valor de índice constante. Por practicidad, como cadena.
//Expresiones
var resType    : integer;  //Tipo de dato: 1->integer. 2->string.
var op1Type    : integer;  //Tipo de dato de Operando 1: 1->integer. 2->string.
var op2Type    : integer;  //Tipo de dato de Operando 2: 1->integer. 2->string.
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
function Capture(c: string): integer;
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
procedure ReadArrayIndex();
// Lee el índice de un arreglo. Es decir, lo que va entre corchetes: [].
// El índice solo puede ser una variable o un literal numérico. Si es una variable
// devuelve el nombre en "idxVarNam", de otra forma será un valor numérico y su
// valor se devuelve en "idxConVal".
// Se asume que el token actual es '['.
// Si encuentra algún error, devuelve el mensaje en "MsjError".
begin
  NextToken();  //Toma '['
  idxVarNam := '';   //Inicia bandera
  if srcToktyp = 2 then begin     //Identificador
    //Busca variable
    FindVariable();   //Actualiza "curVarName", "curVarType" y "curVarArSiz".
    if curVarName = '' then begin
      MsjError := 'Identificador desconocido: ' + srcToken;
      exit;
    end;
    //Valida tipo
    if curVarType <> 1 then begin
      MsjError := 'Se esperaba variable entera.';
      exit;
    end;
    //Valida si es variable
    if curVarArSiz<>0 then begin
      MsjError := 'No se permiten arreglos o funciones como índices.';
      exit;
    end;
    idxVarNam := curVarName;
    NextToken();
  end else if srcToktyp = 3 then begin  //Literal Número
    idxConVal := srcToken;
    NextToken();
  end else begin
    MsjError := 'Se esperaba variable o número.';
    exit;
  end;
  Capture(']');      //Puede salir con error.
end;//Análisis de expresiones
procedure ProcessBlock(); forward;
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
procedure GetOperandArray(vName: string; vType: Integer);
{Lee un operando de tipo "variable[índice]" y genera el código que carga el valor en
un registro. "vName" es el nombre de la variable arreglo.
Si el ítem es entero, su valor se devuelve en el registro "eax", si es cadena, se
devuelve en "_strA"  }
begin
  ReadArrayIndex();  //Actualiza "idxConVal" e "idxVarNam".
  if MsjError<>'' then begin exit; end;
  //Extraemos valor y devolvemos como expresión
  if vType = 1 then begin   //Arreglo de enteros
    if idxVarNam<>'' then begin   //Índice variable
      asmline('mov esi, ' + idxVarNam);
      asmline('mov eax, DWORD PTR [' + vName + '+4*esi]');
    end else begin               //Índice numérico
      asmline('mov esi, ' + idxConVal);
      asmline('mov eax, DWORD PTR [' + vName + '+4*esi]');
    end;
  end else begin                 //Arreglo de cadenas
    if idxVarNam<>'' then begin   //Índice variable
      asmline('mov esi, ' + idxVarNam);
      asmline('shl esi, 8');  //Multiplica por 256
      asmline('add esi, offset '+ vName);
      asmline('invoke szCopy, esi, addr _strA');
    end else begin               //Índice numérico
      asmline('invoke szCopy, addr '+vName+'+256*' + idxConVal + ', addr _strA');
    end;
  end;
end;
procedure GetOperandChar(vName: string);
{Lee un operando de tipo "cadena[índice]" y genera el código que carga el código
ASCII en EAX. "vName" es el nombre de la variable arreglo. }
begin
  ReadArrayIndex();  //Actualiza "idxConVal" e "idxVarNam".
  if MsjError<>'' then begin exit; end;
  //Extraemos valor y devolvemos como expresión
  if idxVarNam<>'' then begin   //Índice variable
    asmline('mov esi, ' + idxVarNam);
  end else begin               //Índice numérico
    asmline('mov esi, ' + idxConVal);
  end;
  asmline('mov eax, DWORD PTR [' + vName + '+esi]');
  asmline('and eax, 255'); //Deja solo el byte de menor peso
end;
procedure GetOperand();
{Extrae un operando. Actualiza la variable "resType".
Genera el código ensamblador necesario para que el operando siempre quede en un
registro. Para operandos enteros el valor se devuelve en el registros "eax",
para cadenas, se devuelve en "_strA".}
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
    if srcToken = '[' then begin  //Es acceso a arreglo
      //Valida si la variable "vName" es un arreglo.
      if curVarArSiz = 0 then begin  //No es un arreglo
        //Pero puede ser acceso a una cadena
        if curVarType = 2 then begin //Es acceso a caracter
          GetOperandChar(vName);
          if MsjError<>'' then begin exit; end;
          resType := 1;  //Devuelve el código ASCII.
        end else begin
          MsjError := 'Esta variable no es un arreglo.';
          exit;
        end;
      end else begin        //Es un arreglo
        GetOperandArray(vName, vType);
        if MsjError<>'' then begin exit; end;
        resType := vType;  //Devuelve el mismo tipo que la variable.
      end;
    end else begin                //Es una variable común
      if vType= 1 then begin         //Variable entera
        asmline('mov eax, ' + vName); //Carga en registro
      end else begin                 //Variable cadena
        asmline('invoke szCopy, addr ' + vName + ', addr _strA');
      end;
      resType := vType;   //Tipo del resultado
    end;
  end else begin
    MsjError := 'Error de sintaxis: ' + srcToken;
    exit;
  end;
end;
procedure GetOperand1();
begin
  GetOperand();
  op1Type   := resType;
end;
procedure GetOperand2();
begin
  //Guarda Operando A en B
  if op1Type = 1 then begin
    asmline('mov ebx, eax');  //Copia Valor en B
  end else begin
    asmline('invoke szCopy, addr _strA, addr _strB');
  end;
  //Lee operando en A
  GetOperand();
  op2Type   := resType;
end;
procedure OperAdd();
{Realiza la operación "+" sobre los operandos "EBX" y "EAX". Devuelve resultado
en "EAX" o en "_strA". Actualiza variable "resType".}
begin
  if op1Type<>op2Type then begin
    MsjError := 'No se pueden sumar estos tipos';
    exit;
  end;
  //Son del mismo tipo
  if op1Type = 1 then begin   //Suma de enteros
    resType := 1;  //Devolvemos un entero.
    asmline('add eax, ebx');
  end else if op1Type = 2 then begin  //Suma de cadenas
    resType := 2;  //Devolvemos una cadena
    asmline('invoke szCatStr, addr _strA, addr _strB');
  end;
end;
procedure OperSub();
{Realiza la operación "-" sobre los operandos "EBX" y "EAX". Devuelve resultado
en "EAX". Actualiza variable "resType".}
begin
  if op1Type<>op2Type then begin
    MsjError := 'No se pueden restar estos tipos';
    exit;
  end;
  //Son del mismo tipo
  if op1Type = 1 then begin  //Resta de enteros
    resType := 1;  //Devolvemos un entero.
    asmline('sub ebx, eax');    //Op1 - Op2
  end else begin
    MsjError := 'Solo se pueden restar enteros.';
  end;
end;
procedure OperOr();
{Realiza la operación "OR" sobre los operandos "EBX" y "EAX". Devuelve resultado
en "EAX". Actualiza variable "resType".}
begin
  if op1Type<>op2Type then begin
    MsjError := 'No se pueden operar sobre estos tipos';
    exit;
  end;
  //Son del mismo tipo
  if op1Type = 1 then begin  //Resta de enteros
    resType := 1;  //Devolvemos un entero.
    asmline('or ebx, eax');    //Op1 OR Op2
  end else begin
    MsjError := 'No se puede aplicar OR sobre cadenas.';
  end;
end;
procedure Compare(macro: string; operation: string);
{Toma el segundo operando de una expresion y realiza la operación de comparación
"operation" usando la macro "macro". Funciona para enteros y cadenas.
Si se encuentra error devuelve el mensaje e "MsjError".}
begin
  NextToken();     //Toma token
  GetOperand2();   //Evalúa segundo operando
  if MsjError<>'' then begin exit; end;
  if op1Type<>op2Type then begin
    MsjError := 'No se pueden comparar tipos diferentes';
    exit;
  end;
  //Son del mismo tipo
  if op1Type = 1 then begin  //Comparación de enteros
    asmline(macro + ' ebx ' + operation + ' eax');
  end else if op1Type = 2 then begin  //Comparación de cadenas
    asmline('invoke lstrcmp, addr _strB, addr _strA');
    if operation = '<' then begin
      asmline(macro + ' eax == -1');   // EAX<0 no funciona porque EAX es siempre positivo.
    end else if operation = '>' then begin
      asmline(macro + ' eax == 1');    // EAX>0 no funciona, porque -1 también cumple.
    end else if operation = '<=' then begin
      asmline(macro + ' (eax == -1) || (eax == 0)' );
    end else if operation = '>=' then begin
      asmline(macro + ' (eax == 1) || (eax == 0)');
    end else begin // "=" o "<>"
      asmline(macro + ' eax ' + operation + ' 0');
    end;
  end;
  resType := 1;  //En realidad el resultado queda en la bandera ZF de la CPU.
end;
procedure EvaluateExpression();
{Evalúa la expresión actual y genera el código necesario para dejar el resultado en el
registro EAX o _strA. Actualiza variable "resType"}
begin
  //Toma primer operando
  GetOperand1();
  if MsjError<>'' then begin exit; end;
  //Verifica si sigue algo, o si la expresión termina aquí.
  if EndOfExpression() = 1 then begin exit; end;
  //Hay más tokens. Extrae operador y operando
  if srcToken = '+' then begin
    NextToken();  //toma token
    GetOperand2();
    if MsjError<>'' then begin exit; end;
    OperAdd();  //Puede salir con error
  end else if srcToken = '-' then begin
    NextToken();  //toma token
    GetOperand2();
    if MsjError<>'' then begin exit; end;
    OperSub();  //Puede salir con error
  end else if srcToken = '|' then begin
    NextToken();  //toma token
    GetOperand2();
    if MsjError<>'' then begin exit; end;
    OperOr();  //Puede salir con error
  end else begin
    MsjError := 'Error de sintaxis: ' + srcToken;
    exit;
  end;
end;
procedure EvaluateIfExpression();
{Evalúa una expresión booleana de dos operandos y genera el código necesario.
El código generado tiene la forma:
   <Código de evaluación/declaración/carga de los operandos>
   <Llamada a la macro .IF>
}
begin
  //Toma primer operando
  GetOperand1();
  if MsjError<>'' then begin exit; end;
  //Guarda datos del operando
  //Verifica si hay operandos, o la expresión termina aquí
  TrimSpaces();
  //Captura primer operando, asumiendo que es el único
  if srcToktyp = 0 then begin exit; end; //Terminó la línea y la expresión
  if srcToken = 'then' then begin exit; end; //Terminó la expresión
  //Hay más tokens
  //Extrae operador y operando
  if srcToken = '=' then begin
    Compare('.IF', '==');  //Puede salir con error
  end else if srcToken = '<>' then begin
    Compare('.IF', '!=');  //Puede salir con error
  end else if srcToken = '>'  then begin
    Compare('.IF', '>');  //Puede salir con error
  end else if srcToken = '<'  then begin
    Compare('.IF', '<');  //Puede salir con error
  end else if srcToken = '>=' then begin
    Compare('.IF', '>=');  //Puede salir con error
  end else if srcToken = '<=' then begin
    Compare('.IF', '<=');  //Puede salir con error
  end else begin
    MsjError := 'Error de sintaxis: ' + srcToken;
    exit;
  end;
end;procedure processPrint(ln: integer);
{Implementa las instrucciones "print" y "println". Si "ln" = 0 se compila "print",
de otra forma se compila "println".}
begin
  NextToken();  //Pasa del "print"
  EvaluateExpression();
  if MsjError<>'' then begin exit; end;
  if resType = 1 then begin
    //Imprime variable entera
    asmline('invoke dwtoa, eax, addr _strA');
    if ln=0 then begin
      asmline('print addr _strA');
    end else begin
      asmline('print addr _strA,13,10');
    end;
  end else if resType = 2 then begin
    //Imprime constante cadena
    if ln=0 then begin
      asmline('print addr _strA');
    end else begin
      asmline('print addr _strA,13,10');
    end;
  end;
end;
procedure processIf();
{Procesa una sentencia condicional}
begin
  NextToken();  //Pasa del "print"
  EvaluateIfExpression();
  if MsjError<>'' then begin exit; end;
  TrimSpaces();
  if srcToken <> 'then' then begin
      MsjError := 'Se esperaba "then"';
      exit;
  end;
  NextToken();  //Toma el "THEN"
  //Aquí Procesamos el cuerpo de la condicional.
  ProcessBlock();   //Llamada recursiva
  if srcToken = 'end' then begin
    asmline('.ENDIF');
    NextToken();  //Toma el "THEN"
  end else if srcToken = 'else' then begin
    NextToken();
    asmline('.ELSE');
    ProcessBlock();   //Llamada recursiva
    if srcToken <> 'end' then begin
      MsjError := 'Se esperaba "end"';
      exit;
    end;
    asmline('.ENDIF');
    NextToken();  //Toma el "END"
  end else begin
    MsjError := 'Se esperaba "end"';
    exit;
  end;
end;

procedure ProcessAssigment();
begin
  FindVariable();   //Actualiza "curVarName", "curVarType" y "curVarArSiz".
  if curVarName = '' then begin
    MsjError := 'Se esperaba variable: ' + srcToken;
    exit;
  end;
  NextToken(); //Toma nombre de variable
  TrimSpaces();
  //Preservamos datos de variable destino
  asgVarName := curVarName;
  asgVarType := curVarType;
  asgVarArSiz := curVarArSiz;
  if asgVarArSiz>0 then begin //La variable destino es un arreglo.
    if srcToken = '[' then begin
      ReadArrayIndex();  //Actualiza "idxConVal" e "idxVarNam".
      if MsjError<>'' then begin exit; end;
      //Actualiza variables de arreglo.
      asgIdConVal := idxConVal;
      asgIdVarNam := idxVarNam;
    end else begin  //Sin corchetes
      //Puede ser asignación de arreglos, pero no lo implementamos por ahora.
      MsjError := 'Se esperaba "[".';
      exit;
    end;
  end;
  TrimSpaces();
  if srcToken<>'=' then begin
    MsjError := 'Se esperaba "=".';
    exit;
  end;
  NextToken();  //Toma "="
  //Evalúa expresión
  EvaluateExpression();
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
    if asgVarArSiz=0 then begin  //Sin arreglo
      asmline('mov ' + asgVarName + ', eax');
    end else begin  //Asignación a Arreglo
      if asgIdVarNam<>'' then begin //Indexado por variable
        asmline('mov esi, DWORD PTR [' + asgIdVarNam + ']');
      end else begin          //Indexado por constante
        asmline('mov esi, ' + asgIdConVal);
      end;
      asmline('mov DWORD PTR [' + asgVarName + ' + 4*esi], eax');
    end;
  end else begin
    //String
    if asgVarType<>2 then begin
      MsjError := 'No se puede asignar una cadena a esta variable.';
    end;
    //<variable> <- Registro
    if asgVarArSiz=0 then begin  //Sin arreglo
      asmline('invoke szCopy, addr _strA, addr '+ asgVarName);
    end else begin  //Asignación a Arreglo
      if asgIdVarNam<>'' then begin //Indexado por variable
        //asmline('mov eax, DWORD PTR [' + asgIdVarNam + ']');
        asmline('mov esi, ' + asgIdVarNam);
        asmline('shl esi, 8');  //Multiplica por 256
        asmline('add esi, offset '+ asgVarName);
        asmline('invoke szCopy, addr _strA, esi');
      end else begin          //Indexado por constante
        asmline('invoke szCopy, addr _strA, addr '+ asgVarName + ' + 256*' + asgIdConVal);
      end;
    end;
  end;
end;
procedure ProcessBlock;
//Procesa un bloque de código.
begin
  while EndOfBlock()<>1 do begin
    if srcToken = 'print' then begin
      processPrint(0);
      if MsjError<>'' then begin break; end;
    end else if srcToken = 'println' then begin
      processPrint(1);
      if MsjError<>'' then begin break; end;
    end else if srcToken = 'if' then begin
      processIf();
      if MsjError<>'' then begin break; end;
    end else if srcToktyp = 2 then begin
      //Es un identificador, debe ser una asignación
      ProcessAssigment();
      if MsjError<>'' then begin break; end;
    end else begin
      MsjError := 'Instrucción desconocida: ' + srcToken;
      break;
    end;
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

