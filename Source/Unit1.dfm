object frmMain: TfrmMain
  Left = 0
  Top = 0
  ActiveControl = btnNext
  BorderStyle = bsDialog
  Caption = 'Install'
  ClientHeight = 413
  ClientWidth = 556
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  DesignSize = (
    556
    413)
  TextHeight = 15
  object btnExit: TButton
    Left = 465
    Top = 380
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Cancel'
    TabOrder = 6
    OnClick = btnExitClick
  end
  object btnNext: TButton
    Left = 384
    Top = 380
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Install >'
    Default = True
    TabOrder = 5
    OnClick = btnNextClick
  end
  object btnLog: TButton
    Left = 19
    Top = 380
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = '&Error log'
    TabOrder = 1
    Visible = False
    OnClick = btnLogClick
  end
  object btnRemovedPaths: TButton
    Left = 100
    Top = 380
    Width = 104
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = '&Removed paths'
    TabOrder = 3
    Visible = False
    OnClick = btnRemovedPathsClick
  end
  object btnAbout: TButton
    Left = 19
    Top = 380
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = '&About'
    TabOrder = 2
    OnClick = btnAboutClick
  end
  object btnOptions: TButton
    Left = 100
    Top = 380
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = '&Options...'
    TabOrder = 4
    Visible = False
    OnClick = btnOptionsClick
  end
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 556
    Height = 369
    ActivePage = tabIDE
    Align = alTop
    TabOrder = 0
    object tabIDE: TTabSheet
      Caption = 'tabIDE'
      TabVisible = False
      DesignSize = (
        548
        359)
      object Label1: TLabel
        Left = 96
        Top = 3
        Width = 436
        Height = 60
        AutoSize = False
        Caption = 'Installing %s in %s IDE'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clHighlight
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        Layout = tlCenter
        WordWrap = True
      end
      object Image1: TImage
        Left = 16
        Top = 3
        Width = 60
        Height = 60
        Center = True
      end
      object clstIDE: TCheckListBox
        Left = 16
        Top = 88
        Width = 508
        Height = 253
        Anchors = [akLeft, akTop, akRight, akBottom]
        ItemHeight = 15
        PopupMenu = PopupMenu1
        TabOrder = 0
        OnClickCheck = clstIDEClickCheck
        OnDblClick = clstIDEDblClick
      end
      object panNoInstallers: TPanel
        Left = 90
        Top = 150
        Width = 369
        Height = 81
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 0
        Margins.Bottom = 0
        BevelOuter = bvNone
        Caption = 
          'The installer was not able to find any supported versions of Del' +
          'phi or C++Builder. Press "Cancel" to exit.'
        Color = clWindow
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clMaroon
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        Padding.Left = 5
        Padding.Top = 5
        Padding.Right = 5
        Padding.Bottom = 5
        ParentBackground = False
        ParentFont = False
        ShowCaption = False
        TabOrder = 1
        Visible = False
        object Label8: TLabel
          Left = 5
          Top = 5
          Width = 359
          Height = 71
          Align = alClient
          Caption = 
            'The installer was not able to find any supported versions of Del' +
            'phi or C++Builder. Press "Cancel" to exit.'
          Layout = tlCenter
          WordWrap = True
          ExplicitWidth = 349
          ExplicitHeight = 30
        end
      end
    end
    object tabProgress: TTabSheet
      Caption = 'tabProgress'
      ImageIndex = 1
      TabVisible = False
      DesignSize = (
        548
        359)
      object lblStatus: TLabel
        Left = 16
        Top = 308
        Width = 45
        Height = 15
        Anchors = [akLeft, akBottom]
        Caption = 'lblStatus'
        ExplicitTop = 320
      end
      object txtLog: TMemo
        Left = 16
        Top = 88
        Width = 508
        Height = 214
        Anchors = [akLeft, akTop, akRight, akBottom]
        Color = clInfoBk
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clInfoText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        Lines.Strings = (
          'Installing:')
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
      end
      object ProgressBar1: TProgressBar
        Left = 16
        Top = 329
        Width = 508
        Height = 17
        Anchors = [akLeft, akRight, akBottom]
        TabOrder = 1
        Visible = False
      end
    end
    object tabUninstall: TTabSheet
      Caption = 'tabUninstall'
      ImageIndex = 2
      TabVisible = False
      DesignSize = (
        548
        359)
      object lblUninstall: TLabel
        Left = 16
        Top = 88
        Width = 508
        Height = 253
        Anchors = [akLeft, akTop, akRight, akBottom]
        AutoSize = False
        Caption = 'This program uninstalls %s from all Delphi and C++Builder IDEs'
        WordWrap = True
        ExplicitWidth = 516
      end
    end
    object tabChoose: TTabSheet
      Caption = 'tabChoose'
      ImageIndex = 3
      TabVisible = False
      object Label4: TLabel
        AlignWithMargins = True
        Left = 16
        Top = 286
        Width = 516
        Height = 57
        Margins.Left = 16
        Margins.Top = 16
        Margins.Right = 16
        Margins.Bottom = 16
        Align = alBottom
        AutoSize = False
        Caption = 
          'This installer can install or uninstall  the components in Delph' +
          'i and C++Builder IDE. It does not copy or delete source files.'
        WordWrap = True
        ExplicitTop = 304
        ExplicitWidth = 577
      end
      object rbInstall: TRadioButton
        Left = 169
        Top = 142
        Width = 200
        Height = 17
        Caption = '&Install or modify'
        Checked = True
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        TabStop = True
      end
      object rbUninstall: TRadioButton
        Left = 169
        Top = 181
        Width = 200
        Height = 17
        Caption = '&Uninstall'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
      end
    end
  end
  object PopupMenu1: TPopupMenu
    Left = 432
    Top = 152
    object SelectAll1: TMenuItem
      Caption = 'Select &All'
      OnClick = SelectAll1Click
    end
    object ClearAll1: TMenuItem
      Caption = '&Clear All'
      OnClick = ClearAll1Click
    end
  end
  object OpenDialog1: TOpenDialog
    DefaultExt = 'iide'
    Filter = 'Configuration file (*.iide)|*.iide'
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Title = 'Choose The Installer Configuration File'
    Left = 264
    Top = 288
  end
end
