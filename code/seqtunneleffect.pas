unit SeqTunnelEffect;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, CastleUIControls, CastleControls, CastleClassUtils,
  CastleScene, CastleColors, X3DNodes, SeqFlyingObjects;

type
  TSeqTunnelEffect = class(TCastleUserInterface)
  protected
    FUrl: String;
    FDesign: TCastleDesign;
    FBoxBG: TCastleBox;
    FTunnel: TCastleScene;
    FFog: TCastleFog;
    FFlyingObjects: Array of TSeqFlyingObjects;
    FRotate: Boolean;
    FSpeed, FColorTransit, FColorTime, FTimeFull: Single;
    FColorLight, FColorBuff, FColorBG: TCastleColorRGB;
    FColorLightPersistent, FColorBGPersistent: TCastleColorRGBPersistent;
    procedure SetUrl(const Value: String); virtual;
    procedure SetSpeed(AValue: Single);
    procedure SetColorLight(const AValue: TCastleColorRGB);
    procedure SetColorBG(const AValue: TCastleColorRGB);
    procedure ApplySpeed;
    procedure ApplyColor;
    procedure ApplyColorBG;
    function GetColorLightForPersistent: TCastleColorRGB;
    procedure SetColorLightForPersistent(const AValue: TCastleColorRGB);
    function GetColorBGForPersistent: TCastleColorRGB;
    procedure SetColorBGForPersistent(const AValue: TCastleColorRGB);
  public
    const
      DefaultRotate = False;
      DefaultSpeed = 1.0;
      DefaultColorTransition = 0.5;
      DefaultColorLight: TCastleColorRGB = (X: 0.6; Y: 0.0; Z: 0.5);
      DefaultColorBG: TCastleColorRGB = (X: 0.0; Y: 0.0; Z: 0.0);

      constructor Create(AOwner: TComponent); override;
      destructor Destroy; override;
      procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
      function PropertySections(const PropertyName: String): TPropertySections; override;

      property ColorLight: TCastleColorRGB read FColorLight write SetColorLight;
      property ColorBG: TCastleColorRGB read FColorBG write SetColorBG;
  published
    property Url: String read FUrl write SetUrl;
    property Rotate: Boolean read FRotate write FRotate
             {$ifdef FPC}default DefaultRotate{$endif};
    property Speed: Single read FSpeed write SetSpeed
             {$ifdef FPC}default DefaultSpeed{$endif};
    property ColorTransition: Single read FColorTransit write FColorTransit
             {$ifdef FPC}default DefaultColorTransition{$endif};
    property ColorLightPersistent: TCastleColorRGBPersistent read FColorLightPersistent;
    property ColorBGPersistent: TCastleColorRGBPersistent read FColorBGPersistent;
end;

implementation

uses
  CastleComponentSerialize, CastleVectors, CastleUtils, CastleTransform
  {$ifdef CASTLE_DESIGN_MODE}
  , PropEdits, CastlePropEdits
  {$endif};

constructor TSeqTunnelEffect.Create(AOwner: TComponent);
begin
  inherited;

  FDesign:= nil;
  FUrl:= '';
  FColorTime:= 0.0;
  FTimeFull:= 0.0;
  FSpeed:= DefaultSpeed;
  FRotate:= DefaultRotate;
  FColorTransit:= DefaultColorTransition;

  { Persistent for ColorLight }
  FColorLight:= DefaultColorLight;
  FColorLightPersistent:= TCastleColorRGBPersistent.Create(nil);
  FColorLightPersistent.SetSubComponent(true);
  FColorLightPersistent.InternalGetValue:= {$ifdef FPC}@{$endif}GetColorLightForPersistent;
  FColorLightPersistent.InternalSetValue:= {$ifdef FPC}@{$endif}SetColorLightForPersistent;
  FColorLightPersistent.InternalDefaultValue:= ColorLight;

  { Persistent for ColorBG }
  FColorBG:= DefaultColorBG;
  FColorBGPersistent:= TCastleColorRGBPersistent.Create(nil);
  FColorBGPersistent.SetSubComponent(true);
  FColorBGPersistent.InternalGetValue:= {$ifdef FPC}@{$endif}GetColorBGForPersistent;
  FColorBGPersistent.InternalSetValue:= {$ifdef FPC}@{$endif}SetColorBGForPersistent;
  FColorBGPersistent.InternalDefaultValue:= ColorBG;
end;

destructor TSeqTunnelEffect.Destroy;
begin
  if Assigned(FDesign) then
    FreeAndNil(FDesign);

  if Assigned(FColorLightPersistent) then
    FreeAndNil(FColorLightPersistent);

  if Assigned(FColorBGPersistent) then
    FreeAndNil(FColorBGPersistent);

  inherited;
end;

procedure TSeqTunnelEffect.Update(const SecondsPassed: Single; var HandleInput: boolean);
var
  pos: TVector3;
  factor: Single;
