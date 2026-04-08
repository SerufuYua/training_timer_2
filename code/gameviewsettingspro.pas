unit GameViewSettingsPro;

interface

uses Classes,
  CastleVectors, CastleUIControls, CastleControls, CastleKeysMouse,
  CastleFlashEffect, SeqExhibiter, CastleCheckColorListBox,
  GameViewSequenceTimer;

type
  TViewSettingsPro = class(TCastleView)
  protected
    FSettingsProList: TPeriodsSettingsList;
    FIndexSeq: Integer;
    procedure DoAferLoad(Sender: TObject);
    procedure DoSelectSeq(AValue: Integer);
    procedure DoEditName(AValue: String);
    function MakeDefaultPeriods: TPeriodsSettings;
    procedure LoadSettings;
    procedure SaveSettings;
    procedure UpdateListPeriods;
    procedure ShowStatistic;
    procedure SetIndexSeq(AValue: Integer);
    function GetIndexSeq: Integer;
    procedure ButtonSeqControlClick(Sender: TObject);
    procedure ButtonSeqEditClick(Sender: TObject);
    procedure ButtonActionClick(Sender: TObject);
  published
    FlashEffect: TCastleFlashEffect;
    ExhibiterControl: TSeqExhibiter;
    ListPeriods: TCastleCheckColorListBox;
    ButtonSeqSelect, ButtonSeqAdd, ButtonSeqRemove, ButtonSeqCopy: TCastleButton;
    ButtonSeqName, ButtonPeriodAdd, ButtonPeriodUp, ButtonPeriodDown,
      ButtonPeriodEdit, ButtonPeriodRemove : TCastleButton;
    ButtonStart, ButtonAbout, ButtonMode: TCastleButton;
    ImageSettings, ImageActions: TCastleImageControl;
    LabelOveralTimeValue: TCastleLabel;
    LabelFps: TCastleLabel;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Start; override;
    procedure Stop; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;

    property IndexSeq: Integer read GetIndexSeq write SetIndexSeq;
  end;

var
  ViewSettingsPro: TViewSettingsPro;

implementation

uses
  SysUtils, CastleConfig, CastleColors, GameViewSettingsSimple, MyTimes,
  GameSound, SeqAbout, SeqListBox, SeqEditString;

const
  MainStor = 'main';
  ModeStr = 'mode';
  ModeThis = 'Pro';
  SettingsStor = 'SettingsPro';
  NameStr = 'Name';
  SeqStr = 'Seq';
  CountSeqsStr = 'CountSeqs';
  NumSeqStr = 'NumSeq';
  CountPeriodsStr = 'CountPeriods';
  PeriodStr = 'Period';
  EnableStr = 'Enable';
  SecondsStr = 'Seconds';
  WarningSecondsStr = 'WarningSeconds';
  WarningStr = 'Warning';
  StartSoundStr = 'StartSound';
  FinalSoundStr = 'FinalSound';
  ColorStr = 'Color';

  constructor TViewSettingsPro.Create(AOwner: TComponent);
begin
  inherited;
  FIndexSeq:= 0;
  DesignUrl := 'castle-data:/gameviewsettingspro.castle-user-interface';
end;

procedure TViewSettingsPro.Start;
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

  { Sequence edit buttons }
  ButtonSeqName.OnClick:=      {$ifdef FPC}@{$endif}ButtonSeqEditClick;
  ButtonPeriodAdd.OnClick:=    {$ifdef FPC}@{$endif}ButtonSeqEditClick;
  ButtonPeriodUp.OnClick:=     {$ifdef FPC}@{$endif}ButtonSeqEditClick;
  ButtonPeriodDown.OnClick:=   {$ifdef FPC}@{$endif}ButtonSeqEditClick;
  ButtonPeriodEdit.OnClick:=   {$ifdef FPC}@{$endif}ButtonSeqEditClick;
  ButtonPeriodRemove.OnClick:= {$ifdef FPC}@{$endif}ButtonSeqEditClick;

  { Actions buttons }
  ButtonStart.OnClick:= {$ifdef FPC}@{$endif}ButtonActionClick;
  ButtonAbout.OnClick:= {$ifdef FPC}@{$endif}ButtonActionClick;
  ButtonMode.OnClick:=  {$ifdef FPC}@{$endif}ButtonActionClick;

  { Show start animation }
  FlashEffect.Duration:= 6.0;
  FlashEffect.Flash(Black, True);
  WaitForRenderAndCall({$ifdef FPC}@{$endif}DoAferLoad);
