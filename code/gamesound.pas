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

{ Initialize, call before any call to Play. }
procedure InitializeSounds;

procedure Play(ASound: TSoundType);

implementation

uses Classes,
  CastleWindow, CastleComponentSerialize, CastleSoundEngine, TypInfo;

var
  { Owner of components loaded from sounds.castle-component. }
  Sounds: TComponent;

procedure Play(ASound: TSoundType);
var
  nameSound: String;
  sound: TCastleSound;
begin
  nameSound:= GetEnumName(TypeInfo(TSoundType), Ord(ASound));
  sound:= Sounds.FindComponent(nameSound) as TCastleSound;
  SoundEngine.Play(sound);
end;

procedure InitializeSounds;
begin
  Sounds:= TComponent.Create(Application);
  ComponentLoad('castle-data:/sounds.castle-component', Sounds);
end;

end.
