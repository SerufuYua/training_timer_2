unit SeqAbout;

interface

uses
  Classes, SeqBaseDialog, CastleVectors, CastleUIControls, CastleControls,
  CastleKeysMouse, SeqExhibiter, SeqWebButton;

type
  TSeqAbout = class(TCastleView)
  strict private
    type
      TSeqAboutDialog = class(TSeqBaseDialog)
      protected
          LabelAppName, LabelVersionNum, LabelCGENum,
            LabelPascalNum: TCastleLabel;
          WebItch, WebGHub, WebCGE: TSeqWebButton;
        procedure ClickWeb(Sender: TObject);
      public
        constructor CreateNew(const AUrl: String; AOwner: TComponent); override;
        procedure Start; override;
      end;
    var
      FDialog: TSeqAboutDialog;
  public
    constructor CreateUntilStopped;
    procedure Start; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
  end;

implementation

uses
  SysUtils, CastleComponentSerialize, CastleApplicationProperties, CastleUtils,
  GameSound;

{ ========= ------------------------------------------------------------------ }
{ TSeqAboutDialog ------------------------------------------------------------ }
{ ========= ------------------------------------------------------------------ }

constructor TSeqAbout.TSeqAboutDialog.CreateNew(const AUrl: String; AOwner: TComponent);
begin
  inherited;

  { Find components, by name, that we need to access from code }
  LabelAppName:= FUiOwner.FindRequiredComponent('LabelAppName') as TCastleLabel;
  LabelVersionNum:= FUiOwner.FindRequiredComponent('LabelVersionNum') as TCastleLabel;
  LabelCGENum:= FUiOwner.FindRequiredComponent('LabelCGENum') as TCastleLabel;
  LabelPascalNum:= FUiOwner.FindRequiredComponent('LabelPascalNum') as TCastleLabel;
  WebItch:= FUiOwner.FindRequiredComponent('WebItch') as TSeqWebButton;
  WebGHub:= FUiOwner.FindRequiredComponent('WebGHub') as TSeqWebButton;
  WebCGE:=  FUiOwner.FindRequiredComponent('WebCGE') as TSeqWebButton;

  WebItch.OnClick:= {$ifdef FPC}@{$endif}ClickWeb;
  WebGHub.OnClick:= {$ifdef FPC}@{$endif}ClickWeb;
  WebCGE.OnClick:=  {$ifdef FPC}@{$endif}ClickWeb;
  WebItch.OnInternalMouseEnter:= {$ifdef FPC}@{$endif}ControlHover;
  WebGHub.OnInternalMouseEnter:= {$ifdef FPC}@{$endif}ControlHover;
  WebCGE.OnInternalMouseEnter:=  {$ifdef FPC}@{$endif}ControlHover;
end;

procedure TSeqAbout.TSeqAboutDialog.Start;
begin
  inherited;

  LabelAppName.Caption:= ApplicationProperties.Caption;
  LabelVersionNum.Caption:= ApplicationProperties.Version
                            {$ifdef DEBUG} + ' Debug'
                            {$else} + ' Release'{$endif};
  LabelCGENum.Caption:= StringReplace(CastleEngineVersion, ' (commit', NL + '(commit', [rfReplaceAll, rfIgnoreCase]);
  LabelPascalNum.Caption:= {$I %FPCVERSION%};
end;

procedure TSeqAbout.TSeqAboutDialog.ClickWeb(Sender: TObject);
begin
  PlaySfx(TSfxType.ClickWeb);
end;

{ ========= ------------------------------------------------------------------ }
{ TSeqAbout ------------------------------------------------------------------ }
{ ========= ------------------------------------------------------------------ }

constructor TSeqAbout.CreateUntilStopped;
begin
  inherited CreateUntilStopped;
  DesignUrl:= 'castle-data:/bgwin.castle-user-interface';
end;

procedure TSeqAbout.Start;
begin
  inherited;
  InterceptInput:= True;

  FDialog:= TSeqAboutDialog.CreateNew('castle-data:/about.castle-user-interface', FreeAtStop);
  FDialog.Anchor(hpMiddle);
  FDialog.Anchor(vpMiddle);
  FDialog.FullSize:= True;
  InsertFront(FDialog);
  FDialog.Start;
end;

procedure TSeqAbout.Update(const SecondsPassed: Single; var HandleInput: boolean);
begin
  inherited;

  if FDialog.Closed then
    Container.PopView(Self);
end;

end.
