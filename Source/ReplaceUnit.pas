unit ReplaceUnit;

interface

{.$DEFINE LOGPKGREPLACE}

uses AnsiStrings, SysUtils, Classes,
  JclIDEUtils, JclCompilerUtils;

type

  TReplaceItem = class (TCollectionItem)
  public
    Prefix, Postfix, Def, Value, ID: String;
    Package, Length: Integer;
  end;

  TReplaceCollection = class (TCollection)
  private
    function GetItem(Index: Integer): TReplaceItem;
    procedure SetItem(Index: Integer; const Value: TReplaceItem);
    function GetValue(Index: Integer; Target: TJclBorRADToolInstallation;
      out Res: String
      {$IFDEF LOGPKGREPLACE}; var Log: String{$ENDIF}): Boolean;
  public
    constructor Create;
    procedure Execute(Target: TJclBorRADToolInstallation;
      Paths, Packages: TStrings; const BasePath: String; CBuilder: Boolean
      {$IFDEF LOGPKGREPLACE}; var Log: String{$ENDIF});
    property Items[Index: Integer]: TReplaceItem read GetItem write SetItem;
  end;

function ReplaceInFile(const FileName: String;
  InStr, OutStr: RawByteString; OnlyIfOutStrNotFound: Boolean): Boolean;

implementation

uses Unit1;

function ReplaceInFile(const FileName: String;
  InStr, OutStr: RawByteString; OnlyIfOutStrNotFound: Boolean): Boolean;
var
  Stream: TFileStream;
  s:      RawByteString;

begin
  Result := True;
  Stream := nil;
  try
    Stream := TFileStream.Create(FileName, fmOpenReadWrite);
    SetLength(s, Stream.Size);
    Stream.Position := 0;
    Stream.ReadBuffer(PAnsiChar(s)^, Length(s));
    if not OnlyIfOutStrNotFound or (AnsiStrings.PosEx(OutStr, s, 1) = 0) then
    begin
      s := AnsiStrings.StringReplace(s, InStr, OutStr,
        [rfReplaceAll, rfIgnoreCase]);
      Stream.Size := 0;
      Stream.WriteBuffer(PAnsiChar(s)^, Length(s));
    end;
  except
    Result := False;
  end;
  Stream.Free;
end;

{ TReplaceCollection }

constructor TReplaceCollection.Create;
begin
   inherited Create(TReplaceItem);
end;

procedure TReplaceCollection.Execute(Target: TJclBorRADToolInstallation;
  Paths, Packages: TStrings; const BasePath: String; CBuilder: Boolean
  {$IFDEF LOGPKGREPLACE}; var Log: String{$ENDIF});
var
  i: Integer;
  Path, Pkg, PkgName, ValW: String;
  ID, Val: AnsiString;

