{
 The contents of this file are subject to the Mozilla Public License
 Version 1.1 (the "License"); you may not use this file except in
 compliance with the License. You may obtain a copy of the License at
 http://www.mozilla.org/MPL/

 Software distributed under the License is distributed on an "AS IS"
 basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
 License for the specific language governing rights and limitations
 under the License.

 The Original Code is Unit1.pas.

 The Initial Developer of the Original Code is Sergey Tkachenko.
 Portions created by Sergey Tkachenko are Copyright (C) Sergey Tkachenko.
 All Rights Reserved.

 Contributor(s): ---

}

unit Unit1;

interface

{$DEFINE TASKBAR}
{.$DEFINE LOGPKGREPLACE}

{.$DEFINE TESTCOMMUNITYEDITION}

uses
  AnsiStrings, Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, ExtCtrls, StdCtrls, CheckLst,
  JclCompilerUtils, JclIDEUtils, JclFileUtils, JclDebug, JclSysInfo, Menus,
  ComCtrls, IniFiles,
  {$IFDEF TASKBAR}
  System.Win.TaskbarCore, Vcl.Taskbar,
  {$ENDIF}
  Registry,
  ReplaceUnit;

const
  PAGE_INSTALL   = 0;
  PAGE_PROCESS   = 1;
  PAGE_UNINSTALL = 2;
  PAGE_MODE      = 3;

  WM_PROCEED = WM_USER + 1;

type
  TInstallPlatform = (ipWin32, ipWin64, ipWin64x, ipOSX64, ipOSXArm64,
    ipAndroid32, ipAndroid64, ipLinux64, ipIOS64, ipIOSSimArm64);
  TInstallPlatforms = set of TInstallPlatform;


  TInstallItem = class
  public
    Target:       TJclBorRADToolInstallation;
    Personality:  TJclBorPersonality;
    Name:         String;
    Dual, Dual64: Boolean;
    InstallPlatforms: TInstallPlatforms;
    constructor Create(ATarget: TJclBorRADToolInstallation;
      APersonality: TJclBorPersonality; ADual, ADual64, FullName: Boolean;
      AInstallPlatforms: TInstallPlatforms);
  end;

  TInstallMode = (imUninstall, imInstall, imChoose);
  TByteSet = set of Byte;

  TInstallConfig = record
    CBuilder, CheckAll, QuickMode, UninstallUnchecked: Boolean;
    BCBVer, DelphiVer, BDSVer, BDSDualVer, BDSWin64Ver, BDSWin64xVer, BDS64DualVer,
    BDSCBuilderVer, BDSCBuilder64Ver, BDSOSX64Ver, BDSOSXArm64Ver,
    BDSAndroid32Ver, BDSAndroid64Ver, BDSLinux64Ver, BDSiOS64Ver, BDSiOSSimArm64Ver: TByteSet;
    InstallPlatforms: TInstallPlatforms;
    InstallMode: TInstallMode;
    Product, IDE: String;
    SourcePath, SourcePathEnv, SourcePathVar: String;
    OptionsKey: String;
    Scheme: Integer;
    NoCompile: Boolean;
    function GetBDSVersForPersonality(APersonality: TJclBorPersonality): TByteSet;
    function GetBDSVersForInstallPlatform(AIP: TInstallPlatform): TByteSet;
    function GetInstallPlatforms(Target: TJclBorRADToolInstallation): TInstallPlatforms;
    function CanInstallIn(ATarget: TJclBorRADToolInstallation; AIP: TInstallPlatform): Boolean;
  end;

  TfrmMain = class(TForm)
    btnExit: TButton;
    btnNext: TButton;
    PopupMenu1: TPopupMenu;
    SelectAll1: TMenuItem;
    ClearAll1: TMenuItem;
    btnLog: TButton;
    btnRemovedPaths: TButton;
    OpenDialog1: TOpenDialog;
    btnAbout: TButton;
    btnOptions: TButton;
    PageControl1: TPageControl;
    tabIDE: TTabSheet;
    tabProgress: TTabSheet;
    tabUninstall: TTabSheet;
    Label1: TLabel;
    Image1: TImage;
    clstIDE: TCheckListBox;
    panNoInstallers: TPanel;
    Label8: TLabel;
    txtLog: TMemo;
    lblStatus: TLabel;
    ProgressBar1: TProgressBar;
    lblUninstall: TLabel;
    tabChoose: TTabSheet;
    rbInstall: TRadioButton;
    rbUninstall: TRadioButton;
    Label4: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure SelectAll1Click(Sender: TObject);
    procedure ClearAll1Click(Sender: TObject);
    procedure btnExitClick(Sender: TObject);
    procedure clstIDEClickCheck(Sender: TObject);
    procedure btnNextClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormDestroy(Sender: TObject);
    procedure clstIDEDblClick(Sender: TObject);
    procedure btnLogClick(Sender: TObject);
    procedure btnRemovedPathsClick(Sender: TObject);
    procedure btnAboutClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnOptionsClick(Sender: TObject);
  private
    { Private declarations }
    FInstallers:   TJclBorRADToolInstallations;
    FUninstallers: TList;
    {$IFDEF TASKBAR}
    FTaskBar: TTaskbar;
    {$ENDIF}
    FPackages, FDepPackages, FCheckUnits, FHelpFiles, FRequirePaths, FCheckIncs: TStringList;
    FPaths, FDescr, FTitles: TStringList;
    FReplacements: TReplaceCollection;
    IsTrial, IsOptional, Is32bit, IsRunTime, NoCE: array of Boolean;
    PkgInstallPlatforms: array of TInstallPlatforms;
    HasTrial: Boolean;
    FPathToSrcWin32, FIgnoreNonWinErrors, FIgnoreOptionalErrors: Boolean;
    Activated, Aborted, CEDetected, CEFailed: Boolean;

    procedure CheckAll(Checked: Boolean);
    function IsIDEChosen: Boolean;
    procedure Install;
    procedure Uninstall;
    function InstallPackage(const PackageFileNameRun, PackageFileNameDsgn,
      Descr, IncludePath: string;
      Target: TJclBorRADToolInstallation; Personality: TJclBorPersonality;
      Dual, Trial, Optional, RuntimeOnly, NoCE: Boolean): Boolean;
    function CopyPackageLibsCB(const PackageFileName: string;
      Target: TJclBorRADToolInstallation): Boolean;
    function CopyToUnitOutputPath(const PackageFileName: string;
      Target: TJclBorRADToolInstallation; Personality: TJclBorPersonality;
      Trial: Boolean): Boolean;
    function GetBplPath(Target: TJclBorRADToolInstallation): String;
    function GetDcpPath(Target: TJclBorRADToolInstallation): String;
    function GetBpl64Path(Target: TJclBorRADToolInstallation): String;
    function GetDcp64Path(Target: TJclBorRADToolInstallation): String;
    function GetBplPathEx(Target: TJclBorRADToolInstallation; APlatform: TJclBDSPlatform): String;
    function GetDcpPathEx(Target: TJclBorRADToolInstallation; APlatform: TJclBDSPlatform): String;


    procedure ConfigureBpr2Mak(const PackageFileName, HppPath: string;
      Target: TJclBorRADToolInstallation);
    function IsInstalled(const PackageFileName: string;
      Target: TJclBorRADToolInstallation): Boolean;
    procedure UpdateCaptions;
    function GetHPPPath(const UnitsPath: String;
      Inst: TJclBorRADToolInstallation; Personality: TJclBorPersonality;
      Trial: Boolean): String;
    function GetObjPath(const HppPath: String; Inst: TJclBorRADToolInstallation;
      Personality: TJclBorPersonality): String;
    function GetUnitPath(const RootPath: String;
      Inst: TJclBorRADToolInstallation; Personality: TJclBorPersonality;
      Trial: Boolean): String;
    function GetUnitOutputPath(const UnitsPath: String;
      Inst: TJclBorRADToolInstallation; Personality: TJclBorPersonality;
      Trial: Boolean): String;
    function CompileRuntime(const PackageFileName, Descr, IncludePath: string;
      Target: TJclBorRADToolInstallation; Personality: TJclBorPersonality;
      APlatform: TJclBDSPlatform;
      Dual, Trial, Optional, NoCE: Boolean): Boolean;

    function AdjustPathToUnitsInPackage(const PackageFileName: string;
      Target: TJclBorRADToolInstallation; APersonality: TJclBorPersonality): Boolean;
    function AdjustPathToUnitsInPackageBack(const PackageFileName: string;
      Target: TJclBorRADToolInstallation; APersonality: TJclBorPersonality): Boolean;
    function AddDirToUnitsInPackage(const PackageFileName: String;
      const Dir: AnsiString): Boolean;
    function RemoveDirFromUnitsInPackage(const PackageFileName: String;
      const Dir: AnsiString): Boolean;
    procedure DeleteCopies(SrcDir, DcuDir, HppDir: String);
    procedure DoDeleteAllCompilationResults(SrcDir, DcuDir, HppDir: String);
    procedure DeleteAllCompilationResults(Target: TJclBorRADToolInstallation;
      const SrcPath: String; Personality: TJclBorPersonality; Trial: Boolean);
    // procedure DeleteCompiled(SrcDir, DcuDir, HppDir: String);
    procedure GetListOfPathToDelete(const Paths: String;
      PathsToDelete: TStringList; const CheckUnit, CheckInc: String;
      Target: TJclBorRADToolInstallation);
    function DeletePathsToOldVersions(Target: TJclBorRADToolInstallation;
      CheckUnit, CheckInc: String): Boolean;
    procedure InitProgress(MaxValue: Integer);
    procedure StepProgress;
    procedure DoneProgress(Success: Boolean);
    procedure InstallHelp(BDSVer: Integer);
    procedure UnInstallHelp(BDSVer: Integer);
    procedure AddToLastLogLine(const S: String);
    procedure HideSourceFiles(SrcDir, DcuDir: String);
    procedure RestoreSourceFiles(SrcDir: String);
    procedure DoDeleteDCU(Dir: String);
    procedure SaveOptions;
    procedure LoadOptions;
    procedure MoveControlsToActivePage;
    function CopyPackageLibsD(const PackageFileName: string;
      Target: TJclBorRADToolInstallation; APlatform: TJclBDSPlatform): Boolean;
  public
    { Public declarations }
    Installing:             Boolean;
    Config:                 TInstallConfig;
    ErrorLog, RemovedPaths: String;
    function GetPkgFile(const RootPath, PkgPrefix, PkgSuffix: String;
      Inst: TJclBorRADToolInstallation; Personality: TJclBorPersonality;
      Trial: Boolean): String;
    function GetPkgFile64(const RootPath, PkgPrefix: String;
      Inst: TJclBorRADToolInstallation; Personality: TJclBorPersonality;
      Trial, DesignTime: Boolean): String;
    function LoadConfig(FileName: String; var ErrorMsg: String): Boolean;
    procedure FillIDEList;
    procedure FillUninstallers;
    procedure CheckExisting;
    procedure RemoveCheckedUninstallers;
    function CheckDelphiRunning: Boolean;
    procedure InitPages;
    function GetEnvPath(const s: String;
      Target: TJclBorRADToolInstallation): String;
    //procedure CheckDir(const s: String);
    procedure WMProceed(var Msg: TMessage); message WM_PROCEED;
    procedure ShowStatusMsg(const S: String);
  end;

var
  frmMain: TfrmMain;

implementation

uses
  ViewLogFrm, OptionsFrm;

const
  AllBDSVer           = [3 .. 12, 14 .. 23];
  HelpBDSVer          = [16 .. 23];
  AllBDSWin64Ver      = [9 .. 12, 14 .. 23];
  AllBDSCBuilderWin64Ver = [10 .. 12, 14 .. 23];
  AllBDSOSX64Ver      = [20 .. 23];
  AllBDSOSXArm64Ver   = [22 .. 23];
  AllBDSAndroid32Ver  = [21 .. 23];
  AllBDSAndroid64Ver  = [21 .. 23];
  AllBDSLinux64Ver    = [20 .. 23];
  AllBDSIOS64Ver      = [21 .. 23];
  AllBDSIOSSimArm64Ver = [22 .. 23];
  AllBDSWin64xVer =     [23];
  AllBDSCompleteCBuilder64Ver = [];

  BDSCommunityEditionVer = 23;
  TextSeparatorLine   = #13#10'-------------------------------------'#13#10;

  FirstNonWinInstallPlatform = ipWin64x; // counting Winx platform as "non-Windows"

const
  LogErrorFmtStr = #13#10 + TextSeparatorLine + 'Error compiling %s:'#13 + #10;

const
  RemovedFmtStr = #13#10 + TextSeparatorLine + 'Removed paths for %s:'#13 + #10;

  {$R *.dfm}

procedure RenameAllFiles(Path, Mask, NewExt: String);
var
  sr: TSearchRec;
  s:  String;
begin
  Path := PathAddSeparator(Path);
  if FindFirst(Path + Mask, 0, sr) = 0 then
  begin
    repeat
      if (sr.Attr and faDirectory) = 0 then
      begin
        s := ChangeFileExt(sr.Name, NewExt);
        RenameFile(Path + sr.Name, Path + s);
      end;
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;
end;

procedure MoveAllFiles(Path, Mask, NewPath: String);
var
  sr: TSearchRec;
begin
  Path := PathAddSeparator(Path);
  NewPath := PathAddSeparator(NewPath);
  if FindFirst(Path + Mask, 0, sr) = 0 then
  begin
    repeat
      if (sr.Attr and faDirectory) = 0 then
      begin
        FileMove(Path + sr.Name, NewPath + sr.Name, True);
      end;
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;
end;
{------------------------------------------------------------------------------}
function DoChangeDcuOutput(var S: String; const Open, Close, Path: String): Boolean;

  function DoChange(var Str: String): Boolean;
  var
    p1, p2: Integer;
  begin
    Result := False;
    p1 := Pos('<DCC_DcuOutput>', Str);
    if p1 = 0 then
      exit;
    inc(p1, Length('<DCC_DcuOutput>'));
    p2 := Pos('</DCC_DcuOutput>', Str, p1);
    if p2 = 0 then
      exit;
    Delete(Str, p1, p2 - p1);
    Insert(Path, Str, p1);
    Result := True;
  end;

  procedure DoAppend(var Str: String);
  var
    p: Integer;
    Indent: String;
  begin
    p := Pos('<', Str);
    if p = 0 then
      Indent := ''
    else
      Indent := Copy(Str, 1, p-1);
    Str := Str + Indent + '<DCC_DcuOutput>' + Path + '</DCC_DcuOutput>';
  end;

var
  p1, p2: Integer;
  s2: String;
begin
  Result := False;
  p1 := Pos(Open, s);
  if p1 = 0 then
    exit;
  inc(p1, Length(Open));
  p2 := Pos(Close, s, p1);
  if p2 = 0 then
    exit;
  while (p2 > p1) and (S[p2]<>'>') do
    dec(P2);
  s2 := Copy(S, p1, p2 - p1 + 1);
  if not DoChange(s2) then
    DoAppend(s2);
  Delete(s, p1, p2 - p1 + 1);
  Insert(s2, s, p1);
  Result := True;
end;
{------------------------------------------------------------------------------}
function ChangeDCUOutput(const DProjFileName, Path: String; BdsVer: Integer): Boolean;
var
  Stream: TFileStream;
  sUTF8: UTF8String;
  s, s2: String;
begin
  Result := False;
  if not FileExists(DProjFileName) then
    exit;
  try
    Stream := TFileStream.Create(DProjFileName, fmOpenRead or fmShareDenyWrite);
    try
       SetLength(sUTF8, Stream.Size);
       Stream.ReadBuffer(PAnsiChar(sUTF8)^, Stream.Size);
       s := UTF8ToString(sUTF8);
       s2 := s;
       if BdsVer >= 9 then // XE2 +
         Result := DoChangeDcuOutput(s,
           '<PropertyGroup Condition="''$(Base_Win32)''!=''''">', '</PropertyGroup>', Path)
       else if BdsVer >= 6 then // 2009 +
         Result := DoChangeDcuOutput(s,
           '<PropertyGroup Condition="''$(Base)''!=''''">', '</PropertyGroup>', Path)
       else if BdsVer = 5 then
         Result :=
           DoChangeDcuOutput(s,
             '<PropertyGroup Condition=" ''$(Configuration)|$(Platform)'' == ''Release|AnyCPU'' ">', '</PropertyGroup>', Path) or
           DoChangeDcuOutput(s,
             '<PropertyGroup Condition=" ''$(Configuration)|$(Platform)'' == ''Debug|AnyCPU'' ">', '</PropertyGroup>', Path)
       else
         Result := False;
       if not Result or (s2 = s) then
         exit;
    finally
      Stream.Free;
    end;
    Stream := TFileStream.Create(DProjFileName, fmCreate);
    try
       sUTF8 := UTF8Encode(s);
       Stream.WriteBuffer(PAnsiChar(sUTF8)^, Length(sUTF8));
    finally
      Stream.Free;
    end;
  except
    Result := False;
  end;
end;
{------------------------------------------------------------------------------}
function GetPlatformName(APlatform: TJclBDSPlatform): String;
begin
  case APlatform of
    bpWin32:          Result := '32-bit Windows';
    bpWin64:          Result := '64-bit Windows';
    bpWin64x:         Result := '64-bit Windows (Modern)';
    bpOSX32:          Result := '32-bit MacOS';
    bpOSX64:          Result := '64-bit MacOS';
    bpOSXArm64:       Result := '64-bit ARM MacOS';
    bpAndroid32:      Result := '32-bit Android';
    bpAndroid64:      Result := '64-bit Android';
    bpLinux64:        Result := '64-bit Linux';
    bpiOSDevice32:    Result := '32-bit iOS';
    bpiOSDevice64:    Result := '64-bit iOS';
    bpiOSSimulatorArm64: Result := '64-bit ARM iOS Simulator';
    else              Result := '?';
  end;
end;
{------------------------------------------------------------------------------}
function GetDCC(Target: TJclBDSInstallation; APlatform: TJclBDSPlatform): TJclDCC32;
begin
  case APlatform of
    bpWin32:          Result := Target.DCC32;
    bpWin64:          Result := Target.DCC64;
    bpWin64x:         Result := Target.DCC64x;
    bpOSX32:          Result := Target.DCCOSX32;
    bpOSX64:          Result := Target.DCCOSX64;
    bpOSXArm64:       Result := Target.DCCOSXArm64;
    bpAndroid32:      Result := Target.DCCArm32;
    bpAndroid64:      Result := Target.DCCArm64;
    bpLinux64:        Result := Target.DCCLinux64;
    bpiOSDevice32:    Result := Target.DCCiOS32;
    bpiOSDevice64:    Result := Target.DCCiOS64;
    bpiOSSimulatorArm64: Result := Target.DCCiOSSimulatorArm64;
    else              Result := nil;
  end;
end;
{------------------------------------------------------------------------------}
function GetPlatformForInstallPlatform(AIP: TInstallPlatform): TJclBDSPlatform;
begin
  case AIP of
    ipWin64:     Result := bpWin64;
    ipWin64x:    Result := bpWin64x;
    ipOSX64:     Result := bpOSX64;
    ipOSXArm64:  Result := bpOSXArm64;
    ipAndroid32: Result := bpAndroid32;
    ipAndroid64: Result := bpAndroid64;
    ipLinux64:   Result := bpLinux64;
    //ipIOS32:   Result := bpiOSDevice32;
    ipIOS64:     Result := bpiOSDevice64;
    ipIOSSimARM64: Result := bpiOSSimulatorArm64;
    else // ipWin32:
                 Result := bpWin32;
  end;
end;
{------------------------------------------------------------------------------}
function GetPersonalitiesForInstallPlatform(AIP: TInstallPlatform): TJclBorPersonalities;
begin
  case AIP of
    ipWin32:     Result := [bpDelphi32, bpBCBuilder32];
    ipWin64:     Result := [bpDelphi64, bpBCBuilder64];
    ipWin64x:    Result := [bpDelphi64x];
    ipOSX64:     Result := [bpDelphiOSX64];
    ipOSXArm64:  Result := [bpDelphiOSXArm64];
    ipAndroid32: Result := [bpDelphiAndroid32];
    ipAndroid64: Result := [bpDelphiAndroid64];
    ipLinux64:   Result := [bpDelphiLinux64];
    //ipIOS32:   Result := [bpDelphiiOSDevice32];
    ipIOS64:     Result := [bpDelphiiOSDevice64];
    ipIOSSimARM64: Result := [bpDelphiiOSSimulatorArm64];
    else         Result := [];
  end;
end;
{------------------------------------------------------------------------------}
function GetDelphiPersonalityForInstallPlatform(AIP: TInstallPlatform): TJclBorPersonality;
begin
  case AIP of
    ipWin64:     Result := bpDelphi64;
    ipWin64x:    Result := bpDelphi64x;
    ipOSX64:     Result := bpDelphiOSX64;
    ipOSXArm64:  Result := bpDelphiOSXArm64;
    ipAndroid32: Result := bpDelphiAndroid32;
    ipAndroid64: Result := bpDelphiAndroid64;
    ipLinux64:   Result := bpDelphiLinux64;
    //ipIOS32:   Result := bpDelphiiOSDevice32;
    ipIOS64:     Result := bpDelphiiOSDevice64;
    ipIOSSimArm64:  Result := bpDelphiiOSSimulatorArm64;
    else // ipWin32:
                 Result := bpDelphi32;
  end;
end;
{------------------------------------------------------------------------------}
function CanInstallInTarget(AIP: TInstallPlatform; ATarget: TJclBorRADToolInstallation): Boolean;
begin
  Result := GetPersonalitiesForInstallPlatform(AIP) * ATarget.Personalities <> [];
