unit GameViewBanner;

interface

uses Classes,
  CastleUIControls, CastleControls, CastleKeysMouse,
  CastleFlashEffect, SeqTunnelEffect, CastleColors;

type
  TViewBanner = class(TCastleView)
  protected
    FNextView: TCastleView;
    FTxtTrans, FEndTime: Single;
    FColorIdx: Integer;
    FColorChain: Array[0..7] of TCastleColorRGB;
    procedure DoAferLoad(Sender: TObject);
  published
    FlashEffect: TCastleFlashEffect;
    TunnelBG: TSeqTunnelEffect;
    LabelFps, LabelStart: TCastleLabel;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Start; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
    function Press(const Event: TInputPressRelease): Boolean; override;
  end;

var
  ViewBanner: TViewBanner;

implementation

uses
  CastleVectors, CastleConfig, GameViewSettingsSimple, GameViewSettingsPro,
  Math, CastleUtils, GameSound;

const
  MainStor = 'main';
  ModeStr = 'mode';

constructor TViewBanner.Create(AOwner: TComponent);
begin
  inherited;
  DesignUrl := 'castle-data:/gameviewbanner.castle-user-interface';
end;

procedure TViewBanner.Start;
begin
  inherited;

  FEndTime:= 0.0;
  FNextView:= nil;
  TunnelBG.ColorTransition:= 0.0;

  FColorChain[0]:= GreenRGB;
  FColorChain[1]:= GrayRGB;
  FColorChain[2]:= RedRGB;
  FColorChain[3]:= GrayRGB;
  FColorChain[4]:= YellowRGB;
  FColorChain[5]:= GrayRGB;
  FColorChain[6]:= BlueRGB;
  FColorChain[7]:= GrayRGB;
  FColorIdx:= 0;
  FTxtTrans:= 0.0;

  { Show start animation }
  FlashEffect.Duration:= 6.0;
  FlashEffect.Flash(Black, True);
  WaitForRenderAndCall({$ifdef FPC}@{$endif}DoAferLoad);
end;

procedure TViewBanner.Update(const SecondsPassed: Single; var HandleInput: boolean);
var
  TxtColor: TCastleColor;
const
  Epsilon = 0.01;
begin
  inherited;
  Assert(LabelFps <> nil, 'If you remove LabelFps from the design, remember to remove also the assignment "LabelFps.Caption := ..." from code');
  LabelFps.Caption := 'FPS: ' + Container.Fps.ToString;

  { switch colors }
  if TVector3.Equals(TunnelBG.Color, FColorChain[FColorIdx], Epsilon) then
  begin
    if (FColorIdx >= High(FColorChain)) then
      FColorIdx:= 0
    else
      FColorIdx:= FColorIdx + 1;
  end
  else
    TunnelBG.Color:= Lerp(SecondsPassed * 1.5, TunnelBG.Color, FColorChain[FColorIdx]);

  { bilnk label }
  TxtColor:= LabelStart.Color;
  TxtColor.W:= Lerp(SecondsPassed * 6.0, TxtColor.W, FTxtTrans);
  LabelStart.Color:= TxtColor;

  if (System.Abs(TxtColor.W - FTxtTrans) <= Epsilon) then
   if (FTxtTrans = 1.0) then
     FTxtTrans:= 0.0
   else
     FTxtTrans:= 1.0;

  { counterclockwise }
  if (FEndTime >= 0.0) then
  begin
    FEndTime:= FEndTime - SecondsPassed;
  end
  else if Assigned(FNextView) then
    Container.View:= FNextView;
end;

function TViewBanner.Press(const Event: TInputPressRelease): Boolean;
begin
  Result:= inherited;
  if Result then Exit; // allow the ancestor to handle keys

  if ((Event.MouseButton = buttonLeft) OR
      (Event.MouseButton = buttonRight) OR
      (Event.MouseButton = buttonMiddle) OR
      Event.IsKey(TKey.keyNone)) then
  begin
    PlaySfx(TSfxType.Intro);
    FlashEffect.Duration:= 3.0;
    FEndTime:= 0.3;
    FlashEffect.Flash(White, False);
    case UserConfig.GetValue(MainStor + '/' + ModeStr, 'Simple') of
      'Simple': FNextView:= ViewSettingsSimple;
      'Pro': FNextView:= ViewSettingsPro;
    end;
  end;
end;

procedure TViewBanner.DoAferLoad(Sender: TObject);
begin
  { appearing background }
  FlashEffect.Duration:= 0.4;
  FlashEffect.Flash(Black, True);
end;

end.
