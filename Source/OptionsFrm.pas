unit OptionsFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TfrmOptions = class(TForm)
    btnOk: TButton;
    btnCancel: TButton;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    rgPAS: TRadioButton;
    rgDCU: TRadioButton;
    cbIgnoreNonWinErrors: TCheckBox;
    cbIgnoreOptionalErrors: TCheckBox;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmOptions: TfrmOptions;

implementation

{$R *.dfm}

procedure TfrmOptions.FormCreate(Sender: TObject);
begin
  if Screen.Fonts.IndexOf(Font.Name) < 0 then
  begin
    Font.Name := 'Tahoma';
    Font.Size := 8;
  end;
end;

end.