end;

procedure TViewSettingsPro.Stop;
begin
  inherited;
  SaveSettings;
end;

function TViewSettingsPro.MakeDefaultPeriods: TPeriodsSettings;
var
  i: Integer;
const
  lastPeriod = DefaultRounds * 2 - 1;
begin
  { prepare periods list }
  Result.Name:= DefaultSeqName;
  Result.Periods:= [];
  SetLength(Result.Periods, DefaultRounds * 2);

  Result.Periods[0].Name:= 'Prepare';
  Result.Periods[0].Enable:= True;
  Result.Periods[0].Seconds:= DefaultRoundSeconds;
  Result.Periods[0].WarningSeconds:= DefaultWarningSeconds;
  Result.Periods[0].Warning:= DefaultWarning;
  Result.Periods[0].Color:= DefaultColorPrepare;
  Result.Periods[0].StartSound:= TSoundType.Init;
  Result.Periods[0].FinalSound:= TSoundType.Start;

  for i:= 1 to lastPeriod do
  begin
    Result.Periods[i].Enable:= True;
    Result.Periods[i].WarningSeconds:= DefaultWarningSeconds;
    Result.Periods[i].Warning:= DefaultWarning;

    if ((i mod 2) = 0) then
    begin
      Result.Periods[i].Name:= 'Rest before Round ' + IntToStr((i div 2) + 1) + ' / ' + IntToStr(DefaultRounds);
      Result.Periods[i].Seconds:= DefaultRestSeconds;
      Result.Periods[i].Color:= DefaultColorRest;
      Result.Periods[i].StartSound:= TSoundType.None;
      Result.Periods[i].FinalSound:= TSoundType.None;
    end
    else
    begin
      Result.Periods[i].Name:= 'Round ' + IntToStr((i div 2) + 1) + ' / ' + IntToStr(DefaultRounds);
      Result.Periods[i].Seconds:= DefaultRoundSeconds;
      Result.Periods[i].Color:= DefaultColorRound;
      Result.Periods[i].StartSound:= TSoundType.Start;
      if (i = lastPeriod) then
        Result.Periods[i].FinalSound:= TSoundType.Final
      else
        Result.Periods[i].FinalSound:= TSoundType.Ending;
    end;
  end;
end;

procedure TViewSettingsPro.LoadSettings;
var
  i, j, num, countPeriods: Integer;
  path, pathPeriod: String;
begin
  num:= UserConfig.GetValue(SettingsStor + '/' + CountSeqsStr, 0);

  if (num > 0) then
  begin
    SetLength(FSettingsProList, num);

    for i:= 0 to (num - 1) do
    begin
      path:= SettingsStor + '/' + SeqStr + IntToStr(i) + '/';

      FSettingsProList[i].Name:= UserConfig.GetValue(path + NameStr, SeqStr + ' ' + IntToStr(i + 1));

      countPeriods:= UserConfig.GetValue(path + CountPeriodsStr, 0);
      SetLength(FSettingsProList[i].Periods, countPeriods);
      for j:= 0 to (countPeriods - 1) do
      begin
        pathPeriod:= path + PeriodStr + IntToStr(j) + '/';
        FSettingsProList[i].Periods[j].Name:= UserConfig.GetValue(pathPeriod + NameStr, PeriodStr + ' ' + IntToStr(j + 1));
        FSettingsProList[i].Periods[j].Enable:= UserConfig.GetValue(pathPeriod + EnableStr, DefaultEnable);
        FSettingsProList[i].Periods[j].Seconds:= UserConfig.GetValue(pathPeriod + SecondsStr, DefaultRoundSeconds);
        FSettingsProList[i].Periods[j].WarningSeconds:= UserConfig.GetValue(pathPeriod + WarningSecondsStr, DefaultWarningSeconds);
        FSettingsProList[i].Periods[j].Warning:= UserConfig.GetValue(pathPeriod + WarningStr, DefaultWarning);
        FSettingsProList[i].Periods[j].StartSound:= TSoundType(UserConfig.GetValue(pathPeriod + StartSoundStr, Ord(DefaultStartSound)));
        FSettingsProList[i].Periods[j].FinalSound:= TSoundType(UserConfig.GetValue(pathPeriod + FinalSoundStr, Ord(DefaultFinalSound)));
        FSettingsProList[i].Periods[j].Color:= UserConfig.GetColorRGB(pathPeriod + ColorStr, DefaultColorPrepare);
      end;
    end;

    IndexSeq:= UserConfig.GetValue(SettingsStor + '/' + NumSeqStr, IndexSeq);
  end
  else
  begin
    SetLength(FSettingsProList, 1);
    FSettingsProList[0]:= MakeDefaultPeriods;
    IndexSeq:= 0;
  end
