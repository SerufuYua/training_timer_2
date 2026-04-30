unit SeqRandomShowTunnel;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, SeqRandomShow, SeqTunnelEffect, CastleClassUtils,
  CastleColors;

type
  TSeqRandomShowTunnel = class(TSeqRandomShow)
  protected
    FSpeed, FColorTransition: Single;
    FColorLight, FColorBG: TCastleColorRGB;
    FColorLightPersistent, FColorBGPersistent: TCastleColorRGBPersistent;
    function GetSpeed: Single;
    procedure SetSpeed(AValue: Single);
    function GetColorTransit: Single;
    procedure SetColorTransit(AValue: Single);
    function GetExistsTunnel: TSeqTunnelEffect;
    function GetColorLight: TCastleColorRGB;
    procedure SetColorLight(const AValue: TCastleColorRGB);
    function GetColorBG: TCastleColorRGB;
    procedure SetColorBG(const AValue: TCastleColorRGB);
    function GetColorLightForPersistent: TCastleColorRGB;
    procedure SetColorLightForPersistent(const AValue: TCastleColorRGB);
    function GetColorBGForPersistent: TCastleColorRGB;
    procedure SetColorBGForPersistent(const AValue: TCastleColorRGB);
    procedure ApplySpeed;
    procedure ApplyColorTransit;
    procedure ApplyColorLight;
    procedure ApplyColorBG;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function PropertySections(const PropertyName: String): TPropertySections; override;
    procedure Shake; override;

    property ExistsTunnel: TSeqTunnelEffect read GetExistsTunnel;
    property ColorLight: TCastleColorRGB read GetColorLight write SetColorLight;
    property ColorBG: TCastleColorRGB read GetColorBG write SetColorBG;
published
    property Speed: Single read GetSpeed write SetSpeed
             {$ifdef FPC}default TSeqTunnelEffect.DefaultSpeed{$endif};
    property ColorTransition: Single read GetColorTransit write SetColorTransit
             {$ifdef FPC}default TSeqTunnelEffect.DefaultColorTransition{$endif};
    property ColorLightPersistent: TCastleColorRGBPersistent read FColorLightPersistent;
    property ColorBGPersistent: TCastleColorRGBPersistent read FColorBGPersistent;
  end;

implementation

uses
  CastleComponentSerialize, CastleUIControls, CastleUtils, CastleVectors;

constructor TSeqRandomShowTunnel.Create(AOwner: TComponent);
begin
  inherited;

  FSpeed:= TSeqTunnelEffect.DefaultSpeed;
  FColorTransition:= TSeqTunnelEffect.DefaultColorTransition;
  FColorLight:= TSeqTunnelEffect.DefaultColorLight;
  FColorBG:= TSeqTunnelEffect.DefaultColorBG;


  { Persistent for ColorLight }
  FColorLightPersistent:= TCastleColorRGBPersistent.Create(nil);
  FColorLightPersistent.SetSubComponent(true);
  FColorLightPersistent.InternalGetValue:= {$ifdef FPC}@{$endif}GetColorLightForPersistent;
  FColorLightPersistent.InternalSetValue:= {$ifdef FPC}@{$endif}SetColorLightForPersistent;
  FColorLightPersistent.InternalDefaultValue:= ColorLight;

  { Persistent for ColorBG }
  FColorBGPersistent:= TCastleColorRGBPersistent.Create(nil);
  FColorBGPersistent.SetSubComponent(true);
  FColorBGPersistent.InternalGetValue:= {$ifdef FPC}@{$endif}GetColorBGForPersistent;
  FColorBGPersistent.InternalSetValue:= {$ifdef FPC}@{$endif}SetColorBGForPersistent;
  FColorBGPersistent.InternalDefaultValue:= ColorBG;

  ApplySpeed;
  ApplyColorTransit;
  ApplyColorLight;
  ApplyColorBG;
end;

destructor TSeqRandomShowTunnel.Destroy;
begin
  if Assigned(FColorLightPersistent) then
    FreeAndNil(FColorLightPersistent);

  if Assigned(FColorBGPersistent) then
    FreeAndNil(FColorBGPersistent);

  inherited;
end;

