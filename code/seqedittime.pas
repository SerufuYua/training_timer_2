unit SeqEditTime;

interface

uses Classes, SeqBaseDialog,
  CastleVectors, CastleUIControls, CastleControls, SeqExhibiter;

type
  TReturnSeconds = procedure(AValue: Integer) of object;

  TSeqEditTime = class(TCastleView)
  strict private
    type
      TSeqEditTimeDialog = class(TSeqBaseDialog)
      protected
        FHr, FSec, Fmin: Integer;
        FOnReturnSeconds: TReturnSeconds;
        EditHrNumber, EditMinNumber, EditSecNumber: TCastleIntegerEdit;
        ButtonHrIncrease, ButtonHrDecrease: TCastleButton;
        ButtonMinIncrease, ButtonMinDecrease: TCastleButton;
        ButtonSecIncrease, ButtonSecDecrease: TCastleButton;
        ButtonSet: TCastleButton;
        procedure ChangeNumber(Sender: TObject);
        procedure ClickControl(Sender: TObject);
        procedure SetSeconds(AValue: Integer);
        function GetSeconds: Integer;
      public
        constructor CreateNew(const AUrl: String; AOwner: TComponent); override;

        property Seconds: Integer read GetSeconds write SetSeconds;
      end;
    var
      FTitle: String;
      FSeconds: Integer;
      FOnReturnSeconds: TReturnSeconds;
      FDialog: TSeqEditTimeDialog;
  public
    constructor CreateUntilStopped(AValue: Integer; ATitle: String; AOnReturnSeconds: TReturnSeconds);
    procedure Start; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
  end;

implementation

uses
  SysUtils, CastleComponentSerialize, CastleFonts, MyUtils;

{ ========= ------------------------------------------------------------------ }
{ TSeqListBoxDialog ---------------------------------------------------------- }
{ ========= ------------------------------------------------------------------ }

constructor TSeqEditTime.TSeqEditTimeDialog.CreateNew(const AUrl: String; AOwner: TComponent);
begin
  inherited;
  FSec:= 0;
  Fmin:= 0;

  { Find components, by name, that we need to access from code }
  EditHrNumber:= FUiOwner.FindRequiredComponent('EditHrNumber') as TCastleIntegerEdit;
  EditMinNumber:= FUiOwner.FindRequiredComponent('EditMinNumber') as TCastleIntegerEdit;
  EditSecNumber:= FUiOwner.FindRequiredComponent('EditSecNumber') as TCastleIntegerEdit;
  ButtonHrIncrease:= FUiOwner.FindRequiredComponent('ButtonHrIncrease') as TCastleButton;
  ButtonHrDecrease:= FUiOwner.FindRequiredComponent('ButtonHrDecrease') as TCastleButton;
  ButtonMinIncrease:= FUiOwner.FindRequiredComponent('ButtonMinIncrease') as TCastleButton;
  ButtonMinDecrease:= FUiOwner.FindRequiredComponent('ButtonMinDecrease') as TCastleButton;
  ButtonSecIncrease:= FUiOwner.FindRequiredComponent('ButtonSecIncrease') as TCastleButton;
  ButtonSecDecrease:= FUiOwner.FindRequiredComponent('ButtonSecDecrease') as TCastleButton;
  ButtonSet:= FUiOwner.FindRequiredComponent('ButtonSet') as TCastleButton;
  EditHrNumber.OnChange:= {$ifdef FPC}@{$endif}ChangeNumber;
  EditMinNumber.OnChange:= {$ifdef FPC}@{$endif}ChangeNumber;
  EditSecNumber.OnChange:= {$ifdef FPC}@{$endif}ChangeNumber;
  ButtonHrIncrease.OnClick:= {$ifdef FPC}@{$endif}ChangeNumber;
  ButtonHrDecrease.OnClick:= {$ifdef FPC}@{$endif}ChangeNumber;
  ButtonMinIncrease.OnClick:= {$ifdef FPC}@{$endif}ChangeNumber;
  ButtonMinDecrease.OnClick:= {$ifdef FPC}@{$endif}ChangeNumber;
  ButtonSecIncrease.OnClick:= {$ifdef FPC}@{$endif}ChangeNumber;
  ButtonSecDecrease.OnClick:= {$ifdef FPC}@{$endif}ChangeNumber;
  ButtonSet.OnClick:= {$ifdef FPC}@{$endif}ClickControl;
