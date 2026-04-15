unit SeqEditPeriod;

interface

uses Classes, SeqBaseDialog,
  CastleVectors, CastleUIControls, CastleControls, CastleColors, SeqExhibiter,
  GameViewSequenceTimer, SeqEditTimeMinSec, SeqListColors;

type
  TReturnPeriod = procedure(AValue: TTimePeriod) of object;

  TSeqEditPeriod = class(TCastleView)
  strict private
    type
      TSeqEditPeriodDialog = class(TSeqBaseDialog)
      protected
        FOnReturnString: TReturnPeriod;
        FPeriod: TTimePeriod;
        ButtonSet, ButtonPeriodName, ButtonSoundStart,
          ButtonSoundEnd, ButtonDuration, ButtonWarningTime,
          ButtonColor,
          ButtonSoundcheckStart, ButtonSoundcheckEnd: TCastleButton;
        CheckEnable, CheckWarning: TCastleCheckbox;
        procedure ClickEdit(Sender: TObject);
        procedure ClickSoundcheck(Sender: TObject);
        procedure ClickControl(Sender: TObject);
        procedure SetPeriod(AValue: TTimePeriod);
        procedure DoEditName(AValue: String);
        procedure DoSelectStartSound(AValue: Integer);
        procedure DoSelectFinalSound(AValue: Integer);
        procedure DoEditDuration(ASeconds: Integer);
        procedure DoEditWarning(ASeconds: Integer);
        procedure DoEditColor(AValue: TCastleColor);
      public
        constructor CreateNew(const AUrl: String; AOwner: TComponent); override;

        property PeriodForEdit: TTimePeriod write SetPeriod;
      end;
    var
      FTitle: String;
      FPeriod: TTimePeriod;
      FOnReturnString: TReturnPeriod;
      FDialog: TSeqEditPeriodDialog;
  public
    constructor CreateUntilStopped(AValue: TTimePeriod; ATitle: String; AOnReturnString: TReturnPeriod);
    procedure Start; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
  end;

implementation

uses
  SysUtils, CastleComponentSerialize, CastleFonts, SeqEditString, SeqListBox,
  MyUtils, GameSound, TypInfo;

{ ========= ------------------------------------------------------------------ }
{ TSeqEditPeriodDialog ------------------------------------------------------- }
{ ========= ------------------------------------------------------------------ }

constructor TSeqEditPeriod.TSeqEditPeriodDialog.CreateNew(const AUrl: String; AOwner: TComponent);
begin
  inherited;

  { Find components, by name, that we need to access from code }
  ButtonPeriodName:= FUiOwner.FindRequiredComponent('ButtonPeriodName') as TCastleButton;
  CheckEnable:= FUiOwner.FindRequiredComponent('CheckEnable') as TCastleCheckbox;
  ButtonSoundStart:= FUiOwner.FindRequiredComponent('ButtonSoundStart') as TCastleButton;
  ButtonSoundEnd:= FUiOwner.FindRequiredComponent('ButtonSoundEnd') as TCastleButton;
  ButtonDuration:= FUiOwner.FindRequiredComponent('ButtonDuration') as TCastleButton;
  ButtonWarningTime:= FUiOwner.FindRequiredComponent('ButtonWarningTime') as TCastleButton;
  CheckWarning:= FUiOwner.FindRequiredComponent('CheckWarning') as TCastleCheckbox;
  ButtonColor:= FUiOwner.FindRequiredComponent('ButtonColor') as TCastleButton;
  ButtonSet:= FUiOwner.FindRequiredComponent('ButtonSet') as TCastleButton;
  ButtonSoundcheckStart:= FUiOwner.FindRequiredComponent('ButtonSoundcheckStart') as TCastleButton;
  ButtonSoundcheckEnd:= FUiOwner.FindRequiredComponent('ButtonSoundcheckEnd') as TCastleButton;

  ButtonPeriodName.OnClick:= {$ifdef FPC}@{$endif}ClickEdit;
  CheckEnable.OnChange:= {$ifdef FPC}@{$endif}ClickEdit;
  ButtonSoundStart.OnClick:= {$ifdef FPC}@{$endif}ClickEdit;
  ButtonSoundEnd.OnClick:= {$ifdef FPC}@{$endif}ClickEdit;
  ButtonDuration.OnClick:= {$ifdef FPC}@{$endif}ClickEdit;
  ButtonWarningTime.OnClick:= {$ifdef FPC}@{$endif}ClickEdit;
  CheckWarning.OnChange:= {$ifdef FPC}@{$endif}ClickEdit;
  ButtonColor.OnClick:= {$ifdef FPC}@{$endif}ClickEdit;
  ButtonSet.OnClick:= {$ifdef FPC}@{$endif}ClickControl;
  ButtonSoundcheckStart.OnClick:= {$ifdef FPC}@{$endif}ClickSoundcheck;
  ButtonSoundcheckEnd.OnClick:= {$ifdef FPC}@{$endif}ClickSoundcheck;
