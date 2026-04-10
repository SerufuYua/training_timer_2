unit SeqEditTimeMinSec;

interface

uses Classes, SeqBaseDialog,
  CastleVectors, CastleUIControls, CastleControls, SeqExhibiter;

type
  TReturnSeconds = procedure(AValue: Integer) of object;

  TSeqEditTimeMinSec = class(TCastleView)
  strict private
    type
      TSeqEditTimeMinSecDialog = class(TSeqBaseDialog)
      protected
        FSec, Fmin: Integer;
        FOnReturnSeconds: TReturnSeconds;
        EditMinNumber, EditSecNumber: TCastleIntegerEdit;
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
      FDialog: TSeqEditTimeMinSecDialog;
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

constructor TSeqEditTimeMinSec.TSeqEditTimeMinSecDialog.CreateNew(const AUrl: String; AOwner: TComponent);
begin
  inherited;
  FSec:= 0;
  Fmin:= 0;

  { Find components, by name, that we need to access from code }
  EditMinNumber:= FUiOwner.FindRequiredComponent('EditMinNumber') as TCastleIntegerEdit;
  EditSecNumber:= FUiOwner.FindRequiredComponent('EditSecNumber') as TCastleIntegerEdit;
  ButtonMinIncrease:= FUiOwner.FindRequiredComponent('ButtonMinIncrease') as TCastleButton;
  ButtonMinDecrease:= FUiOwner.FindRequiredComponent('ButtonMinDecrease') as TCastleButton;
  ButtonSecIncrease:= FUiOwner.FindRequiredComponent('ButtonSecIncrease') as TCastleButton;
  ButtonSecDecrease:= FUiOwner.FindRequiredComponent('ButtonSecDecrease') as TCastleButton;
  ButtonSet:= FUiOwner.FindRequiredComponent('ButtonSet') as TCastleButton;
  EditMinNumber.OnChange:= {$ifdef FPC}@{$endif}ChangeNumber;
  EditSecNumber.OnChange:= {$ifdef FPC}@{$endif}ChangeNumber;
  ButtonMinIncrease.OnClick:= {$ifdef FPC}@{$endif}ChangeNumber;
  ButtonMinDecrease.OnClick:= {$ifdef FPC}@{$endif}ChangeNumber;
  ButtonSecIncrease.OnClick:= {$ifdef FPC}@{$endif}ChangeNumber;
  ButtonSecDecrease.OnClick:= {$ifdef FPC}@{$endif}ChangeNumber;
  ButtonSet.OnClick:= {$ifdef FPC}@{$endif}ClickControl;
end;

procedure TSeqEditTimeMinSec.TSeqEditTimeMinSecDialog.ChangeNumber(Sender: TObject);
var
  component: TComponent;
  edit: TCastleIntegerEdit;
begin
  if (NOT (Sender is TComponent)) then Exit;

  component:= Sender as TComponent;
  case component.Name of
    'ButtonMinIncrease':
      Seconds:= Seconds + 60;
    'ButtonMinDecrease':
      Seconds:= Seconds - 60;
    'ButtonSecIncrease':
      Seconds:= Seconds + 1;
    'ButtonSecDecrease':
      Seconds:= Seconds - 1;
    'EditMinNumber':
    begin
      edit:= Sender as TCastleIntegerEdit;
      Seconds:= MinSecToSeconds(edit.Value, FSec);
    end;
    'EditSecNumber':
    begin
      edit:= Sender as TCastleIntegerEdit;
      Seconds:= MinSecToSeconds(FMin, edit.Value);
    end;
  end;
end;

procedure TSeqEditTimeMinSec.TSeqEditTimeMinSecDialog.SetSeconds(AValue: Integer);
begin
  if (AValue >= 0) then
  begin
    SecondsToMinSec(AValue, FMin, FSec);
    EditMinNumber.Value:= FMin;
    EditSecNumber.Value:= FSec;
  end;
end;

function TSeqEditTimeMinSec.TSeqEditTimeMinSecDialog.GetSeconds: Integer;
begin
  Result:= MinSecToSeconds(FMin, FSec);
end;

procedure TSeqEditTimeMinSec.TSeqEditTimeMinSecDialog.ClickControl(Sender: TObject);
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
{ TSeqEditTimeMinSec --------------------------------------------------------- }
{ ========= ------------------------------------------------------------------ }

constructor TSeqEditTimeMinSec.CreateUntilStopped(AValue: Integer; ATitle: String; AOnReturnSeconds: TReturnSeconds);
begin
  inherited CreateUntilStopped;
  FTitle:= ATitle;
  FSeconds:= AValue;
  FOnReturnSeconds:= AOnReturnSeconds;
  DesignUrl:= 'castle-data:/bgwin.castle-user-interface';
end;

procedure TSeqEditTimeMinSec.Start;
begin
  inherited;
  InterceptInput:= True;

  FDialog:= TSeqEditTimeMinSecDialog.CreateNew('castle-data:/edittime_min_sec.castle-user-interface', FreeAtStop);
  FDialog.Anchor(hpMiddle);
  FDialog.Anchor(vpMiddle);
  FDialog.FullSize:= True;
  FDialog.Title:= FTitle;
  FDialog.Seconds:= FSeconds;
  FDialog.FOnReturnSeconds:= FOnReturnSeconds;
  InsertFront(FDialog);
  FDialog.Start;
end;

procedure TSeqEditTimeMinSec.Update(const SecondsPassed: Single; var HandleInput: boolean);
begin
  inherited;

  if FDialog.Closed then
    Container.PopView(Self);
end;

end.
