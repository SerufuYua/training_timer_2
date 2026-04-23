unit SeqConfig;

interface

uses Classes, SeqBaseDialog,
  CastleVectors, CastleUIControls, CastleControls, CastleColors, SeqExhibiter,
  GameViewSequenceTimer, SeqListColors;

type
  TSeqConfig = class(TCastleView)
  strict private
    type
      TSeqConfigDialog = class(TSeqBaseDialog)
      protected
        CheckSound, CheckSoundSfx: TCastleCheckbox;
        ButtonSet: TCastleButton;
        procedure ClickEdit(Sender: TObject);
        procedure ClickControl(Sender: TObject);
      public
        constructor CreateNew(const AUrl: String; AOwner: TComponent); override;
      end;
    var
      FDialog: TSeqConfigDialog;
  public
    constructor CreateUntilStopped;
    procedure Start; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
  end;

implementation

uses
  SysUtils, CastleComponentSerialize, GameSound, MyTimerConfig;

{ ========= ------------------------------------------------------------------ }
{ TSeqConfigDialog ----------------------------------------------------------- }
{ ========= ------------------------------------------------------------------ }

constructor TSeqConfig.TSeqConfigDialog.CreateNew(const AUrl: String; AOwner: TComponent);
begin
  inherited;

  { Find components, by name, that we need to access from code }
  CheckSound:= FUiOwner.FindRequiredComponent('CheckSound') as TCastleCheckbox;
  CheckSoundSfx:= FUiOwner.FindRequiredComponent('CheckSoundSfx') as TCastleCheckbox;
  ButtonSet:= FUiOwner.FindRequiredComponent('ButtonSet') as TCastleButton;

  CheckSound.OnChange:=    {$ifdef FPC}@{$endif}ClickEdit;
  CheckSoundSfx.OnChange:= {$ifdef FPC}@{$endif}ClickEdit;
  ButtonSet.OnClick:=      {$ifdef FPC}@{$endif}ClickControl;

  CheckSound.OnInternalMouseEnter:=    {$ifdef FPC}@{$endif}ControlHover;
  CheckSoundSfx.OnInternalMouseEnter:= {$ifdef FPC}@{$endif}ControlHover;
  ButtonSet.OnInternalMouseEnter:=     {$ifdef FPC}@{$endif}ControlHover;

  CheckSound.Checked:= TimerConfig.Sound;
  CheckSoundSfx.Checked:= TimerConfig.SoundSfx;
end;

procedure TSeqConfig.TSeqConfigDialog.ClickEdit(Sender: TObject);
var
  component: TComponent;
begin
  if (NOT (Sender is TComponent)) then Exit;

  component:= Sender as TComponent;
  case component.Name of
    'CheckSound', 'CheckSoundSfx':
      PlaySfx(TSfxType.Check);
  end;
end;

procedure TSeqConfig.TSeqConfigDialog.ClickControl(Sender: TObject);
var
  button: TCastleButton;
begin
  if NOT (Sender is TCastleButton) then Exit;
  button:= Sender as TCastleButton;

  if (button.Name = 'ButtonSet') then
  begin
    PlaySfx(TSfxType.ClickOk);
    TimerConfig.Sound:= CheckSound.Checked;
    TimerConfig.SoundSfx:= CheckSoundSfx.Checked;
    TimerConfig.Save;
  end;

  ShowClose;
end;

{ ========= ------------------------------------------------------------------ }
{ TSeqConfig ------------------------------------------------------------ }
{ ========= ------------------------------------------------------------------ }

constructor TSeqConfig.CreateUntilStopped;
begin
  inherited CreateUntilStopped;
  DesignUrl:= 'castle-data:/bgwin.castle-user-interface';
end;

procedure TSeqConfig.Start;
begin
  inherited;
  InterceptInput:= True;

  FDialog:= TSeqConfigDialog.CreateNew('castle-data:/config.castle-user-interface', FreeAtStop);
  FDialog.Anchor(hpMiddle);
  FDialog.Anchor(vpMiddle);
  FDialog.FullSize:= True;
  InsertFront(FDialog);
  FDialog.Start;
end;

procedure TSeqConfig.Update(const SecondsPassed: Single; var HandleInput: boolean);
begin
  inherited;

  if FDialog.Closed then
    Container.PopView(Self);
end;

end.

