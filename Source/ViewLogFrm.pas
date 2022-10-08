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

unit ViewLogFrm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls;

type
  TfrmLog = class(TForm)
    Button1: TButton;
    txt: TMemo;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure RemoveEmptyLines;
  end;

procedure ShowLog(const Text, Caption: String);


implementation

{$R *.dfm}

procedure ShowLog(const Text, Caption: String);
var frm: TfrmLog;
begin
  frm := TfrmLog.Create(Application);
  try
    frm.txt.Lines.Text := Text;
    frm.Caption := Caption;
    frm.RemoveEmptyLines;
    frm.ShowModal;
  finally
    frm.Free;
  end;
end;

procedure TfrmLog.FormCreate(Sender: TObject);
begin
  if Screen.Fonts.IndexOf(Font.Name) < 0 then
  begin
    Font.Name := 'Tahoma';
    Font.Size := 8;
    txt.Font.Name := 'Tahoma';
    txt.Font.Size := 8;
  end;
end;

procedure TfrmLog.RemoveEmptyLines;
var i: Integer;
begin
  txt.Lines.BeginUpdate;
  try
    for i := txt.Lines.Count-1 downto 0 do
      if Trim(txt.Lines[i])='' then
        txt.Lines.Delete(i);
  finally
    txt.Lines.EndUpdate;
  end;
end;

end.