end;

procedure TViewSettingsPro.SaveSettings;
var
  i, j: Integer;
  path, pathPeriod: String;
begin
  UserConfig.DeletePath(SettingsStor);

  UserConfig.SetValue(SettingsStor + '/' + CountSeqsStr, Length(FSettingsProList));

  for i:= 0 to High(FSettingsProList) do
  begin
    path:= SettingsStor + '/' + SeqStr + IntToStr(i) + '/';
    UserConfig.SetValue(path + NameStr, FSettingsProList[i].Name);
    UserConfig.SetValue(path + CountPeriodsStr, Length(FSettingsProList[i].Periods));

    for j:= 0 to High(FSettingsProList[i].Periods) do
    begin
      pathPeriod:= path + PeriodStr + IntToStr(j) + '/';

      UserConfig.SetValue(pathPeriod + NameStr, FSettingsProList[i].Periods[j].Name);

      if (FSettingsProList[i].Periods[j].Enable <> DefaultEnable) then
        UserConfig.SetValue(pathPeriod + EnableStr, FSettingsProList[i].Periods[j].Enable);

      if (FSettingsProList[i].Periods[j].Seconds <> DefaultRoundSeconds) then
        UserConfig.SetValue(pathPeriod + SecondsStr, FSettingsProList[i].Periods[j].Seconds);

      if (FSettingsProList[i].Periods[j].WarningSeconds <> DefaultWarningSeconds) then
        UserConfig.SetValue(pathPeriod + WarningSecondsStr, FSettingsProList[i].Periods[j].WarningSeconds);

      if (FSettingsProList[i].Periods[j].Warning <> DefaultWarning) then
        UserConfig.SetValue(pathPeriod + WarningStr, FSettingsProList[i].Periods[j].Warning);

      if (FSettingsProList[i].Periods[j].StartSound <> DefaultStartSound) then
        UserConfig.SetValue(pathPeriod + StartSoundStr, Ord(FSettingsProList[i].Periods[j].StartSound));

      if (FSettingsProList[i].Periods[j].FinalSound <> DefaultFinalSound) then
        UserConfig.SetValue(pathPeriod + FinalSoundStr, Ord(FSettingsProList[i].Periods[j].FinalSound));

      if NOT TVector3.Equals(FSettingsProList[i].Periods[j].Color, DefaultColorPrepare) then
        UserConfig.SetColorRGB(pathPeriod + ColorStr, FSettingsProList[i].Periods[j].Color);
    end;
  end;

  UserConfig.SetValue(SettingsStor + '/' + NumSeqStr, IndexSeq);
  UserConfig.SetValue(MainStor + '/' + ModeStr, ModeThis);

  UserConfig.Save;
end;

procedure TViewSettingsPro.UpdateListPeriods;
var
  i: integer;
  Period: TTimePeriod;
begin
  ButtonSeqName.Caption:= FSettingsProList[IndexSeq].Name;

  { TODO: compose new periods list }

  i:= 0;
  ListPeriods.List.Clear;
  for Period in FSettingsProList[IndexSeq].Periods do
  begin
    ListPeriods.List.Add(TimeToShortStr(Period.Seconds) + ' ' + Period.Name);
    ListPeriods.SetCheck(i, Period.Enable);
    ListPeriods.SetColor(i, Vector4(Period.Color, 1.0));
    i:= i + 1;
  end;
  ListPeriods.Index:= -1;

  ShowStatistic;
end;

procedure TViewSettingsPro.ShowStatistic;
var
  sec: Integer;
  Period: TTimePeriod;
begin
  sec:= 0;
  for Period in FSettingsProList[IndexSeq].Periods do
    sec:= sec + Period.Seconds;

  LabelOveralTimeValue.Caption:= TimeToFullStr(sec);
end;

procedure TViewSettingsPro.Update(const SecondsPassed: Single; var HandleInput: boolean);
begin
  inherited;
  Assert(LabelFps <> nil, 'If you remove LabelFps from the design, remember to remove also the assignment "LabelFps.Caption := ..." from code');
  LabelFps.Caption := 'FPS: ' + Container.Fps.ToString;
