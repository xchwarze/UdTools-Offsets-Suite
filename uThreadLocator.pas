unit uThreadLocator;

interface

uses
  System.Classes, System.SysUtils, Winapi.Windows, Vcl.Forms, System.IOUtils;

type
  HPrincipal = class(TThread)
  private
    Procedure AvFuck;
    Procedure Split;
    Procedure VaciarCarpeta;
    Procedure AvFucker(Fichero, RutaOffsets: String;
  Inicio, Fin, Bytes: Integer; RellenarCon: String);
    Procedure DSplit(Fichero, RutaOffsets: String; Inicio, Fin, Bytes: Integer);
    { Private declarations }
  protected
    procedure Execute; override;
  end;

implementation

uses
  uUOS;

//Funci�n para almacenar los bytes del fichero en una cadena
Function FileToStr(mFile: String): String;
var
  hFile: THandle;
  dwRet: DWORD;
  iSize: DWORD;
  Buff: AnsiString; //El buffer DEBE ser AnsiString y NO WideString, responsable: Microsoft (?)
begin
  hFile := CreateFile(PChar(mFile), GENERIC_READ, FILE_SHARE_READ,
    nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if hFile = INVALID_HANDLE_VALUE then
    Exit;
  iSize := GetFileSize(hFile, nil);
  SetFilePointer(hFile, 0, nil, FILE_BEGIN);
  SetLength(Buff, iSize);
  ReadFile(hFile, Buff[1], iSize, dwRet, nil);
  CloseHandle(hFile);
  Result := WiDeString(Buff);
end;

//Funci�n para crear ficheros a partir de una cadena
Function StrToFile(Str, Ruta: String): Boolean;
var
  hFile: THandle;
  iSize: DWORD;
  dwRet: DWORD;
  Buff: AnsiString; //El buffer DEBE ser AnsiString y NO WideString, responsable: Microsoft (?)
begin
  Buff:= AnsiString(Str);
  iSize := Length(Buff);
  hFile := CreateFile(PChar(Ruta), GENERIC_WRITE, FILE_SHARE_READ,
    nil, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  if (WriteFile(hFile, Buff[1], iSize, dwRet, nil) = True) then
    Result := True;
  CloseHandle(hFile);
end;

//Funci�n para eliminar todos los ficheros existentes en el Directorio de trabajo
Procedure HPrincipal.VaciarCarpeta;
var
  Resultado: Integer;
  SearchResult: TSearchRec;
begin
  SetCurrentDir(Form1.EdDir.Text);
  Form1.Estado.SimpleText := 'Estado: Vaciando carpeta...';
  Resultado := FindFirst('*', faArchive, SearchResult);
  while Resultado = 0 do
  begin
    if (SearchResult.Attr and faArchive = faArchive) and
      (SearchResult.Attr and faDirectory <> faDirectory) then
      Deletefile(PChar(Form1.EdDir.Text + '\' + SearchResult.Name));
    Resultado := FindNext(SearchResult);
  end;
  System.SysUtils.FindClose(SearchResult);
  Form1.Estado.SimpleText := 'Estado: Carpeta vaciada.';
end;

//Funci�n para realizar AvFucker
Procedure HPrincipal.AvFucker(Fichero, RutaOffsets: String;
  Inicio, Fin, Bytes: Integer; RellenarCon: String);
var
  o, Rell, Tam: Integer;
  Aux, Aux2, OffIni, sBytes: String;
begin
  Aux2 := Fichero;
  Fichero := FileToStr(Fichero);
  Rell := StrToInt('$' + RellenarCon);
  Tam := Length(Fichero) - 1;
  If Fin > Tam then
    Fin:= Tam;
  if Inicio > Tam then
    Inicio:= Tam;
  Repeat
    if Terminated then
      Exit;
    Aux := Fichero;
    if Inicio + Bytes <= Tam then
      for o := Inicio to Inicio + Bytes - 1 do
        Aux[o + 1] := Chr(Rell)
    else
      for o := Inicio to (Inicio + (Tam - Inicio)) do
        Aux[o + 1] := Chr(Rell);

    OffIni := IntToStr(Inicio);
    sBytes := IntToStr(Bytes);

    Form1.Estado.SimpleText := 'Procesando fichero: ' + OffIni + '_' + sBytes +
      ExtractFileExt(Aux2);
    Application.ProcessMessages;

    StrToFile(Aux, RutaOffsets + '\' + OffIni + '_' + sBytes +
      ExtractFileExt(Aux2));

    Inc(Inicio, Bytes);
  until Inicio > Fin;
  Form1.Estado.SimpleText := 'Proceso terminado.';
end;

//Funci�n para realizar DSplit
Procedure HPrincipal.DSplit(Fichero, RutaOffsets: String; Inicio, Fin, Bytes: Integer);
var
  FichAux: String;
  FichFinal: String;
  IniAux: Integer;
  TamFichero: Integer;
  Ultimo: Boolean;
begin
  FichAux := Fichero;
  Fichero := FileToStr(Fichero);
  TamFichero := Length(Fichero);

  If TamFichero = 0 then
    Exit;

  IniAux := Inicio + 1;

  if IniAux > TamFichero then
    IniAux:= TamFichero;

  if IniAux < Bytes then
    IniAux := Bytes;

  Ultimo := False;

  Repeat
    if Terminated then
      Exit;
    if IniAux = TamFichero then
      Ultimo := True;
    FichFinal := '';
    SetLength(FichFinal, IniAux);
    CopyMemory(@FichFinal[1], @Fichero[1], IniAux);
    Form1.Estado.SimpleText := 'Procesando fichero: ' + IntToStr(IniAux - 1) + '_' +
      IntToStr(Bytes) + ExtractFileExt(FichAux);
    Application.ProcessMessages;
    StrToFile(FichFinal, RutaOffsets + '\' + IntToStr(IniAux - 1) + '_' +
      IntToStr(Bytes) + ExtractFileExt(FichAux));

    If IniAux -1 = Fin then
      begin
        Form1.Estado.SimpleText := 'Proceso terminado.';
        Exit;
      end;

    Inc(IniAux, Bytes);
  until Ultimo = True;
  Form1.Estado.SimpleText := 'Proceso terminado.';
end;

//Procedimiento para realizar AvFucker con par�metros inclu�dos
Procedure HPrincipal.AvFuck;
begin
  AvFucker(Form1.EdFichero.Text, Form1.EdDir.Text, StrToInt(Form1.EdInicio.Text),
    StrToInt(Form1.EdFin.Text), StrToInt(Form1.EdBytes.Text), Form1.EdValor.Text);
end;

//Procedimiento para realizar DSplit con par�metros inclu�dos
Procedure HPrincipal.Split;
begin
  DSplit(Form1.EdFichero.Text, Form1.EdDir.Text, StrToInt(Form1.EdInicio.Text),
    StrToInt(Form1.EdFin.Text), StrToInt(Form1.EdBytes.Text));
end;

{ HPrincipal }
//Ejecuci�n del Thread seg�n proceda sincronizado con el form principal para mostrar el proceso en tiempo real
procedure HPrincipal.Execute;
begin
  if Form1.CheckVaciar.Checked then
    Synchronize(VaciarCarpeta);
  if Form1.RadAvFucker.Checked then
    Synchronize(AvFuck);
  if Form1.RadDSplit.Checked then
    Synchronize(Split);
  { Place thread code here }
end;

end.