end;

procedure TSeqEditPeriod.TSeqEditPeriodDialog.ClickEdit(Sender: TObject);
var
  component: TComponent;
begin
  if (NOT (Sender is TComponent)) then Exit;

  component:= Sender as TComponent;
  case component.Name of
    'ButtonPeriodName':
    begin
      if NOT (Container.FrontView is TSeqEditString) then
        Container.PushView(TSeqEditString.CreateUntilStopped(
          FPeriod.Name, 'Period Name', {$ifdef FPC}@{$endif}DoEditName));
    end;
    'CheckEnable':
    begin
      if (component is TCastleCheckbox) then
        FPeriod.Enable:= (component as TCastleCheckbox).Checked;
    end;
    'ButtonSoundStart':
    begin
      if NOT (Container.FrontView is TSeqListBox) then
        Container.PushView(TSeqListBox.CreateUntilStopped(ListOfSet(TypeInfo(TSoundType)),
          'Select Start Sound', {$ifdef FPC}@{$endif}DoSelectStartSound));
    end;
    'ButtonSoundEnd':
    begin
      if NOT (Container.FrontView is TSeqListBox) then
        Container.PushView(TSeqListBox.CreateUntilStopped(ListOfSet(TypeInfo(TSoundType)),
          'Select Final Sound', {$ifdef FPC}@{$endif}DoSelectFinalSound));
    end;
    'ButtonDuration':
    begin
      if NOT (Container.FrontView is TSeqEditTimeMinSec) then
        Container.PushView(TSeqEditTimeMinSec.CreateUntilStopped(
          FPeriod.DurationSec, 'Period Time', {$ifdef FPC}@{$endif}DoEditDuration));
    end;
    'ButtonWarningTime':
    begin
      if NOT (Container.FrontView is TSeqEditTimeMinSec) then
        Container.PushView(TSeqEditTimeMinSec.CreateUntilStopped(
          FPeriod.WarningSec, 'Period Time', {$ifdef FPC}@{$endif}DoEditWarning));
    end;
    'CheckWarning':
    begin
      if (component is TCastleCheckbox) then
        FPeriod.Warning:= (component as TCastleCheckbox).Checked;
    end;
    'ButtonColor':
    begin
      if NOT (Container.FrontView is TSeqListColors) then
        Container.PushView(TSeqListColors.CreateUntilStopped(
          nil, 'Period Color', {$ifdef FPC}@{$endif}DoEditColor));
    end;
  end;
end;

procedure TSeqEditPeriod.TSeqEditPeriodDialog.ClickSoundcheck(Sender: TObject);
var
  component: TComponent;
begin
  if (NOT (Sender is TComponent)) then Exit;

  component:= Sender as TComponent;
  case component.Name of
    'ButtonSoundcheckStart': Play(FPeriod.SoundStart);
    'ButtonSoundcheckEnd':   Play(FPeriod.SoundEnding);
  end;
end;

procedure TSeqEditPeriod.TSeqEditPeriodDialog.ClickControl(Sender: TObject);
var
  button: TCastleButton;
begin
  if NOT (Sender is TCastleButton) then Exit;
  button:= Sender as TCastleButton;

  if ((button.Name = 'ButtonSet') AND Assigned(FOnReturnString)) then
    FOnReturnString(FPeriod);

  ShowClose;
end;

