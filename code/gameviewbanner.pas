unit GameViewBanner;

interface

uses Classes,
  CastleVectors, CastleUIControls, CastleControls, CastleKeysMouse,
  CastleFlashEffect, SeqTunnelEffect;

type
  TViewBanner = class(TCastleView)
  protected
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
  CastleColors;

constructor TViewBanner.Create(AOwner: TComponent);
begin
  inherited;
  DesignUrl := 'castle-data:/gameviewbanner.castle-user-interface';
end;

procedure TViewBanner.Start;
begin
  inherited;

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

  TunnelBG.Color:= Lerp(SecondsPassed * 0.5, TunnelBG.Color, GreenRGB);
end;

procedure TViewBanner.DoAferLoad(Sender: TObject);
begin
  { appearing background }
  FlashEffect.Duration:= 0.4;
  FlashEffect.Flash(Black, True);
end;

end.