procedure TSeqRandomShowTunnel.Shake;
begin
  inherited;
  ApplySpeed;
  ApplyColorTransit;
  ApplyColorLight;
  ApplyColorBG;
end;

function TSeqRandomShowTunnel.GetSpeed: Single;
begin
  if Assigned(ExistsTunnel) then
    Result:= ExistsTunnel.Speed
  else
    Result:= FSpeed;
end;

procedure TSeqRandomShowTunnel.SetSpeed(AValue: Single);
begin
  if (FSpeed = AValue) then Exit;
  FSpeed:= AValue;

  ApplySpeed;
end;

function TSeqRandomShowTunnel.GetColorTransit: Single;
begin
  if Assigned(ExistsTunnel) then
    Result:= ExistsTunnel.ColorTransition
  else
    Result:= FColorTransition;
end;

procedure TSeqRandomShowTunnel.SetColorTransit(AValue: Single);
begin
  if (FColorTransition = AValue) then Exit;
  FColorTransition:= AValue;

  ApplyColorTransit;
end;

function TSeqRandomShowTunnel.GetColorLight: TCastleColorRGB;
begin
  if Assigned(ExistsTunnel) then
    Result:= ExistsTunnel.ColorLight
  else
    Result:= FColorLight;
end;

procedure TSeqRandomShowTunnel.SetColorLight(const AValue: TCastleColorRGB);
begin
  if TVector3.Equals(FColorLight, AValue) then Exit;
  FColorLight:= AValue;

  ApplyColorLight;
end;

function TSeqRandomShowTunnel.GetColorBG: TCastleColorRGB;
begin
  if Assigned(ExistsTunnel) then
    Result:= ExistsTunnel.ColorBG
  else
    Result:= FColorBG;
end;

procedure TSeqRandomShowTunnel.SetColorBG(const AValue: TCastleColorRGB);
begin
  if TVector3.Equals(FColorBG, AValue) then Exit;
  FColorBG:= AValue;

  ApplyColorBG;
end;

procedure TSeqRandomShowTunnel.ApplySpeed;
begin
  if Assigned(ExistsTunnel) then
    ExistsTunnel.Speed:= FSpeed;
end;

procedure TSeqRandomShowTunnel.ApplyColorTransit;
begin
  if Assigned(ExistsTunnel) then
    ExistsTunnel.ColorTransition:= FColorTransition;
end;

procedure TSeqRandomShowTunnel.ApplyColorLight;
begin
  if Assigned(ExistsTunnel) then
    ExistsTunnel.ColorLight:= FColorLight;
end;

procedure TSeqRandomShowTunnel.ApplyColorBG;
begin
  if Assigned(ExistsTunnel) then
    ExistsTunnel.ColorBG:= FColorBG;
end;

function TSeqRandomShowTunnel.GetExistsTunnel: TSeqTunnelEffect;
var
  Plane: TCastleUserInterface;
begin
  Plane:= ExistsPlane;
  if (Assigned(Plane) AND (Plane is TSeqTunnelEffect)) then
    Result:= (Plane as TSeqTunnelEffect)
  else
    Result:= nil;
end;

function TSeqRandomShowTunnel.GetColorLightForPersistent: TCastleColorRGB;
begin
  Result:= ColorLight;
end;

procedure TSeqRandomShowTunnel.SetColorLightForPersistent(const AValue: TCastleColorRGB);
begin
  ColorLight:= AValue;
end;

function TSeqRandomShowTunnel.GetColorBGForPersistent: TCastleColorRGB;
begin
  Result:= ColorBG;
end;

procedure TSeqRandomShowTunnel.SetColorBGForPersistent(const AValue: TCastleColorRGB);
begin
  ColorBG:= AValue;
end;

function TSeqRandomShowTunnel.PropertySections(const PropertyName: String): TPropertySections;
begin
  if ArrayContainsString(PropertyName, [
       'Url', 'Speed', 'ColorTransition',
       'ColorLightPersistent', 'ColorBGPersistent'
     ]) then
    Result:= [psBasic]
  else
    Result:= inherited PropertySections(PropertyName);
end;

initialization
  Randomize;
  RegisterSerializableComponent(TSeqRandomShowTunnel, ['Seq', 'Random Show Tunnel']);
end.

