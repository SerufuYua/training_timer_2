{ Main view, where most of the application logic takes place.

  Feel free to use this code as a starting point for your own projects.
  This template code is in public domain, unlike most other CGE code which
  is covered by BSD or LGPL (see https://castle-engine.io/license). }
unit GameViewSettingsSimple;

interface

uses Classes,
  CastleVectors, CastleComponentSerialize, CastleFlashEffect,
  CastleUIControls, CastleControls, CastleKeysMouse, SeqExhibiter,
  GameViewSequenceTimer;

type
  TSettingsSimple = record
    Name: String;
    Rounds: Integer;
    RoundSeconds, RestSeconds, PrepareSeconds, WarningSeconds: Integer;
    Warning: Boolean;
  end;

  TSettingsSimpleList = Array of TSettingsSimple;

  { Main view, where most of the application logic takes place. }
  TViewSettingsSimple = class(TCastleView)
  protected
    FSettingsSimpleList: TSettingsSimpleList;
    FIndexSeq: Integer;
    procedure DoAferLoad(Sender: TObject);
    procedure DoSelectSeq(AValue: Integer);
    procedure DoRemoveSeq(Sender: TObject);
    procedure DoEditName(AValue: String);
    procedure DoEditRound(AValue: Integer);
    procedure DoEditRoundTime(ASeconds: Integer);
    procedure DoEditRestTime(ASeconds: Integer);
    procedure DoEditPrepareTime(ASeconds: Integer);
    procedure DoEditWarningTime(ASeconds: Integer);
    procedure LoadSettings;
    procedure SaveSettings;
    function MakeDefaultSettings: TSettingsSimple;
    function MakePeriods(AIndex: Integer): TPeriodsSettings;
    procedure UpdateSettings;
    procedure ShowStatistic;
    procedure SetIndexSeq(AValue: Integer);
    function GetIndexSeq: Integer;
    procedure ControlHover(const Sender: TCastleUserInterface);
    procedure ButtonSeqControlClick(Sender: TObject);
    procedure ButtonSeqEditClick(Sender: TObject);
    procedure ButtonActionClick(Sender: TObject);
  published
    FlashEffect: TCastleFlashEffect;
    ExhibiterControl: TSeqExhibiter;
    ButtonSeqSelect, ButtonSeqAdd, ButtonSeqRemove, ButtonSeqCopy: TCastleButton;
    ButtonSeqName, ButtonRounds, ButtonRoundTime, ButtonRestTime,
      ButtonPrepareTime, ButtonWarningTime : TCastleButton;
    ButtonStart, ButtonAbout, ButtonMode: TCastleButton;
    CheckWarning: TCastleCheckBox;
    LabelOveralTimeValue: TCastleLabel;
    ImageSettings, ImageActions: TCastleImageControl;
    LabelFps: TCastleLabel;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Start; override;
    procedure Stop; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: Boolean); override;

    property IndexSeq: Integer read GetIndexSeq write SetIndexSeq;
  end;

var
  ViewSettingsSimple: TViewSettingsSimple;

implementation

uses
  SysUtils, CastleConfig, MyUtils, CastleColors,
  SeqListBox, SeqEditInteger, SeqEditString, SeqEditTime, SeqAbout, SeqConfirm,
  GameViewSettingsPro, GameSound;

const
  MainStor = 'main';
  ModeStr = 'mode';
  ModeThis = 'Simple';
  SettingsStor = 'SettingsSimple';
  NameStr = 'Name';
  SeqStr = 'Seq';
  CountSeqsStr = 'CountSeqs';
  NumSeqStr = 'NumSeq';
  RoundsStr = 'Rounds';
  RoundSecondsStr = 'RoundSeconds';
  RestSecondsStr = 'RestSeconds';
  PrepareSecondsStr = 'PrepareSeconds';
  WarningSecondsStr = 'WarningSeconds';
  WarningStr = 'Warning';

constructor TViewSettingsSimple.Create(AOwner: TComponent);
begin
  inherited;
  FIndexSeq:= 0;
  DesignUrl := 'castle-data:/gameviewsettingssimple.castle-user-interface';
end;

procedure TViewSettingsSimple.Start;
begin
  inherited;

  ImageSettings.Exists:= False;
  ImageActions.Exists:= False;
  LoadSettings;

  { Sequence control buttons }
  ButtonSeqSelect.OnClick:= {$ifdef FPC}@{$endif}ButtonSeqControlClick;
  ButtonSeqAdd.OnClick:=    {$ifdef FPC}@{$endif}ButtonSeqControlClick;
  ButtonSeqRemove.OnClick:= {$ifdef FPC}@{$endif}ButtonSeqControlClick;
  ButtonSeqCopy.OnClick:=   {$ifdef FPC}@{$endif}ButtonSeqControlClick;
  ButtonSeqSelect.OnInternalMouseEnter:= {$ifdef FPC}@{$endif}ControlHover;
  ButtonSeqAdd.OnInternalMouseEnter:=    {$ifdef FPC}@{$endif}ControlHover;
  ButtonSeqRemove.OnInternalMouseEnter:= {$ifdef FPC}@{$endif}ControlHover;
  ButtonSeqCopy.OnInternalMouseEnter:=   {$ifdef FPC}@{$endif}ControlHover;

  { Sequence edit buttons }
  ButtonSeqName.OnClick:=     {$ifdef FPC}@{$endif}ButtonSeqEditClick;
  ButtonRounds.OnClick:=      {$ifdef FPC}@{$endif}ButtonSeqEditClick;
  ButtonRoundTime.OnClick:=   {$ifdef FPC}@{$endif}ButtonSeqEditClick;
  ButtonRestTime.OnClick:=    {$ifdef FPC}@{$endif}ButtonSeqEditClick;
  ButtonPrepareTime.OnClick:= {$ifdef FPC}@{$endif}ButtonSeqEditClick;
  ButtonWarningTime.OnClick:= {$ifdef FPC}@{$endif}ButtonSeqEditClick;
  CheckWarning.OnChange:=     {$ifdef FPC}@{$endif}ButtonSeqEditClick;
  ButtonSeqName.OnInternalMouseEnter:=     {$ifdef FPC}@{$endif}ControlHover;
  ButtonRounds.OnInternalMouseEnter:=      {$ifdef FPC}@{$endif}ControlHover;
  ButtonRoundTime.OnInternalMouseEnter:=   {$ifdef FPC}@{$endif}ControlHover;
  ButtonRestTime.OnInternalMouseEnter:=    {$ifdef FPC}@{$endif}ControlHover;
  ButtonPrepareTime.OnInternalMouseEnter:= {$ifdef FPC}@{$endif}ControlHover;
  ButtonWarningTime.OnInternalMouseEnter:= {$ifdef FPC}@{$endif}ControlHover;
  CheckWarning.OnInternalMouseEnter:=      {$ifdef FPC}@{$endif}ControlHover;

  { Actions buttons }
  ButtonStart.OnClick:= {$ifdef FPC}@{$endif}ButtonActionClick;
  ButtonAbout.OnClick:= {$ifdef FPC}@{$endif}ButtonActionClick;
  ButtonMode.OnClick:=  {$ifdef FPC}@{$endif}ButtonActionClick;
  ButtonStart.OnInternalMouseEnter:= {$ifdef FPC}@{$endif}ControlHover;
  ButtonAbout.OnInternalMouseEnter:= {$ifdef FPC}@{$endif}ControlHover;
  ButtonMode.OnInternalMouseEnter:=  {$ifdef FPC}@{$endif}ControlHover;

  { Show start animation }
  FlashEffect.Duration:= 6.0;
  FlashEffect.Flash(Black, True);
  WaitForRenderAndCall({$ifdef FPC}@{$endif}DoAferLoad);
end;

procedure TViewSettingsSimple.Stop;
begin
  inherited;
  SaveSettings;
end;

procedure TViewSettingsSimple.LoadSettings;
var
  i, num: Integer;
  path: String;
begin
  num:= UserConfig.GetValue(SettingsStor + '/' + CountSeqsStr, 0);

  if (num > 0) then
  begin
    SetLength(FSettingsSimpleList, num);

    for i:= 0 to (num - 1) do
    begin
      path:= SettingsStor + '/' + SeqStr + IntToStr(i) + '/';
      FSettingsSimpleList[i].Name:= UserConfig.GetValue(path + NameStr, SeqStr + ' ' + IntToStr(i + 1));
      FSettingsSimpleList[i].Rounds:= UserConfig.GetValue(path + RoundsStr, DefaultRounds);
      FSettingsSimpleList[i].RoundSeconds:= UserConfig.GetValue(path + RoundSecondsStr, DefaultRoundSeconds);
      FSettingsSimpleList[i].RestSeconds:= UserConfig.GetValue(path + RestSecondsStr, DefaultRestSeconds);
      FSettingsSimpleList[i].PrepareSeconds:= UserConfig.GetValue(path + PrepareSecondsStr, DefaultPrepareSeconds);
      FSettingsSimpleList[i].WarningSeconds:= UserConfig.GetValue(path + WarningSecondsStr, DefaultWarningSeconds);
      FSettingsSimpleList[i].Warning:= UserConfig.GetValue(path + WarningStr, DefaultWarning);
    end;

    IndexSeq:= UserConfig.GetValue(SettingsStor + '/' + NumSeqStr, 0);
  end
  else
  begin
    SetLength(FSettingsSimpleList, 1);
    FSettingsSimpleList[0]:= MakeDefaultSettings;
    FSettingsSimpleList[0].Name:= FSettingsSimpleList[0].Name + ' 0';
    IndexSeq:= 0;
  end;
end;

procedure TViewSettingsSimple.SaveSettings;
var
  i: Integer;
  path: String;
begin
  UserConfig.DeletePath(SettingsStor);

  UserConfig.SetValue(SettingsStor + '/' + CountSeqsStr, Length(FSettingsSimpleList));

  for i:= 0 to High(FSettingsSimpleList) do
  begin
    path:= SettingsStor + '/' + SeqStr + IntToStr(i) + '/';
    UserConfig.SetValue(path + NameStr, FSettingsSimpleList[i].Name);

    if (FSettingsSimpleList[i].Rounds <> DefaultRounds) then
      UserConfig.SetValue(path + RoundsStr, FSettingsSimpleList[i].Rounds);

    if (FSettingsSimpleList[i].RoundSeconds <> DefaultRoundSeconds) then
      UserConfig.SetValue(path + RoundSecondsStr, FSettingsSimpleList[i].RoundSeconds);

    if (FSettingsSimpleList[i].RestSeconds <> DefaultRestSeconds) then
      UserConfig.SetValue(path + RestSecondsStr, FSettingsSimpleList[i].RestSeconds);

    if (FSettingsSimpleList[i].PrepareSeconds <> DefaultPrepareSeconds) then
      UserConfig.SetValue(path + PrepareSecondsStr, FSettingsSimpleList[i].PrepareSeconds);

    if (FSettingsSimpleList[i].WarningSeconds <> DefaultWarningSeconds) then
      UserConfig.SetValue(path + WarningSecondsStr, FSettingsSimpleList[i].WarningSeconds);

    if (FSettingsSimpleList[i].Warning <> DefaultWarning) then
      UserConfig.SetValue(path + WarningStr, FSettingsSimpleList[i].Warning);
  end;

  UserConfig.SetValue(SettingsStor + '/' + NumSeqStr, IndexSeq);
  UserConfig.SetValue(MainStor + '/' + ModeStr, ModeThis);

  UserConfig.Save;
end;

procedure TViewSettingsSimple.UpdateSettings;
begin
  ButtonSeqName.Caption:= FSettingsSimpleList[IndexSeq].Name;
  ButtonRounds.Caption:= IntToStr(FSettingsSimpleList[IndexSeq].Rounds);
  ButtonRoundTime.Caption:= TimeToShortStr(FSettingsSimpleList[IndexSeq].RoundSeconds);
  ButtonRestTime.Caption:= TimeToShortStr(FSettingsSimpleList[IndexSeq].RestSeconds);
  ButtonPrepareTime.Caption:= TimeToShortStr(FSettingsSimpleList[IndexSeq].PrepareSeconds);
  ButtonWarningTime.Caption:= TimeToShortStr(FSettingsSimpleList[IndexSeq].WarningSeconds);
  CheckWarning.Checked:= FSettingsSimpleList[IndexSeq].Warning;

  ShowStatistic;
end;

procedure TViewSettingsSimple.ShowStatistic;
var
  sec: Integer;
begin
  sec:= FSettingsSimpleList[IndexSeq].PrepareSeconds +
        FSettingsSimpleList[IndexSeq].RestSeconds * (FSettingsSimpleList[IndexSeq].Rounds - 1) +
        FSettingsSimpleList[IndexSeq].RoundSeconds * FSettingsSimpleList[IndexSeq].Rounds;

  LabelOveralTimeValue.Caption:= TimeToFullStr(sec);
end;

function TViewSettingsSimple.MakeDefaultSettings: TSettingsSimple;
begin
  Result.Name:= DefaultSeqName;
  Result.Rounds:= DefaultRounds;
  Result.RoundSeconds:= DefaultRoundSeconds;
  Result.RestSeconds:= DefaultRestSeconds;
  Result.PrepareSeconds:= DefaultPrepareSeconds;
  Result.WarningSeconds:= DefaultWarningSeconds;
  Result.Warning:= DefaultWarning;
end;

function TViewSettingsSimple.MakePeriods(AIndex: Integer): TPeriodsSettings;
var
 i, lastPeriod: Integer;
begin
  { prepare Result list }
  Result.Name:= FSettingsSimpleList[AIndex].Name;
  Result.Periods:= [];
  SetLength(Result.Periods, FSettingsSimpleList[AIndex].Rounds * 2);

  Result.Periods[0].Name:= 'Prepare';
  Result.Periods[0].Enable:= True;
  Result.Periods[0].DurationSec:= FSettingsSimpleList[AIndex].PrepareSeconds;
  Result.Periods[0].WarningSec:= FSettingsSimpleList[AIndex].WarningSeconds;
  Result.Periods[0].Warning:= FSettingsSimpleList[AIndex].Warning;
  Result.Periods[0].Color:= DefaultColorPrepare;
  Result.Periods[0].SoundStart:= TSoundType.Init;
  Result.Periods[0].SoundEnding:= TSoundType.Start;

  lastPeriod:= FSettingsSimpleList[AIndex].Rounds * 2 - 1;

  for i:= 1 to lastPeriod do
  begin
    Result.Periods[i].Enable:= True;
    Result.Periods[i].WarningSec:= FSettingsSimpleList[AIndex].WarningSeconds;
    Result.Periods[i].Warning:= FSettingsSimpleList[AIndex].Warning;

    if ((i mod 2) = 0) then
    begin
      Result.Periods[i].Name:= 'Rest before Round ' + IntToStr((i div 2) + 1) + ' / ' + IntToStr(FSettingsSimpleList[AIndex].Rounds);
      Result.Periods[i].DurationSec:= FSettingsSimpleList[AIndex].RestSeconds;
      Result.Periods[i].Color:= DefaultColorRest;
      Result.Periods[i].SoundStart:= TSoundType.None;
      Result.Periods[i].SoundEnding:= TSoundType.None;
    end
    else
    begin
      Result.Periods[i].Name:= 'Round ' + IntToStr((i div 2) + 1) + ' / ' + IntToStr(FSettingsSimpleList[AIndex].Rounds);
      Result.Periods[i].DurationSec:= FSettingsSimpleList[AIndex].RoundSeconds;
      Result.Periods[i].Color:= DefaultColorRound;
      Result.Periods[i].SoundStart:= TSoundType.Start;
      if (i = lastPeriod) then
        Result.Periods[i].SoundEnding:= TSoundType.Final
      else
        Result.Periods[i].SoundEnding:= TSoundType.Ending;
    end;
  end;
end;

procedure TViewSettingsSimple.ControlHover(const Sender: TCastleUserInterface);
begin
  PlaySfx(TSfxType.PointerHover);
end;

procedure TViewSettingsSimple.ButtonSeqControlClick(Sender: TObject);
var
  component: TComponent;
  idx, i: Integer;
  list: TStringArray;
begin
  if (NOT (Sender is TComponent)) then Exit;
  PlaySfx(TSfxType.ClickEdit);

  idx:= IndexSeq;
  component:= Sender as TComponent;
  case component.Name of
    'ButtonSeqSelect':
    begin
      SetLength(list, Length(FSettingsSimpleList));

      for i:= 0 to High(FSettingsSimpleList) do
        list[i]:= FSettingsSimpleList[i].Name;

      if NOT (Container.CurrentFrontView is TSeqListBox) then
        Container.PushView(TSeqListBox.CreateUntilStopped(list,
          'Select Sequence', {$ifdef FPC}@{$endif}DoSelectSeq));
    end;
    'ButtonSeqAdd':
    begin
      SetLength(FSettingsSimpleList, (Length(FSettingsSimpleList) + 1));
      idx:= High(FSettingsSimpleList);
      FSettingsSimpleList[idx]:= MakeDefaultSettings;
      FSettingsSimpleList[idx].Name:= FSettingsSimpleList[idx].Name + ' ' +
                                      IntToStr(idx);
    end;
    'ButtonSeqRemove':
    begin
      if (Length(FSettingsSimpleList) > 1) then
      begin
        if NOT (Container.CurrentFrontView is TSeqConfirm) then
          Container.PushView(TSeqConfirm.CreateUntilStopped(
            ['Do You want to Remove ',
             '"' + FSettingsSimpleList[idx].Name + '"'],
            'Question', {$ifdef FPC}@{$endif}DoRemoveSeq));
      end;
    end;
    'ButtonSeqCopy':
    begin
      if ((Length(FSettingsSimpleList) > 0) AND (IndexSeq > -1)) then
      begin
        SetLength(FSettingsSimpleList, (Length(FSettingsSimpleList) + 1));
        idx:= High(FSettingsSimpleList);
        FSettingsSimpleList[idx]:= FSettingsSimpleList[IndexSeq];
        FSettingsSimpleList[idx].Name:= FSettingsSimpleList[idx].Name + ' Copy';
      end;
    end;
  end;

  IndexSeq:= idx;
end;

procedure TViewSettingsSimple.ButtonSeqEditClick(Sender: TObject);
var
  component: TComponent;
  check: TCastleCheckBox;
begin
  if (NOT (Sender is TComponent)) then Exit;

  component:= Sender as TComponent;
  case component.Name of
    'ButtonSeqName':
    begin
      PlaySfx(TSfxType.ClickEdit);
      if NOT (Container.CurrentFrontView is TSeqEditString) then
        Container.PushView(TSeqEditString.CreateUntilStopped(
          FSettingsSimpleList[IndexSeq].Name,
          'Sequence Name', {$ifdef FPC}@{$endif}DoEditName));
    end;
    'ButtonRounds':
    begin
      PlaySfx(TSfxType.ClickEdit);
      if NOT (Container.CurrentFrontView is TSeqEditInteger) then
        Container.PushView(TSeqEditInteger.CreateUntilStopped(
          FSettingsSimpleList[IndexSeq].Rounds, 1, 99,
          'Rounds', {$ifdef FPC}@{$endif}DoEditRound));
    end;
    'ButtonRoundTime':
    begin
      PlaySfx(TSfxType.ClickEdit);
      if NOT (Container.CurrentFrontView is TSeqEditTime) then
        Container.PushView(TSeqEditTime.CreateUntilStopped(
          FSettingsSimpleList[IndexSeq].RoundSeconds,
          'Round Time', {$ifdef FPC}@{$endif}DoEditRoundTime));
    end;
    'ButtonRestTime':
    begin
      PlaySfx(TSfxType.ClickEdit);
      if NOT (Container.CurrentFrontView is TSeqEditTime) then
        Container.PushView(TSeqEditTime.CreateUntilStopped(
          FSettingsSimpleList[IndexSeq].RestSeconds,
          'Rest Time', {$ifdef FPC}@{$endif}DoEditRestTime));
    end;
    'ButtonPrepareTime':
    begin
      PlaySfx(TSfxType.ClickEdit);
      if NOT (Container.CurrentFrontView is TSeqEditTime) then
        Container.PushView(TSeqEditTime.CreateUntilStopped(
          FSettingsSimpleList[IndexSeq].PrepareSeconds,
          'Prepare Time', {$ifdef FPC}@{$endif}DoEditPrepareTime));
    end;
    'ButtonWarningTime':
    begin
      PlaySfx(TSfxType.ClickEdit);
      if NOT (Container.CurrentFrontView is TSeqEditTime) then
        Container.PushView(TSeqEditTime.CreateUntilStopped(
          FSettingsSimpleList[IndexSeq].WarningSeconds,
          'Warning Time', {$ifdef FPC}@{$endif}DoEditWarningTime));
    end;
    'CheckWarning':
    begin
      PlaySfx(TSfxType.Check);
      check:= component as TCastleCheckBox;
      FSettingsSimpleList[IndexSeq].Warning:= check.Checked;
    end;
  end;
end;

procedure TViewSettingsSimple.ButtonActionClick(Sender: TObject);
var
  component: TComponent;
begin
  if (NOT (Sender is TComponent)) then Exit;

  component:= Sender as TComponent;
  case component.Name of
    'ButtonStart':
    begin
      PlaySfx(TSfxType.ClickStart);
      ViewSequenceTimer.ReturnTo:= self;
      ViewSequenceTimer.Periods:= MakePeriods(IndexSeq);
      Container.View:= ViewSequenceTimer;
    end;
    'ButtonAbout':
      if NOT (Container.CurrentFrontView is TSeqAbout) then
      begin
        PlaySfx(TSfxType.ClickAction);
        Container.PushView(TSeqAbout.CreateUntilStopped);
      end;
    'ButtonMode':
    begin
      PlaySfx(TSfxType.ClickMode);
      Container.View:= ViewSettingsPro;
    end;
  end;
end;

procedure TViewSettingsSimple.DoSelectSeq(AValue: Integer);
begin
  IndexSeq:= AValue;
end;

procedure TViewSettingsSimple.DoRemoveSeq(Sender: TObject);
begin
  Delete(FSettingsSimpleList, IndexSeq, 1);
  IndexSeq:= 0;
end;

procedure TViewSettingsSimple.DoEditName(AValue: String);
begin
  FSettingsSimpleList[IndexSeq].Name:= AValue;
  ButtonSeqName.Caption:= AValue;
end;

procedure TViewSettingsSimple.DoEditRound(AValue: Integer);
begin
  FSettingsSimpleList[IndexSeq].Rounds:= AValue;
  ButtonRounds.Caption:= IntToStr(AValue);
  ShowStatistic;
end;

procedure TViewSettingsSimple.DoEditRoundTime(ASeconds: Integer);
begin
  FSettingsSimpleList[IndexSeq].RoundSeconds:= ASeconds;
  ButtonRoundTime.Caption:= TimeToShortStr(ASeconds);
  ShowStatistic;
end;

procedure TViewSettingsSimple.DoEditRestTime(ASeconds: Integer);
begin
  FSettingsSimpleList[IndexSeq].RestSeconds:= ASeconds;
  ButtonRestTime.Caption:= TimeToShortStr(ASeconds);
  ShowStatistic;
end;

procedure TViewSettingsSimple.DoEditPrepareTime(ASeconds: Integer);
begin
  FSettingsSimpleList[IndexSeq].PrepareSeconds:= ASeconds;
  ButtonPrepareTime.Caption:= TimeToShortStr(ASeconds);
  ShowStatistic;
end;

procedure TViewSettingsSimple.DoEditWarningTime(ASeconds: Integer);
begin
  FSettingsSimpleList[IndexSeq].WarningSeconds:= ASeconds;
  ButtonWarningTime.Caption:= TimeToShortStr(ASeconds);
end;

procedure TViewSettingsSimple.Update(const SecondsPassed: Single; var HandleInput: Boolean);
begin
  inherited;
  Assert(LabelFps <> nil, 'If you remove LabelFps from the design, remember to remove also the assignment "LabelFps.Caption := ..." from code');
  LabelFps.Caption := 'FPS: ' + Container.Fps.ToString;
end;

procedure TViewSettingsSimple.DoAferLoad(Sender: TObject);
begin
  { appearing background }
  FlashEffect.Duration:= 0.75;
  FlashEffect.Flash(Black, True);
  { appearing menus }
  ExhibiterControl.ExecuteOnce:= True;
end;

procedure TViewSettingsSimple.SetIndexSeq(AValue: Integer);
begin
  if ((AValue >= Low(FSettingsSimpleList)) AND (AValue <= High(FSettingsSimpleList))) then
  begin
    FIndexSeq:= AValue;
    UpdateSettings;
  end;
end;

function TViewSettingsSimple.GetIndexSeq: Integer;
begin
  Result:= FIndexSeq;
end;

end.
