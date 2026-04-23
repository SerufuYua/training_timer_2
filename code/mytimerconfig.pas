unit MyTimerConfig;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, CastleClassUtils;

type
  TMyTimerConfig = class(TCastleComponent)
  protected
    FModePro, FSound, FSoundSfx: Boolean;
    procedure LoadConfig;
    procedure SaveConfig;
  public
  const
    DefaulModePro = False;
    DefaultSound = True;
    DefaultSoundSfx = True;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Save;

    property ModePro: Boolean read FModePro write FModePro
             {$ifdef FPC}default DefaulModePro{$endif};
    property Sound: Boolean read FSound write FSound
             {$ifdef FPC}default DefaultSound{$endif};
    property SoundSfx: Boolean read FSoundSfx write FSoundSfx
             {$ifdef FPC}default DefaultSoundSfx{$endif};
  end;

var
  TimerConfig: TMyTimerConfig;

implementation

uses
  CastleConfig;

const
  ConfigStor = 'Config';
  ModeProConf = 'ModePro';
  SoundConf = 'Sound';
  SoundSfxConf = 'SoundSfx';

constructor TMyTimerConfig.Create(AOwner: TComponent);
begin
  inherited;

  FSound:= DefaultSound;
  FSoundSfx:= DefaultSoundSfx;

  LoadConfig;
end;

destructor TMyTimerConfig.Destroy;
begin
  SaveConfig;
  inherited;
end;

procedure TMyTimerConfig.Save;
begin
  SaveConfig;
end;

procedure TMyTimerConfig.LoadConfig;
var
  path: String;
begin
  path:= ConfigStor + '/';

  FModePro:= UserConfig.GetValue(path + ModeProConf, DefaulModePro);
  FSound:= UserConfig.GetValue(path + SoundConf, DefaultSound);
  FSoundSfx:= UserConfig.GetValue(path + SoundSfxConf, DefaultSoundSfx);
end;

procedure TMyTimerConfig.SaveConfig;
var
  path: String;
begin
  path:= ConfigStor + '/';

  UserConfig.SetValue(path + ModeProConf, FModePro);
  UserConfig.SetValue(path + SoundConf, FSound);
  UserConfig.SetValue(path + SoundSfxConf, FSoundSfx);

  UserConfig.Save;
end;

end.

