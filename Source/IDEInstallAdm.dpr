program IDEInstallAdm;

uses
  Vcl.Forms,
  Windows,
  Unit1 in 'Unit1.pas' {frmMain},
  ViewLogFrm in 'ViewLogFrm.pas' {frmLog},
  ReplaceUnit in 'ReplaceUnit.pas',
  OptionsFrm in 'OptionsFrm.pas' {frmOptions};

{$R *.res}


begin
  Application.Initialize;
  Application.Title := 'IDE Installer';
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmOptions, frmOptions);
  Application.Run;
end.