end;
{------------------------------------------------------------------------------}
function TInstallConfig.GetBDSVersForPersonality(APersonality: TJclBorPersonality): TByteSet;
begin
  case APersonality of
    bpDelphi32:             Result := BDSVer;
    bpDelphi64:             Result := BDSWin64Ver;
    bpDelphi64x:            Result := BDSWin64xVer;
    bpDelphiOSX64:          Result := BDSOSX64Ver;
    bpDelphiOSXArm64:       Result := BDSOSXArm64Ver;
    bpDelphiAndroid32:      Result := BDSAndroid32Ver;
    bpDelphiAndroid64:      Result := BDSAndroid64Ver;
    bpDelphiLinux64:        Result := BDSLinux64Ver;
    bpDelphiiOSDevice32:    Result := []; // unsupported
    bpDelphiiOSDevice64:    Result := BDSIOS64Ver;
    bpDelphiiOSSimulatorArm64: Result := BDSIOSSimArm64Ver;
    else                    Result := [];
  end;
end;
{------------------------------------------------------------------------------}
function TInstallConfig.GetBDSVersForInstallPlatform(AIP: TInstallPlatform): TByteSet;
begin
  case AIP of
    ipWin32:     Result := BDSVer;
    ipWin64:     Result := BDSWin64Ver;
    ipWin64x:    Result := BDSWin64xVer;
    ipOSX64:     Result := BDSOSX64Ver;
    ipOSXArm64:  Result := BDSOSXArm64Ver;
    ipAndroid32: Result := BDSAndroid32Ver;
    ipAndroid64: Result := BDSAndroid64Ver;
    ipLinux64:   Result := BDSLinux64Ver;
    //ipIOS32:   Result := []; // unsupported
    ipIOS64:     Result := BDSIOS64Ver;
    ipIOSSimArm64:  Result := BDSIOSSimArm64Ver;
    else         Result := [];
  end;
end;
{------------------------------------------------------------------------------}
// Does not include Win32 and Win64
function TInstallConfig.GetInstallPlatforms(Target: TJclBorRADToolInstallation): TInstallPlatforms;
begin
  Result := [];
  if (bpDelphi64x in Target.Personalities) and (Target.VersionNumber in BDSWin64xVer) then
    Include(Result, ipWin64x);
  if (bpDelphiOSX64 in Target.Personalities) and (Target.VersionNumber in BDSOSX64Ver) then
    Include(Result, ipOSX64);
  if (bpDelphiOSXArm64 in Target.Personalities) and (Target.VersionNumber in BDSOSXArm64Ver) then
    Include(Result, ipOSXArm64);
  if (bpDelphiAndroid32 in Target.Personalities) and (Target.VersionNumber in BDSAndroid32Ver) then
    Include(Result, ipAndroid32);
  if (bpDelphiAndroid64 in Target.Personalities) and (Target.VersionNumber in BDSAndroid64Ver) then
    Include(Result, ipAndroid64);
  if (bpDelphiLinux64 in Target.Personalities) and (Target.VersionNumber in BDSLinux64Ver) then
    Include(Result, ipLinux64);
  // iOS32 skipped
  if (bpDelphiiOSDevice64 in Target.Personalities) and (Target.VersionNumber in AllBDSIOS64Ver) then
    Include(Result, ipIOS64);
  if (bpDelphiiOSSimulatorArm64 in Target.Personalities) and (Target.VersionNumber in AllBDSIOSSimArm64Ver) then
    Include(Result, ipIOSSimArm64);
end;
{------------------------------------------------------------------------------}
function TInstallConfig.CanInstallIn(ATarget: TJclBorRADToolInstallation; AIP: TInstallPlatform): Boolean;
begin
  Result := CanInstallInTarget(AIP, ATarget) and (AIP in InstallPlatforms) and
    (ATarget.VersionNumber in GetBDSVersForInstallPlatform(AIP));
end;
{------------------------------------------------------------------------------}
constructor TInstallItem.Create(ATarget: TJclBorRADToolInstallation;
  APersonality: TJclBorPersonality; ADual, ADual64, FullName: Boolean;
  AInstallPlatforms: TInstallPlatforms);
begin
  inherited Create;
  Target := ATarget;
  Personality := APersonality;
  Dual := ADual;
  Dual64 := ADual64;
  InstallPlatforms := AInstallPlatforms + [ipWin32, ipWin64];

  Name := Target.Name;
  if FullName then
    if Personality = bpDelphi32 then
      if Dual then
        Name := Name + ': Delphi and C++Builder'
      else
        Name := Name + ': Delphi'
    else
      Name := Name + ': C++Builder';
end;

function TfrmMain.GetUnitPath(const RootPath: String;
  Inst: TJclBorRADToolInstallation; Personality: TJclBorPersonality;
  Trial: Boolean): String;
begin
  if not Trial then
  begin
    Result := PathAddSeparator(RootPath);
    exit;
  end;
  Result := '?';
  case Inst.RadToolKind of
    brDelphi:
      case Inst.VersionNumber of
        3 .. 7:
          Result := 'D' + IntToStr(Inst.VersionNumber);
      end;
    brCppBuilder:
      case Inst.VersionNumber of
        6:
          Result := 'CB6';
      end;
    brBorlandDevStudio:
      case Inst.VersionNumber of
        3:
          Result := 'D2005';
        4:
          Result := '2006';
        5:
          if Personality = bpDelphi32 then
            Result := '2007'
          else
            Result := 'CB2007';
        6:
          if Personality = bpDelphi32 then
            Result := '2009'
          else
            Result := 'CB2009';
        7:
          if Personality = bpDelphi32 then
            Result := '2010'
          else
            Result := 'CB2010';
        8:
          if Personality = bpDelphi32 then
            Result := 'XE'
          else
            Result := 'CBXE';
        9 .. 12:
          if Personality in [bpDelphi32, bpDelphi64] then
            Result := 'XE' + IntToStr(Inst.VersionNumber - 7)
          else
            Result := 'CBXE' + IntToStr(Inst.VersionNumber - 7);
        14 .. 16:
          if Personality in [bpDelphi32, bpDelphi64] then
            Result := 'XE' + IntToStr(Inst.VersionNumber - 8)
          else
            Result := 'CBXE' + IntToStr(Inst.VersionNumber - 8);
        17:
          if Personality in [bpDelphi32, bpDelphi64] then
            Result := '10'
          else
            Result := 'CB10';
        18:
          if Personality in [bpDelphi32, bpDelphi64] then
            Result := '10_1'
          else
            Result := 'CB10_1';
        19:
          if Personality in [bpDelphi32, bpDelphi64] then
            Result := '10_2'
          else
            Result := 'CB10_2';
        20:
          if Personality in [bpDelphi32, bpDelphi64, bpDelphiOSX64, bpDelphiLinux64] then
            Result := '10_3'
          else
            Result := 'CB10_3';
        21:
          if Personality in [bpDelphi32, bpDelphi64,
            bpDelphiOSX64,
            bpDelphiAndroid32, bpDelphiAndroid64,
            bpDelphiLinux64,
            bpDelphiiOSDevice64] then
            Result := '10_4'
          else
            Result := 'CB10_4';
        22:
          if Personality in [bpDelphi32, bpDelphi64,
            bpDelphiOSX64, bpDelphiOSXArm64,
            bpDelphiAndroid32, bpDelphiAndroid64,
            bpDelphiLinux64,
            bpDelphiiOSDevice64, bpDelphiiOSSimulatorArm64] then
            Result := '11'
          else
            Result := 'CB11';
        23:
          if Personality in [bpDelphi32, bpDelphi64, bpDelphi64x,
            bpDelphiOSX64, bpDelphiOSXArm64,
            bpDelphiAndroid32, bpDelphiAndroid64,
            bpDelphiLinux64,
            bpDelphiiOSDevice64, bpDelphiiOSSimulatorArm64] then
            Result := '12'
          else
            Result := 'CB12';
      end;
  end;
  Result := PathAddSeparator(RootPath + Result);
end;

function TfrmMain.GetPkgFile64(const RootPath, PkgPrefix: String;
  Inst: TJclBorRADToolInstallation; Personality: TJclBorPersonality;
  Trial, DesignTime: Boolean): String;
var
  Suffix: String;
begin
  Result := '?';
  if (Inst.RadToolKind <> brBorlandDevStudio) or (Inst.VersionNumber < 9) then
    exit;

  case Config.Scheme of
    1: Suffix := '_64';
    2: Suffix := '';
    else exit;
  end;
  if DesignTime then
    Suffix := '_Dsgn';

  Result := GetPkgFile(RootPath, PkgPrefix, Suffix, Inst, Personality, Trial);
end;

function TfrmMain.GetPkgFile(const RootPath, PkgPrefix, PkgSuffix: String;
  Inst: TJclBorRADToolInstallation; Personality: TJclBorPersonality;
  Trial: Boolean): String;
begin
  Result := '?';
  case Inst.RadToolKind of
    brDelphi:
      case Inst.VersionNumber of
        3 .. 7:
          Result := 'D' + IntToStr(Inst.VersionNumber) + PkgSuffix + '.dpk';
      end;
    brCppBuilder:
      case Inst.VersionNumber of
        6:
          Result := 'CB6' + PkgSuffix + '.bpk';
      end;
    brBorlandDevStudio:
      case Inst.VersionNumber of
        3:
          Result := 'D2005' + PkgSuffix + '.dpk';
        4:
          Result := '2006' + PkgSuffix + '.dpk';
        5:
          if Personality = bpDelphi32 then
            Result := 'D2007' + PkgSuffix + '.dpk'
          else
            Result := 'CB2007' + PkgSuffix + '.cbproj';
        6:
          if Personality = bpDelphi32 then
            Result := 'D2009' + PkgSuffix + '.dpk'
          else
            Result := 'CB2009' + PkgSuffix + '.cbproj';
        7:
          if Personality = bpDelphi32 then
            Result := 'D2010' + PkgSuffix + '.dpk'
          else
            Result := 'CB2010' + PkgSuffix + '.cbproj';
        8:
          if Personality = bpDelphi32 then
            Result := 'DXE' + PkgSuffix + '.dpk'
          else
            Result := 'CBXE' + PkgSuffix + '.cbproj';
        9 .. 12:
          if Personality in [bpDelphi32, bpDelphi64] then
            Result := 'DXE' + IntToStr(Inst.VersionNumber - 7) + PkgSuffix + '.dpk'
          else
            Result := 'CBXE' + IntToStr(Inst.VersionNumber - 7) + PkgSuffix + '.cbproj';
        14 .. 16:
          if Personality in [bpDelphi32, bpDelphi64] then
            Result := 'DXE' + IntToStr(Inst.VersionNumber - 8) + PkgSuffix + '.dpk'
          else
            Result := 'CBXE' + IntToStr(Inst.VersionNumber - 8) + PkgSuffix + '.cbproj';
        17:
          if Personality in [bpDelphi32, bpDelphi64] then
            Result := 'D10' + PkgSuffix + '.dpk'
          else
            Result := 'CB10' + PkgSuffix + '.cbproj';
        18:
          if Personality in [bpDelphi32, bpDelphi64] then
            Result := 'D10_1' + PkgSuffix + '.dpk'
          else
            Result := 'CB10_1' + PkgSuffix + '.cbproj';
        19:
          if Personality in [bpDelphi32, bpDelphi64] then
            Result := 'D10_2' + PkgSuffix + '.dpk'
          else
            Result := 'CB10_2' + PkgSuffix + '.cbproj';
        20:
          if Personality in [bpDelphi32, bpDelphi64, bpDelphiOSX64, bpDelphiLinux64] then
            Result := 'D10_3' + PkgSuffix + '.dpk'
          else
            Result := 'CB10_3' + PkgSuffix + '.cbproj';
        21:
          if Personality in [bpDelphi32, bpDelphi64,
            bpDelphiOSX64,
            bpDelphiAndroid32, bpDelphiAndroid64,
            bpDelphiLinux64,
            bpDelphiiOSDevice64] then
            Result := 'D10_4' + PkgSuffix + '.dpk'
          else
            Result := 'CB10_4' + PkgSuffix + '.cbproj';
        22:
          if Personality in [bpDelphi32, bpDelphi64,
            bpDelphiOSX64, bpDelphiOSXArm64,
            bpDelphiAndroid32, bpDelphiAndroid64,
            bpDelphiLinux64,
            bpDelphiiOSDevice64, bpDelphiiOSSimulatorArm64] then
            Result := 'D11' + PkgSuffix + '.dpk'
          else
            Result := 'CB11' + PkgSuffix + '.cbproj';
        23:
          if Personality in [bpDelphi32, bpDelphi64, bpDelphi64x,
            bpDelphiOSX64, bpDelphiOSXArm64,
            bpDelphiAndroid32, bpDelphiAndroid64,
            bpDelphiLinux64,
            bpDelphiiOSDevice64, bpDelphiiOSSimulatorArm64] then
            Result := 'D12' + PkgSuffix + '.dpk'
          else
            Result := 'CB12' + PkgSuffix + '.cbproj';
      end;
  end;
  Result := GetUnitPath(PathAddSeparator(RootPath), Inst, Personality, Trial) +
    PkgPrefix + Result;
end;

function GetOutputPath(APersonality:  TJclBorPersonality): String;
begin
  case APersonality of
    bpDelphi32, bpBCBuilder32: Result := '32';
    bpDelphi64, bpBCBuilder64: Result := '64';
    bpDelphi64x:               Result := '64x';
    bpDelphiOSX32:             Result := 'OSX32';
    bpDelphiOSX64:             Result := 'OSX64';
    bpDelphiOSXArm64:          Result := 'OSXArm64';
    bpDelphiAndroid32:         Result := 'Android32';
    bpDelphiAndroid64:         Result := 'Android64';
    bpDelphiLinux64:           Result := 'Linux64';
    bpDelphiiOSDevice32:       Result := '?';
    bpDelphiiOSDevice64:       Result := 'iOSDevice64';
    bpDelphiiOSSimulatorArm64: Result := 'iOSSimARM64';
    else                       Result := '?';
  end;
end;

function GetDelphiOutputPath(APersonality:  TJclBorPersonality): String;
begin
  Result := 'Delphi' + GetOutputPath(APersonality);
end;

function GetCBuilderOutputPath(APersonality:  TJclBorPersonality): String;
begin
  Result := 'CBuilder' + GetOutputPath(APersonality);
end;


function TfrmMain.GetHPPPath(const UnitsPath: String;
  Inst: TJclBorRADToolInstallation; Personality: TJclBorPersonality;
  Trial: Boolean): String;
var
  Folder: String;
