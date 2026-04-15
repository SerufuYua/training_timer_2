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
    procedure DoEditPeriod(AValue: TTimePeriod);
    function MakeDefaultPeriods: TPeriodsSettings;
    procedure LoadSettings;
    procedure SaveSettings;
    procedure UpdateListLength;
    procedure UpdateListContent;
    procedure ShowStatistic;
    procedure SetIndexSeq(AValue: Integer);
    function GetIndexSeq: Integer;
    procedure ButtonSeqControlClick(Sender: TObject);
    procedure ButtonSeqEditClick(Sender: TObject);
    procedure ButtonActionClick(Sender: TObject);
    procedure CheckPeriod(Sender: TObject; AIndex: Integer; ACheck: Boolean);
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
  SysUtils, CastleConfig, CastleColors, GameViewSettingsSimple, MyUtils,
  GameSound, SeqAbout, SeqListBox, SeqEditString, SeqEditPeriod;

const
  DefaultPeriodName = 'New Period';
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
  ListPeriods.OnClickSecond:= {$ifdef FPC}@{$endif}ButtonSeqEditClick;
  ListPeriods.OnCheck:= {$ifdef FPC}@{$endif}CheckPeriod;

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
  Result.Periods[0].DurationSec:= DefaultPrepareSeconds;
  Result.Periods[0].WarningSec:= DefaultWarningSeconds;
  Result.Periods[0].Warning:= DefaultWarning;
  Result.Periods[0].Color:= DefaultColorPrepare;
  Result.Periods[0].SoundStart:= TSoundType.Init;
  Result.Periods[0].SoundEnding:= TSoundType.Start;

  for i:= 1 to lastPeriod do
  begin
    Result.Periods[i].Enable:= True;
    Result.Periods[i].WarningSec:= DefaultWarningSeconds;
    Result.Periods[i].Warning:= DefaultWarning;

    if ((i mod 2) = 0) then
    begin
      Result.Periods[i].Name:= 'Rest before Round ' + IntToStr((i div 2) + 1) + ' / ' + IntToStr(DefaultRounds);
      Result.Periods[i].DurationSec:= DefaultRestSeconds;
      Result.Periods[i].Color:= DefaultColorRest;
      Result.Periods[i].SoundStart:= TSoundType.None;
      Result.Periods[i].SoundEnding:= TSoundType.None;
    end
    else
    begin
      Result.Periods[i].Name:= 'Round ' + IntToStr((i div 2) + 1) + ' / ' + IntToStr(DefaultRounds);
      Result.Periods[i].DurationSec:= DefaultRoundSeconds;
      Result.Periods[i].Color:= DefaultColorRound;
      Result.Periods[i].SoundStart:= TSoundType.Start;
      if (i = lastPeriod) then
        Result.Periods[i].SoundEnding:= TSoundType.Final
      else
        Result.Periods[i].SoundEnding:= TSoundType.Ending;
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
        FSettingsProList[i].Periods[j].DurationSec:= UserConfig.GetValue(pathPeriod + SecondsStr, DefaultRoundSeconds);
        FSettingsProList[i].Periods[j].WarningSec:= UserConfig.GetValue(pathPeriod + WarningSecondsStr, DefaultWarningSeconds);
        FSettingsProList[i].Periods[j].Warning:= UserConfig.GetValue(pathPeriod + WarningStr, DefaultWarning);
        FSettingsProList[i].Periods[j].SoundStart:= TSoundType(UserConfig.GetValue(pathPeriod + StartSoundStr, Ord(DefaultStartSound)));
        FSettingsProList[i].Periods[j].SoundEnding:= TSoundType(UserConfig.GetValue(pathPeriod + FinalSoundStr, Ord(DefaultEndingSound)));
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

      if (FSettingsProList[i].Periods[j].DurationSec <> DefaultRoundSeconds) then
        UserConfig.SetValue(pathPeriod + SecondsStr, FSettingsProList[i].Periods[j].DurationSec);

      if (FSettingsProList[i].Periods[j].WarningSec <> DefaultWarningSeconds) then
        UserConfig.SetValue(pathPeriod + WarningSecondsStr, FSettingsProList[i].Periods[j].WarningSec);

      if (FSettingsProList[i].Periods[j].Warning <> DefaultWarning) then
        UserConfig.SetValue(pathPeriod + WarningStr, FSettingsProList[i].Periods[j].Warning);

      if (FSettingsProList[i].Periods[j].SoundStart <> DefaultStartSound) then
        UserConfig.SetValue(pathPeriod + StartSoundStr, Ord(FSettingsProList[i].Periods[j].SoundStart));

      if (FSettingsProList[i].Periods[j].SoundEnding <> DefaultEndingSound) then
        UserConfig.SetValue(pathPeriod + FinalSoundStr, Ord(FSettingsProList[i].Periods[j].SoundEnding));

      if NOT TVector3.Equals(FSettingsProList[i].Periods[j].Color, DefaultColorPrepare) then
        UserConfig.SetColorRGB(pathPeriod + ColorStr, FSettingsProList[i].Periods[j].Color);
    end;
  end;

  UserConfig.SetValue(SettingsStor + '/' + NumSeqStr, IndexSeq);
  UserConfig.SetValue(MainStor + '/' + ModeStr, ModeThis);

  UserConfig.Save;
