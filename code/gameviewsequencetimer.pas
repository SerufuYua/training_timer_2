unit GameViewSequenceTimer;

interface

uses Classes,
  CastleVectors, CastleUIControls, CastleControls, CastleFlashEffect,
  CastleKeysMouse, CastleColors, SeqExhibiter, SeqTunnelEffect, SeqPause,
  SeqLoadingBar, GameSound;

type
  TTimePeriod = record
    Name: String;
    FinalSound: TSoundType;
    Seconds, WarningSeconds: Integer;
    Warning, Enable: Boolean;
    Color: TCastleColorRGB;
  end;

  TPeriodsList = Array of TTimePeriod;

  TPeriodsSettings = record
    Name: String;
    Periods: TPeriodsList;
  end;

  TPeriodsSettingsList = Array of TPeriodsSettings;

  TViewSequenceTimer = class(TCastleView)
  protected
    FReturnTo: TCastleView;
    FEnabled: Boolean;
    FSpeedBuff, FSpeedCount: Single;
    FPeriods: TPeriodsList;
    FSequenceName: String;
    FPeriod: Integer;
    FElapsedSeconds, FStartPauseSeconds, FLastRemainingSeconds, FTargetSeconds,
      FPeriodSeconds, FWarningSeconds, FFullSeconds: Single;
    FWarning: Boolean;
    FFinalSound: TSoundType;
    FSignalColor: TCastleColorRGB;
    procedure DoAferLoad(Sender: TObject);
    procedure DoAferAnimation(Sender: TObject);
    procedure SetPeriods(AValue: TPeriodsSettings);
    procedure ResetTimer;
    procedure ShowColor(AValue: TCastleColorRGB; ATransition: Single);
    procedure ShowProgress(AValue: Single);
    procedure ShowTime(ASeconds: Single);
    procedure ShowFullTime(ASeconds: Single);
    procedure ButtonActionClick(Sender: TObject);
  published
    FlashEffect: TCastleFlashEffect;
    ExhibiterInfo, ExhibiterActions: TSeqExhibiter;
    ButtonStop, ButtonRestart, ButtonPause: TCastleButton;
    ImageTimer, ImageActions: TCastleImageControl;
    TunnelBG: TSeqTunnelEffect;
    LoadingBars: TSeqLoadingBar;
    LabelFps, LabelSequenceName, LabelPeriodName,
      LabelMin, LabelSec, LabelSecPart, LabelFullTime: TCastleLabel;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Start; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
    function Press(const Event: TInputPressRelease): Boolean; override;
    procedure SetupPeriod(AIndex: Integer);
    procedure NextPeriod;
    procedure Pause; override;
    procedure Resume; override;

    property Periods: TPeriodsSettings write SetPeriods;
    property ReturnTo: TCastleView write FReturnTo;
  end;

const
  DefaultSeqName = 'Time Sequence';
  DefaultPeriodName = 'Period';
  DefaultRounds = 2;
  DefaultRoundSeconds = 90;
  DefaultRestSeconds = 60;
  DefaultPrepareSeconds = 30;
  DefaultWarningSeconds = 10;
  DefaultWarning = True;
  DefaultEnable = True;
  DefaultFinalSound = TSoundType.Start;
  DefaultColorPrepare: TCastleColorRGB = (X: 0.0; Y: 1.0; Z: 0.0); { Lime }
  DefaultColorRest: TCastleColorRGB = (X: 1.0; Y: 1.0; Z: 0.0); { Yellow }
  DefaultColorRound: TCastleColorRGB = (X: 1.0; Y: 0.0; Z: 0.0); { Red }

var
  ViewSequenceTimer: TViewSequenceTimer;

implementation

uses
  SysUtils, MyTimes, CastleScene, CastleViewport;

constructor TViewSequenceTimer.Create(AOwner: TComponent);
begin
  inherited;
  DesignUrl := 'castle-data:/gameviewsequencetimer.castle-user-interface';
end;

procedure TViewSequenceTimer.Start;
var
  i: Integer;