procedure TSeqEditPeriod.TSeqEditPeriodDialog.SetPeriod(AValue: TTimePeriod);
begin
  FPeriod:= AValue;
  ButtonPeriodName.Caption:= FPeriod.Name;
  CheckEnable.Checked:= FPeriod.Enable;
  ButtonSoundStart.Caption:= GetEnumName(TypeInfo(TSoundType), Ord(FPeriod.SoundStart));
  ButtonSoundEnd.Caption:= GetEnumName(TypeInfo(TSoundType), Ord(FPeriod.SoundEnding));
  ButtonDuration.Caption:= TimeToShortStr(FPeriod.DurationSec);
  ButtonWarningTime.Caption:= TimeToShortStr(FPeriod.WarningSec);
  CheckWarning.Checked:= FPeriod.Warning;
  ButtonColor.CustomBackgroundNormal.Color:= Vector4(FPeriod.Color, 1.0);
  ButtonColor.CustomBackgroundFocused.Color:= Vector4(FPeriod.Color, 1.0);
  ButtonColor.CustomBackgroundPressed.Color:= Vector4(FPeriod.Color, 1.0);
end;

procedure TSeqEditPeriod.TSeqEditPeriodDialog.DoEditName(AValue: String);
begin
  FPeriod.Name:= AValue;
  ButtonPeriodName.Caption:= FPeriod.Name;
end;

procedure TSeqEditPeriod.TSeqEditPeriodDialog.DoSelectStartSound(AValue: Integer);
begin
  FPeriod.SoundStart:= TSoundType(AValue);
  ButtonSoundStart.Caption:= GetEnumName(TypeInfo(TSoundType), AValue);
end;

procedure TSeqEditPeriod.TSeqEditPeriodDialog.DoSelectFinalSound(AValue: Integer);
begin
  FPeriod.SoundEnding:= TSoundType(AValue);
  ButtonSoundEnd.Caption:= GetEnumName(TypeInfo(TSoundType), AValue);
end;

procedure TSeqEditPeriod.TSeqEditPeriodDialog.DoEditDuration(ASeconds: Integer);
begin
  FPeriod.DurationSec:= ASeconds;
  ButtonDuration.Caption:= TimeToShortStr(ASeconds);
end;

procedure TSeqEditPeriod.TSeqEditPeriodDialog.DoEditWarning(ASeconds: Integer);
begin
  FPeriod.WarningSec:= ASeconds;
  ButtonWarningTime.Caption:= TimeToShortStr(ASeconds);
end;

procedure TSeqEditPeriod.TSeqEditPeriodDialog.DoEditColor(AValue: TCastleColor);
begin
  FPeriod.Color:= AValue.RGB;
  ButtonColor.CustomBackgroundNormal.Color:= AValue;
  ButtonColor.CustomBackgroundFocused.Color:= AValue;
  ButtonColor.CustomBackgroundPressed.Color:= AValue;
end;

{ ========= ------------------------------------------------------------------ }
{ TSeqEditPeriod ------------------------------------------------------------ }
{ ========= ------------------------------------------------------------------ }

constructor TSeqEditPeriod.CreateUntilStopped(AValue: TTimePeriod; ATitle: String; AOnReturnString: TReturnPeriod);
begin
  inherited CreateUntilStopped;
  FTitle:= ATitle;
  FPeriod:= AValue;
  FOnReturnString:= AOnReturnString;
  DesignUrl:= 'castle-data:/bgwin.castle-user-interface';
end;

procedure TSeqEditPeriod.Start;
begin
  inherited;
  InterceptInput:= True;

  FDialog:= TSeqEditPeriodDialog.CreateNew('castle-data:/editperiod.castle-user-interface', FreeAtStop);
  FDialog.Anchor(hpMiddle);
  FDialog.Anchor(vpMiddle);
  FDialog.FullSize:= True;
  FDialog.Title:= FTitle;
  FDialog.PeriodForEdit:= FPeriod;
  FDialog.FOnReturnString:= FOnReturnString;
  InsertFront(FDialog);
  FDialog.Start;
end;

procedure TSeqEditPeriod.Update(const SecondsPassed: Single; var HandleInput: boolean);
begin
  inherited;

  if FDialog.Closed then
    Container.PopView(Self);
end;

end.