begin
  inherited;

  { animate tunnel }
  if Assigned(FTunnel) then
  begin
    pos:= FTunnel.Translation;
    pos.Z:= pos.Z + SecondsPassed * FSpeed;
    if (pos.Z > 1.0) then pos.Z:= 0.0;
    FTunnel.Translation:= pos;

    if Rotate then
    begin
      FTimeFull:= FTimeFull + SecondsPassed;
      FTunnel.Rotation:= Vector4(0.0, 0.0, 1.0, FSpeed * FTimeFull / 4.0);
    end;
  end;

  { transit ColorLight }
  if (Assigned(FFog) AND (FColorTransit > 0.0)) then
  begin
    if (FColorTime > 0.0) then
    begin
      FColorTime:= FColorTime - SecondsPassed;
      factor:= 1.0 - FColorTime / FColorTransit;
      FFog.Color:= Lerp(factor, FColorBuff, FColorLight);
    end;
  end;
end;

procedure TSeqTunnelEffect.SetUrl(const value: String);
var
  tempComponent: TCastleTransform;
begin
  if (FUrl = value) then Exit;
  FUrl:= value;

  if NOT Assigned(FDesign) then
  begin
    FDesign:= TCastleDesign.Create(Self);
    FDesign.SetTransient;
    InsertFront(FDesign);
  end;

  FDesign.Url:= value;
  FDesign.FullSize:= True;

  FBoxBG:= FDesign.DesignedComponent('BoxBG', False) as TCastleBox;
  FTunnel:= FDesign.DesignedComponent('Tunnel', False) as TCastleScene;
  FFog:= FDesign.DesignedComponent('FogColor', False) as TCastleFog;

  FFlyingObjects:= [];
  if Assigned(FDesign.DesignedComponent('FlyingObjects', False)) then
    for tempComponent in (FDesign.DesignedComponent('FlyingObjects') as TCastleTransform) do
      if (tempComponent is TSeqFlyingObjects) then
        System.Insert((tempComponent as TSeqFlyingObjects), FFlyingObjects, Length(FFlyingObjects));

  ApplySpeed;
  ApplyColor;
  ApplyColorBG;
end;

procedure TSeqTunnelEffect.SetSpeed(AValue: Single);
begin
  if (FSpeed = AValue) then Exit;
  FSpeed:= AValue;
  ApplySpeed;
end;

procedure TSeqTunnelEffect.SetColorLight(const AValue: TCastleColorRGB);
begin
  FColorLight:= AValue;
  ApplyColor;
end;

procedure TSeqTunnelEffect.SetColorBG(const AValue: TCastleColorRGB);
begin
  FColorBG:= AValue;
  ApplyColorBG;
end;

procedure TSeqTunnelEffect.ApplySpeed;
var
  FlyObj: TSeqFlyingObjects;
begin
  for FlyObj in FFlyingObjects do
  begin
    FlyObj.Speed:= FSpeed;
    FlyObj.SpeedRandom:= FSpeed * 0.2;
  end;
end;

procedure TSeqTunnelEffect.ApplyColor;
begin
  if Assigned(FFog) then
  begin
    if (FColorTransit > 0.0) then
    begin
      FColorTime:= FColorTransit;
      FColorBuff:= FFog.Color;
    end
    else
    begin
      FColorTime:= 0.0;
      FColorBuff:= FColorLight;
      FFog.Color:= FColorLight;
    end;
  end;
end;

procedure TSeqTunnelEffect.ApplyColorBG;
begin
  if Assigned(FBoxBG) then
    FBoxBG.Color:= Vector4(FColorBG, 1.0);
end;

function TSeqTunnelEffect.GetColorLightForPersistent: TCastleColorRGB;
begin
  Result:= ColorLight;
end;

procedure TSeqTunnelEffect.SetColorLightForPersistent(const AValue: TCastleColorRGB);
begin
  ColorLight:= AValue;
end;

function TSeqTunnelEffect.GetColorBGForPersistent: TCastleColorRGB;
begin
  Result:= ColorBG;
end;

procedure TSeqTunnelEffect.SetColorBGForPersistent(const AValue: TCastleColorRGB);
begin
  ColorBG:= AValue;
end;

function TSeqTunnelEffect.PropertySections(const PropertyName: String): TPropertySections;
begin
  if ArrayContainsString(PropertyName, [
       'Url', 'Speed', 'Rotate', 'ColorTransition',
       'ColorLightPersistent', 'ColorBGPersistent'
     ]) then
    Result:= [psBasic]
  else
    Result:= inherited PropertySections(PropertyName);
end;

initialization
  RegisterSerializableComponent(TSeqTunnelEffect, ['Seq', 'Tunnel Effect']);

  {$ifdef CASTLE_DESIGN_MODE}
  RegisterPropertyEditor(TypeInfo(AnsiString), TSeqTunnelEffect, 'URL',
                         TUiDesignUrlPropertyEditor);
  {$endif}
end.

