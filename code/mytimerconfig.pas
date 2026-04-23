unit MyTimerConfig;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, CastleClassUtils;

type
  TMyTimerConfig = class(TCastleComponent)
  protected
    FSound, FSoundSfx: Boolean;
    procedure LoadConfig;
    procedure SaveConfig;
    procedure SetSound(AValue: Boolean);
    procedure SetSoundSfx(AValue: Boolean);
  public
  const
    DefaultSound = True;
    DefaultSoundSfx = True;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Save;

    property Sound: Boolean read FSound write SetSound
             {$ifdef FPC}default DefaultSound{$endif};
    property SoundSfx: Boolean read FSoundSfx write SetSoundSfx
             {$ifdef FPC}default DefaultSoundSfx{$endif};
  end;

var
  TimerConfig: TMyTimerConfig;

implementation

uses
  CastleConfig;

const
  ConfigStor = 'Config';
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

  FSound:= UserConfig.GetValue(path + SoundConf, DefaultSound);
  FSoundSfx:= UserConfig.GetValue(path + SoundSfxConf, DefaultSoundSfx);
end;

procedure TMyTimerConfig.SaveConfig;
var
  path: String;
begin
  path:= ConfigStor + '/';

  UserConfig.SetValue(path + SoundConf, FSound);
  UserConfig.SetValue(path + SoundSfxConf, FSoundSfx);

  UserConfig.Save;
end;

procedure TMyTimerConfig.SetSound(AValue: Boolean);
begin
  if (FSound = AValue) then Exit;
  FSound:= AValue;
end;

procedure TMyTimerConfig.SetSoundSfx(AValue: Boolean);
begin
  if (FSoundSfx = AValue) then Exit;
  FSoundSfx:= AValue;
end;

end.

