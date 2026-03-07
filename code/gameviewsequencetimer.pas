unit GameViewSequenceTimer;

interface

uses Classes,
  CastleVectors, CastleUIControls, CastleControls, CastleKeysMouse,
  CastleColors, SeqExhibiter, GameSound;

type
  TTimePeriod = record
    Name: String;
    FinalSound: TSoundType;
    Seconds, WarningSeconds: Integer;
    Warning, Enable: Boolean;
    Color: TCastleColor;
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
    FPeriods: TPeriodsList;
    FSequenceName: String;
    FPeriod: Integer;
    FElapsedSeconds, FStartPauseSeconds, FLastRemainingSeconds, FPeriodSeconds,
      FWarningSeconds, FFullSeconds: Single;
    FWarning: Boolean;
    FFinalSound: TSoundType;
    FSignalColor: TCastleColor;
    procedure DoAferLoad(Sender: TObject);
    procedure DoAferAnimation(Sender: TObject);
    procedure SetPeriods(AValue: TPeriodsSettings);
    procedure ResetTimer;
    procedure ShowColor(AValue: TCastleColor);
    procedure ShowProgress(AValue: Single);
    procedure ShowTime(ASeconds: Single);
    procedure ShowFullTime(ASeconds: Single);
    procedure ButtonActionClick(Sender: TObject);
  published
    ButtonStop, ButtonRestart, ButtonPause: TCastleButton;
    RectangleColor, ImageTimer, ImageActions: TCastleImageControl;
    ExhibiterInfo, ExhibiterActions: TSeqExhibiter;
    LabelFps, LabelSequenceName, LabelPeriodName,
      LabelMin, LabelSec, LabelSecPart: TCastleLabel;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Start; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
    procedure SetupPeriod(AIndex: Integer);
    procedure NextPeriod;

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
  DefaultColorPrepare: TCastleColor = (X: 0.0; Y: 1.0; Z: 0.0; W: 1.0); { Lime }
  DefaultColorRest: TCastleColor = (X: 1.0; Y: 1.0; Z: 0.0; W: 1.0); { Yellow }
  DefaultColorRound: TCastleColor = (X: 1.0; Y: 0.0; Z: 0.0; W: 1.0); { Red }

var
  ViewSequenceTimer: TViewSequenceTimer;

implementation

uses
  SysUtils, MyTimes;

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
  FElapsedSeconds:= FElapsedSeconds + SecondsPassed;
  RemainingSeconds:= FPeriodSeconds - FElapsedSeconds;

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
    ShowColor(Black)
  else
  if (IsTime(initTime * 1.0 - (initTime / 2.0)) OR
      IsTime(initTime * 2.0 - (initTime / 2.0)) OR
      IsTime(initTime * 3.0 - (initTime / 2.0))) then
    ShowColor(FSignalColor);

  { color blink warning signal }
  if FWarning then
  begin
    if IsTime(FWarningSeconds) then
      ShowColor(Gray)
    else
    if ((FWarningSeconds > initTime) AND
        (IsTime(FWarningSeconds - (initTime / 2.0)))) then
      ShowColor(FSignalColor);
  end;

  { count time and change period }
  if (RemainingSeconds > 0.0) then
  begin
    ShowTime(RemainingSeconds);
    ShowFullTime(FFullSeconds - FElapsedSeconds);
    ShowProgress(RemainingSeconds);
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

procedure TViewSequenceTimer.SetPeriods(AValue: TPeriodsSettings);
begin
  FSequenceName:= AValue.Name;
  FPeriods:= AValue.Periods;
end;

procedure TViewSequenceTimer.ResetTimer;
begin
  FPeriodSeconds:= 0;
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
  ShowColor(FSignalColor);
  FWarningSeconds:= FPeriods[FPeriod].WarningSeconds;
  FWarning:= FPeriods[FPeriod].Warning;
  FPeriodSeconds:= FPeriodSeconds + FPeriods[FPeriod].Seconds;
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
    ShowColor(Black);
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
    begin
      if FEnabled then
      begin
        FEnabled:= False;
        button.Caption:= 'Continue...';
      end
      else
      begin
        FEnabled:= True;
        button.Caption:= 'Pause';
      end;
    end;
  end;
end;

procedure TViewSequenceTimer.ShowProgress(AValue: Single);
begin

end;

procedure TViewSequenceTimer.ShowColor(AValue: TCastleColor);
begin
  RectangleColor.Color:= AValue;
end;

procedure TViewSequenceTimer.ShowTime(ASeconds: Single);
var
  min, sec, part: Integer;
begin
  SecondsToMinSec(Round(ASeconds), min, sec);
  part:= Trunc((ASeconds - Single(Trunc(ASeconds))) * 10.0);

  LabelMin.Caption:= Format('%.2d', [min]);
  LabelSec.Caption:= Format('%.2d', [sec]);
  LabelSecPart.Caption:= Format('%.1d', [part]);
end;

procedure TViewSequenceTimer.ShowFullTime(ASeconds: Single);
begin

end;

procedure TViewSequenceTimer.DoAferLoad(Sender: TObject);
begin
  ExhibiterInfo.ExecuteOnce:= True;
end;

procedure TViewSequenceTimer.DoAferAnimation(Sender: TObject);
begin
  ResetTimer;
end;

end.
