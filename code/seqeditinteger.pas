unit SeqEditInteger;

interface

uses Classes, SeqBaseDialog,
  CastleVectors, CastleUIControls, CastleControls, SeqExhibiter;

type
  TReturnInteger = procedure(AValue: Integer) of object;

  TSeqEditInteger = class(TCastleView)
  strict private
    type
      TSeqEditIntegerDialog = class(TSeqBaseDialog)
      protected
        FNumber, FMin, FMax: Integer;
        FOnReturnInteger: TReturnInteger;
        EditNumber: TCastleIntegerEdit;
        ButtonIncrease, ButtonDecrease: TCastleButton;
        ButtonSet: TCastleButton;
        procedure ChangeNumber(Sender: TObject);
        procedure ClickControl(Sender: TObject);
        procedure SetNumber(AValue: Integer);
        procedure SetMin(AValue: Integer);
        procedure SetMax(AValue: Integer);
      public
        constructor CreateNew(const AUrl: String; AOwner: TComponent); override;

        property Number: Integer read FNumber write SetNumber;
        property Min: Integer read FMin write SetMin;
        property Max: Integer read FMax write SetMax;
      end;
    var
      FTitle: String;
      FNumber, FMin, FMax: Integer;
      FOnReturnInteger: TReturnInteger;
      FDialog: TSeqEditIntegerDialog;
  public
    constructor CreateUntilStopped(AValue, AMin, AMax: Integer; ATitle: String; AOnReturnInteger: TReturnInteger);
    procedure Start; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
  end;

implementation

uses
  SysUtils, CastleComponentSerialize, CastleFonts, GameSound;

{ ========= ------------------------------------------------------------------ }
{ TSeqListBoxDialog ---------------------------------------------------------- }
{ ========= ------------------------------------------------------------------ }

constructor TSeqEditInteger.TSeqEditIntegerDialog.CreateNew(const AUrl: String; AOwner: TComponent);
begin
  inherited;
  FNumber:= 0;
  Fmin:= 0;
  FMax:= 10000;

  { Find components, by name, that we need to access from code }
  EditNumber:= FUiOwner.FindRequiredComponent('EditNumber') as TCastleIntegerEdit;
  ButtonIncrease:= FUiOwner.FindRequiredComponent('ButtonIncrease') as TCastleButton;
  ButtonDecrease:= FUiOwner.FindRequiredComponent('ButtonDecrease') as TCastleButton;
  ButtonSet:= FUiOwner.FindRequiredComponent('ButtonSet') as TCastleButton;
  EditNumber.OnChange:= {$ifdef FPC}@{$endif}ChangeNumber;
  ButtonIncrease.OnClick:= {$ifdef FPC}@{$endif}ChangeNumber;
  ButtonDecrease.OnClick:= {$ifdef FPC}@{$endif}ChangeNumber;
  ButtonSet.OnClick:= {$ifdef FPC}@{$endif}ClickControl;
  ButtonIncrease.OnInternalMouseEnter:= {$ifdef FPC}@{$endif}ControlHover;
  ButtonDecrease.OnInternalMouseEnter:= {$ifdef FPC}@{$endif}ControlHover;
  ButtonSet.OnInternalMouseEnter:= {$ifdef FPC}@{$endif}ControlHover;
end;

procedure TSeqEditInteger.TSeqEditIntegerDialog.ChangeNumber(Sender: TObject);
var
  component: TComponent;
  edit: TCastleIntegerEdit;
begin
  if (NOT (Sender is TComponent)) then Exit;

  component:= Sender as TComponent;
  case component.Name of
    'EditNumber':
    begin
      PlaySfx(TSfxType.TapKey);
      edit:= Sender as TCastleIntegerEdit;
      Number:= Integer(edit.Value);
    end;
    'ButtonIncrease':
    begin
      PlaySfx(TSfxType.ClickEdit);
      Number:= Number + 1;
    end;
    'ButtonDecrease':
    begin
      PlaySfx(TSfxType.ClickEdit);
      Number:= Number - 1;
    end;
  end;
end;

procedure TSeqEditInteger.TSeqEditIntegerDialog.SetNumber(AValue: Integer);
begin
  if (AValue < Fmin) then
    AValue:= Fmin
  else
  if (AValue > FMax) then
    AValue:= FMax;

  if (FNumber <> AValue) then
  begin
    FNumber:= AValue;
    EditNumber.Value:= FNumber;
  end;
end;

procedure TSeqEditInteger.TSeqEditIntegerDialog.SetMin(AValue: Integer);
begin
  FMin:= AValue;
  EditNumber.Min:= FMin;
end;

procedure TSeqEditInteger.TSeqEditIntegerDialog.SetMax(AValue: Integer);
begin
  FMax:= AValue;
  EditNumber.Max:= FMax;
end;

procedure TSeqEditInteger.TSeqEditIntegerDialog.ClickControl(Sender: TObject);
var
  button: TCastleButton;
begin
  if NOT (Sender is TCastleButton) then Exit;
  button:= Sender as TCastleButton;

  if ((button.Name = 'ButtonSet') AND Assigned(FOnReturnInteger)) then
  begin
    PlaySfx(TSfxType.ClickOk);
    FOnReturnInteger(Number);
  end;

  ShowClose;
end;

{ ========= ------------------------------------------------------------------ }
{ TSeqEditInteger ------------------------------------------------------------ }
{ ========= ------------------------------------------------------------------ }

constructor TSeqEditInteger.CreateUntilStopped(AValue, AMin, AMax: Integer; ATitle: String; AOnReturnInteger: TReturnInteger);
begin
  inherited CreateUntilStopped;
  FTitle:= ATitle;
  FMin:= AMin;
  FMax:= AMax;
  FNumber:= AValue;
  FOnReturnInteger:= AOnReturnInteger;
  DesignUrl:= 'castle-data:/bgwin.castle-user-interface';
end;

procedure TSeqEditInteger.Start;
begin
  inherited;
  InterceptInput:= True;

  FDialog:= TSeqEditIntegerDialog.CreateNew('castle-data:/editinteger.castle-user-interface', FreeAtStop);
  FDialog.Anchor(hpMiddle);
  FDialog.Anchor(vpMiddle);
  FDialog.FullSize:= True;
  FDialog.Title:= FTitle;
  FDialog.Min:= FMin;
  FDialog.Max:= FMax;
  FDialog.Number:= FNumber;
  FDialog.FOnReturnInteger:= FOnReturnInteger;
  InsertFront(FDialog);
  FDialog.Start;
end;

procedure TSeqEditInteger.Update(const SecondsPassed: Single; var HandleInput: boolean);
begin
  inherited;

  if FDialog.Closed then
    Container.PopView(Self);
end;

end.
