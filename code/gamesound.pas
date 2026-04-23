{ Manage the repository of sounds (useful from any view).

  Usage:
  - Configure sounds using CGE editor by editing sounds.castle-component ,
  - From code:
    - Call once InitializeSounds (e.g. from ApplicationInitialize)
    - Use Play to play sound. }
unit GameSound;

interface

type
  TSoundType = (None, Start, Ending, Final, Warn, Init);
  TSfxType = (Intro, ClickMode, ClickAction, ClickEdit, ClickOk, ClickCancel,
              ClickDeny, PointerHover, ListHover, ClickStart, ClickStop,
              ClickWeb, Check, TapKey);

{ Initialize, call before any call to Play. }
procedure InitializeSounds;

procedure Play(ASound: TSoundType);
procedure PlaySfx(ASfx: TSfxType);

implementation

uses Classes,
  CastleWindow, CastleComponentSerialize, CastleSoundEngine, TypInfo, MyTimerConfig;

var
  { Owner of components loaded from sounds.castle-component. }
  Sounds: TComponent;

procedure Play(ASound: TSoundType);
var
  nameSound: String;
  sound: TCastleSound;
begin
  if NOT TimerConfig.Sound then Exit;

  nameSound:= GetEnumName(TypeInfo(TSoundType), Ord(ASound));
  sound:= Sounds.FindComponent(nameSound) as TCastleSound;
  SoundEngine.Play(sound);
end;

procedure PlaySfx(ASfx: TSfxType);
var
  nameSfx: String;
  sfx: TCastleSound;
begin
  if NOT TimerConfig.SoundSfx then Exit;

  nameSfx:= GetEnumName(TypeInfo(TSfxType), Ord(ASfx));
  sfx:= Sounds.FindComponent('sfx_' + nameSfx) as TCastleSound;
  SoundEngine.Play(sfx);
end;

procedure InitializeSounds;
begin
  Sounds:= TComponent.Create(Application);
  ComponentLoad('castle-data:/sounds.castle-component', Sounds);
end;

end.