end;

procedure TViewSettingsPro.ButtonSeqControlClick(Sender: TObject);
var
  component: TComponent;
  idx, i: Integer;
  list: TStringArray;
begin
  if (NOT (Sender is TComponent)) then Exit;

  idx:= IndexSeq;
  component:= Sender as TComponent;
  case component.Name of
    'ButtonSeqSelect':
    begin
      SetLength(list, Length(FSettingsProList));

      for i:= 0 to High(FSettingsProList) do
        list[i]:= FSettingsProList[i].Name;

      if NOT (Container.FrontView is TSeqListBox) then
        Container.PushView(TSeqListBox.CreateUntilStopped(list,
          'Select Sequence', {$ifdef FPC}@{$endif}DoSelectSeq));
    end;
    'ButtonSeqAdd':
    begin
      SetLength(FSettingsProList, (Length(FSettingsProList) + 1));
      idx:= High(FSettingsProList);
      FSettingsProList[idx]:= MakeDefaultPeriods;
      FSettingsProList[idx].Name:= DefaultSeqName + ' ' + IntToStr(idx);
    end;
    'ButtonSeqRemove':
    begin
      if (Length(FSettingsProList) > 1) then
      begin
        Delete(FSettingsProList, idx, 1);
        idx:= 0;
      end;
    end;
    'ButtonSeqCopy':
    begin
      if ((Length(FSettingsProList) > 0) AND (IndexSeq > -1)) then
      begin
        SetLength(FSettingsProList, (Length(FSettingsProList) + 1));
        idx:= High(FSettingsProList);
        FSettingsProList[idx]:= FSettingsProList[IndexSeq];
        FSettingsProList[idx].Name:= FSettingsProList[idx].Name + ' Copy';
      end;
    end;
  end;

  IndexSeq:= idx;
end;

procedure TViewSettingsPro.ButtonSeqEditClick(Sender: TObject);
var
  component: TComponent;
  check: TCastleCheckBox;
begin
  if (NOT (Sender is TComponent)) then Exit;

  component:= Sender as TComponent;
  case component.Name of
    'ButtonSeqName':
    begin
      if NOT (Container.FrontView is TSeqEditString) then
        Container.PushView(TSeqEditString.CreateUntilStopped(
          FSettingsProList[IndexSeq].Name,
          'Sequence Name', {$ifdef FPC}@{$endif}DoEditName));
    end;
    'ButtonPeriodAdd':
    begin

    end;
    'ButtonPeriodUp':
    begin

    end;
    'ButtonPeriodDown':
    begin

    end;
    'ButtonPeriodEdit':
    begin

    end;
    'ButtonPeriodRemove':
    begin

    end;
  end;
end;

procedure TViewSettingsPro.ButtonActionClick(Sender: TObject);
var
  component: TComponent;
begin
  if (NOT (Sender is TComponent)) then Exit;

  component:= Sender as TComponent;
  case component.Name of
    'ButtonStart':
    begin
      ViewSequenceTimer.ReturnTo:= self;
      ViewSequenceTimer.Periods:= FSettingsProList[IndexSeq];
      Container.View:= ViewSequenceTimer;
    end;
    'ButtonAbout':
      if NOT (Container.FrontView is TSeqAbout) then
        Container.PushView(TSeqAbout.CreateUntilStopped);
    'ButtonMode':
      Container.View:= ViewSettingsSimple;
  end;
end;

procedure TViewSettingsPro.DoSelectSeq(AValue: Integer);
begin
  IndexSeq:= AValue;
end;

procedure TViewSettingsPro.DoEditName(AValue: String);
begin
  FSettingsProList[IndexSeq].Name:= AValue;
  ButtonSeqName.Caption:= AValue;
end;

procedure TViewSettingsPro.DoAferLoad(Sender: TObject);
begin
  { appearing background }
  FlashEffect.Duration:= 0.75;
  FlashEffect.Flash(Black, True);
  { appearing menus }
  ExhibiterControl.ExecuteOnce:= True;
end;

procedure TViewSettingsPro.SetIndexSeq(AValue: Integer);
begin
  if ((AValue >= Low(FSettingsProList)) AND (AValue <= High(FSettingsProList))) then
  begin
    FIndexSeq:= AValue;
    UpdateListPeriods;
  end;
end;

function TViewSettingsPro.GetIndexSeq: Integer;
begin
  Result:= FIndexSeq;
end;

end.