begin
  for i := 0 to Count - 1 do
  begin
    if not GetValue(i, Target, ValW {$IFDEF LOGPKGREPLACE}, Log{$ENDIF}) then
      continue;
    Val := AnsiString(ValW);
    Path := BasePath + Paths[Items[i].Package - 1];
    Pkg := Packages[Items[i].Package - 1];
    ID :=  AnsiString('{' + Items[i].ID + '}');
    if not CBuilder then
    begin
      if bpDelphi32 in Target.Personalities then
      begin
        PkgName := frmMain.GetPkgFile(Path, Pkg, '', Target, bpDelphi32, False);
        ReplaceInFile(PkgName, ID, Val, False);
        PkgName := ChangeFileExt(PkgName, SourceExtensionDProject);
        if FileExists(PkgName) then
          ReplaceInFile(PkgName, ID, Val, False);
        PkgName := frmMain.GetPkgFile(Path, Pkg, '_Dsgn', Target, bpDelphi32, False);
        if FileExists(PkgName) then
          ReplaceInFile(PkgName, ID, Val, False);
        PkgName := ChangeFileExt(PkgName, SourceExtensionDProject);
        if FileExists(PkgName) then
          ReplaceInFile(PkgName, ID, Val, False);
      end;
      if bpDelphi64 in Target.Personalities then
      begin
        PkgName := frmMain.GetPkgFile64(Path, Pkg, Target, bpDelphi64, False);
        ReplaceInFile(PkgName, ID, Val, False);
        PkgName := ChangeFileExt(PkgName, SourceExtensionDProject);
        if FileExists(PkgName) then
          ReplaceInFile(PkgName, ID, Val, False);
      end;
    end
    else
    begin
      if bpBCBuilder32 in Target.Personalities then
      begin
        PkgName := frmMain.GetPkgFile(Path, Pkg, '', Target, bpBCBuilder32, False);
        PkgName := ChangeFileExt(PkgName, SourceExtensionRSBCBPackage);
        if FileExists(PkgName) then
          ReplaceInFile(PkgName, ID, Val, False);
        PkgName := frmMain.GetPkgFile(Path, Pkg, '_Dsgn', Target, bpBCBuilder32, False);
        PkgName := ChangeFileExt(PkgName, SourceExtensionRSBCBPackage);
        if FileExists(PkgName) then
          ReplaceInFile(PkgName, ID, Val, False);
      end;
    end;
  end;
end;

function TReplaceCollection.GetItem(Index: Integer): TReplaceItem;
begin
  Result := TReplaceItem(inherited GetItem(Index));
end;

procedure TReplaceCollection.SetItem(Index: Integer; const Value: TReplaceItem);
begin
  inherited SetItem(Index, Value);
end;

function TReplaceCollection.GetValue(Index: Integer;
  Target: TJclBorRADToolInstallation; out Res: String
  {$IFDEF LOGPKGREPLACE}; var Log: String{$ENDIF}): Boolean;
var
  PrefixLen, PostfixLen, i, p, j: Integer;
  Package: String;
begin
  Result := True;
  PrefixLen := Length(Items[Index].Prefix);
  PostfixLen := Length(Items[Index].Postfix);
  {$IFDEF LOGPKGREPLACE}
  Log := Log + #13#10 + 'Searching for the package started from ' + Items[Index].Prefix +':';
  {$ENDIF}

  for i := 0 to Target.IdePackages.Count - 1 do
    if not Target.IdePackages.PackageDisabled[i] then
    begin
       {$IFDEF LOGPKGREPLACE}
       Log := Log + #13#10 + ' - ' + Target.IdePackages.PackageFileNames[i];
       {$ENDIF}
       Package := AnsiLowerCase(ExtractFileName(Target.IdePackages.PackageFileNames[i]));
       if Copy(Package, 1, PrefixLen) = Items[Index].Prefix then
       begin
         if Items[Index].Length > 0 then
         begin
           Res := Copy(Package, PrefixLen + 1, Items[Index].Length);
           if (Length(Res) <> Items[Index].Length) or (Pos('.', Res) <> 0) then
             continue;
         end
         else
         begin
           p := Pos('.', Package);
           if p <> 0 then
             Package := Copy(Package, 1, p-1);
           if Items[Index].Postfix <> '' then
           begin
             p := 0;
             for j := Length(Package) - PostfixLen + 1 downto PrefixLen + 1 do
               if Copy(Package, j, PostfixLen) = Items[Index].Postfix then
               begin
                 p := j;
                 break;
               end;
           end
           else
             p := Length(Package);
           if p < 1 then
             continue;
           Res := Copy(Package, PrefixLen + 1, p - PrefixLen - 1);
         end;
         {$IFDEF LOGPKGREPLACE}
         Log := Log + ' FOUND! Result = ' + Result;
         {$ENDIF}
         exit;
       end;
    end;
  Res := '';
  Result := False;
  {$IFDEF LOGPKGREPLACE}
  Log := Log + #13#10 + 'Not found';
  {$ENDIF}
end;

end.