begin
  inherited;

  FEnabled:= False;
  FSpeedCount:= 0.0;
  FSpeedBuff:= TunnelBG.Speed;
  ImageTimer.Exists:= False;
  ImageActions.Exists:= False;

  LabelSequenceName.Caption:= FSequenceName;
  FFullSeconds:= 0;
  for i:= Low(FPeriods) to High(FPeriods) do
    if FPeriods[i].Enable then
      FFullSeconds:= FFullSeconds + FPeriods[i].Seconds;

  { Actions buttons }
  ButtonStop.OnClick:= {$ifdef FPC}@{$endif}ButtonActionClick;
  ButtonRestart.OnClick:= {$ifdef FPC}@{$endif}ButtonActionClick;
  ButtonPause.OnClick:= {$ifdef FPC}@{$endif}ButtonActionClick;

  ExhibiterActions.OnFinish:= {$ifdef FPC}@{$endif}DoAferAnimation;

  { Show start animation }
  WaitForRenderAndCall({$ifdef FPC}@{$endif}DoAferLoad);
end;

procedure TViewSequenceTimer.Update(const SecondsPassed: Single; var HandleInput: boolean);
const
  initTime = 1.0;
var
  RemainingSeconds: Single;

function IsTime(thisTime: Single): Boolean; inline;
begin
  Result:= ((FLastRemainingSeconds >= thisTime) AND
            (RemainingSeconds < thisTime));
end;

begin
  inherited;
  Assert(LabelFps <> nil, 'If you remove LabelFps from the design, remember to remove also the assignment "LabelFps.Caption := ..." from code');
  LabelFps.Caption := 'FPS: ' + Container.Fps.ToString;

  if NOT FEnabled then Exit;
  FElapsedSeconds:= FElapsedSeconds + SecondsPassed * FSpeedCount;
  RemainingSeconds:= FTargetSeconds - FElapsedSeconds;

  { play warning and initial signals }
  if (FWarning AND IsTime(FWarningSeconds)) then
    Play(TSoundType.Warn)
  else
  if (IsTime(initTime * 1.0) OR
      IsTime(initTime * 2.0) OR
      IsTime(initTime * 3.0)) then
    Play(TSoundType.Init);

  { color blink initial signal }
  if (IsTime(initTime * 1.0) OR
      IsTime(initTime * 2.0) OR
      IsTime(initTime * 3.0)) then
    ShowColor(BlackRGB, 0.05)
  else
  if (IsTime(initTime * 1.0 - (initTime / 4.0)) OR
      IsTime(initTime * 2.0 - (initTime / 4.0)) OR
      IsTime(initTime * 3.0 - (initTime / 4.0))) then
    ShowColor(FSignalColor, 0.4);

  { color blink warning signal }
  if FWarning then
  begin
    if IsTime(FWarningSeconds) then
      ShowColor(GrayRGB, 0.05)
    else
    if ((FWarningSeconds > initTime) AND
        (IsTime(FWarningSeconds - (initTime / 2.0)))) then
      ShowColor(FSignalColor, 0.5);
  end;

  { count time and change period }
  if (RemainingSeconds > 0.0) then
  begin
    ShowTime(RemainingSeconds);
    ShowFullTime(FFullSeconds - FElapsedSeconds);
    ShowProgress(RemainingSeconds);
    LoadingBars.Value:= 1.0 - RemainingSeconds / FPeriodSeconds;
  end
  else
  begin
    ShowTime(0.0);
    Play(FFinalSound);
    NextPeriod;
  end;

  { remember Time Remaining }
  FLastRemainingSeconds:= RemainingSeconds;
end;

function TViewSequenceTimer.Press(const Event: TInputPressRelease): Boolean;
begin
  Result:= inherited;
  if Result then Exit; // allow the ancestor to handle keys

  { return pause }
  if (Event.IsKey(TKey.keyEscape) OR
      Event.IsKey(TKey.keySpace) OR
      Event.IsKey(TKey.keyPause) OR
      Event.IsKey(TKey.keyEnter)) then
  begin
    if NOT (Container.FrontView is TSeqPause) then
      Container.PushView(TSeqPause.CreateUntilStopped);
    Exit(True);
  end;
end;

procedure TViewSequenceTimer.SetPeriods(AValue: TPeriodsSettings);
begin
  FSequenceName:= AValue.Name;
  FPeriods:= AValue.Periods;
