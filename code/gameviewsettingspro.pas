unit GameViewSettingsPro;

interface

uses Classes,
  CastleVectors, CastleUIControls, CastleControls, CastleKeysMouse,
  CastleFlashEffect, SeqExhibiter, GameViewSequenceTimer;

type
  TViewSettingsPro = class(TCastleView)
  protected
    FSettingsProList: TPeriodsSettingsList;
    FIndexSeq: Integer;
    procedure DoAferLoad(Sender: TObject);
    procedure LoadSettings;
    procedure SaveSettings;
    procedure UpdateListPeriods;
    procedure ShowStatistic;
    procedure SetIndexSeq(AValue: Integer);
    function GetIndexSeq: Integer;
    procedure ButtonActionClick(Sender: TObject);
  published
    FlashEffect: TCastleFlashEffect;
    ExhibiterControl: TSeqExhibiter;
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
  SeqAbout;

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

  { Actions buttons }
  ButtonStart.OnClick:= {$ifdef FPC}@{$endif}ButtonActionClick;
  ButtonAbout.OnClick:= {$ifdef FPC}@{$endif}ButtonActionClick;
  ButtonMode.OnClick:= {$ifdef FPC}@{$endif}ButtonActionClick;

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

procedure TViewSettingsPro.LoadSettings;
begin

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

    UserConfig.SetValue(SettingsStor + '/' + CountPeriodsStr, Length(FSettingsProList[i].Periods));


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

      if (TVector3.Equals(FSettingsProList[i].Periods[j].Color, DefaultColorPrepare)) then
        UserConfig.SetValue(pathPeriod + ColorStr, FSettingsProList[i].Periods[j].Color.ToString);
    end;
  end;

  UserConfig.SetValue(SettingsStor + '/' + NumSeqStr, IndexSeq);
  UserConfig.SetValue(MainStor + '/' + ModeStr, ModeThis);

  UserConfig.Save;
end;

procedure TViewSettingsPro.UpdateListPeriods;
begin
  { TODO: compose new periods list }

  ShowStatistic;
end;

procedure TViewSettingsPro.ShowStatistic;
var
  sec: Integer;
begin
  sec:= 1000;

  LabelOveralTimeValue.Caption:= TimeToFullStr(sec);
end;

procedure TViewSettingsPro.Update(const SecondsPassed: Single; var HandleInput: boolean);
begin
  inherited;
  Assert(LabelFps <> nil, 'If you remove LabelFps from the design, remember to remove also the assignment "LabelFps.Caption := ..." from code');
  LabelFps.Caption := 'FPS: ' + Container.Fps.ToString;
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
      {ViewSequenceTimer.ReturnTo:= self;
      ViewSequenceTimer.Periods:= MakePeriods(IndexSeq);
      Container.View:= ViewSequenceTimer;}
    end;
    'ButtonAbout':
      if NOT (Container.FrontView is TSeqAbout) then
        Container.PushView(TSeqAbout.CreateUntilStopped);
    'ButtonMode':
      Container.View:= ViewSettingsSimple;
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
    UpdateListPeriods;
  end;
end;

function TViewSettingsPro.GetIndexSeq: Integer;
begin
  Result:= FIndexSeq;
end;

end.
