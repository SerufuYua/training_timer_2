unit GameViewSettingsPro;

interface

uses Classes,
  CastleVectors, CastleUIControls, CastleControls, CastleKeysMouse,
  CastleFlashEffect, SeqExhibiter;

type
  TViewSettingsPro = class(TCastleView)
  protected
    procedure DoAferLoad(Sender: TObject);
    procedure LoadSettings;
    procedure SaveSettings;
    procedure ButtonActionClick(Sender: TObject);
  published
    FlashEffect: TCastleFlashEffect;
    ExhibiterControl: TSeqExhibiter;
    ButtonStart, ButtonAbout, ButtonMode: TCastleButton;
    ImageSettings, ImageActions, ImageAbout, ImageMode: TCastleImageControl;
    LabelFps: TCastleLabel;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Start; override;
    procedure Stop; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
  end;

var
  ViewSettingsPro: TViewSettingsPro;

implementation

uses
  CastleConfig, CastleColors, GameViewSettingsSimple, SeqAbout;

const
  MainStor = 'main';
  ModeStr = 'mode';
  ModeThis = 'Pro';
  SettingsStor = 'SettingsPro';

  constructor TViewSettingsPro.Create(AOwner: TComponent);
begin
  inherited;
  DesignUrl := 'castle-data:/gameviewsettingspro.castle-user-interface';
end;

procedure TViewSettingsPro.Start;
begin
  inherited;

  ImageSettings.Exists:= False;
  ImageActions.Exists:= False;
  ImageAbout.Exists:= False;
  ImageMode.Exists:= False;
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
begin
  UserConfig.SetValue(MainStor + '/' + ModeStr, ModeThis);

  UserConfig.Save;
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

end.
