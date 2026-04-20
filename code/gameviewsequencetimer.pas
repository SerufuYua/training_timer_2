unit GameViewSequenceTimer;

interface

uses Classes,
  CastleVectors, CastleUIControls, CastleControls, CastleFlashEffect,
  CastleKeysMouse, CastleColors, SeqExhibiter, SeqTunnelEffect, SeqPause,
  SeqLoadingBar, GameSound;

type
  TTimePeriod = record
    Name: String;
    SoundStart, SoundEnding: TSoundType;
    DurationSec, WarningSec: Integer;
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
    FEnabled, FPaused: Boolean;
    FPeriods: TPeriodsList;
    FSequenceName: String;
    FPeriod: Integer;
    FElapsedSeconds, FStartPauseSeconds, FLastRemainingSeconds, FTargetSeconds,
      FPeriodSeconds, FWarningSeconds, FFullSeconds: Single;
    {$if defined(WINDOWS)}
    FKeepScreenSeconds: Single;
    {$endif}
    FWarning: Boolean;
    FSoundEnding: TSoundType;
    FSignalColor: TCastleColorRGB;
    procedure DoAferLoad(Sender: TObject);
    procedure DoAferAnimation(Sender: TObject);
    procedure DoResetTimer(Sender: TObject);
    procedure SetPeriods(AValue: TPeriodsSettings);
    procedure ResetTimer;
    procedure ShowColor(AValue: TCastleColorRGB; ATransition: Single);
    procedure ShowProgress(AValue: Single);
    procedure ShowTime(ASeconds: Single);
    procedure ShowFullTime(ASeconds: Single);
    procedure ButtonActionClick(Sender: TObject);
    procedure OnTouchTimer(const Sender: TCastleUserInterface;
      const Event: TInputPressRelease; var Handled: Boolean);
    procedure SetEnabled(AValue: Boolean);
  published
    FlashEffect: TCastleFlashEffect;
    ExhibiterInfo, ExhibiterActions: TSeqExhibiter;
    ButtonStop, ButtonRestart, ButtonPause: TCastleButton;
    ImageTimer, ImageActions: TCastleImageControl;
    TunnelBG: TSeqTunnelEffect;
    LoadingBars, LoadingBarsShadow: TSeqLoadingBar;
    LabelFps, LabelSequenceName, LabelPeriodName: TCastleLabel;
    LabelMin, LabelMinShadow,
      LabelTime, LabelTimeShadow,
      LabelDec, LabelDecShadow,
      LabelFullTime, LabelFullTimeShadow: TCastleLabel;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Start; override;
    procedure Stop; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
    function Press(const Event: TInputPressRelease): Boolean; override;
    procedure SetupPeriod(AIndex: Integer);
    procedure NextPeriod;
    procedure Pause; override;
    procedure Resume; override;

    property Enabled: Boolean read FEnabled write SetEnabled;
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
  DefaultStartSound = TSoundType.Start;
  DefaultEndingSound = TSoundType.Ending;
  DefaultColorPrepare: TCastleColorRGB = (X: 0.0; Y: 0.85; Z: 0.0); { Green }
  DefaultColorRest: TCastleColorRGB = (X: 0.0; Y: 0.0; Z: 0.85); { Blue }
  DefaultColorRound: TCastleColorRGB = (X: 1.0; Y: 0.0; Z: 0.0); { Red }

var
  ViewSequenceTimer: TViewSequenceTimer;

implementation

uses
  SysUtils, MyUtils, CastleScene, CastleViewport, SeqConfirm, MySysUtils;

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
  FPaused:= False;
  ImageTimer.Exists:= False;
  ImageActions.Exists:= False;
  {$if defined(WINDOWS)}
  FKeepScreenSeconds:= 0.0;
  {$endif}

  LabelSequenceName.Caption:= FSequenceName;
  FFullSeconds:= 0;
  for i:= Low(FPeriods) to High(FPeriods) do
    if FPeriods[i].Enable then
      FFullSeconds:= FFullSeconds + FPeriods[i].DurationSec;

  { Actions buttons }
  ButtonStop.OnClick:= {$ifdef FPC}@{$endif}ButtonActionClick;
  ButtonRestart.OnClick:= {$ifdef FPC}@{$endif}ButtonActionClick;
  ButtonPause.OnClick:= {$ifdef FPC}@{$endif}ButtonActionClick;

  ExhibiterActions.OnFinish:= {$ifdef FPC}@{$endif}DoAferAnimation;

  { Show start animation }
  FlashEffect.Duration:= 6.0;
  FlashEffect.Flash(Black, True);
  WaitForRenderAndCall({$ifdef FPC}@{$endif}DoAferLoad);
end;

