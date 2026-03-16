unit GameViewBanner;

interface

uses Classes,
  CastleUIControls, CastleControls, CastleKeysMouse,
  CastleFlashEffect, SeqTunnelEffect, CastleColors;

type
  TViewBanner = class(TCastleView)
  protected
    FColorIdx: Integer;
    FColorChain: Array[0..7] of TCastleColorRGB;
    procedure DoAferLoad(Sender: TObject);
  published
    FlashEffect: TCastleFlashEffect;
    TunnelBG: TSeqTunnelEffect;
    LabelFps: TCastleLabel;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Start; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
  end;

var
  ViewBanner: TViewBanner;

implementation

uses
  CastleVectors;

constructor TViewBanner.Create(AOwner: TComponent);
begin
  inherited;
  DesignUrl := 'castle-data:/gameviewbanner.castle-user-interface';
end;

procedure TViewBanner.Start;
begin
  inherited;

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

  { Show start animation }
  FlashEffect.Duration:= 4.0;
  FlashEffect.Flash(Black, True);
  WaitForRenderAndCall({$ifdef FPC}@{$endif}DoAferLoad);
end;

procedure TViewBanner.Update(const SecondsPassed: Single; var HandleInput: boolean);
begin
  inherited;
  Assert(LabelFps <> nil, 'If you remove LabelFps from the design, remember to remove also the assignment "LabelFps.Caption := ..." from code');
  LabelFps.Caption := 'FPS: ' + Container.Fps.ToString;

  if TVector3.Equals(TunnelBG.Color, FColorChain[FColorIdx], 0.01) then
  begin
    if (FColorIdx >= High(FColorChain)) then
      FColorIdx:= 0
    else
      FColorIdx:= FColorIdx + 1;
  end
  else
    TunnelBG.Color:= Lerp(SecondsPassed * 2.0, TunnelBG.Color, FColorChain[FColorIdx]);
end;

procedure TViewBanner.DoAferLoad(Sender: TObject);
begin
  { appearing background }
  FlashEffect.Duration:= 0.4;
  FlashEffect.Flash(Black, True);
end;

end.
