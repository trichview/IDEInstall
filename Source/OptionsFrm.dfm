object frmOptions: TfrmOptions
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Options'
  ClientHeight = 205
  ClientWidth = 302
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object btnOk: TButton
    Left = 138
    Top = 172
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 3
  end
  object btnCancel: TButton
    Left = 219
    Top = 172
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 4
  end
  object GroupBox1: TGroupBox
    Left = 8
    Top = 8
    Width = 282
    Height = 105
    Caption = 'Library path for 32-bit Windows platform:'
    TabOrder = 0
    object Label1: TLabel
      Left = 8
      Top = 80
      Width = 198
      Height = 13
      Caption = 'All other platforms use pre-compiled units'
    end
    object rgPAS: TRadioButton
      Left = 24
      Top = 27
      Width = 200
      Height = 17
      Caption = 'add path to &source code'
      TabOrder = 0
    end
    object rgDCU: TRadioButton
      Left = 24
      Top = 50
      Width = 200
      Height = 17
      Caption = 'add path to pre-&compiled units'
      TabOrder = 1
    end
  end
  object cbIgnoreNonWinErrors: TCheckBox
    Left = 16
    Top = 119
    Width = 249
    Height = 17
    Caption = '&Ignore errors for non-Windows platforms'
    TabOrder = 1
  end
  object cbIgnoreOptionalErrors: TCheckBox
    Left = 16
    Top = 142
    Width = 249
    Height = 17
    Caption = 'Ignore errors for &optional packages'
    TabOrder = 2
  end
end