procedure TViewSequenceTimer.Stop;
begin
  inherited;
  {$if defined(ANDROID)}
  KeepScreen(False);
  {$endif}
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

  if ((NOT Enabled) OR FPaused) then Exit;

  {$if defined(WINDOWS)}
  { keep screen forwindows }
  FKeepScreenSeconds:= FKeepScreenSeconds + SecondsPassed;
  if (FKeepScreenSeconds > 5.0) then
  begin
    FKeepScreenSeconds:= 0.0;
    KeepScreen;
  end;
  {$endif};

  FElapsedSeconds:= FElapsedSeconds + SecondsPassed;
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
    ShowProgress(1.0 - RemainingSeconds / FPeriodSeconds);
  end
  else
  begin
    ShowTime(0.0);
    Play(FSoundEnding);
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
    if NOT (Container.CurrentFrontView is TSeqPause) then
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
  FPeriod:= -1;
  NextPeriod;
  Enabled:= True;
end;

procedure TViewSequenceTimer.SetupPeriod(AIndex: Integer);
begin
  FPeriod:= AIndex;
  ShowTime(FPeriods[FPeriod].DurationSec);
  LabelPeriodName.Caption:= FPeriods[FPeriod].Name;
  FSignalColor:= FPeriods[FPeriod].Color;
  ShowColor(FSignalColor, 0.2);
  FWarningSeconds:= FPeriods[FPeriod].WarningSec;
  FWarning:= FPeriods[FPeriod].Warning;
  FTargetSeconds:= FTargetSeconds + FPeriods[FPeriod].DurationSec;
  FPeriodSeconds:= FPeriods[FPeriod].DurationSec;
  FSoundEnding:= FPeriods[FPeriod].SoundEnding;
  Play(FPeriods[FPeriod].SoundStart);
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
    Enabled:= False;
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
      Enabled:= False;
      Container.View:= FReturnTo;
    end;
    'ButtonRestart':
      if NOT (Container.CurrentFrontView is TSeqConfirm) then
        Container.PushView(TSeqConfirm.CreateUntilStopped(
          ['Do You want to', 'Restart timer?'],
          'Question', {$ifdef FPC}@{$endif}DoResetTimer));
    'ButtonPause':
      if (Enabled AND (NOT (Container.CurrentFrontView is TSeqPause))) then
        Container.PushView(TSeqPause.CreateUntilStopped);
  end;
end;

procedure TViewSequenceTimer.OnTouchTimer(const Sender: TCastleUserInterface;
  const Event: TInputPressRelease; var Handled: Boolean);
begin
  if (Enabled AND (NOT (Container.CurrentFrontView is TSeqPause))) then
    Container.PushView(TSeqPause.CreateUntilStopped);
end;

procedure TViewSequenceTimer.ShowProgress(AValue: Single);
begin
  LoadingBars.Value:= AValue;
  LoadingBarsShadow.Value:= AValue;
  TunnelBG.Speed:= (0.2 + 2.0 * AValue);
end;

procedure TViewSequenceTimer.ShowColor(AValue: TCastleColorRGB; ATransition: Single);
begin
  TunnelBG.ColorTransition:= ATransition;
  TunnelBG.Color:= AValue;
end;

procedure TViewSequenceTimer.ShowTime(ASeconds: Single);
var
  sec, dec: Integer;
  s: String;
begin
  dec:= Trunc(Frac(ASeconds) * 10.0);

  sec:= Round(ASeconds);
  s:= TimeToAdaptiveStr(sec);
  LabelTime.Caption:= s;
  LabelTimeShadow.Caption:= s;

  if (sec < 60) then
  begin
    LabelTime.FontSize:= 400;
    LabelTimeShadow.FontSize:= 400;
  end
  else if (sec < 60 * 60) then
  begin
    LabelTime.FontSize:= 220;
    LabelTimeShadow.FontSize:= 220;
  end
  else
  begin
    LabelTime.FontSize:= 120;
    LabelTimeShadow.FontSize:= 120;
  end;

  s:= Format('.%.1d', [dec]);
  LabelDec.Caption:= s;
  LabelDecShadow.Caption:= s;
end;

procedure TViewSequenceTimer.ShowFullTime(ASeconds: Single);
var
  s: String;
begin
  s:= TimeToShortStr(Round(ASeconds));
  LabelFullTime.Caption:= s;
  LabelFullTimeShadow.Caption:= s;
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
  ImageTimer.OnRelease:= {$ifdef FPC}@{$endif}OnTouchTimer;
  ResetTimer;
end;

procedure TViewSequenceTimer.DoResetTimer(Sender: TObject);
begin
  ResetTimer;
end;

procedure TViewSequenceTimer.SetEnabled(AValue: Boolean);
begin
  {$if defined(ANDROID)}
  KeepScreen(AValue);
  {$endif}
  FEnabled:= AValue;
end;

procedure TViewSequenceTimer.Pause;
begin
  inherited;
  FPaused:= True;
  {$if defined(ANDROID)}
  KeepScreen(False);
  {$endif}
end;

procedure TViewSequenceTimer.Resume;
begin
  inherited;
  {$if defined(ANDROID)}
  KeepScreen(True);
  {$endif}
  FPaused:= False;
end;

end.