begin
  Result := '';
  case Inst.RadToolKind of
    brCppBuilder:
      case Inst.VersionNumber of
        6:
          Result := '6';
      end;
    brBorlandDevStudio:
      case Inst.VersionNumber of
        3:
          Result := 'D2005';
        4:
          Result := '2006';
        5:
          Result := '2007';
        6:
          Result := '2009';
        7:
          Result := '2010';
        8:
          Result := 'XE';
        9 .. 12:
          Result := 'XE' + IntToStr(Inst.VersionNumber - 7);
        14 .. 16:
          Result := 'XE' + IntToStr(Inst.VersionNumber - 8);
        17:
          Result := '10';
        18:
          Result := '10_1';
        19:
          Result := '10_2';
        20:
          Result := '10_3';
        21:
          Result := '10_4';
        22:
          Result := '11';
        23:
          Result := '12';
      end;
  end;
  Folder := GetCBuilderOutputPath(Personality);
  Result := PathAddSeparator(PathAddSeparator(UnitsPath) + Folder + '\' + Result);
end;

function TfrmMain.GetObjPath(const HppPath: String;
  Inst: TJclBorRADToolInstallation; Personality: TJclBorPersonality): String;
begin
  case Inst.RadToolKind of
    brCppBuilder:
      Result := HppPath;
    else
      Result := HppPath + 'Release\';
  end;

end;

function TfrmMain.GetUnitOutputPath(const UnitsPath: String;
  Inst: TJclBorRADToolInstallation; Personality: TJclBorPersonality;
  Trial: Boolean): String;
var
  Folder: String;
begin
  Result := '';
  case Inst.RadToolKind of
    brDelphi:
      case Inst.VersionNumber of
        3 .. 7:
          Result := 'D' + IntToStr(Inst.VersionNumber);
      end;
    brBorlandDevStudio:
      case Inst.VersionNumber of
        3:
          Result := '2005';
        4:
          Result := '2006';
        5:
          Result := '2007';
        6:
          Result := '2009';
        7:
          Result := '2010';
        8:
          Result := 'XE';
        9 .. 12:
          Result := 'XE' + IntToStr(Inst.VersionNumber - 7);
        14 .. 16:
          Result := 'XE' + IntToStr(Inst.VersionNumber - 8);
        17:
          Result := '10';
        18:
          Result := '10_1';
        19:
          Result := '10_2';
        20:
          Result := '10_3';
        21:
          Result := '10_4';
        22:
          Result := '11';
        23:
          Result := '12';
      end;
  end;
  Folder := GetDelphiOutputPath(Personality);
  Result := Folder + '\' + Result + '\Release\';
  if UnitsPath <> '' then
    Result := PathAddSeparator(UnitsPath) + Result;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
var
  i: Integer;
begin
  FInstallers.Free;
  for i := 0 to clstIDE.Items.Count - 1 do
    clstIDE.Items.Objects[i].Free;
  FPackages.Free;
  FCheckUnits.Free;
  FCheckIncs.Free;
  FDepPackages.Free;
  FPaths.Free;
  FDescr.Free;
  FTitles.Free;
  FUninstallers.Free;
  FHelpFiles.Free;
  FRequirePaths.Free;
  FReplacements.Free;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  if Activated then
    exit;
  Activated := True;
  if Config.QuickMode and (Config.InstallMode = imUninstall) then
    PostMessage(Handle, WM_PROCEED, 0, 0);
end;

procedure TfrmMain.WMProceed(var Msg: TMessage);
begin
  btnNextClick(nil);
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if Installing then
  begin
    CanClose := False;
    if not Aborted then
    begin
      Aborted := Application.MessageBox('Do you want to exit?', PChar(Caption),
      MB_ICONQUESTION or MB_YESNO) = IDYES;
      if Aborted then
      begin
        btnExit.Caption := 'Aborting...';
        btnExit.Enabled := False;
      end;
    end;
  end
  else if (PageControl1.ActivePage = tabIDE) or
    (PageControl1.ActivePage = tabUninstall) or (PageControl1.ActivePage = tabChoose) then
    CanClose := Application.MessageBox('Do you want to exit?', PChar(Caption),
      MB_ICONQUESTION or MB_YESNO) = IDYES;
end;

procedure TfrmMain.UpdateCaptions;
begin
  case Config.InstallMode of
    imInstall:
      begin
        Label1.Caption :=
          Format('Installing %s in %s IDE', [Config.Product, Config.IDE]) +
          #13#10'Choose IDE versions to install the components';
        btnNext.Caption := 'Install >';
      end;
    imUninstall:
      begin
        Label1.Caption :=
          Format('Uninstalling %s from Delphi and C++Builder IDE', [Config.Product]) +
          #13#10'Click "Uninstall" to start';;
        btnNext.Caption := 'Uninstall >';
      end;
    imChoose:
      begin
        Label1.Caption :=
          Format('Installing or uninstalling %s to Delphi and C++Builder IDE', [Config.Product]);
        btnNext.Caption := 'Next >';
      end;
  end;
  Label1.Width := Label1.Parent.Width - Label1.Left - Image1.Left;
end;

const
  EnvRegSection = 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment';

function SetGlobalEnvironmentVariable(const AName, AValue: String): Boolean;
var
  Reg: TRegistry;
  Res: DWORD_PTR;
const
  Setting = 'Environment';
begin
  Result := False;
  try
    Reg := TRegistry.Create;
    try
      Reg.RootKey := HKEY_LOCAL_MACHINE;
      Reg.OpenKey(EnvRegSection, False);
      if AValue <> '' then
        Reg.WriteExpandString(AName, AValue)
      else
        Reg.DeleteValue(AName);
      SendMessageTimeout (HWND_BROADCAST, WM_SETTINGCHANGE, 0, LParam(PChar(Setting)),
        SMTO_ABORTIFHUNG, 5000, @Res);
      Result := True;
    finally
      Reg.Free;
    end;
  except

  end;
end;

function GetGlobalEnvironmentVariable(const AName: String): String;
var
  Reg: TRegistry;
begin
  Result := '';
  try
    Reg := TRegistry.Create;
    try
      Reg.Access := KEY_READ;
      Reg.RootKey := HKEY_LOCAL_MACHINE;
      Reg.OpenKey(EnvRegSection, False);
      Result := Reg.ReadString(AName);
    finally
      Reg.Free;
    end;
  except
  end;
end;

procedure TfrmMain.InitPages;
begin
  case Config.InstallMode of
    imInstall:
      begin
        PageControl1.ActivePage := tabIDE;
        MoveControlsToActivePage;
        btnOptions.Visible := not HasTrial and not Config.CBuilder;
        if Config.SourcePathVar <> '' then
        begin
          if SetGlobalEnvironmentVariable(Config.SourcePathVar, Config.SourcePath) then
            Config.SourcePathEnv := '$('+Config.SourcePathVar+')\'
          else
            Application.MessageBox('Cannot set the global environment variable (administrator right are reqiured)'#13#10+
              'The installer will add the full path to packages', 'Warning', MB_OK or MB_ICONINFORMATION);
        end;
        FillIDEList;
        CheckExisting;
        btnNext.Enabled := IsIDEChosen;
      end;
    imUninstall:
      begin
        FillUninstallers;
        PageControl1.ActivePage := tabUninstall;
        MoveControlsToActivePage;
        btnNext.Enabled := True;
      end;
    imChoose:
      begin
        PageControl1.ActivePage := tabChoose;
        MoveControlsToActivePage;
        btnNext.Enabled := True;
      end;
  end;
end;

function IsWin7Up: Boolean;
var
  vi: TOSVersionInfo;
begin
  vi.dwOSVersionInfoSize := sizeof(vi);
  GetVersionEx(vi);
  Result := (vi.dwPlatformId = VER_PLATFORM_WIN32_NT) and
    (
      ((vi.dwMajorVersion = 6) and (vi.dwMinorVersion >= 1)) or
      (vi.dwMajorVersion > 6)
    );
end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  ErrorMsg, FileName: String;
begin
  if Screen.Fonts.IndexOf(Font.Name) < 0 then
  begin
    Font.Name := 'Tahoma';
    Font.Size := 8;
    panNoInstallers.Font.Name := 'Tahoma';
    panNoInstallers.Font.Size := 8;
    txtLog.Font.Name := 'Tahoma';
    txtLog.Font.Size := 8;
    Label1.Font.Name := 'Tahoma';
    Label1.Font.Size := 11;
  end;
  ShowStatusMsg('');
  {$IFDEF TASKBAR}
  try
    if IsWin7Up then
      FTaskBar := TTaskbar.Create(Self);
  except
    FreeAndNil(FTaskBar);
  end;
  {$ENDIF}
  FReplacements := TReplaceCollection.Create;
  FInstallers := TJclBorRADToolInstallations.Create;
  FUninstallers := TList.Create;

  FileName := '';
  ErrorMsg := '';
  if (ParamCount = 0) then
  begin
    if OpenDialog1.Execute then
      FileName := OpenDialog1.FileName;
  end
  else
    FileName := ParamStr(1);
  if (FileName = '') or not LoadConfig(FileName, ErrorMsg) then
  begin
    if ErrorMsg <> '' then
      Application.MessageBox(PChar(ErrorMsg), nil, MB_OK or MB_ICONSTOP);
    Application.Terminate;
    exit;
  end;
  lblUninstall.Caption := Format(lblUninstall.Caption, [Config.Product]);
  UpdateCaptions;
  InitPages;
  if Config.QuickMode and (Config.InstallMode = imUninstall) then
    btnNext.Enabled := False;
  FPathToSrcWin32 := True;
  LoadOptions;
end;

procedure TfrmMain.FillIDEList;
var
  i:           Integer;
  Target:      TJclBorRADToolInstallation;
  InstallItem: TInstallItem;
begin
  for i := 0 to FInstallers.Count - 1 do
  begin
    Target := FInstallers.Installations[i];
    case Target.RadToolKind of
      brDelphi:
        if Target.VersionNumber in Config.DelphiVer then
        begin
          InstallItem := TInstallItem.Create(Target, bpDelphi32, False,
            False, False, []);
          clstIDE.AddItem(InstallItem.Name, InstallItem);
        end;
      brCppBuilder:
        if Target.VersionNumber in Config.BCBVer then
        begin
          InstallItem := TInstallItem.Create(Target, bpBCBuilder32, False,
            False, False, []);
          clstIDE.AddItem(InstallItem.Name, InstallItem);
        end;
      brBorlandDevStudio:
        if (Target.VersionNumber in Config.BDSVer) and
          (Target.Personalities * [bpDelphi32, bpBCBuilder32] <> []) then
        begin
          if not Config.CBuilder and (bpDelphi32 in Target.Personalities) then
          begin
            InstallItem := TInstallItem.Create(Target, bpDelphi32,
              (bpBCBuilder32 in Target.Personalities) and (Target.VersionNumber in Config.BDSDualVer),
              (bpBCBuilder64 in Target.Personalities) and (Target.VersionNumber in Config.BDS64DualVer),
              True, Config.GetInstallPlatforms(Target));
            clstIDE.AddItem(InstallItem.Name, InstallItem);
          end;
          if Config.CBuilder and (bpBCBuilder32 in Target.Personalities) and
            (Target.VersionNumber in Config.BDSVer) then
          begin
            InstallItem := TInstallItem.Create(Target, bpBCBuilder32, False,
              False, True, []);
            clstIDE.AddItem(InstallItem.Name, InstallItem);
          end;
        end;
    end;
  end;
  panNoInstallers.Visible := clstIDE.Items.Count=0;
end;

procedure TfrmMain.FillUninstallers;
var
  i:      Integer;
  Target: TJclBorRADToolInstallation;
begin
  for i := 0 to FInstallers.Count - 1 do
  begin
    Target := FInstallers.Installations[i];
    case Target.RadToolKind of
      brDelphi:
        if (Target.VersionNumber in Config.DelphiVer) then
        begin
          FUninstallers.Add(Target);
        end;
      brCppBuilder:
        if Target.VersionNumber in Config.BCBVer then
        begin
          FUninstallers.Add(Target);
        end;
      brBorlandDevStudio:
        if (Target.VersionNumber in Config.BDSVer) and
          (Target.Personalities * [bpDelphi32, bpBCBuilder32] <> []) then
        begin
          FUninstallers.Add(Target);
        end;
    end;
  end;
end;

function TfrmMain.GetBplPath(Target: TJclBorRADToolInstallation): String;
begin
  Result := Target.BPLOutputPath[bpWin32];
  if (Target.RadToolKind <> brBorlandDevStudio) or (Target.VersionNumber < 3)
  then
    Result := PathGetShortName(Result);
end;

function TfrmMain.GetDcpPath(Target: TJclBorRADToolInstallation): String;
begin
  Result := Target.DcpOutputPath[bpWin32];
  if (Target.RadToolKind <> brBorlandDevStudio) or (Target.VersionNumber < 3)
  then
    Result := PathGetShortName(Result);
end;

function TfrmMain.GetBpl64Path(Target: TJclBorRADToolInstallation): String;
begin
  Result := Target.BPLOutputPath[bpWin64];
end;

function TfrmMain.GetDcp64Path(Target: TJclBorRADToolInstallation): String;
begin
  Result := Target.DcpOutputPath[bpWin64];
end;

function TfrmMain.GetBplPathEx(Target: TJclBorRADToolInstallation;
  APlatform: TJclBDSPlatform): String;
begin
  Result := Target.BPLOutputPath[APlatform];
end;

function TfrmMain.GetDcpPathEx(Target: TJclBorRADToolInstallation;
  APlatform: TJclBDSPlatform): String;
begin
  Result := Target.DcpOutputPath[APlatform];
end;

function TfrmMain.IsInstalled(const PackageFileName: string;
  Target: TJclBorRADToolInstallation): Boolean;
begin
  Result := FileExists(BinaryFileName(GetBplPath(Target), PackageFileName));
end;

procedure TfrmMain.CheckExisting;
var
  i:         Integer;
  PkgName:   String;
  Installed: Boolean;
begin
  Screen.Cursor := crHourGlass;
  clstIDE.Items.BeginUpdate;
  try
    FUninstallers.Clear;
    for i := 0 to clstIDE.Items.Count - 1 do
    begin
      PkgName := GetPkgFile(Config.SourcePath + FPaths[0], FPackages[0], '',
        TInstallItem(clstIDE.Items.Objects[i]).Target,
        TInstallItem(clstIDE.Items.Objects[i]).Personality, IsTrial[0]);
      Installed := IsInstalled(PkgName,
        TInstallItem(clstIDE.Items.Objects[i]).Target);
      clstIDE.Checked[i] := Installed;
      if Installed then
        FUninstallers.Add(TInstallItem(clstIDE.Items.Objects[i]).Target);
    end;
    if Config.CheckAll and (FUninstallers.Count = 0) then
      for i := 0 to clstIDE.Items.Count - 1 do
        clstIDE.Checked[i] := True;
  finally
    clstIDE.Items.EndUpdate;
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.RemoveCheckedUninstallers;
var
  i, idx: Integer;
begin
  for i := 0 to clstIDE.Items.Count - 1 do
    if clstIDE.Checked[i] then
    begin
      idx := FUninstallers.IndexOf
        (TInstallItem(clstIDE.Items.Objects[i]).Target);
      if idx >= 0 then
        FUninstallers.Delete(idx);
    end;
end;

procedure TfrmMain.ConfigureBpr2Mak(const PackageFileName, HppPath: string;
  Target: TJclBorRADToolInstallation);

     function GetRelativePath: String;
     var
       s: String;
       i: Integer;
     begin
       s := PackageFileName;
       Delete(s, 1, Length(Config.SourcePath));
       Result := '';
       for i := 1 to Length(s) do
         if s[i] = '\' then
           Result := Result + '..\';
     end;

begin
  if clProj2Mak in Target.CommandLineTools then
  begin
    Target.Bpr2Mak.Options.Clear;
    Target.Bpr2Mak.AddPathOption('t', GetRelativePath+'Lib\BCB.bmk');
  end;
  if clMake in Target.CommandLineTools then
  begin
    Target.Make.Options.Clear;
    Target.Make.AddPathOption('DBPILIBDIR=', GetDcpPath(Target));
    Target.Make.AddPathOption('DBPLDIR=', GetBplPath(Target));

    if HppPath <> '' then
      Target.Make.AddPathOption('DHPPDIR=',
        ExtractRelativePath(ExtractFilePath(PackageFileName), HppPath));
  end;
end;

procedure TfrmMain.GetListOfPathToDelete(const Paths: String;
  PathsToDelete: TStringList; const CheckUnit, CheckInc: String;
  Target: TJclBorRADToolInstallation);
var
  sl, sl2:   TStringList;
  i:    Integer;
  Path: String;
  DeleteIt: Boolean;
  Paths2: String;
begin
  Paths2 := Paths;
  ExpandEnvironmentVarCustom(Paths2, Target.EnvironmentVariables);
  sl := TStringList.Create;
  sl2 := TStringList.Create;
  try
    PathsToDelete.Clear;
    Target.ExtractPaths(Paths, sl);
    Target.ExtractPaths(Paths2, sl2);
    if sl.Count <> sl2.Count then
      exit;
    for i := sl.Count - 1 downto 0 do
    begin
      Path := PathAddSeparator(sl2.Strings[i]);
      DeleteIt :=
        (CheckUnit <> '') and
        (FileExists(Path + CheckUnit + '.pas') or
         FileExists(Path + CheckUnit + '.dcu') or
         FileExists(Path + CheckUnit + '.obj') or
         FileExists(Path + CheckUnit + '.o') or
         FileExists(Path + CheckUnit + '.hpp'));
      if not DeleteIt and (CheckInc <> '') then
        DeleteIt :=
          FileExists(Path + CheckInc);
      if DeleteIt then
        PathsToDelete.Add(sl.Strings[i]);
    end;
  finally
    sl.Free;
    sl2.Free;
  end;
end;

function TfrmMain.DeletePathsToOldVersions(Target: TJclBorRADToolInstallation;
  CheckUnit, CheckInc: String): Boolean;
var
  PathsToDelete: TStringList;
  Log:           String;
  PathCollection: TJclLibPathCollection;
  BDSTarget: TJclBDSInstallation;

  procedure AddLog(const PathType: String; APlatform: TJclBDSPlatform);
  var
    i: Integer;
  begin
    for i := PathsToDelete.Count - 1 downto 0 do
      if AnsiPos(AnsiLowerCase(PathRemoveSeparator(Config.SourcePath)),
        AnsiLowerCase(PathRemoveSeparator(PathsToDelete.Strings[i]))) = 1 then
        PathsToDelete.Delete(i);
    if PathsToDelete.Count = 0 then
      exit;
    Log := Log + #13#10 + '--- ' + PathType + ' (' + Target.GetBDSPlatformStr
      (APlatform) + '): ---';
    for i := 0 to PathsToDelete.Count - 1 do
      Log := Log + #13#10 + PathsToDelete.Strings[i];
  end;

  function CleanLibrarySearchPath(APlatform: TJclBDSPlatform): Boolean;
  var
    i: Integer;
  begin
    GetListOfPathToDelete(Target.LibrarySearchPath[APlatform], PathsToDelete,
      CheckUnit, CheckInc, Target);
    Result := PathsToDelete.Count > 0;
    if PathCollection <> nil then
      for i := 0 to PathsToDelete.Count - 1 do
        PathCollection.AddLibrarySearchPath(PathsToDelete.Strings[i], BDSTarget, APlatform)
    else
      for i := 0 to PathsToDelete.Count - 1 do
        Target.RemoveFromLibrarySearchPath(PathsToDelete.Strings[i], APlatform);
    AddLog('Library', APlatform);
    GetListOfPathToDelete(Target.LibraryBrowsingPath[APlatform], PathsToDelete,
      CheckUnit, CheckInc, Target);
    Result := Result or (PathsToDelete.Count > 0);
    if PathCollection <> nil then
      for i := 0 to PathsToDelete.Count - 1 do
       PathCollection.AddLibraryBrowsingPath(PathsToDelete.Strings[i], BDSTarget, APlatform)
    else
      for i := 0 to PathsToDelete.Count - 1 do
       Target.RemoveFromLibraryBrowsingPath(PathsToDelete.Strings[i], APlatform);
    AddLog('Browsing', APlatform);
  end;

  function CleanCBuilderPath(APlatform: TJclBDSPlatform): Boolean;
  var
    i:       Integer;
    LTarget: TJclBDSInstallation;
  begin
    Result := False;
    if not(Target is TJclBDSInstallation) then
      exit;
    LTarget := TJclBDSInstallation(Target);
    GetListOfPathToDelete(LTarget.CppLibraryPath[APlatform], PathsToDelete,
      CheckUnit, CheckInc, Target);
    Result := PathsToDelete.Count > 0;
    if PathCollection <> nil then
      for i := 0 to PathsToDelete.Count - 1 do
        PathCollection.AddCppLibraryPath(PathsToDelete.Strings[i], LTarget, APlatform)
    else
      for i := 0 to PathsToDelete.Count - 1 do
        LTarget.RemoveFromCppLibraryPath(PathsToDelete.Strings[i], APlatform);
    AddLog('C++ library', APlatform);

    if (APlatform = bpWin32) and Target.HasClang32 and (PathCollection = nil) then
    begin
      GetListOfPathToDelete(LTarget.CppLibraryPath_Clang32, PathsToDelete,
        CheckUnit, CheckInc, Target);
      Result := Result or (PathsToDelete.Count > 0);
      for i := 0 to PathsToDelete.Count - 1 do
        LTarget.RemoveFromCppLibraryPath_Clang32(PathsToDelete.Strings[i]);
      AddLog('C++ library for new compiler', APlatform);
    end;

    GetListOfPathToDelete(LTarget.CppBrowsingPath[APlatform], PathsToDelete,
      CheckUnit, CheckInc, Target);
    Result := Result or (PathsToDelete.Count > 0);
    if PathCollection <> nil then
      for i := 0 to PathsToDelete.Count - 1 do
        PathCollection.AddCppBrowsingPath(PathsToDelete.Strings[i], LTarget, APlatform)
    else
      for i := 0 to PathsToDelete.Count - 1 do
        LTarget.RemoveFromCppBrowsingPath(PathsToDelete.Strings[i], APlatform);
    AddLog('C++ browsing', APlatform);

    GetListOfPathToDelete(LTarget.CppIncludePath[APlatform], PathsToDelete,
      CheckUnit, CheckInc, Target);
    Result := Result or (PathsToDelete.Count > 0);
    if PathCollection <> nil then
      for i := 0 to PathsToDelete.Count - 1 do
        PathCollection.AddCppIncludePath(PathsToDelete.Strings[i], LTarget, APlatform)
    else
      for i := 0 to PathsToDelete.Count - 1 do
        LTarget.RemoveFromCppIncludePath(PathsToDelete.Strings[i], APlatform);
    AddLog('C++ include', APlatform);

    if (APlatform = bpWin32) and Target.HasClang32 and (PathCollection = nil) then
    begin
      GetListOfPathToDelete(LTarget.CppIncludePath_Clang32, PathsToDelete,
        CheckUnit, CheckInc, Target);
      Result := Result or (PathsToDelete.Count > 0);
      for i := 0 to PathsToDelete.Count - 1 do
        LTarget.RemoveFromCppIncludePath_Clang32(PathsToDelete.Strings[i]);
      AddLog('C++ include for new compiler', APlatform);
    end;

    GetListOfPathToDelete(LTarget.CppSearchPath[APlatform], PathsToDelete,
      CheckUnit, CheckInc, Target);
    Result := Result or (PathsToDelete.Count > 0);
    for i := 0 to PathsToDelete.Count - 1 do
      LTarget.RemoveFromCppSearchPath(PathsToDelete.Strings[i], APlatform);
    AddLog('C++ search', APlatform);
  end;
  {............................................................................}
  function CleanLibrarySearchPaths: Boolean;
  var
    IP: TInstallPlatform;
  begin
    Result := False;
    for IP := Low(TInstallPlatform) to High(TInstallPlatform) do
      if CanInstallInTarget(IP, Target) then
        if CleanLibrarySearchPath(GetPlatformForInstallPlatform(IP)) then
          Result := True;
    if bpBCBuilder32 in Target.Personalities then
      if CleanCBuilderPath(bpWin32) then
        Result := True;
    if bpBCBuilder64 in Target.Personalities then
      if CleanCBuilderPath(bpWin64) then
        Result := True;
    if bpDelphi64x in Target.Personalities then { we did not define bpCBuilder64x yet }
      if CleanCBuilderPath(bpWin64x) then
        Result := True;
  end;

begin
  Result := False;
  if (CheckUnit = '') and (CheckInc = '') then
    exit;
  PathsToDelete := TStringList.Create;
  if (Target is TJclBDSInstallation) and (Target.IDEVersionNumber >= 5) then
  begin
    PathCollection := TJclLibPathCollection.Create;
    BDSTarget := TJclBDSInstallation(Target);
  end
  else
  begin
    PathCollection := nil;
    BDSTarget := nil;
  end;
  try
    Log := '';
    Result := CleanLibrarySearchPaths;
    if (PathCollection <> nil) and (PathCollection.Count > 0) then
      BDSTarget.RemoveFromAnyLibPath(PathCollection);
    if Log <> '' then
      Log := Format(RemovedFmtStr, [Target.Name]) + Log;
    RemovedPaths := RemovedPaths + Log;
  finally
    PathsToDelete.Free;
    PathCollection.Free;
  end;
end;

function TfrmMain.InstallPackage(const PackageFileNameRun, PackageFileNameDsgn,
  Descr, IncludePath: string; Target: TJclBorRADToolInstallation;
  Personality: TJclBorPersonality; Dual, Trial, Optional, RuntimeOnly, NoCE: Boolean): Boolean;
var
  SrcPath, HppPath, ObjPath, DcpPath, BplPath, LibPaths, UnitPath, Options, NU: string;
  SpecialDsgnPackage: Boolean;
  LPlatform: TJclBDSPlatform;
  DelphiPersonality: TJclBorPersonality;

  procedure CleanPackagesCache;
  begin
    if Target.RadToolKind = brBorlandDevStudio then
    begin
      (Target as TJclBDSInstallation).CleanPackageCache
        (BinaryFileName(BplPath, PackageFileNameRun), LPlatform);
      if SpecialDsgnPackage then
        (Target as TJclBDSInstallation).CleanPackageCache
          (BinaryFileName(BplPath, PackageFileNameDsgn), LPlatform);
    end;
  end;

  procedure AddLogAndUninstall(const PackageFileName, Msg: String);
  begin
    if not (Optional and FIgnoreOptionalErrors) then
      ErrorLog := ErrorLog + Format(LogErrorFmtStr, [PackageFileName]) + Msg;
    ShowStatusMsg(Format('Uninstalling package %s (%s)',
      [ExtractFileName(ChangeFileExt(PackageFileNameRun, SourceExtensionDelphiPackage)), GetPlatformName(LPlatform)]));
    Target.UninstallPackage(ChangeFileExt(PackageFileNameRun, SourceExtensionDelphiPackage),
      BplPath, DcpPath, LPlatform, LPlatform);
    if SpecialDsgnPackage and not RuntimeOnly then
    begin
      ShowStatusMsg(Format('Uninstalling package %s (%s)',
        [ExtractFileName(ChangeFileExt(PackageFileNameDsgn, SourceExtensionDelphiPackage)), GetPlatformName(LPlatform)]));
      Target.UninstallPackage(ChangeFileExt(PackageFileNameDsgn, SourceExtensionDelphiPackage),
        BplPath, DcpPath, LPlatform, LPlatform);
    end;
  end;

  procedure ChangeDCUOutputDir(const PackageFileName: String);
  begin
    if HasTrial or Config.CBuilder or (LPlatform <> bpWin32) then
      exit;
    if FPathToSrcWin32 then
      ChangeDCUOutput(ChangeFileExt(PackageFileName, SourceExtensionDProject),
        '.', Target.VersionNumber)
    else
      ChangeDCUOutput(ChangeFileExt(PackageFileName, SourceExtensionDProject),
        GetUnitOutputPath('', Target, DelphiPersonality, False), Target.VersionNumber);
  end;

  function CompileAndInstall(const IncludePath: String): Boolean;
  begin
    Result := True;
    CleanPackagesCache;
    if SpecialDsgnPackage or RuntimeOnly then
    begin
      ShowStatusMsg('Modifying package ' + ExtractFileName(PackageFileNameRun));
      ChangeDCUOutputDir(PackageFileNameRun);
      ShowStatusMsg(Format('Compiling package %s (%s)',
        [ExtractFileName(PackageFileNameRun), GetPlatformName(LPlatform)]));
      Result := Target.CompilePackage(PackageFileNameRun,
          BplPath, DcpPath, HppPath, IncludePath, LibPaths, Options);
      if not Result then
        AddLogAndUninstall(PackageFileNameRun, Target.DCC.Output);
      if Result and not IsCBProjPackage(PackageFileNameRun) and
        (Target.VersionNumber = BDSCommunityEditionVer)
        {$IFnDEF TESTCOMMUNITYEDITION}
         and not FileExists(PathAddSeparator(DcpPath) + ChangeFileExt(ExtractFileName(PackageFileNameRun), '.dcp'))
        {$ENDIF}
        then
      begin
        CEDetected := True;
        ShowStatusMsg(Format('Copying Community Edition package %s (%s)',
          [ExtractFileName(PackageFileNameRun), GetPlatformName(LPlatform)]));
        Result := CopyPackageLibsD(PackageFileNameRun, Target, LPlatform);
        if not Result and not NoCE then
        begin
          CEFailed := True;
          AddLogAndUninstall(PackageFileNameRun,
            Format('Error while copying precompiled library files for Community Edition (%s)', [GetPlatformName(LPlatform)]));
        end;
      end;
      if Result and IsCBProjPackage(PackageFileNameRun) then
      begin
        ShowStatusMsg('Hiding source files');
        HideSourceFiles(SrcPath, ObjPath);
      end;
    end;
    if Result and not RuntimeOnly then
    begin
      ShowStatusMsg('Modifying package ' + ExtractFileName(PackageFileNameDsgn));
      ChangeDCUOutputDir(PackageFileNameDsgn);
      ShowStatusMsg('Installing package ' + ExtractFileName(PackageFileNameDsgn));
      Result := Target.InstallPackage(PackageFileNameDsgn,
        BplPath, DcpPath, HppPath, IncludePath, LibPaths, Options, LPlatform);
      if not Result then
        AddLogAndUninstall(PackageFileNameDsgn, Target.DCC.Output);
      if Result and not IsCBProjPackage(PackageFileNameDsgn) and
        (Target.VersionNumber = BDSCommunityEditionVer)
        {$IFnDEF TESTCOMMUNITYEDITION}
        and not FileExists(PathAddSeparator(DcpPath) + ChangeFileExt(ExtractFileName(PackageFileNameDsgn), '.dcp'))
        {$ENDIF}
        then
      begin
        CEDetected := True;
        ShowStatusMsg(Format('Copying Community Edition package %s (%s)',
          [ExtractFileName(PackageFileNameDsgn), GetPlatformName(LPlatform)]));
        Result := CopyPackageLibsD(PackageFileNameDsgn, Target, LPlatform);
        if not Result and not NoCE then
        begin
          AddLogAndUninstall(PackageFileNameRun,
            Format('Error while copying precompiled library files for Community Edition (%s)', [GetPlatformName(LPlatform)]));
          CEFailed := True;
        end;
        ShowStatusMsg('Registering package ' + ExtractFileName(PackageFileNameDsgn));
        Result := Target.RegisterPackage(BinaryFileName(BplPath, PackageFileNameDsgn),
          Format(Descr, [Target.Name]), LPlatform);
        if not Result then
          AddLogAndUninstall(PackageFileNameDsgn, 'Error registering package')
      end;
      if Result and IsCBProjPackage(PackageFileNameRun) then
      begin
        ShowStatusMsg('Hiding source files');
        HideSourceFiles(SrcPath, ObjPath);
      end;
    end;
  end;

  function CompileAndInstallBpk: Boolean;
  begin
    Result := True;
    ShowStatusMsg('Preparing BPK compilation');
    ConfigureBpr2Mak(PackageFileNameRun, HppPath, Target);
    CleanPackagesCache;
    Target.Make.Output := '';
    if SpecialDsgnPackage or RuntimeOnly then
    begin
      ShowStatusMsg('Compiling package ' + ExtractFileName(PackageFileNameRun));
      Result := Target.CompilePackage(PackageFileNameRun,
        BplPath, DcpPath, HppPath, '', '', '');
    end;
    if not Result then
      AddLogAndUninstall(PackageFileNameRun, Target.Make.Output)
    else if not RuntimeOnly then
    begin
      ShowStatusMsg('Installing package ' + ExtractFileName(PackageFileNameDsgn));
      Target.Make.Output := '';
      Result := Target.InstallPackage(PackageFileNameDsgn,
        BplPath, DcpPath, HppPath, LibPaths, '', '', LPlatform);
      if not Result then
        AddLogAndUninstall(PackageFileNameDsgn, Target.Make.Output)
    end;
  end;

  function CopyAndInstallCB: Boolean;
  begin
    Result := True;
    if SpecialDsgnPackage or RuntimeOnly then
    begin
      ShowStatusMsg('Copying package ' + ExtractFileName(PackageFileNameRun));
      Result := CopyPackageLibsCB(PackageFileNameRun, Target);
    end;
    if not Result then
      AddLogAndUninstall(PackageFileNameRun, 'Error while copying precompiled library files')
    else if not RuntimeOnly then
    begin
      ShowStatusMsg('Copying package ' + ExtractFileName(PackageFileNameDsgn));
      Result := CopyPackageLibsCB(PackageFileNameDsgn, Target);
      if not Result then
        AddLogAndUninstall(PackageFileNameDsgn, 'Error while copying precompiled library files')
    end;
    if Result and not RuntimeOnly then
    begin
      ShowStatusMsg('Registering package ' + ExtractFileName(PackageFileNameDsgn));
      Result := Target.RegisterPackage(BinaryFileName(BplPath, PackageFileNameDsgn),
        Format(Descr, [Target.Name]), LPlatform);
      if not Result then
        AddLogAndUninstall(PackageFileNameDsgn, 'Error registering package')
    end;
  end;

var
  DCURenamed: Boolean;

begin
  if Config.NoCompile then
  begin
    Result := True;
    exit;
  end;
  DCURenamed := False;
  try
    ShowStatusMsg(Format('Preparing compilation of package %s (%s)',
      [ExtractFileName(PackageFileNameRun), GetPlatformName(LPlatform)]));

    if Personality in [bpDelphi32, bpBCBuilder32] then
    begin
      LPlatform := bpWin32;
      DelphiPersonality := bpDelphi32;
      Target.DCC := Target.DCC32;
      DcpPath := GetDcpPath(Target);
      BplPath := GetBplPath(Target);
    end
    else
    begin
      LPlatform := bpWin64;
      DelphiPersonality := bpDelphi64;
      Target.DCC := (Target as TJclBDSInstallation).DCC64;
      DcpPath := GetDcp64Path(Target);
      BplPath := GetBpl64Path(Target);
    end;

    SpecialDsgnPackage := PackageFileNameRun <> PackageFileNameDsgn;
    SrcPath := ExtractFilePath(PackageFileNameRun);
    HppPath := GetHPPPath(SrcPath, Target, Personality, Trial);
    ObjPath := GetObjPath(HppPath, Target, Personality);
    ForceDirectories(PathRemoveSeparator(DcpPath));
    ForceDirectories(PathRemoveSeparator(BplPath));
    LibPaths := Target.LibrarySearchPath[LPlatform];

    if not FPathToSrcWin32 or (LPlatform = bpWin64) then
    begin
      UnitPath := PathRemoveSeparator
        (GetUnitOutputPath(ExtractFilePath(PackageFileNameRun), Target,
        DelphiPersonality, Trial));
      ForceDirectories(UnitPath);
      CopyToUnitOutputPath(PackageFileNameRun, Target, DelphiPersonality, Trial);
      if LPlatform = bpWin32 then
        DoDeleteDCU(ExtractFilePath(PackageFileNameRun))
      else
      begin
        RenameAllFiles(ExtractFilePath(PackageFileNameRun), '*.dcu', '._dcu');
        DCURenamed := True;
      end;
      Options := '-U' + AnsiQuotedStr(UnitPath, '"');
      if not Trial then
      begin
        case Target.RadToolKind of
          brDelphi:
            NU := 'N'; // Delphi 5 - 7
          brBorlandDevStudio:
            case Target.VersionNumber of
              0..3: NU := 'N'; // Delphi 2005
              4..9: NU := 'N0' // 2007 .. XE2
              else  NU := 'NU';
            end;
          else
            NU := '???';
        end;
        Options := '-B -' + NU + AnsiQuotedStr(UnitPath, '"');
      end;
    end
    else
      Options := '';
    //Application.MessageBox(PChar(LibPaths), nil, 0);
    ExpandEnvironmentVarCustom(LibPaths, Target.EnvironmentVariables);
    if ((Target is TJclBDSInstallation) and Dual) or
      (IsCBProjPackage(PackageFileNameRun) and (bpBCBuilder32 in Target.Personalities)) or
      (IsBCBPackage(PackageFileNameRun)    and (bpBCBuilder32 in Target.Personalities))
    then
    begin
      ForceDirectories(PathRemoveSeparator(HppPath));
      if Target is TJclBDSInstallation then
        TJclBDSInstallation(Target).DualPackageInstallation := True;
    end
    else
      TJclBDSInstallation(Target).DualPackageInstallation := False;
    if IsDelphiPackage(PackageFileNameRun) and
      (DelphiPersonality in Target.Personalities) then
      Result := CompileAndInstall(IncludePath)
    else if IsCBProjPackage(PackageFileNameRun) and
      (bpBCBuilder32 in Target.Personalities) then
    begin
      if Trial then
        Result := CopyAndInstallCB
      else
      begin
        Result := CompileAndInstall('');
        // DeleteCopies is not needed any more: instead, we hide pas-files
        // of previously compiled packages
        //DeleteCopies(SrcPath, ObjPath, HppPath);
      end;
    end
    else if IsBCBPackage(PackageFileNameRun) and
      (bpBCBuilder32 in Target.Personalities) then
    begin
      if Trial then
        Result := CopyAndInstallCB
      else
        Result := CompileAndInstallBpk;
    end
    else
    begin
      Result := False;
    end;
  except
    on E: Exception do
    begin
      if not (Optional and FIgnoreOptionalErrors) then
        ErrorLog := ErrorLog + Format(LogErrorFmtStr, [PackageFileNameRun]) +
          'Exception ' + E.ClassName + ': ' + E.Message;
      Result := False;
    end;
  end;
  if DCURenamed then
    RenameAllFiles(ExtractFilePath(PackageFileNameRun), '*._dcu', '.dcu');
end;

function TfrmMain.AddDirToUnitsInPackage(const PackageFileName: String;
  const Dir: AnsiString): Boolean;
var
  DProjFileName: String;
begin
  DProjFileName := ChangeFileExt(PackageFileName, SourceExtensionDProject);
  Result := ReplaceInFile(PackageFileName, 'in ''', 'in ''' + Dir, True) and
    ReplaceInFile(DProjFileName, 'DCCReference Include="',
    'DCCReference Include="' + Dir, True)
end;

function TfrmMain.RemoveDirFromUnitsInPackage(const PackageFileName: String;
  const Dir: AnsiString): Boolean;
var
  DProjFileName: String;
begin
  DProjFileName := ChangeFileExt(PackageFileName, SourceExtensionDProject);
  Result := ReplaceInFile(PackageFileName, 'in ''' + Dir, 'in ''' , False) and
    ReplaceInFile(DProjFileName, 'DCCReference Include="' + Dir,
    'DCCReference Include="', False)
end;
{------------------------------------------------------------------------------}
function TfrmMain.AdjustPathToUnitsInPackage(const PackageFileName: string;
  Target: TJclBorRADToolInstallation; APersonality: TJclBorPersonality): Boolean;
var
  Dir: String;
begin
  if IsDelphiPackage(PackageFileName) and (APersonality in Target.Personalities)
    and (Target.VersionNumber in Config.GetBDSVersForPersonality(APersonality)) then
  begin
    Dir := GetUnitOutputPath('', Target, APersonality, True);
    Result := AddDirToUnitsInPackage(PackageFileName, AnsiString(Dir));
  end
  else
    Result := True;
end;
{------------------------------------------------------------------------------}
function TfrmMain.AdjustPathToUnitsInPackageBack(const PackageFileName: string;
  Target: TJclBorRADToolInstallation; APersonality: TJclBorPersonality): Boolean;
var
  Dir: String;
begin
  if IsDelphiPackage(PackageFileName) and (APersonality in Target.Personalities)
    and (Target.VersionNumber in Config.GetBDSVersForPersonality(APersonality)) then
  begin
    Dir := GetUnitOutputPath('', Target, APersonality, True);
    Result := RemoveDirFromUnitsInPackage(PackageFileName, AnsiString(Dir));
  end
  else
    Result := True;
end;
{------------------------------------------------------------------------------}
function TfrmMain.CompileRuntime(const PackageFileName, Descr, IncludePath: string;
  Target: TJclBorRADToolInstallation; Personality: TJclBorPersonality;
  APlatform: TJclBDSPlatform; Dual, Trial, Optional, NoCE: Boolean): Boolean;
var
  HppPath, UnitPath, Options, NU, DcpPath, BplPath, LibPaths: string;
  {............................................................................}
  procedure AddLogAndUninstall(const PackageFileName, Msg: String);
  begin
    if not (Optional and FIgnoreOptionalErrors) and
      (not FIgnoreNonWinErrors or (APlatform in [bpWin32, bpWin64])) then
      ErrorLog := ErrorLog + Format(LogErrorFmtStr, [PackageFileName]) + Msg;
    ShowStatusMsg(Format('Uninstalling package %s (%s)',
      [ExtractFileName(PackageFileName), GetPlatformName(APlatform)]));
    Target.UninstallPackage(ChangeFileExt(PackageFileName, SourceExtensionDelphiPackage),
      BplPath, DcpPath, APlatform, bpWin32);
      // Last parameter = bpWin32 because we do not call this function
      // for Win64 packages if 64-bit IDE exists
  end;
  {............................................................................}
  procedure PreparePaths;
  begin
    DcpPath := GetDcpPathEx(Target, APlatform);
    BplPath := GetBplPathEx(Target, APlatform);
    LibPaths := Target.LibrarySearchPath[APlatform];
    //if APlatform = bpLinux64 then
    //  LibPaths := '$(fmxlinux)\Lib\$(ProductVersion)\Release;' + LibPaths;
    ExpandEnvironmentVarCustom(LibPaths, Target.EnvironmentVariables);
    HppPath := PathRemoveSeparator
      (GetHPPPath(ExtractFilePath(PackageFileName), Target, Personality, Trial));
  end;
  {............................................................................}
begin
  if Config.NoCompile then
  begin
    Result := True;
    exit;
  end;
  try
    if IsDelphiPackage(PackageFileName) and (Personality in Target.Personalities)
      and (Target.VersionNumber in Config.GetBDSVersForPersonality(Personality)) then
    begin
      ShowStatusMsg(Format('Preparing compilation of package %s (%s)',
        [ExtractFileName(PackageFileName), GetPlatformName(APlatform)]));
      PreparePaths;
      Target.DCC := GetDCC(Target as TJclBDSInstallation, APlatform);
      UnitPath := PathRemoveSeparator
        (GetUnitOutputPath(ExtractFilePath(PackageFileName), Target,
        Personality, Trial));
      if Dual then
      begin
        ForceDirectories(PathRemoveSeparator(HppPath));
        TJclBDSInstallation(Target).DualPackageInstallation := True;
      end
      else
        TJclBDSInstallation(Target).DualPackageInstallation := False;
      ForceDirectories(UnitPath);
      CopyToUnitOutputPath(PackageFileName, Target, Personality, Trial);
      (Target as TJclBDSInstallation).CleanPackageCache
        (BinaryFileName(BplPath, PackageFileName), APlatform);
      RenameAllFiles(ExtractFilePath(PackageFileName), '*.dcu', '._dcu');
      try
        Options := '-U' + AnsiQuotedStr(UnitPath, '"');
        if not Trial then
        begin
          if Target.VersionNumber = 9 then
            NU := 'N0'
          else
            NU := 'NU';
          Options := '-B -' + NU + AnsiQuotedStr(UnitPath, '"');
        end;
        ForceDirectories(BplPath);
        ForceDirectories(DcpPath);
        ShowStatusMsg(Format('Compiling package %s (%s)',
          [ExtractFileName(PackageFileName), GetPlatformName(APlatform)]));
        Result := (Target as TJclBDSInstallation).CompileDelphiPackage
          (PackageFileName, BplPath, DcpPath, HppPath,
          IncludePath, LibPaths, Options);
        if not Result then
          AddLogAndUninstall(PackageFileName, Target.DCC.Output);
        if Result and (Target.VersionNumber = BDSCommunityEditionVer)
          {$IFnDEF TESTCOMMUNITYEDITION}
          and not FileExists(PathAddSeparator(DcpPath)+ ChangeFileExt(ExtractFileName(PackageFileName), '.dcp'))
          {$ENDIF}
        then
        begin
          CEDetected := True;
          ShowStatusMsg(Format('Copying Community Edition package %s (%s)',
            [ExtractFileName(PackageFileName), GetPlatformName(APlatform)]));
          Result := CopyPackageLibsD(PackageFileName, Target, APlatform);
          if not Result and not NoCE then
          begin
            AddLogAndUninstall(PackageFileName,
              Format('Error while copying precompiled library files for Community Edition (%s)', [GetPlatformName(APlatform)]));
            CEFailed := True;
          end;
        end;
      finally
        ShowStatusMsg(Format('Finalizing compilation of package %s (%s)',
          [ExtractFileName(PackageFileName), GetPlatformName(APlatform)]));
        RenameAllFiles(ExtractFilePath(PackageFileName), '*._dcu', '.dcu');
      end;
    end
    else if IsCBProjPackage(PackageFileName) and (bpBCBuilder64 in Target.Personalities)
      and (Target.VersionNumber in Config.BDSCBuilder64Ver) then
    begin
      // this code is never executed - 64-bit CBPROJ packages are not supported yet
      PreparePaths;
      if Trial then
        Result := False // to-do
      else
      begin
        ForceDirectories(BplPath);
        ForceDirectories(DcpPath);
        Result := Target.CompileCBProjPackage(PackageFileName,
          BplPath, DcpPath, HppPath, bpWin64, True);
        DeleteCopies(
          ExtractFilePath(PackageFileName),
          GetObjPath(HppPath, Target, Personality), HppPath);

        if not Result then
          AddLogAndUninstall(PackageFileName, Target.DCC.Output);
      end;
    end
    else
    begin
      Result := False;
    end;
  except
    on E: Exception do
    begin
      if not (Optional and FIgnoreOptionalErrors) then
        ErrorLog := ErrorLog + Format(LogErrorFmtStr, [PackageFileName]) +
          'Exception ' + E.ClassName + ': ' + E.Message;
      Result := False;
    end;
  end;

end;

function TfrmMain.CopyPackageLibsCB(const PackageFileName: string;
  Target: TJclBorRADToolInstallation): Boolean;
var
  FileName, Source, Dest: String;
begin
  FileName := ExtractFileName(PackageFileName);
  Source := PathAddSeparator(Config.SourcePath) + 'Lib\' +
    ChangeFileExt(FileName, '.bpl');
  Dest := PathAddSeparator(GetBplPath(Target)) +
    ChangeFileExt(FileName, '.bpl');
  Result := CopyFile(PChar(Source), PChar(Dest), False);
  if not Result then
    exit;
  Source := PathAddSeparator(Config.SourcePath) + 'Lib\' +
    ChangeFileExt(FileName, '.bpi');
  Dest := PathAddSeparator(GetDcpPath(Target)) +
    ChangeFileExt(FileName, '.bpi');
  Result := CopyFile(PChar(Source), PChar(Dest), False);
  if not Result then
    exit;
  Source := PathAddSeparator(Config.SourcePath) + 'Lib\' +
    ChangeFileExt(FileName, '.lib');
  Dest := PathAddSeparator(GetDcpPath(Target)) +
    ChangeFileExt(FileName, '.lib');
  Result := CopyFile(PChar(Source), PChar(Dest), False);
end;

function GetOutputPath2(APlatform: TJclBDSPlatform): String;
begin
  case APlatform of
    bpWin32:          Result := '';
    bpWin64:          Result := 'Win64';
    bpWin64x:         Result := 'Win64x';
    bpOSX64:          Result := 'OSX64';
    bpOSXArm64:       Result := 'OSXArm64';
    bpAndroid32:      Result := 'Android';
    bpAndroid64:      Result := 'Android64';
    bpLinux64:        Result := 'Linux64';
    bpiOSDevice32:    Result :=  '?';
    bpiOSDevice64:    Result := 'iOSDevice64';
    bpiOSSimulatorArm64: Result := 'iOSSimARM64';
    else              Result := '?';
  end;
end;

function TfrmMain.CopyPackageLibsD(const PackageFileName: string;
  Target: TJclBorRADToolInstallation; APlatform: TJclBDSPlatform): Boolean;
var
  SrcPath, DstPath: String;
  FileName: String;

  function DoCopy(FileName: String): Boolean;
  var
    Src, Dst: String;
  begin
    Src := SrcPath + FileName;
    Dst := DstPath + FileName;
    Result := CopyFile(PChar(Src), PChar(Dst), False);
  end;

begin
  FileName := ExtractFileName(PackageFileName);
  SrcPath := PathAddSeparator(PathAddSeparator(Config.SourcePath) + 'LibCE\' + GetOutputPath2(APlatform));
  DstPath := PathAddSeparator(GetDcpPathEx(Target, APlatform));
  Result := DoCopy(ChangeFileExt(FileName, '.dcp'));
  if not Result then
    exit;
  case APlatform of
    bpWin32, bpWin64x:
      begin
        Result := DoCopy(ChangeFileExt(FileName, '.bpi')) and
          DoCopy(ChangeFileExt(FileName, '.lib'));
      end;
    bpWin64:
      begin
        Result := DoCopy(ChangeFileExt(FileName, '.bpi')) and
          DoCopy(ChangeFileExt(FileName, '.a'));
      end;
    bpOSX64, bpOSXArm64, bpLinux64:
      begin
        Result := DoCopy(ChangeFileExt('lib' + FileName, '.a')) and
          DoCopy(ChangeFileExt(FileName, '_nonshared.a')) and
          DoCopy(ChangeFileExt(FileName, '.bpi')) and
          DoCopy(ChangeFileExt(FileName, '.imp.o'));
      end;
    bpAndroid32, bpAndroid64, bpiOSDevice64, bpiOSSimulatorArm64:
      begin
        Result := DoCopy(ChangeFileExt('lib' + FileName, '.a'));
      end;
    else
      Result := False;
  end;
  if not Result then
    exit;
  DstPath := PathAddSeparator(GetBplPathEx(Target, APlatform));
  case APlatform of
    bpWin32, bpWin64, bpWin64x:
      begin
        Result := DoCopy(ChangeFileExt(FileName, '.bpl'));
      end;
    bpOSX64, bpOSXArm64:
      begin
        Result := DoCopy(ChangeFileExt('bpl' + FileName, '.dylib'));
      end;
    bpAndroid32, bpAndroid64, bpiOSDevice64, bpiOSSimulatorArm64: ;
    bpLinux64:
      begin
        Result := DoCopy(ChangeFileExt('bpl' + FileName, '.so'));
      end;
    else
      Result := False;
  end;
end;

function TfrmMain.CopyToUnitOutputPath(const PackageFileName: string;
  Target: TJclBorRADToolInstallation; Personality: TJclBorPersonality;
  Trial: Boolean): Boolean;
var
  SourceDir, DestDir, Source, Dest: String;
  sr:                               TSearchRec;
begin
  SourceDir := ExtractFilePath(PackageFileName);
  DestDir := GetUnitOutputPath(SourceDir, Target, Personality, Trial);
  Result := True;

  if FindFirst(SourceDir + '*.dfm', 0, sr) = 0 then
  begin
    repeat
      if (sr.Attr and faDirectory) = 0 then
      begin
        Source := SourceDir + sr.Name;
        Dest := DestDir + sr.Name;
        if not CopyFile(PChar(Source), PChar(Dest), False) then
          Result := False;
      end;
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;
  if FindFirst(SourceDir + '*.fmx', 0, sr) = 0 then
  begin
    repeat
      if (sr.Attr and faDirectory) = 0 then
      begin
        Source := SourceDir + sr.Name;
        Dest := DestDir + sr.Name;
        if not CopyFile(PChar(Source), PChar(Dest), False) then
          Result := False;
      end;
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;
  if FindFirst(SourceDir + '*.res', 0, sr) = 0 then
  begin
    repeat
      if (sr.Attr and faDirectory) = 0 then
      begin
        Source := SourceDir + sr.Name;
        if not(FileExists(ChangeFileExt(Source, SourceExtensionDelphiPackage))
          or FileExists(ChangeFileExt(Source, SourceExtensionBCBPackage)) or
          FileExists(ChangeFileExt(Source, SourceExtensionRSBCBPackage)) or
          FileExists(ChangeFileExt(Source, SourceExtensionBDSProject))) then
        begin
          Dest := DestDir + sr.Name;
          if not CopyFile(PChar(Source), PChar(Dest), False) then
            Result := False;
        end;
      end;
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;
end;

procedure TfrmMain.DeleteCopies(SrcDir, DcuDir, HppDir: String);
var
  sr: TSearchRec;
begin
  DcuDir := PathAddSeparator(DcuDir);
  SrcDir := PathAddSeparator(SrcDir);
  HppDir := PathAddSeparator(HppDir);

  if FindFirst(PathAddSeparator(DcuDir) + '*.dcu', 0, sr) = 0 then
  begin
    repeat
      if (sr.Attr and faDirectory) = 0 then
      begin
        if not FileExists(SrcDir + ChangeFileExt(sr.Name, '.pas')) then
          FileDelete(DcuDir + sr.Name, False);
      end;
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;
  if FindFirst(PathAddSeparator(DcuDir) + '*.obj', 0, sr) = 0 then
  begin
    repeat
      if (sr.Attr and faDirectory) = 0 then
      begin
        if not FileExists(SrcDir + ChangeFileExt(sr.Name, '.pas')) then
          FileDelete(DcuDir + sr.Name, False);
      end;
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;
  if FindFirst(PathAddSeparator(DcuDir) + '*.o', 0, sr) = 0 then
  begin
    repeat
      if (sr.Attr and faDirectory) = 0 then
      begin
        if not FileExists(SrcDir + ChangeFileExt(sr.Name, '.pas')) then
          FileDelete(DcuDir + sr.Name, False);
      end;
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;
  if FindFirst(PathAddSeparator(HppDir) + '*.hpp', 0, sr) = 0 then
  begin
    repeat
      if (sr.Attr and faDirectory) = 0 then
      begin
        if not FileExists(SrcDir + ChangeFileExt(sr.Name, '.pas')) then
          FileDelete(HppDir + sr.Name, False);
      end;
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;
end;

procedure TfrmMain.DoDeleteDCU(Dir: String);
var
  sr: TSearchRec;
begin
  Dir := PathAddSeparator(Dir);
  if FindFirst(Dir + '*.dcu', 0, sr) = 0 then
  begin
    repeat
      if (sr.Attr and faDirectory) = 0 then
        FileDelete(Dir + sr.Name, False);
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;
end;

procedure TfrmMain.DoDeleteAllCompilationResults(SrcDir, DcuDir, HppDir: String);
var
  sr: TSearchRec;
begin
  SrcDir := PathAddSeparator(SrcDir);
  DcuDir := PathAddSeparator(DcuDir);
  HppDir := PathAddSeparator(HppDir);

  if FindFirst(DcuDir + '*.dcu', 0, sr) = 0 then
  begin
    repeat
      if (sr.Attr and faDirectory) = 0 then
        FileDelete(DcuDir + sr.Name, False);
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;
  if FindFirst(DcuDir + '*.obj', 0, sr) = 0 then
  begin
    repeat
      if (sr.Attr and faDirectory) = 0 then
        FileDelete(DcuDir + sr.Name, False);
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;
  if FindFirst(DcuDir + '*.o', 0, sr) = 0 then
  begin
    repeat
      if (sr.Attr and faDirectory) = 0 then
        FileDelete(DcuDir + sr.Name, False);
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;
  if FindFirst(DcuDir + '*.#00', 0, sr) = 0 then
  begin
    repeat
      if (sr.Attr and faDirectory) = 0 then
        FileDelete(DcuDir + sr.Name, False);
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;
  if FindFirst(DcuDir + '*.pch', 0, sr) = 0 then
  begin
    repeat
      if (sr.Attr and faDirectory) = 0 then
        FileDelete(DcuDir + sr.Name, False);
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;
  if FindFirst(DcuDir + 'staticobjs\*.obj', 0, sr) = 0 then
  begin
    repeat
      if (sr.Attr and faDirectory) = 0 then
        FileDelete(DcuDir + 'staticobjs\' + sr.Name, False);
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;
  if FindFirst(DcuDir + 'staticobjs\*.o', 0, sr) = 0 then
  begin
    repeat
      if (sr.Attr and faDirectory) = 0 then
        FileDelete(DcuDir + 'staticobjs\' + sr.Name, False);
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;
  if FindFirst(HppDir + '*.hpp', 0, sr) = 0 then
  begin
    repeat
      if (sr.Attr and faDirectory) = 0 then
        FileDelete(HppDir + sr.Name, False);
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;

  if FindFirst(SrcDir + '*.dcu', 0, sr) = 0 then
  begin
    repeat
      if (sr.Attr and faDirectory) = 0 then
        FileDelete(SrcDir + sr.Name, False);
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;
  if FindFirst(SrcDir + '*.obj', 0, sr) = 0 then
  begin
    repeat
      if (sr.Attr and faDirectory) = 0 then
        FileDelete(SrcDir + sr.Name, False);
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;
  if FindFirst(SrcDir + '*.o', 0, sr) = 0 then
  begin
    repeat
      if (sr.Attr and faDirectory) = 0 then
        FileDelete(SrcDir + sr.Name, False);
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;
  if FindFirst(SrcDir + '*.hpp', 0, sr) = 0 then
  begin
    repeat
      if (sr.Attr and faDirectory) = 0 then
        FileDelete(SrcDir + sr.Name, False);
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;

end;

procedure TfrmMain.DeleteAllCompilationResults(Target: TJclBorRADToolInstallation;
  const SrcPath: String; Personality: TJclBorPersonality; Trial: Boolean);
var
  HppPath,  ObjPath: String;
begin
  HppPath := GetHPPPath(SrcPath, Target, Personality, Trial);
  ObjPath := GetObjPath(HppPath, Target, Personality);
  DoDeleteAllCompilationResults(SrcPath, ObjPath, HppPath);
end;

procedure TfrmMain.HideSourceFiles(SrcDir, DcuDir: String);
var
  sr: TSearchRec;
begin
  SrcDir := PathAddSeparator(SrcDir);

  if DcuDir <> '' then
  begin
    DcuDir := PathAddSeparator(DcuDir);
    if FindFirst(DcuDir + '*.dcu', 0, sr) = 0 then
    begin
      repeat
        if (sr.Attr and faDirectory) = 0 then
        begin
          if FileExists(SrcDir + ChangeFileExt(sr.Name, '.pas')) then
          begin
            DeleteFile(SrcDir + ChangeFileExt(sr.Name, '.hidden_pas'));
            RenameFile(
              SrcDir + ChangeFileExt(sr.Name, '.pas'),
              SrcDir + ChangeFileExt(sr.Name, '.hidden_pas'));
          end;
        end;
      until FindNext(sr) <> 0;
      FindClose(sr);
    end
  end
  else
  begin
    if FindFirst(SrcDir + '*.pas', 0, sr) = 0 then
    begin
      repeat
        if (sr.Attr and faDirectory) = 0 then
        begin
            RenameFile(
              SrcDir + ChangeFileExt(sr.Name, '.pas'),
              SrcDir + ChangeFileExt(sr.Name, '.hidden_pas'));
        end;
      until FindNext(sr) <> 0;
      FindClose(sr);
    end;
  end;
end;

procedure TfrmMain.RestoreSourceFiles(SrcDir: String);
var
  sr: TSearchRec;
begin
  SrcDir := PathAddSeparator(SrcDir);

  if FindFirst(SrcDir + '*.hidden_pas', 0, sr) = 0 then
  begin
    repeat
      if (sr.Attr and faDirectory) = 0 then
      begin
          RenameFile(
            SrcDir + ChangeFileExt(sr.Name, '.hidden_pas'),
            SrcDir + ChangeFileExt(sr.Name, '.pas'));
      end;
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;
end;

{
 // probably, it makes sense to delete previosly compiled files,
 // especially for C++Builder 6 that does "make" and does not regenerate hpp
 // but we need to do it only for the first package in the folder
 procedure TfrmMain.DeleteCompiled(SrcDir, DcuDir, HppDir: String);
 var sr: TSearchRec;
 begin
 DcuDir := PathAddSeparator(DcuDir);
 SrcDir := PathAddSeparator(SrcDir);
 HppDir := PathAddSeparator(HppDir);

 if FindFirst(PathAddSeparator(SrcDir)+'*.pas', 0, sr) = 0 then
 begin
 repeat
 if (sr.Attr and faDirectory) = 0 then begin
 FileDelete(DcuDir+ChangeFileExt(sr.Name, '.dcu'));
 FileDelete(DcuDir+ChangeFileExt(sr.Name, '.obj'));
 FileDelete(HppDir+ChangeFileExt(sr.Name, '.hpp'));
 end;
 until FindNext(sr) <> 0;
 FindClose(sr);
 end;
 if FindFirst(PathAddSeparator(SrcDir)+'*.dcu', 0, sr) = 0 then
 begin
 repeat
 if (sr.Attr and faDirectory) = 0 then begin
 FileDelete(DcuDir+ChangeFileExt(sr.Name, '.dcu'));
 FileDelete(DcuDir+ChangeFileExt(sr.Name, '.obj'));
 FileDelete(HppDir+ChangeFileExt(sr.Name, '.hpp'));
 end;
 until FindNext(sr) <> 0;
 FindClose(sr);
 end;
 end;
}

function PathRemoveSeparator(const Path: string): string;
begin
  Result := Path;
  if (Path <> '') and (Path[Length(Path)] = DirDelimiter) then
    Result := Copy(Path, 1, Length(Path) - 1);
end;

function MakeUninstallName(const PkgName: String): String;
begin
  Result := PkgName;
  if SameText(ExtractFileExt(PkgName), '.cbproj') then
    Result := ChangeFileExt(PkgName, SourceExtensionDelphiPackage);
end;

procedure TfrmMain.AddToLastLogLine(const S: String);
begin
  txtLog.Lines[txtLog.Lines.Count - 1] :=
    txtLog.Lines[txtLog.Lines.Count - 1] + S;
end;

procedure TfrmMain.Install;
var
  i, j:                       Integer;
  Target:                     TJclBorRADToolInstallation;
  Personality32, Personality64: TJclBorPersonality;
  FullIncludePaths, HppPaths, DCUPaths: array [TInstallPlatform] of String;
  PkgNameRun, PkgNameDsgn, Path, PrevPath, IncludePath, PrevIncludePath,
  ObjPathWin32, PkgTitle, Verb: String;
  AllOk, Ok, Dual, Dual64, PackageExists: Boolean;
  Count: Integer;
  PathCollection: TJclLibPathCollection;
  {............................................................................}
  procedure UninstallPackage(Target: TJclBorRADToolInstallation;
    const Path, Pkg: String);
  var
    PkgName, Suffix: String;
  begin
    ShowStatusMsg('Uninstalling ' + ExtractFileName(Pkg));
    case Config.Scheme of
      1: Suffix := '';
      2: Suffix := '_Dsgn';
      else Suffix := '?';
    end;
    if bpDelphi32 in Target.Personalities then
    begin
      PkgName := GetPkgFile(Path, Pkg, Suffix, Target, bpDelphi32, False);
      Target.UninstallPackage(PkgName, GetBplPath(Target), GetDcpPath(Target), bpWin32, bpWin32);
    end;
    if bpBCBuilder32 in Target.Personalities then
    begin
      PkgName := GetPkgFile(Path, Pkg, Suffix, Target, bpBCBuilder32, False);
      Target.UninstallPackage(MakeUninstallName(PkgName), GetBplPath(Target),
        GetDcpPath(Target), bpWin32, bpWin32);
    end;
    if clBds64 in Target.CommandLineTools then
    begin
      PkgName := GetPkgFile(Path, Pkg, Suffix, Target, bpDelphi64, False);
      Target.UninstallPackage(PkgName, GetBplPath(Target), GetDcpPath(Target), bpWin64, bpWin64);
    end;

  end;
  {............................................................................}
  procedure UninstallDepPackages(Target: TJclBorRADToolInstallation);
  var
    i: Integer;
  begin
    if FDepPackages.Count > 0 then
      ShowStatusMsg('Uninstalling dependent packages');
    for i := 0 to FDepPackages.Count - 1 do
    begin
      UninstallPackage(Target, '', FDepPackages[i]);
    end;
  end;
  {............................................................................}
  procedure SetFullIncludePaths;
  var
    IP: TInstallPlatform;
  begin
    for IP := Low(TInstallPlatform) to High(TInstallPlatform) do
      if CanInstallInTarget(IP, Target) then
      begin
        FullIncludePaths[IP] := Target.LibrarySearchPath[GetPlatformForInstallPlatform(IP)];
        ExpandEnvironmentVarCustom(FullIncludePaths[IP], Target.EnvironmentVariables);
      end
      else
        FullIncludePaths[IP] := '';
  end;
  {............................................................................}
  procedure AddToFullIncludePaths(const AIncludePath: String);
  var
    IP: TInstallPlatform;
  begin
    for IP := Low(TInstallPlatform) to High(TInstallPlatform) do
      if FullIncludePaths[IP] = '' then
        FullIncludePaths[IP] := AIncludePath
      else
        FullIncludePaths[IP] := FullIncludePaths[IP] + ';' + AIncludePath;
  end;
  {............................................................................}
  procedure AddIncludePathToLibrarySearchPath(Target: TJclBorRADToolInstallation;
    AIncludePath: String; PathCollection: TJclLibPathCollection; j: Integer);
  var
    BDSTarget: TJclBDSInstallation;
    IP: TInstallPlatform;
  begin
    AIncludePath := GetEnvPath(AIncludePath, Target);
    if (Target is TJclBDSInstallation) and (Target.IDEVersionNumber >= 5) then
    begin
      BDSTarget := TJclBDSInstallation(Target);
      PathCollection.AddLibrarySearchPath(AIncludePath, BDSTarget, bpWin32);
      if not Is32Bit[j] then
      begin
        if ((bpDelphi64 in Target.Personalities) and (Target.VersionNumber in Config.BDSWin64Ver)) or
           ((bpBCBuilder64 in Target.Personalities) and (Target.VersionNumber in Config.BDSCBuilder64Ver)) then
          PathCollection.AddLibrarySearchPath(AIncludePath, BDSTarget, bpWin64);
        for IP := FirstNonWinInstallPlatform to High(TInstallPlatform) do
          if Config.CanInstallIn(Target, IP) and (IP in PkgInstallPlatforms[j]) then
            PathCollection.AddLibrarySearchPath(AIncludePath, BDSTarget, GetPlatformForInstallPlatform(IP));
      end;
    end
    else
    begin
      Target.AddToLibrarySearchPath(AIncludePath, bpWin32);
      if not Is32Bit[j] then
      begin
        if ((bpDelphi64 in Target.Personalities) and (Target.VersionNumber in Config.BDSWin64Ver)) or
           ((bpBCBuilder64 in Target.Personalities) and (Target.VersionNumber in Config.BDSCBuilder64Ver)) then
          Target.AddToLibrarySearchPath(AIncludePath, bpWin64);
        for IP := FirstNonWinInstallPlatform to High(TInstallPlatform) do
          if Config.CanInstallIn(Target, IP) and (IP in PkgInstallPlatforms[j]) then
            Target.AddToLibrarySearchPath(AIncludePath, GetPlatformForInstallPlatform(IP));
      end;
    end;
  end;
  {............................................................................}
  procedure AddIncludePathToCppIncludePath(Target: TJclBDSInstallation;
    IncludePath: String; PathCollection: TJclLibPathCollection; j: Integer);
  begin
    IncludePath := GetEnvPath(IncludePath, Target);
    if Target.IDEVersionNumber >= 5 then
    begin
      if bpBCBuilder32 in Target.Personalities then
      begin
        PathCollection.AddCppIncludePath(IncludePath, Target, bpWin32);
        if Target.VersionNumber = 4 then
          Target.AddToCppSearchPath(IncludePath, bpWin32);
      end;
      if not Is32Bit[j] and (bpBCBuilder64 in Target.Personalities) then
        PathCollection.AddCppIncludePath(IncludePath, Target, bpWin64);
      if not Is32Bit[j] and (bpDelphi64x in Target.Personalities) then { we did not define bpBCBuilder64x yet }
        PathCollection.AddCppIncludePath(IncludePath, Target, bpWin64x);
    end
    else
    begin
      if bpBCBuilder32 in Target.Personalities then
      begin
        Target.AddToCppIncludePath(IncludePath, bpWin32);
        Target.AddToCppIncludePath_Clang32(IncludePath);
        if Target.VersionNumber = 4 then
          Target.AddToCppSearchPath(IncludePath, bpWin32);
      end;
      if not Is32Bit[j] and (bpBCBuilder64 in Target.Personalities) then
        Target.AddToCppIncludePath(IncludePath, bpWin64);
    end;
  end;
  {............................................................................}
  procedure AddDCUPathToLibrarySearchPath(Target: TJclBorRADToolInstallation;
    const Path: String; PathCollection: TJclLibPathCollection; j: Integer;
    AllPlatforms: Boolean);
  var
    BDSTarget: TJclBDSInstallation;
    IP: TInstallPlatform;
  begin
    if (Target is TJclBDSInstallation) and (Target.IDEVersionNumber >= 5) then
    begin
      BDSTarget := TJclBDSInstallation(Target);
      if FPathToSrcWin32 then
        PathCollection.AddLibrarySearchPath(GetEnvPath(Path, Target), BDSTarget, bpWin32)
      else
      begin
        PathCollection.AddLibraryBrowsingPath(GetEnvPath(Path, Target), BDSTarget, bpWin32);
        PathCollection.AddLibrarySearchPath(GetEnvPath(DCUPaths[ipWin32], Target), BDSTarget, bpWin32);
      end;
      if not Is32Bit[j] and AllPlatforms then
      begin
         if ((bpDelphi64 in Target.Personalities) and (Target.VersionNumber in Config.BDSWin64Ver)) or
            ((bpBCBuilder64 in Target.Personalities) and (Target.VersionNumber in Config.BDSCBuilder64Ver)) then
         begin
            PathCollection.AddLibraryBrowsingPath(GetEnvPath(Path, Target), BDSTarget, bpWin64);
            PathCollection.AddLibrarySearchPath(GetEnvPath(DCUPaths[ipWin64], Target), BDSTarget, bpWin64);
         end;
        for IP := FirstNonWinInstallPlatform to High(TInstallPlatform) do
          if Config.CanInstallIn(Target, IP) and (IP in PkgInstallPlatforms[j]) then
           begin
             PathCollection.AddLibraryBrowsingPath(GetEnvPath(Path, Target), BDSTarget, GetPlatformForInstallPlatform(IP));
             PathCollection.AddLibrarySearchPath(GetEnvPath(DCUPaths[IP], Target), BDSTarget, GetPlatformForInstallPlatform(IP));
           end;
      end;
    end
    else
    begin
      if FPathToSrcWin32 then
        Target.AddToLibrarySearchPath(GetEnvPath(Path, Target), bpWin32)
      else
      begin
        Target.AddToLibraryBrowsingPath(GetEnvPath(Path, Target), bpWin32);
        Target.AddToLibrarySearchPath(GetEnvPath(DCUPaths[ipWin32], Target), bpWin32);
      end;
      if not Is32Bit[j] and AllPlatforms then
      begin
         if ((bpDelphi64 in Target.Personalities) and (Target.VersionNumber in Config.BDSWin64Ver)) or
            ((bpBCBuilder64 in Target.Personalities) and (Target.VersionNumber in Config.BDSCBuilder64Ver)) then
         begin
           Target.AddToLibraryBrowsingPath(GetEnvPath(Path, Target), bpWin64);
           Target.AddToLibrarySearchPath(GetEnvPath(DCUPaths[ipWin64], Target), bpWin64);
         end;
        for IP := FirstNonWinInstallPlatform to High(TInstallPlatform) do
          if Config.CanInstallIn(Target, IP) and (IP in PkgInstallPlatforms[j]) then
          begin
            Target.AddToLibraryBrowsingPath(GetEnvPath(Path, Target), GetPlatformForInstallPlatform(IP));
            Target.AddToLibrarySearchPath(GetEnvPath(DCUPaths[IP], Target), GetPlatformForInstallPlatform(IP));
          end;
      end;
    end;
  end;
  {............................................................................}
  procedure AddToCPPPath(Target: TJclBDSInstallation;
    Path: String; PathCollection: TJclLibPathCollection; j: Integer;
    AllPlatforms: Boolean);
  begin
    if Target.IDEVersionNumber >= 5 then
    begin
      if (bpBCBuilder32 in Target.Personalities) and
        (Target.VersionNumber in Config.BDSCBuilderVer + Config.BDSDualVer) then
      begin
        if not IsTrial[j] then
          PathCollection.AddCppBrowsingPath(GetEnvPath(Path, Target), Target, bpWin32);
        if Target.VersionNumber = 4 then
          Target.AddToCppSearchPath(GetEnvPath(HppPaths[ipWin32], Target), bpWin32);
        PathCollection.AddCppIncludePath(GetEnvPath(HppPaths[ipWin32], Target), Target, bpWin32);
        if SameText(ExtractFileExt(PkgNameRun), SourceExtensionRSBCBPackage) then
        begin
          PathCollection.AddLibrarySearchPath(GetEnvPath(ObjPathWin32, Target), Target, bpWin32);
          PathCollection.AddCppLibraryPath(GetEnvPath(ObjPathWin32, Target), Target, bpWin32);
        end;
        if FPathToSrcWin32 then
          PathCollection.AddCppLibraryPath(GetEnvPath(Path, Target), Target, bpWin32)
        else
          PathCollection.AddCppLibraryPath(GetEnvPath(DCUPaths[ipWin32], Target), Target, bpWin32);
      end;
      if not Is32Bit[j] and AllPlatforms then
      begin
        if (bpBCBuilder64 in Target.Personalities) and
          (Target.VersionNumber in Config.BDSWin64Ver * (Config.BDSCBuilderVer + Config.BDSDualVer)) then
        begin
          if not IsTrial[j] then
            PathCollection.AddCppBrowsingPath(GetEnvPath(Path, Target), Target, bpWin64);
          PathCollection.AddCppIncludePath(GetEnvPath(HppPaths[ipWin64], Target), Target, bpWin64);
          PathCollection.AddCppLibraryPath(GetEnvPath(DCUPaths[ipWin64], Target), Target, bpWin64);
        end;
        if (bpDelphi64x in Target.Personalities) and { we did not define bpBCBuilder64x yet }
          (Target.VersionNumber in Config.BDSWin64xVer * (Config.BDSCBuilderVer + Config.BDSDualVer)) then
        begin
          if not IsTrial[j] then
            PathCollection.AddCppBrowsingPath(GetEnvPath(Path, Target), Target, bpWin64x);
          PathCollection.AddCppIncludePath(GetEnvPath(HppPaths[ipWin64x], Target), Target, bpWin64x);
          PathCollection.AddCppLibraryPath(GetEnvPath(DCUPaths[ipWin64x], Target), Target, bpWin64x);
        end;
      end;
    end
    else
    begin
      if (bpBCBuilder32 in Target.Personalities) and
        (Target.VersionNumber in Config.BDSCBuilderVer + Config.BDSDualVer) then
      begin
        if not IsTrial[j] then
          Target.AddToCppBrowsingPath(GetEnvPath(Path, Target), bpWin32);
        if Target.VersionNumber = 4 then
          Target.AddToCppSearchPath(GetEnvPath(HppPaths[ipWin32], Target), bpWin32);
        Target.AddToCppIncludePath(GetEnvPath(HppPaths[ipWin32], Target), bpWin32);
        Target.AddToCppIncludePath_Clang32(GetEnvPath(HppPaths[ipWin32], Target));
        if SameText(ExtractFileExt(PkgNameRun), SourceExtensionRSBCBPackage) then
        begin
          Target.AddToLibrarySearchPath(GetEnvPath(ObjPathWin32, Target), bpWin32);
          Target.AddToCppLibraryPath(GetEnvPath(ObjPathWin32, Target), bpWin32);
          Target.AddToCppLibraryPath_Clang32(GetEnvPath(ObjPathWin32, Target));
        end;
        if FPathToSrcWin32 then
        begin
          Target.AddToCppLibraryPath(GetEnvPath(Path, Target), bpWin32);
          Target.AddToCppLibraryPath_Clang32(GetEnvPath(Path, Target));
        end
        else
        begin
          Target.AddToCppLibraryPath(GetEnvPath(DCUPaths[ipWin32], Target), bpWin32);
          Target.AddToCppLibraryPath_Clang32(GetEnvPath(DCUPaths[ipWin32], Target));
        end;
      end;
      if not Is32Bit[j] and AllPlatforms then
      begin
        if (bpBCBuilder64 in Target.Personalities) and
          (Target.VersionNumber in Config.BDSWin64Ver * (Config.BDSCBuilderVer + Config.BDSDualVer)) then
        begin
          if not IsTrial[j] then
            Target.AddToCppBrowsingPath(GetEnvPath(Path, Target), bpWin64);
          Target.AddToCppIncludePath(GetEnvPath(HppPaths[ipWin64], Target), bpWin64);
          Target.AddToCppLibraryPath(GetEnvPath(DCUPaths[ipWin64], Target), bpWin64);
        end;
      end;
    end;
  end;
  {............................................................................}
  procedure InitDCUandHPPPaths(j: Integer);
  var
    IP: TInstallPlatform;
  begin
    HppPaths[ipWin32] := GetHPPPath(Path,           Target, Personality32,    IsTrial[j]);
    ObjPathWin32 := GetObjPath(HppPaths[ipWin32],   Target, Personality32);
    DCUPaths[ipWin32] := GetUnitOutputPath(Path,    Target, bpDelphi32,       IsTrial[j]);
    HppPaths[ipWin64] := GetHPPPath(Path,           Target, Personality64,    IsTrial[j]);
    DCUPaths[ipWin64] := GetUnitOutputPath(Path,    Target, Personality64,    IsTrial[j]);
    for IP := FirstNonWinInstallPlatform to High(TInstallPlatform) do
    begin
      HppPaths[IP] := GetHPPPath(       Path, Target, GetDelphiPersonalityForInstallPlatform(IP), IsTrial[j]);
      DCUPaths[IP] := GetUnitOutputPath(Path, Target, GetDelphiPersonalityForInstallPlatform(IP), IsTrial[j]);
    end;
  end;
  {............................................................................}
var
  IP: TInstallPlatform;
  OldPathsDeleted: Boolean;
begin
  ShowStatusMsg('Starting');
  AllOk := True;
  txtLog.Clear;
  RemoveCheckedUninstallers;
  if Config.UninstallUnchecked and (FUninstallers.Count > 0) and
    (Application.MessageBox(
      'Do you want to uninstall the components from unchecked IDEs?',
      'Confirm Uninstall',
      MB_YESNO or MB_ICONQUESTION) = IDYES) then
  begin
    Uninstall;
    txtLog.Lines.Add('');
    txtLog.Lines.Add('');
  end;
  Count := 0;
  for i := 0 to clstIDE.Items.Count - 1 do
    if clstIDE.Checked[i] then
      inc(Count);
  PathCollection := TJclLibPathCollection.Create;
  InitProgress(Count * FPackages.Count);
  try
    for i := 0 to clstIDE.Items.Count - 1 do
      if clstIDE.Checked[i] then
      begin
        Application.ProcessMessages; if Aborted then exit;
        Target := TInstallItem(clstIDE.Items.Objects[i]).Target;
        txtLog.Lines.Add('=== ' + Target.Name + ' ===');
        txtLog.Lines.Add('Preparing...');
        ShowStatusMsg('Adjusting for versions of third-party packages');
        FReplacements.Execute(Target, FPaths, FPackages, Config.SourcePath, Config.CBuilder,
        bpWin32
          {$IFDEF LOGPKGREPLACE}, ErrorLog{$ENDIF});
        if (Target.RadToolKind = brBorlandDevStudio) and
          (Target.VersionNumber in HelpBDSVer) then
          InstallHelp(Target.VersionNumber);
        Personality32 := TInstallItem(clstIDE.Items.Objects[i]).Personality;
        if Personality32 = bpDelphi32 then
          Personality64 := bpDelphi64
        else
          Personality64 := bpBCBuilder64;
        Dual := TInstallItem(clstIDE.Items.Objects[i]).Dual;
        Dual64 := TInstallItem(clstIDE.Items.Objects[i]).Dual64;
        PrevPath := '';
        SetFullIncludePaths;
        PrevIncludePath := '';
        UninstallDepPackages(Target);
        ShowStatusMsg('Removing old versions');
        OldPathsDeleted := False;
        for j := 0 to FPackages.Count - 1 do
        begin
          if DeletePathsToOldVersions(Target, FCheckUnits[j], FCheckIncs[j]) then
            OldPathsDeleted := True;
          if Config.CBuilder then
          begin
            DeleteAllCompilationResults(Target, Config.SourcePath + FPaths[j],
              Personality32, IsTrial[j]);
          end;
        end;
        if OldPathsDeleted then
          SetFullIncludePaths;
        Application.ProcessMessages; if Aborted then exit;
        try
          if Config.CBuilder then
          begin
            ShowStatusMsg('Hiding source files');
            for j := 0 to FRequirePaths.Count - 1 do
              HideSourceFiles(FRequirePaths[j], '');
          end;
          AddToLastLogLine(' Done.');
          for j := 0 to FPackages.Count - 1 do
          begin
            PackageExists := False;
            try
              if PathCollection.Count > 0 then
              begin
                txtLog.Lines.Add('Internal error: orphaned library paths!');
                raise Exception.Create('Internal error: orphaned library paths!');
              end;
              ShowStatusMsg('Updating library paths');
              Path := Config.SourcePath + FPaths[j];
              IncludePath := PathAddSeparator(Config.SourcePath + FPaths[j]) +
                'Include';
              if DirectoryExists(IncludePath) and (IncludePath <> PrevIncludePath) then
              begin
                AddToFullIncludePaths(IncludePath);
                AddIncludePathToLibrarySearchPath(Target, IncludePath, PathCollection, j);
                if (Target is TJclBDSInstallation) and
                  (Target.RadToolKind = brBorlandDevStudio) and
                  (Target.VersionNumber in Config.BDSCBuilderVer + Config.BDSDualVer) then

                  AddIncludePathToCppIncludePath(TJclBDSInstallation(Target),
                    IncludePath, PathCollection, j);
                PrevIncludePath := IncludePath;
              end;
              PkgNameRun := GetPkgFile(Path, FPackages[j], '', Target, Personality32, IsTrial[j]);
              case Config.Scheme of
                1:
                  PkgNameDsgn := PkgNameRun;
                2:
                  PkgNameDsgn := GetPkgFile(Path, FPackages[j], '_Dsgn',
                    Target, Personality32, IsTrial[j]);
                else
                  PkgNameDsgn := '?';
              end;
              Path := ExtractFilePath(PkgNameRun);
              InitDCUandHPPPaths(j);
              PackageExists := FileExists(PkgNameRun);
              if PackageExists or not IsOptional[j] then
              begin
                if FTitles[j] = '' then
                  PkgTitle := ExtractFileName(PkgNameDsgn)
                else
                  PkgTitle := FTitles[j];
                if IsRunTime[j] then
                  Verb := 'Compiling'
                else
                  Verb := 'Installing';
                if IsOptional[j] then
                  txtLog.Lines.Add(Verb + ' optional ' + PkgTitle +'...')
                else
                  txtLog.Lines.Add(Verb + ' ' + PkgTitle + '...');
                if not IsRunTime[j] then
                  UninstallPackage(Target, Path, FPackages[j]);
                if Path <> PrevPath then
                begin
                  AddDCUPathToLibrarySearchPath(Target, Path, PathCollection, j, True);
                  if (Target is TJclBDSInstallation) then
                    AddToCPPPath(TJclBDSInstallation(Target), Path, PathCollection, j, True);
                  if (bpBCBuilder32 in Target.Personalities) and
                    (Target.RadToolKind = brCppBuilder) then
                    Target.AddToLibrarySearchPath(GetEnvPath(ObjPathWin32, Target), bpWin32);
                  PrevPath := Path;
                end;
                if PathCollection.Count > 0 then
                begin
                  TJclBDSInstallation(Target).AddToAnyLibPath(PathCollection);
                  PathCollection.Clear;
                end;
                Ok := InstallPackage(PkgNameRun, PkgNameDsgn, FDescr[j],
                  FullIncludePaths[ipWin32], Target, Personality32, Dual, IsTrial[j], IsOptional[j], IsRuntime[j], NoCE[j]);
                Application.ProcessMessages; if Aborted then exit;
                if Ok and not Is32Bit[j] and not Config.CBuilder then
                begin
                  // Win64
                  PkgNameRun := GetPkgFile64(Config.SourcePath + FPaths[j], FPackages[j], Target, Personality64, IsTrial[j], False);
                  PkgNameDsgn := GetPkgFile64(Config.SourcePath + FPaths[j], FPackages[j], Target, Personality64, IsTrial[j], True);
                  if IsTrial[j] then
                  begin
                    AdjustPathToUnitsInPackage(PkgNameRun, Target, bpDelphi64);
                    if clBds64 in Target.CommandLineTools then
                      AdjustPathToUnitsInPackage(PkgNameDsgn, Target, bpDelphi64);
                  end;
                  try
                    if clBds64 in Target.CommandLineTools then
                      InstallPackage(PkgNameRun, PkgNameDsgn, FDescr[j],
                        FullIncludePaths[ipWin64], Target, Personality64, Dual, IsTrial[j], IsOptional[j], IsRuntime[j], NoCE[j])
                    else
                      CompileRuntime(PkgNameRun,
                        FDescr[j], FullIncludePaths[ipWin64], Target, Personality64, bpWin64,
                        Dual64, IsTrial[j], IsOptional[j], NoCE[j])
                  finally
                    if IsTrial[j] then
                    begin
                      AdjustPathToUnitsInPackageBack(PkgNameRun, Target, bpDelphi64);
                      if clBds64 in Target.CommandLineTools then
                        AdjustPathToUnitsInPackageBack(PkgNameDsgn, Target, bpDelphi64);
                    end;
                  end;
                  Application.ProcessMessages; if Aborted then exit;
                  for IP := FirstNonWinInstallPlatform to High(TInstallPlatform) do
                    if (IP in PkgInstallPlatforms[j]) and CanInstallInTarget(IP, Target) then
                    begin
                      // Win64x, OSX64, OSXArm64, Android32, Android64, Linux64, iOS64, iOSSim64
                      if IsTrial[j] then
                        AdjustPathToUnitsInPackage(
                          GetPkgFile64(Config.SourcePath + FPaths[j], FPackages[j], Target, GetDelphiPersonalityForInstallPlatform(IP), True, False),
                            Target, GetDelphiPersonalityForInstallPlatform(IP));
                      try
                        CompileRuntime(
                          GetPkgFile64(Config.SourcePath + FPaths[j], FPackages[j], Target, GetDelphiPersonalityForInstallPlatform(IP), IsTrial[j], False),
                          FDescr[j], FullIncludePaths[IP], Target, GetDelphiPersonalityForInstallPlatform(IP),
                          GetPlatformForInstallPlatform(IP), Dual64, IsTrial[j], IsOptional[j], NoCE[j])
                      finally
                        if IsTrial[j] then
                          AdjustPathToUnitsInPackageBack(
                            GetPkgFile64(Config.SourcePath + FPaths[j], FPackages[j], Target, GetDelphiPersonalityForInstallPlatform(IP), True, False),
                            Target, GetDelphiPersonalityForInstallPlatform(IP));
                      end;
                      Application.ProcessMessages; if Aborted then exit;
                    end;
                end;
              end
              else
                Ok := False;
              PathCollection.Clear;
            except
              Ok := False;
            end;
            if Ok then
              if IsRunTime[j] then
                AddToLastLogLine(' Compiled.')
              else
                AddToLastLogLine(' Installed.')
            else
            begin
              if IsOptional[j] or (NoCE[j] and (Target.VersionNumber = BDSCommunityEditionVer)) then
              begin
                if PackageExists then
                  if not IsOptional[j] or (NoCE[j] and (Target.VersionNumber = BDSCommunityEditionVer)) then
                    AddToLastLogLine(' Skipped for CE.')
                  else
                    AddToLastLogLine(' Skipped.')
              end
              else
              begin
                AddToLastLogLine(' FAILED.');
                AllOk := False;
              end;
            end;
            StepProgress;
          end;
        finally
          if Config.CBuilder then
          begin
            txtLog.Lines.Add('Finalizing...');
            ShowStatusMsg('Unhiding source files');
            for j := 0 to FPackages.Count - 1 do
              if not IsTrial[j] then
                RestoreSourceFiles(Config.SourcePath + FPaths[j]);
            for j := 0 to FRequirePaths.Count - 1 do
              RestoreSourceFiles(FRequirePaths[j]);
            AddToLastLogLine(' Done.');
          end;
        end;
      end;
  finally
    ShowStatusMsg('');
    if AllOk then
    begin
      txtLog.Lines.Add('Installation completed successfully.');
      if ErrorLog <> '' then
        txtLog.Lines.Add
          ('However, some errors happened while installing optional files. You can click "Error log" button to view a detailed information.');
    end
    else
    begin
      txtLog.Lines.Add
        ('Installation completed. Some packages were not installed. Click "Error log" button to view a detailed information.');
      if CEFailed then
      txtLog.Lines.Add
        ('Errors were detected when installing in RAD Studio Community Edition. Possible reason: the setup can install only core packages, other packages require manual installation. '+
        'See the installation instruction on the components'' downloading page.');
    end;
    if RemovedPaths <> '' then
      txtLog.Lines.Add
        ('The installer removed some paths from RAD Studio library, because they contained the same units. Click "Removed paths" button to view a detailed information.');
    // txtLog.Lines.Add('If you have a different version of these components installed before, please delete paths to that version from RAD Studio library paths manually.');
    DoneProgress(AllOK);
    btnExit.Caption := 'Finish';
    if ErrorLog <> '' then
      btnLog.Visible := True;
    if RemovedPaths <> '' then
    begin
      btnRemovedPaths.Visible := True;
      if not btnLog.Visible then
        btnRemovedPaths.Left := btnLog.Left;
    end;
    PathCollection.Free;
  end;
end;

procedure TfrmMain.InstallHelp(BDSVer: Integer);
var
  Reg: TRegistry;
  i:   Integer;
begin
  if (FHelpFiles = nil) or (FHelpFiles.Count = 0) then
    exit;
  ShowStatusMsg('Integrating help files');
  Reg := TRegistry.Create;
  try
    if Reg.OpenKey('Software\Embarcadero\BDS\' + IntToStr(BDSVer) +
      '.0\Help\HtmlHelp1Files', True) then
      for i := 0 to FHelpFiles.Count - 1 do
        Reg.WriteString(FHelpFiles.Names[i], FHelpFiles.ValueFromIndex[i]);
  finally
    Reg.Free;
  end;
end;

procedure TfrmMain.UnInstallHelp(BDSVer: Integer);
var
  Reg: TRegistry;
  i:   Integer;
begin
  if (FHelpFiles = nil) or (FHelpFiles.Count = 0) then
    exit;
  Reg := TRegistry.Create;
  try
    if Reg.OpenKey('Software\Embarcadero\BDS\' + IntToStr(BDSVer) +
      '.0\Help\HtmlHelp1Files', False) then
      for i := 0 to FHelpFiles.Count - 1 do
        Reg.DeleteValue(FHelpFiles.Names[i]);
  finally
    Reg.Free;
  end;
end;
{------------------------------------------------------------------------------}
procedure TfrmMain.Uninstall;
var
  i:      Integer;
  Target: TJclBorRADToolInstallation;
  HppPaths, DcuPaths: array [TInstallPlatform] of String;
  ObjPathWin32: String;
  {............................................................................}
  procedure GetHPPandOBJPaths(const DPath: String; AIsTrial: Boolean;
    ATarget: TJclBorRADToolInstallation);
  var
    IP: TInstallPlatform;
  begin
    HppPaths[ipWin32] := GetHPPPath(DPath,   ATarget, bpBCBuilder32, AIsTrial);
    ObjPathWin32 := GetObjPath(HppPaths[ipWin32], ATarget, bpBCBuilder32);
    DcuPaths[ipWin32] := GetUnitOutputPath(DPath, ATarget, bpDelphi32, AIsTrial);
    HppPaths[ipWin64] := GetHPPPath(DPath, ATarget, bpBCBuilder64, AIsTrial);
    DcuPaths[ipWin64] := GetUnitOutputPath(DPath, ATarget, bpDelphi64, AIsTrial);
    for IP := FirstNonWinInstallPlatform to High(TInstallPlatform) do
    begin
      HppPaths[IP] := GetHPPPath(       DPath, ATarget, GetDelphiPersonalityForInstallPlatform(IP), AIsTrial);
      DcuPaths[IP] := GetUnitOutputPath(DPath, ATarget, GetDelphiPersonalityForInstallPlatform(IP), AIsTrial);
    end;
  end;
  {............................................................................}
  function UninstallPackageFromAllPlatforms(DPkgNameRun, DPkgNameDsgn: String;
    ATarget: TJclBorRADToolInstallation; const APath, APackage: String; AIsTrial: Boolean): Boolean;
  var
    s: String;
    IP: TInstallPlatform;
    BDSP: TJclBDSPlatform;
  begin
    Result := True;
    if DPkgNameRun <> DPkgNameDsgn then
    begin
      ShowStatusMsg(Format('Uninstalling %s (%s)', [ExtractFileName(DPkgNameRun), GetPlatformName(bpWin32)]));
      ATarget.UninstallPackage(DPkgNameRun, GetBplPath(ATarget), GetDcpPath(ATarget), bpWin32, bpWin32);
    end;
    if FileExists(DPkgNameDsgn) then
    begin
      ShowStatusMsg(Format('Uninstalling %s (%s)', [ExtractFileName(DPkgNameDsgn), GetPlatformName(bpWin32)]));
      Result := ATarget.UninstallPackage(DPkgNameDsgn, GetBplPath(ATarget), GetDcpPath(ATarget), bpWin32, bpWin32);
    end;
    if (bpDelphi64 in ATarget.Personalities) and (ipWin64 in Config.InstallPlatforms) then
    begin
      s := GetPkgFile64(Config.SourcePath + APath, APackage, ATarget, bpDelphi64, AIsTrial, False);
      ShowStatusMsg(Format('Uninstalling %s (%s)', [ExtractFileName(s), GetPlatformName(bpWin64)]));
      ATarget.UninstallPackage(s, GetBpl64Path(ATarget), GetDcp64Path(ATarget), bpWin64, bpWin32);
      if (clBds64 in Target.CommandLineTools) and FileExists(DPkgNameDsgn) and
        (DPkgNameRun <> DPkgNameDsgn) then
      begin
        ShowStatusMsg(Format('Uninstalling %s (%s)', [ExtractFileName(DPkgNameDsgn), GetPlatformName(bpWin64)]));
        ATarget.UninstallPackage(DPkgNameDsgn, GetBpl64Path(ATarget), GetDcp64Path(ATarget), bpWin64, bpWin64);
      end;
    end;
    for IP := FirstNonWinInstallPlatform to High(TInstallPlatform) do
      if Config.CanInstallIn(ATarget, IP) then
      begin
        BDSP := GetPlatformForInstallPlatform(IP);
        s := GetPkgFile64(Config.SourcePath + APath, APackage, ATarget, GetDelphiPersonalityForInstallPlatform(IP), AIsTrial, False);
        ShowStatusMsg(Format('Uninstalling %s (%s)', [ExtractFileName(s), GetPlatformName(BDSP)]));
        ATarget.UninstallPackage(s, GetBplPathEx(ATarget, BDSP), GetDcpPathEx(ATarget, BDSP), BDSP, bpWin32);
      end;
  end;
  {............................................................................}
  procedure RemoveIncludePathFromLibrarySearchPath(Target: TJclBorRADToolInstallation;
    IncludePath: String; PathCollection: TJclLibPathCollection; j: Integer);
  var
    BDSTarget: TJclBDSInstallation;
    IP: TInstallPlatform;
  begin
    IncludePath := GetEnvPath(IncludePath, Target);
    if (Target is TJclBDSInstallation) and (Target.IDEVersionNumber >= 5) then
    begin
      BDSTarget := TJclBDSInstallation(Target);
      PathCollection.AddLibrarySearchPath(IncludePath, BDSTarget, bpWin32);
      if bpDelphi64 in Target.Personalities then
        PathCollection.AddLibrarySearchPath(IncludePath, BDSTarget, bpWin64);
      for IP := FirstNonWinInstallPlatform to High(TInstallPlatform) do
        if Config.CanInstallIn(Target, IP) and (IP in PkgInstallPlatforms[j]) then
          PathCollection.AddLibrarySearchPath(IncludePath, BDSTarget, GetPlatformForInstallPlatform(IP));
    end
    else
    begin
      Target.RemoveFromLibrarySearchPath(IncludePath, bpWin32);
      if bpDelphi64 in Target.Personalities then
        Target.RemoveFromLibrarySearchPath(IncludePath, bpWin64);
      for IP := FirstNonWinInstallPlatform to High(TInstallPlatform) do
        if Config.CanInstallIn(Target, IP) and (IP in PkgInstallPlatforms[j]) then
          Target.RemoveFromLibrarySearchPath(IncludePath, GetPlatformForInstallPlatform(IP));
    end;
  end;
  {............................................................................}
  procedure RemoveIncludePathFromFromCppIncludePath(Target: TJclBDSInstallation;
    IncludePath: String; PathCollection: TJclLibPathCollection; j: Integer);
  begin
    IncludePath := GetEnvPath(IncludePath, Target);
    if Target.IDEVersionNumber >= 5 then
    begin
      if bpBCBuilder32 in Target.Personalities then
      begin
        PathCollection.AddCppIncludePath(IncludePath, Target, bpWin32);
        Target.RemoveFromCppSearchPath(IncludePath, bpWin32);
      end;
      if bpBCBuilder64 in Target.Personalities then
        PathCollection.AddCppIncludePath(IncludePath, Target, bpWin64);
      if bpDelphi64x in Target.Personalities then { we did not define bpBCBuilder64x yet }
        PathCollection.AddCppIncludePath(IncludePath, Target, bpWin64x);
    end
    else
    begin
      if bpBCBuilder32 in Target.Personalities then
      begin
        Target.RemoveFromCppIncludePath(IncludePath, bpWin32);
        Target.RemoveFromCppIncludePath_Clang32(IncludePath);
        Target.RemoveFromCppSearchPath(IncludePath, bpWin32);
      end;
      if bpBCBuilder64 in Target.Personalities then
        Target.RemoveFromCppIncludePath(IncludePath, bpWin64);
    end;
  end;
  {............................................................................}
  procedure RemoveDCUPathFromLibrarySearchPath(Target: TJclBorRADToolInstallation;
    const DPath: String; PathCollection: TJclLibPathCollection; j: Integer;
    AllPlatforms: Boolean);
  var
    BDSTarget: TJclBDSInstallation;
    IP: TInstallPlatform;
    BDSP: TJclBDSPlatform;
  begin
    if (Target is TJclBDSInstallation) and (Target.IDEVersionNumber >= 5) then
    begin
      BDSTarget := TJclBDSInstallation(Target);
      PathCollection.AddLibrarySearchPath(GetEnvPath(DPath, Target), BDSTarget, bpWin32);
      PathCollection.AddLibraryBrowsingPath(GetEnvPath(DPath, Target), BDSTarget, bpWin32);
      PathCollection.AddLibrarySearchPath(GetEnvPath(ObjPathWin32, Target), BDSTarget, bpWin32);
      if DCUPaths[ipWin32] <> '' then
        PathCollection.AddLibrarySearchPath(GetEnvPath(DCUPaths[ipWin32], Target), BDSTarget, bpWin32);
      if AllPlatforms then
      begin
        if (bpDelphi64 in Target.Personalities) and (ipWin64 in Config.InstallPlatforms)  then
        begin
          PathCollection.AddLibraryBrowsingPath(GetEnvPath(DPath, Target), BDSTarget, bpWin64);
          PathCollection.AddLibrarySearchPath(GetEnvPath(DCUPaths[ipWin64], Target), BDSTarget, bpWin64);
        end;
        for IP := FirstNonWinInstallPlatform to High(TInstallPlatform) do
          if Config.CanInstallIn(Target, IP) and (IP in PkgInstallPlatforms[j]) then
          begin
            BDSP := GetPlatformForInstallPlatform(IP);
            PathCollection.AddLibraryBrowsingPath(GetEnvPath(DPath, Target), BDSTarget, BDSP);
            PathCollection.AddLibrarySearchPath(GetEnvPath(DCUPaths[IP], Target), BDSTarget, BDSP);
          end;
      end;
    end
    else
    begin
      Target.RemoveFromLibrarySearchPath(GetEnvPath(DPath, Target), bpWin32);
      Target.RemoveFromLibraryBrowsingPath(GetEnvPath(DPath, Target), bpWin32);
      Target.RemoveFromLibrarySearchPath(GetEnvPath(ObjPathWin32, Target), bpWin32);
      if DCUPaths[ipWin32] <> '' then
        Target.RemoveFromLibrarySearchPath(GetEnvPath(DCUPaths[ipWin32], Target), bpWin32);
      if AllPlatforms then
      begin
        if (bpDelphi64 in Target.Personalities) and (ipWin64 in Config.InstallPlatforms) then
        begin
          Target.RemoveFromLibraryBrowsingPath(GetEnvPath(DPath, Target), bpWin64);
          Target.RemoveFromLibrarySearchPath(GetEnvPath(DCUPaths[ipWin64], Target), bpWin64);
        end;
        for IP := FirstNonWinInstallPlatform to High(TInstallPlatform) do
          if Config.CanInstallIn(Target, IP) and (IP in PkgInstallPlatforms[j]) then
          begin
            BDSP := GetPlatformForInstallPlatform(IP);
            Target.RemoveFromLibraryBrowsingPath(GetEnvPath(DPath, Target), BDSP);
            Target.RemoveFromLibrarySearchPath(GetEnvPath(DCUPaths[IP], Target), BDSP);
          end;
      end;
    end;
  end;
  {............................................................................}
  procedure RemoveFromCPPPath(Target: TJclBDSInstallation;
    DPath: String; PathCollection: TJclLibPathCollection; j: Integer;
    AllPlatforms: Boolean);
  begin
    DPath := GetEnvPath(DPath, Target);
    if Target.IDEVersionNumber >= 5 then
    begin
      if bpBCBuilder32 in Target.Personalities then
      begin
        if not IsTrial[j] then
          PathCollection.AddCppBrowsingPath(DPath, Target, bpWin32);
        PathCollection.AddCppLibraryPath(DPath, Target, bpWin32);
        PathCollection.AddCppLibraryPath(GetEnvPath(ObjPathWin32, Target), Target, bpWin32);
        if DCUPaths[ipWin32] <> '' then
          PathCollection.AddCppLibraryPath(GetEnvPath(DCUPaths[ipWin32], Target), Target, bpWin32);
        PathCollection.AddCppIncludePath(GetEnvPath(HPPPaths[ipWin32], Target), Target, bpWin32);
      end;
      if AllPlatforms then
      begin
        if (bpBCBuilder64 in Target.Personalities) and (ipWin64 in Config.InstallPlatforms) then
        begin
          if not IsTrial[j] then
            PathCollection.AddCppBrowsingPath(DPath, Target, bpWin64);
          PathCollection.AddCppLibraryPath(GetEnvPath(DCUPaths[ipWin64], Target), Target, bpWin64);
          PathCollection.AddCppIncludePath(GetEnvPath(HPPPaths[ipWin64], Target), Target, bpWin64);
        end;
        if (bpDelphi64x in Target.Personalities) and (ipWin64 in Config.InstallPlatforms) then { we did not define bpBCBuilder64x yet }
        begin
          if not IsTrial[j] then
            PathCollection.AddCppBrowsingPath(DPath, Target, bpWin64x);
          PathCollection.AddCppLibraryPath(GetEnvPath(DCUPaths[ipWin64x], Target), Target, bpWin64x);
          PathCollection.AddCppIncludePath(GetEnvPath(HPPPaths[ipWin64x], Target), Target, bpWin64x);
        end;
      end;
    end
    else
    begin
      if bpBCBuilder32 in Target.Personalities then
      begin
        if not IsTrial[j] then
          Target.RemoveFromCppBrowsingPath(DPath, bpWin32);
        Target.RemoveFromCppLibraryPath(DPath, bpWin32);
        Target.RemoveFromCppLibraryPath(GetEnvPath(ObjPathWin32, Target), bpWin32);
        if DCUPaths[ipWin32] <> '' then
          Target.RemoveFromCppLibraryPath(GetEnvPath(DCUPaths[ipWin32], Target), bpWin32);
        Target.RemoveFromCppIncludePath(GetEnvPath(HppPaths[ipWin32], Target), bpWin32);
        Target.RemoveFromCppLibraryPath_Clang32(DPath);
        Target.RemoveFromCppLibraryPath_Clang32(GetEnvPath(ObjPathWin32, Target));
        if DCUPaths[ipWin32] <> '' then
          Target.RemoveFromCppLibraryPath_Clang32(GetEnvPath(DCUPaths[ipWin32], Target));
        Target.RemoveFromCppIncludePath_Clang32(GetEnvPath(HppPaths[ipWin32], Target));
      end;
      if AllPlatforms then
      begin
        if (bpBCBuilder64 in Target.Personalities) and (ipWin64 in Config.InstallPlatforms)  then
        begin
          if not IsTrial[j] then
            Target.RemoveFromCppBrowsingPath(DPath, bpWin64);
          Target.RemoveFromCppLibraryPath(DPath, bpWin64);
          Target.RemoveFromCppLibraryPath(GetEnvPath(DCUPaths[ipWin64], Target), bpWin64);
          Target.RemoveFromCppIncludePath(GetEnvPath(HppPaths[ipWin64], Target), bpWin64);
        end;
      end;
    end;
  end;
  {............................................................................}
  function UninstallPackages(Packages: TStringList;
    Target: TJclBorRADToolInstallation): Boolean;
  var
    j:  Integer;
    Ok: Boolean;
    DPkgNameRun, DPkgNameDsgn, CBPkgNameRun, CBPkgNameDsgn, DPath, CBPath,
      DPrevPath, CBPrevPath, PrevIncludePath, IncludePath: String;
    PathCollection: TJclLibPathCollection;
  begin
    ShowStatusMsg('Starting');
    Result := True;
    DPrevPath := '';
    CBPrevPath := '';
    PrevIncludePath := '';
    PathCollection := TJclLibPathCollection.Create;
    for j := Packages.Count - 1 downto 0 do
    begin
      Ok := True;
      DPath := '';
      CBPath := '';
      try
        IncludePath := PathAddSeparator(Config.SourcePath + FPaths[j]) +
          'Include';
        if (IncludePath <> PrevIncludePath) and DirectoryExists(IncludePath)
        then
        begin
          ShowStatusMsg('Cleaning include paths');
          RemoveIncludePathFromLibrarySearchPath(Target, IncludePath, PathCollection, j);
          if Target is TJclBDSInstallation  then
            RemoveIncludePathFromFromCppIncludePath(TJclBDSInstallation(Target), IncludePath, PathCollection, j);
          PrevIncludePath := IncludePath;
        end;
        if bpDelphi32 in Target.Personalities then
        begin
          DPath := Config.SourcePath + FPaths[j];
          DPkgNameRun := GetPkgFile(DPath, Packages[j], '', Target, bpDelphi32,
            IsTrial[j]);
          case Config.Scheme of
            1:
              DPkgNameDsgn := DPkgNameRun;
            2:
              DPkgNameDsgn := GetPkgFile(DPath, Packages[j], '_Dsgn', Target, bpDelphi32,
                IsTrial[j]);
          end;
          DPath := ExtractFilePath(DPkgNameRun);
          GetHPPandOBJPaths(DPath, IsTrial[j], Target);
          txtLog.Lines.Add('Uninstalling ' + ExtractFileName(DPkgNameDsgn) +
            ' from ' + Target.Name + '...');
          Ok := UninstallPackageFromAllPlatforms(DPkgNameRun, DPkgNameDsgn,
            Target, FPaths[j], Packages[j], IsTrial[j]);
          if DPath <> DPrevPath then
          begin
            ShowStatusMsg('Cleaning library paths');
            RemoveDCUPathFromLibrarySearchPath(Target, DPath, PathCollection, j, True);
            if (bpBCBuilder32 in Target.Personalities) and (Target.RadToolKind = brCppBuilder) then
              Target.RemoveFromLibrarySearchPath(GetEnvPath(ObjPathWin32, Target), bpWin32);
            if Target is TJclBDSInstallation then
              RemoveFromCPPPath(TJclBDSInstallation(Target), DPath, PathCollection, j, True);
            DPrevPath := DPath;
          end;
          if Ok then
            txtLog.Lines[txtLog.Lines.Count - 1] :=
              txtLog.Lines[txtLog.Lines.Count - 1] + ' Done.'
          else
            txtLog.Lines[txtLog.Lines.Count - 1] :=
              txtLog.Lines[txtLog.Lines.Count - 1] + ' Not installed.';
        end;
        if bpBCBuilder32 in Target.Personalities then
        begin
          CBPath := Config.SourcePath + FPaths[j];
          CBPkgNameRun := GetPkgFile(CBPath, Packages[j], '', Target, bpBCBuilder32,
            IsTrial[j]);
          case Config.Scheme of
            1:
              CBPkgNameDsgn := CBPkgNameRun;
            2:
              CBPkgNameDsgn := GetPkgFile(CBPath, Packages[j], '_Dsgn', Target, bpBCBuilder32,
                IsTrial[j]);
          end;
          if CBPkgNameRun <> DPkgNameRun then
          begin
            CBPath := ExtractFilePath(CBPkgNameRun);
            HppPaths[ipWin32] := GetHPPPath(CBPath, Target, bpBCBuilder32, IsTrial[j]);
            ObjPathWin32 := GetObjPath(HppPaths[ipWin32], Target, bpBCBuilder32);
            DCUPaths[ipWin32] := '';
            txtLog.Lines.Add('Uninstalling ' + ExtractFileName(CBPkgNameDsgn) +
              ' from ' + Target.Name + '...');
            if CBPkgNameRun <> CBPkgNameDsgn then
            begin
              ShowStatusMsg(Format('Uninstalling %s (%s)', [ExtractFileName(CBPkgNameRun), GetPlatformName(bpWin32)]));
              Target.UninstallPackage(CBPkgNameRun, GetBplPath(Target), GetDcpPath(Target), bpWin32, bpWin32);
            end;
            ShowStatusMsg(Format('Uninstalling %s (%s)', [ExtractFileName(CBPkgNameDsgn), GetPlatformName(bpWin32)]));
            Ok := Target.UninstallPackage(MakeUninstallName(CBPkgNameDsgn),
              GetBplPath(Target), GetDcpPath(Target), bpWin32, bpWin32);
            if (CBPath <> CBPrevPath) then
            begin
              ShowStatusMsg('Cleaning library paths');
              RemoveDCUPathFromLibrarySearchPath(Target, CBPath, PathCollection, j, False);
              if Target is TJclBDSInstallation then
                RemoveFromCPPPath(TJclBDSInstallation(Target), CBPath, PathCollection, j, False);
              CBPrevPath := CBPath;
            end;
            if Ok then
              txtLog.Lines[txtLog.Lines.Count - 1] :=
                txtLog.Lines[txtLog.Lines.Count - 1] + ' Done.'
            else
              txtLog.Lines[txtLog.Lines.Count - 1] :=
                txtLog.Lines[txtLog.Lines.Count - 1] + ' Not installed.';
          end;
        end;
      except
        Ok := False;
      end;
      Result := Result and Ok;
      StepProgress;
    end;
    if PathCollection.Count > 0 then
    begin
      ShowStatusMsg('Finalizing paths cleaning');
      TJclBDSInstallation(Target).RemoveFromAnyLibPath(PathCollection);
    end;
    ShowStatusMsg('');
    PathCollection.Free;
  end;

begin
  txtLog.Clear;
  InitProgress(FUninstallers.Count * (FPackages.Count + FDepPackages.Count));
  if (Config.SourcePathVar <> '') and
    (GetGlobalEnvironmentVariable(Config.SourcePathVar) <> '') then
    Config.SourcePathEnv := '$(' + Config.SourcePathVar + ')\';
  for i := 0 to FUninstallers.Count - 1 do
  begin
    Target := TJclBorRADToolInstallation(FUninstallers.Items[i]);
    if (Target.RadToolKind = brBorlandDevStudio) and
      (Target.VersionNumber in HelpBDSVer) then
      UnInstallHelp(Target.VersionNumber);
    UninstallPackages(FDepPackages, Target);
    UninstallPackages(FPackages, Target);
  end;
  if Config.SourcePathVar <> '' then
    SetGlobalEnvironmentVariable(Config.SourcePathVar, '');
  txtLog.Lines.Add('Uninstallation completed.');
  DoneProgress(True);
  btnExit.Caption := 'Finish';
end;

function TfrmMain.IsIDEChosen: Boolean;
var
  i: Integer;
begin
  Result := True;
  for i := 0 to clstIDE.Items.Count - 1 do
    if clstIDE.Checked[i] then
      exit;
  Result := False;
end;

function TfrmMain.LoadConfig(FileName: String; var ErrorMsg: String): Boolean;
var
  ini:   TIniFile;
  i:     Integer;
  s, s2: String;
  CurPath: String;
const
  TargetsSection    = 'Targets';
  UISection         = 'UI';
  ComponentsSection = 'Components';
  RequiresSection   = 'Requires';
  InstallSection    = 'Install';
  HelpSection       = 'Help';
  ReplaceSection    = 'Replace';

  procedure AddRange(var s: TByteSet; MinV, MaxV: Byte);
  var
    i: Byte;
  begin
    for i := MinV to MaxV do
      Include(s, i);
  end;

  function GetEnvVarFromRegistry(const VarName: String): String;
  var
    r: TRegistry;
  begin
    r := TRegistry.Create;
    try
      r.RootKey := HKEY_LOCAL_MACHINE;
      r.Access := KEY_QUERY_VALUE;
      r.OpenKey(
        'SYSTEM\CurrentControlSet\Control\Session Manager\Environment\', False);
      Result := r.ReadString(VarName);
    except
      Result := '';
    end;
    r.Free;
  end;

var
  MinBDS, MaxBDS: Byte;
  FullUninstall:  Boolean;

begin
  Result := False;
  if Pos(':', FileName) = 0 then
    FileName := ExtractFilePath(Application.ExeName) + FileName;
  if not FileExists(FileName) then
  begin
    ErrorMsg := 'The file "' + FileName + '" is not found';
    exit;
  end;

  ini := TIniFile.Create(FileName);
  try
    s := ExtractFilePath(FileName) + ini.ReadString(UISection, 'Image', '');
    if FileExists(s) then
      Image1.Picture.Bitmap.LoadFromFile(s)
    else
    begin
      Image1.Visible := False;
      Label1.Left := Image1.Left;
    end;
    Caption := ini.ReadString(UISection, 'Title', 'Install');
    Config.QuickMode := False;
    if ParamCount >= 2 then
    begin
      s := ParamStr(2);
      Config.QuickMode := True;
    end
    else
      s := ini.ReadString(InstallSection, 'Mode', 'choose');

    Config.OptionsKey := ini.ReadString(InstallSection, 'OptionsKey', '');
    FIgnoreNonWinErrors := ini.ReadInteger(InstallSection, 'IgnoreNonWinErrors', 1) <> 0;
    FIgnoreOptionalErrors := ini.ReadInteger(InstallSection, 'IgnoreOptionalErrors', 1) <> 0;
    Config.NoCompile := ini.ReadBool(InstallSection, 'NoCompile', False);
    if Config.NoCompile then
      Caption := Caption + ' - * NO-COMPILE MODE *';
    Config.CheckAll := False;
    FullUninstall := False;
    if s = 'install' then
      Config.InstallMode := imInstall
    else if s = 'installall' then
    begin
      Config.InstallMode := imInstall;
      Config.CheckAll := True;
    end
    else if s = 'uninstall' then
      Config.InstallMode := imUninstall
    else if s = 'uninstallfull' then
    begin
      Config.InstallMode := imUninstall;
      FullUninstall := True;
    end
    else
      Config.InstallMode := imChoose;
    Config.UninstallUnchecked := Config.InstallMode <> imInstall;
    Config.BCBVer := [];
    Config.DelphiVer := [];
    Config.BDSVer := [];
    Config.BDSDualVer := [];
    Config.BDSWin64Ver := [];
    Config.BDSWin64xVer := [];
    Config.BDSCBuilder64Ver := [];
    Config.BDSOSX64Ver := [];
    Config.BDSOSXArm64Ver := [];
    Config.BDSAndroid32Ver := [];
    Config.BDSAndroid64Ver := [];
    Config.BDSiOS64Ver := [];
    Config.BDSiOSSimArm64Ver := [];
    Config.BDSLinux64Ver := [];
    Config.CBuilder := ini.ReadInteger(TargetsSection, 'CBuilder', 0) <> 0;
    Config.InstallPlatforms := [ipWin32];
    if ini.ReadInteger(TargetsSection, '64bits', 0) <> 0 then
      Include(Config.InstallPlatforms, ipWin64);
    if ini.ReadInteger(TargetsSection, '64bitsX', 0) <> 0 then
      Include(Config.InstallPlatforms, ipWin64x);
    if ini.ReadInteger(TargetsSection, 'OSX64', 0) <> 0 then
      Include(Config.InstallPlatforms, ipOSX64);
    if ini.ReadInteger(TargetsSection, 'OSXArm64', 0) <> 0 then
      Include(Config.InstallPlatforms, ipOSXArm64);
    if ini.ReadInteger(TargetsSection, 'Android32', 0) <> 0 then
      Include(Config.InstallPlatforms, ipAndroid32);
    if ini.ReadInteger(TargetsSection, 'Android64', 0) <> 0 then
      Include(Config.InstallPlatforms, ipAndroid64);
    if ini.ReadInteger(TargetsSection, 'Linux64', 0) <> 0 then
      Include(Config.InstallPlatforms, ipLinux64);
    if ini.ReadInteger(TargetsSection, 'iOSDevice64', 0) <> 0 then
      Include(Config.InstallPlatforms, ipIOS64);
    if ini.ReadInteger(TargetsSection, 'iOSSimARM64', 0) <> 0 then
      Include(Config.InstallPlatforms, ipIOSSimArm64);
    MaxBDS := Byte(ini.ReadInteger(TargetsSection, 'MaxRADStudio', 16));
    Config.Scheme := ini.ReadInteger(TargetsSection, 'Scheme', 1);
    if not (Config.Scheme in [1, 2]) then
    begin
      ErrorMsg := 'Unknown package naming scheme';
      exit;
    end;

    if Config.CBuilder or FullUninstall then
    begin
      if ini.ReadInteger(TargetsSection, 'BCB6', 0) <> 0 then
        Include(Config.BCBVer, 6);
      MinBDS := Byte(ini.ReadInteger(TargetsSection, 'MinBCBRADStudio', 4));
      AddRange(Config.BDSVer, MinBDS, MaxBDS);
    end;
    if not Config.CBuilder or FullUninstall then
    begin
      if ini.ReadInteger(TargetsSection, 'D5', 0) <> 0 then
        Include(Config.DelphiVer, 5);
      if ini.ReadInteger(TargetsSection, 'D6', 0) <> 0 then
        Include(Config.DelphiVer, 6);
      if ini.ReadInteger(TargetsSection, 'D7', 0) <> 0 then
        Include(Config.DelphiVer, 7);
      MinBDS := Byte(ini.ReadInteger(TargetsSection, 'MinRADStudio', 3));
      AddRange(Config.BDSVer, MinBDS, MaxBDS);
      MinBDS := Byte(ini.ReadInteger(TargetsSection, 'MinDualRADStudio', 3));
      AddRange(Config.BDSDualVer, MinBDS, MaxBDS);
      if ipWin64 in Config.InstallPlatforms then
      begin
        Config.BDSWin64Ver := Config.BDSVer * AllBDSWin64Ver;
        Config.BDS64DualVer := Config.BDSDualVer * AllBDSCBuilderWin64Ver;
      end;
      if ipWin64x in Config.InstallPlatforms then
        Config.BDSWin64xVer := Config.BDSVer * AllBDSWin64xVer;
      if ipOSX64 in Config.InstallPlatforms then
        Config.BDSOSX64Ver := Config.BDSVer * AllBDSOSX64Ver;
      if ipOSXArm64 in Config.InstallPlatforms then
        Config.BDSOSXArm64Ver := Config.BDSVer * AllBDSOSXArm64Ver;
      if ipAndroid32 in Config.InstallPlatforms then
        Config.BDSAndroid32Ver := Config.BDSVer * AllBDSAndroid32Ver;
      if ipAndroid64 in Config.InstallPlatforms then
        Config.BDSAndroid64Ver := Config.BDSVer * AllBDSAndroid64Ver;
      if ipLinux64 in Config.InstallPlatforms then
        Config.BDSLinux64Ver := Config.BDSVer * AllBDSLinux64Ver;
      if ipIOS64 in Config.InstallPlatforms then
        Config.BDSiOS64Ver := Config.BDSVer * AllBDSIOS64Ver;
      if ipIOSSimArm64 in Config.InstallPlatforms then
        Config.BDSiOSSimArm64Ver := Config.BDSVer * AllBDSIOSSimArm64Ver;
    end;
    if Config.CBuilder then
    begin
      Config.IDE := 'C++Builder';
      Config.BDSCBuilderVer := Config.BDSVer;
    end
    else
    begin
      Config.IDE := 'Delphi and C++Builder';
      Config.BDSCBuilderVer := Config.BDSDualVer;
    end;

    if (ipWin64 in Config.InstallPlatforms) and (Config.CBuilder or FullUninstall) and (Config.Scheme=2) then
      Config.BDSCBuilder64Ver := Config.BDSCBuilderVer * AllBDSCompleteCBuilder64Ver;

    Config.SourcePath := ini.ReadString(InstallSection, 'Files', '');
    if Config.SourcePath <> '' then
    begin
      if Config.SourcePath[1] = '%' then
      begin
        Delete(Config.SourcePath, 1, 1);
        Config.SourcePathEnv := Config.SourcePath;
        Config.SourcePath := GetEnvVarFromRegistry(Config.SourcePathEnv);
        if Config.SourcePath = '' then
        begin
          ErrorMsg := 'The environment variable ' + Config.SourcePathEnv +
            ' is not defined';
          exit;
        end;
        Config.SourcePathEnv := '$(' + Config.SourcePathEnv + ')\';
      end
      else
      begin
        if Pos(':', Config.SourcePath) = 0 then
        begin
          CurPath := GetCurrentDir;
          SetCurrentDir(ExtractFilePath(Application.ExeName));
          Config.SourcePath := ExpandFileName(Config.SourcePath);
          SetCurrentDir(CurPath);
        end;
        Config.SourcePathEnv := '';
      end;
    end;
    Config.SourcePath := PathAddSeparator(Config.SourcePath);
    Config.SourcePathVar := ini.ReadString(InstallSection, 'Variable', '');

    Config.Product := ini.ReadString('UI', 'Product', '');
    FPackages := TStringList.Create;
    FCheckUnits := TStringList.Create;
    FCheckIncs := TStringList.Create;
    FDepPackages := TStringList.Create;
    FPaths := TStringList.Create;
    FDescr := TStringList.Create;
    FTitles := TStringList.Create;
    i := 1;
    repeat
      s := ini.ReadString(ComponentsSection, 'Package' + IntToStr(i), '');
      if s <> '' then
      begin
        FPackages.Add(s);
        FPaths.Add(ini.ReadString(ComponentsSection, 'Path' + IntToStr(i), ''));
        FDescr.Add(ini.ReadString(ComponentsSection,
          'Descr' + IntToStr(i), ''));
        FTitles.Add(ini.ReadString(ComponentsSection,
          'Title' + IntToStr(i), ''));
        FCheckUnits.Add(ini.ReadString(ComponentsSection,
          'CheckUnit' + IntToStr(i), ''));
        FCheckIncs.Add(ini.ReadString(ComponentsSection,
          'CheckInc' + IntToStr(i), ''));
      end;
      inc(i);
    until s = '';

    FRequirePaths := TStringList.Create;
    i := 1;
    repeat
      s := ini.ReadString(RequiresSection, 'Path' + IntToStr(i), '');
      if s <> '' then
      begin
        FRequirePaths.Add(Config.SourcePath + s);
      end;
      inc(i);
    until s = '';

    SetLength(IsTrial, FPackages.Count);
    SetLength(IsOptional, FPackages.Count);
    SetLength(Is32Bit, FPackages.Count);
    SetLength(IsRunTime,FPackages.Count);
    SetLength(PkgInstallPlatforms,FPackages.Count);
    SetLength(NoCE, FPackages.Count);
    HasTrial := False;
    for i := 0 to FPackages.Count - 1 do
    begin
      IsTrial[i] := ini.ReadInteger(ComponentsSection,
        'Trial' + IntToStr(i + 1), 0) <> 0;
      if IsTrial[i] then
        HasTrial := True;
      IsOptional[i] := ini.ReadInteger(ComponentsSection,
        'Optional' + IntToStr(i + 1), 0) <> 0;
      Is32bit[i] := ini.ReadInteger(ComponentsSection,
        '32Bit' + IntToStr(i + 1), 0) <> 0;
      IsRuntime[i] := ini.ReadInteger(ComponentsSection,
        'Runtime' + IntToStr(i + 1), 0) <> 0;
      NoCE[i] := ini.ReadInteger(ComponentsSection,
        'NoCE' + IntToStr(i + 1), 0) <> 0;
      PkgInstallPlatforms[i] := [ipWin32];
      if not Is32bit[i] then
      begin
        Include(PkgInstallPlatforms[i], ipWin64);
        if ipWin64x in Config.InstallPlatforms then
          Include(PkgInstallPlatforms[i], ipWin64x);
        if ini.ReadInteger(ComponentsSection, 'OSX64' + IntToStr(i + 1), 0) <> 0 then
          Include(PkgInstallPlatforms[i], ipOSX64);
        if ini.ReadInteger(ComponentsSection, 'OSXARM64' + IntToStr(i + 1), 0) <> 0 then
          Include(PkgInstallPlatforms[i], ipOSXArm64);
        if ini.ReadInteger(ComponentsSection, 'Android32' + IntToStr(i + 1), 0) <> 0 then
          Include(PkgInstallPlatforms[i], ipAndroid32);
        if ini.ReadInteger(ComponentsSection, 'Android64' + IntToStr(i + 1), 0) <> 0 then
          Include(PkgInstallPlatforms[i], ipAndroid64);
        if ini.ReadInteger(ComponentsSection, 'Linux64' + IntToStr(i + 1), 0) <> 0 then
          Include(PkgInstallPlatforms[i], ipLinux64);
        if ini.ReadInteger(ComponentsSection, 'iOSDevice64' + IntToStr(i + 1), 0) <> 0 then
          Include(PkgInstallPlatforms[i], ipIOS64);
        if ini.ReadInteger(ComponentsSection, 'iOSSimARM64' + IntToStr(i + 1), 0) <> 0 then
          Include(PkgInstallPlatforms[i], ipIOSSimArm64);
      end;
    end;
    i := 1;
    repeat
      s := ini.ReadString(ComponentsSection, 'DepPackage' + IntToStr(i), '');
      if s <> '' then
      begin
        FDepPackages.Add(s);
      end;
      inc(i);
    until s = '';
    if FPackages.Count = 0 then
    begin
      ErrorMsg := 'No packages to install';
      exit;
    end;

    FHelpFiles := TStringList.Create;
    i := 1;
    repeat
      s := ini.ReadString(HelpSection, 'HelpID' + IntToStr(i), '');
      if s <> '' then
      begin
        s2 := ini.ReadString(HelpSection, 'Help' + IntToStr(i), '');
        if Pos(':', s2) = 0 then
          s2 := Config.SourcePath + s2;
        FHelpFiles.Add(s + '=' + s2);
      end;
      inc(i);
    until s = '';

    i := 1;
    repeat
      s := AnsiLowerCase(ini.ReadString(ReplaceSection + IntToStr(i), 'Prefix', ''));
      if s <> '' then
        with FReplacements.Add as TReplaceItem do
        begin
          Prefix := s;
          Postfix := AnsiLowerCase(ini.ReadString(ReplaceSection + IntToStr(i), 'Postfix', ''));
          Length := ini.ReadInteger(ReplaceSection + IntToStr(i), 'Length', 0);
          Package := ini.ReadInteger(ReplaceSection + IntToStr(i), 'Package', -1);
          ID := ini.ReadString(ReplaceSection + IntToStr(i), 'ID', '');
          Def := ini.ReadString(ReplaceSection + IntToStr(i), 'Default', '');
          inc(i);
        end;
    until s = '';

    Result := True;
  finally
    ini.Free;
  end;
end;

procedure TfrmMain.btnLogClick(Sender: TObject);
begin
  ShowLog(ErrorLog, 'Error Log');
end;

procedure TfrmMain.btnRemovedPathsClick(Sender: TObject);
begin
  ShowLog(RemovedPaths, 'Removed Paths');
end;

procedure TfrmMain.btnNextClick(Sender: TObject);
begin
  if PageControl1.ActivePage = tabChoose then
  begin
    if rbInstall.Checked then
    begin
      Config.InstallMode := imInstall;
      btnOptions.Visible := not HasTrial and not Config.CBuilder;
    end
    else
      Config.InstallMode := imUninstall;
    UpdateCaptions;
    InitPages;
  end
  else if PageControl1.ActivePage = tabIDE then
  begin
    if not CheckDelphiRunning then
      exit;
    btnOptions.Visible := False;
    Label1.Caption := Format('Installing %s in %s IDE',
      [Config.Product, Config.IDE]);
    Label1.Width := Label1.Parent.Width - Label1.Left - Image1.Left;
    btnNext.Visible := False;
    //btnExit.Visible := False;
    btnAbout.Visible := False;
    PageControl1.ActivePage := tabProgress;
    MoveControlsToActivePage;
    Screen.Cursor := crHourGlass;
    Installing := True;
    try
      Install;
    finally
      Installing := False;
      Screen.Cursor := crDefault;
      btnExit.Visible := True;
      if Aborted then
      begin
        ProgressBar1.Visible := False;
        lblStatus.Visible := False;
        txtLog.Lines.Add('*** Aborted by user ***');
        btnExit.Caption := 'E&xit';
        btnExit.Enabled := True;
      end
      else
        SaveOptions;
    end;
  end
  else if PageControl1.ActivePage = tabUninstall then
  begin
    if not CheckDelphiRunning then
    begin
      btnNext.Enabled := True;
      exit;
    end;
    btnOptions.Visible := False;
    Label1.Caption :=
      Format('Uninstalling %s from Delphi and C++Builder IDE', [Config.Product]);
    Label1.Width := Label1.Parent.Width - Label1.Left - Image1.Left;
    btnNext.Visible := False;
    btnExit.Visible := False;
    btnAbout.Visible := False;
    PageControl1.ActivePage := tabProgress;
    MoveControlsToActivePage;
    Screen.Cursor := crHourGlass;
    Installing := True;
    try
      Uninstall;
    finally
      Installing := False;
      Screen.Cursor := crDefault;
      btnExit.Visible := True;
    end;
    if Config.QuickMode then
      Close;
  end;
end;

procedure TfrmMain.btnOptionsClick(Sender: TObject);
var
  frm: TfrmOptions;
begin
  frm := TfrmOptions.Create(Application);
  try
    frm.rgPAS.Checked := FPathToSrcWin32;
    frm.rgDCU.Checked := not FPathToSrcWin32;
    frm.cbIgnoreNonWinErrors.Checked := FIgnoreNonWinErrors;
    frm.cbIgnoreOptionalErrors.Checked := FIgnoreOptionalErrors;
    if frm.ShowModal <> mrOk then
      exit;
    FPathToSrcWin32 := frm.rgPAS.Checked;
    FIgnoreNonWinErrors := frm.cbIgnoreNonWinErrors.Checked;
    FIgnoreOptionalErrors  := frm.cbIgnoreOptionalErrors.Checked;
  finally
    frm.Free;
  end;
end;

procedure TfrmMain.CheckAll(Checked: Boolean);
var
  i: Integer;
begin
  for i := 0 to clstIDE.Items.Count - 1 do
    clstIDE.Checked[i] := Checked;
  btnNext.Enabled := IsIDEChosen;
end;

function TfrmMain.CheckDelphiRunning: Boolean;
begin
  Result := not FInstallers.AnyInstanceRunning or IsDebuggerAttached;
  if not Result then
    Application.MessageBox
      ('Please close all running instances of Delphi/C++Builder IDE before the installation.',
      nil, MB_OK or MB_ICONSTOP);
end;

procedure TfrmMain.btnAboutClick(Sender: TObject);
begin
  ShowLog(TextSeparatorLine +
    'IDE Installer � Sergey Tkachenko, http://www.trichview.com/'#13#10 +
    TextSeparatorLine +
    'This software uses Jedi VCL http://jvcl.delphi-jedi.org/'#13#10 +
    'IDE Installer and its source code are released under Mozilla Public License Version 1.1: https://www.mozilla.org/MPL/1.1/'#13#10
    + 'Source code of IDE Installer is available at http://www.trichview.com/ideinstall/',
    'About IDE Installer');
end;

procedure TfrmMain.btnExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.ClearAll1Click(Sender: TObject);
begin
  CheckAll(False);
end;

procedure TfrmMain.clstIDEClickCheck(Sender: TObject);
begin
  btnNext.Enabled := IsIDEChosen;
end;

procedure TfrmMain.clstIDEDblClick(Sender: TObject);
begin
  if clstIDE.ItemIndex >= 0 then
    clstIDE.Checked[clstIDE.ItemIndex] := not clstIDE.Checked
      [clstIDE.ItemIndex];
  btnNext.Enabled := IsIDEChosen;
end;

procedure TfrmMain.SelectAll1Click(Sender: TObject);
begin
  CheckAll(True);
end;

function TfrmMain.GetEnvPath(const s: String;
  Target: TJclBorRADToolInstallation): String;

  function DoesTargetSupportEnv: Boolean;
  begin
    case Target.RadToolKind of
      brDelphi, brCppBuilder:
        Result := Target.VersionNumber >= 6;
      else
        Result := True;
    end;
  end;

begin
  Result := s;
  if (Config.SourcePathEnv <> '') and DoesTargetSupportEnv then
    Result := Config.SourcePathEnv + Copy(s, Length(Config.SourcePath) + 1,
      Length(s));
  Result := PathRemoveSeparator(Result);
end;

{
// in the first installer version, directories were added to paths after
// the compilation
// in the new version, they are added before, so we cannot check them
procedure TfrmMain.CheckDir(const s: String);
begin
  if not DirectoryExists(PathRemoveSeparator(s)) then
    ErrorLog := ErrorLog + #13#10 + 'Warning: folder does not exist: ' + s;
end;
}

procedure TfrmMain.InitProgress(MaxValue: Integer);
begin
  ProgressBar1.Position := 0;
  ProgressBar1.Max := MaxValue;
  ProgressBar1.Step := 1;
  ProgressBar1.Visible := True;
  ProgressBar1.Update;
  {$IFDEF TASKBAR}
  if FTaskBar <> nil then
  begin
    FTaskBar.ProgressValue := 0;
    FTaskBar.ProgressMaxValue := MaxValue;
    FTaskBar.ProgressState := TTaskBarProgressState.Normal;
  end;
  {$ENDIF}
  Application.ProcessMessages;
end;

procedure TfrmMain.StepProgress;
begin
  ProgressBar1.StepIt;
  {$IFDEF TASKBAR}
  if FTaskBar <> nil then
    FTaskBar.ProgressValue := ProgressBar1.Position;
  {$ENDIF}
  Application.ProcessMessages;
end;

procedure TfrmMain.DoneProgress(Success: Boolean);
begin
  ProgressBar1.Visible := False;
  {$IFDEF TASKBAR}
  if FTaskBar <> nil then
  begin
    if not Success then
      FTaskBar.ProgressState := TTaskBarProgressState.Error
    else
    begin
      FTaskBar.ProgressState := TTaskBarProgressState.None;
      FlashWindow(Handle, False);
    end;
  end;
  {$ENDIF}
end;

procedure TfrmMain.ShowStatusMsg(const S: String);
begin
  lblStatus.Caption := S;
  lblStatus.Update;
end;

procedure TfrmMain.SaveOptions;
var
  Reg: TRegistry;
begin
  if Config.OptionsKey = '' then
    exit;
  try
    Reg := TRegistry.Create;
    try
      if Reg.OpenKey(Config.OptionsKey, True) then
      begin
        Reg.WriteBool('PathToSrcWin32', FPathToSrcWin32);
        Reg.WriteBool('IgnoreNonWinErrors', FIgnoreNonWinErrors);
        Reg.WriteBool('IgnoreOptionalErrors', FIgnoreOptionalErrors);
      end;
    finally
      Reg.Free;
    end;
  except
  end;
end;

procedure TfrmMain.LoadOptions;
var
  Reg: TRegistry;
begin
  if Config.OptionsKey = '' then
    exit;
  try
    Reg := TRegistry.Create;
    try
      if Reg.OpenKeyReadOnly(Config.OptionsKey) then
      begin
        if not HasTrial and not Config.CBuilder then
        begin
          if Reg.ValueExists('PathToSrcWin32') then
            FPathToSrcWin32 := Reg.ReadBool('PathToSrcWin32');
        end
        else
          FPathToSrcWin32 := True;
        if Reg.ValueExists('IgnoreNonWinErrors') then
          FIgnoreNonWinErrors := Reg.ReadBool('IgnoreNonWinErrors');
        if Reg.ValueExists('IgnoreOptionalErrors') then
          FIgnoreOptionalErrors := Reg.ReadBool('IgnoreOptionalErrors');
      end;
    finally
      Reg.Free;
    end;
  except
  end;
end;

procedure TfrmMain.MoveControlsToActivePage;
begin
  Label1.Parent := PageControl1.ActivePage;
  Image1.Parent := PageControl1.ActivePage;
end;



end.