end;

procedure TViewSettingsPro.UpdateListLength;
var
  i, idx, len, pos: integer;
  StrList: TStringList;
begin
  ButtonSeqName.Caption:= FSettingsProList[IndexSeq].Name;

  if (ListPeriods.List is TStringList) then
  begin
    StrList:= ListPeriods.List as TStringList;
    idx:= ListPeriods.Index;
    i:= 0;

    { sync ListPeriods.List and Periods Length }
    len:= Length(FSettingsProList[IndexSeq].Periods);
    if (StrList.Count < len) then { increase List }
    begin
      len:= len - StrList.Count;
      for i:= 1 to len do
        StrList.Add('empty');
    end
    else if (StrList.Count > len) then { decrease List }
    begin
      len:= StrList.Count - len;
      for i:= 1 to len do
        StrList.Delete(StrList.Count - 1);

      pos:= High(FSettingsProList[IndexSeq].Periods);
      if (idx > pos) then
        ListPeriods.Index:= pos;
    end;

    UpdateListContent;
  end;

  ShowStatistic;
end;

procedure TViewSettingsPro.UpdateListContent;
var
  i: integer;
  StrList: TStringList;
  Period: TTimePeriod;
begin
  if (ListPeriods.List is TStringList) then
  begin
    StrList:= ListPeriods.List as TStringList;
    for i:= 0 to High(FSettingsProList[IndexSeq].Periods) do
    begin
      Period:= FSettingsProList[IndexSeq].Periods[i];
      StrList[i]:= TimeToShortStr(Period.DurationSec) + ' ' + Period.Name;
      ListPeriods.SetCheck(i, Period.Enable);
      ListPeriods.SetColor(i, Vector4(Period.Color, 1.0));
    end;
  end;
end;

procedure TViewSettingsPro.ShowStatistic;
var
  sec: Integer;
  Period: TTimePeriod;