end;

procedure TViewSequenceTimer.ResetTimer;
begin
  FTargetSeconds:= 0;
  FElapsedSeconds:= 0;
  SetupPeriod(0);
  ButtonPause.Enabled:= True;
  ButtonPause.Caption:= 'Pause';
  Play(TSoundType.Init);
  FEnabled:= True;
end;

procedure TViewSequenceTimer.SetupPeriod(AIndex: Integer);
begin
  FPeriod:= AIndex;
  ShowTime(FPeriods[FPeriod].Seconds);
  LabelPeriodName.Caption:= FPeriods[FPeriod].Name;
  FSignalColor:= FPeriods[FPeriod].Color;
  ShowColor(FSignalColor, 0.2);
  FWarningSeconds:= FPeriods[FPeriod].WarningSeconds;
  FWarning:= FPeriods[FPeriod].Warning;
  FTargetSeconds:= FTargetSeconds + FPeriods[FPeriod].Seconds;
  FPeriodSeconds:= FPeriods[FPeriod].Seconds;
  FFinalSound:= FPeriods[FPeriod].FinalSound;
end;

procedure TViewSequenceTimer.NextPeriod;
var
  i: Integer;
  found: Boolean;
begin
  i:= 0;
  found:= False;

  { check for Last Period }
  if (FPeriod < High(FPeriods)) then
  begin
    { find next enbled Period Index }
    for i:= (FPeriod + 1) to High(FPeriods) do
      if FPeriods[i].Enable then
      begin
        found:= True;
        Break;
      end;

    { setup Next Period }
    if found then
      SetupPeriod(i);
  end;

  if (NOT found) then
  begin
    { got Last Period - stop counter }
    FEnabled:= False;
    ShowColor(BlackRGB, 0.2);
  end;
end;

procedure TViewSequenceTimer.ButtonActionClick(Sender: TObject);
var
  button: TCastleButton;
begin
  if (NOT (Sender is TCastleButton)) then Exit;

  button:= Sender as TCastleButton;
  case button.Name of
    'ButtonStop':
    begin
      FEnabled:= False;
      Container.View:= FReturnTo;
    end;
    'ButtonRestart': ResetTimer;
    'ButtonPause':
      if NOT (Container.FrontView is TSeqPause) then
        Container.PushView(TSeqPause.CreateUntilStopped);
  end;
end;

procedure TViewSequenceTimer.ShowProgress(AValue: Single);
begin

end;

procedure TViewSequenceTimer.ShowColor(AValue: TCastleColorRGB; ATransition: Single);
begin
  TunnelBG.ColorTransition:= ATransition;
  TunnelBG.Color:= AValue;
end;

procedure TViewSequenceTimer.ShowTime(ASeconds: Single);
var
  min, sec, part: Integer;
begin
  SecondsToMinSec(Round(ASeconds), min, sec);
  part:= Trunc(Frac(ASeconds) * 10.0);

  LabelMin.Caption:= Format('%.2d', [min]);
  LabelSec.Caption:= Format('%.2d', [sec]);
  LabelSecPart.Caption:= Format('%.1d', [part]);
end;

procedure TViewSequenceTimer.ShowFullTime(ASeconds: Single);
begin
  LabelFullTime.Caption:= TimeToShortStr(Round(ASeconds));
end;

procedure TViewSequenceTimer.DoAferLoad(Sender: TObject);
begin
  { appearing background }
  FlashEffect.Duration:= 0.4;
  FlashEffect.Flash(Black, True);
  { appearing menus }
  ExhibiterInfo.ExecuteOnce:= True;
end;

procedure TViewSequenceTimer.DoAferAnimation(Sender: TObject);
begin
  ResetTimer;
end;

procedure TViewSequenceTimer.Pause;
begin
  inherited;
  FSpeedCount:= 0.0;
  FSpeedBuff:= TunnelBG.Speed;
  TunnelBG.Speed:= 0.0;
end;

procedure TViewSequenceTimer.Resume;
begin
  inherited;
  TunnelBG.Speed:= FSpeedBuff;
  FSpeedCount:= 1.0;
end;

end.
