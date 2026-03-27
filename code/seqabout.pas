unit SeqAbout;

interface

uses Classes, SeqBaseDialog,
  CastleVectors, CastleUIControls, CastleControls, CastleKeysMouse,
  SeqExhibiter;

type
  TSeqAbout = class(TCastleView)
  strict private
    type
      TSeqAboutDialog = class(TSeqBaseDialog)
      protected
          LabelAppName, LabelVersionNum, LabelCGENum,
            LabelPascalNum: TCastleLabel;
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
  SeqWebButton;

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
end;

procedure TSeqAbout.TSeqAboutDialog.Start;
begin
  inherited;

  LabelAppName.Caption:= ApplicationProperties.Caption;
  LabelVersionNum.Caption:= ApplicationProperties.Version;
  LabelCGENum.Caption:= StringReplace(CastleEngineVersion, ' (commit', NL + '(commit', [rfReplaceAll, rfIgnoreCase]);
  LabelPascalNum.Caption:= {$I %FPCVERSION%};
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