end;

procedure TSeqEditTime.TSeqEditTimeDialog.ChangeNumber(Sender: TObject);
var
  component: TComponent;
  edit: TCastleIntegerEdit;
begin
  if (NOT (Sender is TComponent)) then Exit;

  component:= Sender as TComponent;
  case component.Name of
    'ButtonHrIncrease':
      Seconds:= Seconds + 60 * 60;
    'ButtonHrDecrease':
      Seconds:= Seconds - 60 * 60;
    'ButtonMinIncrease':
      Seconds:= Seconds + 60;
    'ButtonMinDecrease':
      Seconds:= Seconds - 60;
    'ButtonSecIncrease':
      Seconds:= Seconds + 1;
    'ButtonSecDecrease':
      Seconds:= Seconds - 1;
    'EditHrNumber':
    begin
      edit:= Sender as TCastleIntegerEdit;
      Seconds:= HrMinSecToSeconds(edit.Value, FMin, FSec);
    end;
    'EditMinNumber':
    begin
      edit:= Sender as TCastleIntegerEdit;
      Seconds:= HrMinSecToSeconds(FHr, edit.Value, FSec);
    end;
    'EditSecNumber':
    begin
      edit:= Sender as TCastleIntegerEdit;
      Seconds:= HrMinSecToSeconds(FHr, FMin, edit.Value);
    end;
  end;
end;

procedure TSeqEditTime.TSeqEditTimeDialog.SetSeconds(AValue: Integer);
begin
  if (AValue >= 0) then
  begin
    SecondsToHrMinSec(AValue, FHr, FMin, FSec);
    EditHrNumber.Value:= FHr;
    EditMinNumber.Value:= FMin;
    EditSecNumber.Value:= FSec;
  end;
end;

function TSeqEditTime.TSeqEditTimeDialog.GetSeconds: Integer;
begin
  Result:= HrMinSecToSeconds(FHr, FMin, FSec);
end;

procedure TSeqEditTime.TSeqEditTimeDialog.ClickControl(Sender: TObject);
var
  button: TCastleButton;
begin
  if NOT (Sender is TCastleButton) then Exit;
  button:= Sender as TCastleButton;

  if ((button.Name = 'ButtonSet') AND Assigned(FOnReturnSeconds)) then
    FOnReturnSeconds(Seconds);

  ShowClose;
end;

{ ========= ------------------------------------------------------------------ }
{ TSeqEditTime --------------------------------------------------------- }
{ ========= ------------------------------------------------------------------ }

constructor TSeqEditTime.CreateUntilStopped(AValue: Integer; ATitle: String; AOnReturnSeconds: TReturnSeconds);
begin
  inherited CreateUntilStopped;
  FTitle:= ATitle;
  FSeconds:= AValue;
  FOnReturnSeconds:= AOnReturnSeconds;
  DesignUrl:= 'castle-data:/bgwin.castle-user-interface';
end;

procedure TSeqEditTime.Start;
begin
  inherited;
  InterceptInput:= True;

  FDialog:= TSeqEditTimeDialog.CreateNew('castle-data:/edittime.castle-user-interface', FreeAtStop);
  FDialog.Anchor(hpMiddle);
  FDialog.Anchor(vpMiddle);
  FDialog.FullSize:= True;
  FDialog.Title:= FTitle;
  FDialog.Seconds:= FSeconds;
  FDialog.FOnReturnSeconds:= FOnReturnSeconds;
  InsertFront(FDialog);
  FDialog.Start;
end;

procedure TSeqEditTime.Update(const SecondsPassed: Single; var HandleInput: boolean);
begin
  inherited;

  if FDialog.Closed then
    Container.PopView(Self);
end;

end.