begin
  sec:= 0;
  for Period in FSettingsProList[IndexSeq].Periods do
    if Period.Enable then
      sec:= sec + Period.DurationSec;

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
  idx: Integer;
  component: TComponent;
  period: TTimePeriod;
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
      if ((ListPeriods.Index > -1) AND
          (ListPeriods.Index < Length(FSettingsProList[IndexSeq].Periods))) then
        idx:= ListPeriods.Index + 1
      else
        idx:= Length(FSettingsProList[IndexSeq].Periods);

      period.Name:= DefaultPeriodName + ' ' + IntToStr(idx);
      period.Color:= DefaultColorRest;
      period.Enable:= True;
      period.SoundStart:= TSoundType.None;
      period.SoundEnding:= DefaultEndingSound;
      period.DurationSec:= DefaultRestSeconds;
      period.Warning:= True;
      period.WarningSec:= DefaultWarningSeconds;

      System.Insert(period, FSettingsProList[IndexSeq].Periods, idx);
      ListPeriods.LineInsert(idx, period.Enable, period.Color, TimeToShortStr(Period.DurationSec) + ' ' + period.Name);

      ListPeriods.Index:= idx;
      ShowStatistic;
    end;
    'ButtonPeriodUp':
    begin
      if ((ListPeriods.Index > -1) AND
          (ListPeriods.Index < Length(FSettingsProList[IndexSeq].Periods))) then
      begin
        period:= FSettingsProList[IndexSeq].Periods[ListPeriods.Index - 1];
        FSettingsProList[IndexSeq].Periods[ListPeriods.Index - 1]:=
          FSettingsProList[IndexSeq].Periods[ListPeriods.Index];
        FSettingsProList[IndexSeq].Periods[ListPeriods.Index]:= period;

        ListPeriods.LineSwap(ListPeriods.Index, ListPeriods.Index - 1);
        ListPeriods.Index:= ListPeriods.Index - 1;
      end;
    end;
    'ButtonPeriodDown':
    begin
      if ((ListPeriods.Index > -1) AND
          (ListPeriods.Index < Length(FSettingsProList[IndexSeq].Periods))) then
      begin
        period:= FSettingsProList[IndexSeq].Periods[ListPeriods.Index + 1];
        FSettingsProList[IndexSeq].Periods[ListPeriods.Index + 1]:=
          FSettingsProList[IndexSeq].Periods[ListPeriods.Index];
        FSettingsProList[IndexSeq].Periods[ListPeriods.Index]:= period;

        ListPeriods.LineSwap(ListPeriods.Index, ListPeriods.Index + 1);
        ListPeriods.Index:= ListPeriods.Index + 1;
      end;
    end;
    'ButtonPeriodEdit', 'ListPeriods':
    begin
      if ((ListPeriods.Index > -1) AND
          (ListPeriods.Index < Length(FSettingsProList[IndexSeq].Periods))) then
      begin
        if NOT (Container.FrontView is TSeqEditPeriod) then
          Container.PushView(TSeqEditPeriod.CreateUntilStopped(
            FSettingsProList[IndexSeq].Periods[ListPeriods.Index],
            'Edit Period', {$ifdef FPC}@{$endif}DoEditPeriod));
      end;
    end;
    'ButtonPeriodRemove':
    begin
      idx:= ListPeriods.Index;
      if ((idx > -1) AND
          (idx < Length(FSettingsProList[IndexSeq].Periods))) then
      begin
        Delete(FSettingsProList[IndexSeq].Periods, idx, 1);

        ListPeriods.LineDelete(idx);

        if (idx > High(FSettingsProList[IndexSeq].Periods)) then
          idx:= High(FSettingsProList[IndexSeq].Periods);
        ListPeriods.Index:= idx;
        ShowStatistic;
      end;
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

procedure TViewSettingsPro.CheckPeriod(Sender: TObject; AIndex: Integer; ACheck: Boolean);
begin
  FSettingsProList[IndexSeq].Periods[AIndex].Enable:= ACheck;
  ShowStatistic;
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

procedure TViewSettingsPro.DoEditPeriod(AValue: TTimePeriod);
begin
  if ((ListPeriods.Index > -1) AND
      (ListPeriods.Index < Length(FSettingsProList[IndexSeq].Periods))) then
  begin
    FSettingsProList[IndexSeq].Periods[ListPeriods.Index]:= AValue;

    ListPeriods.List[ListPeriods.Index]:= TimeToShortStr(AValue.DurationSec) + ' ' + AValue.Name;
    ListPeriods.SetCheck(ListPeriods.Index, AValue.Enable);
    ListPeriods.SetColor(ListPeriods.Index, Vector4(AValue.Color, 1.0));
    ShowStatistic;
  end;
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
    UpdateListLength;
    ListPeriods.Index:= -1;
  end;
end;

function TViewSettingsPro.GetIndexSeq: Integer;
begin
  Result:= FIndexSeq;
end;

end.
