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
    FFlyingObjects: TSeqFlyingObjects;
    FSpeed, FColorTransit, FColorTime: Single;
    FColor, FColorBuff, FColorBG, FColorMesh: TCastleColorRGB;
    FColorPersistent, FColorBGPersistent, FColorMeshPersistent: TCastleColorRGBPersistent;
    procedure SetUrl(const Value: String); virtual;
    procedure SetSpeed(AValue: Single);
    procedure SetColor(const AValue: TCastleColorRGB);
    procedure SetColorBG(const AValue: TCastleColorRGB);
    procedure SetColorMesh(const AValue: TCastleColorRGB);
    procedure ApplySpeed;
    procedure ApplyColor;
    procedure ApplyColorBG;
    procedure ApplyColorMesh;
    function GetColorForPersistent: TCastleColorRGB;
    procedure SetColorForPersistent(const AValue: TCastleColorRGB);
    function GetColorBGForPersistent: TCastleColorRGB;
    procedure SetColorBGForPersistent(const AValue: TCastleColorRGB);
    function GetColorMeshForPersistent: TCastleColorRGB;
    procedure SetColorMeshForPersistent(const AValue: TCastleColorRGB);
    procedure HandleNodeColorMesh(ANode: TX3DNode);
  public
    const
      DefaultSpeed = 1.0;
      DefaultColorTransition = 0.5;
      DefaultColor: TCastleColorRGB = (X: 0.6; Y: 0.0; Z: 0.5);
      DefaultColorBG: TCastleColorRGB = (X: 0.0; Y: 0.0; Z: 0.0);
      DefaultColorMesh: TCastleColorRGB = (X: 1.0; Y: 1.0; Z: 1.0);

      constructor Create(AOwner: TComponent); override;
      destructor Destroy; override;
      procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
      function PropertySections(const PropertyName: String): TPropertySections; override;
      property Color: TCastleColorRGB read FColor write SetColor;
      property ColorBG: TCastleColorRGB read FColorBG write SetColorBG;
      property ColorMesh: TCastleColorRGB read FColorMesh write SetColorMesh;
  published
    property Url: String read FUrl write SetUrl;
    property Speed: Single read FSpeed write SetSpeed
             {$ifdef FPC}default DefaultSpeed{$endif};
    property ColorTransition: Single read FColorTransit write FColorTransit
             {$ifdef FPC}default DefaultColorTransition{$endif};
    property ColorPersistent: TCastleColorRGBPersistent read FColorPersistent;
    property ColorBGPersistent: TCastleColorRGBPersistent read FColorBGPersistent;
    property ColorMeshPersistent: TCastleColorRGBPersistent read FColorMeshPersistent;
end;

implementation

uses
  CastleComponentSerialize, CastleVectors, CastleUtils
  {$ifdef CASTLE_DESIGN_MODE}
  , PropEdits, CastlePropEdits
  {$endif};

constructor TSeqTunnelEffect.Create(AOwner: TComponent);
begin
  inherited;

  FDesign:= nil;
  FUrl:= '';
  FColorTime:= 0.0;
  FSpeed:= DefaultSpeed;
  FColorTransit:= DefaultColorTransition;

  { Persistent for Color }
  FColor:= DefaultColor;
  FColorPersistent:= TCastleColorRGBPersistent.Create(nil);
  FColorPersistent.SetSubComponent(true);
  FColorPersistent.InternalGetValue:= {$ifdef FPC}@{$endif}GetColorForPersistent;
  FColorPersistent.InternalSetValue:= {$ifdef FPC}@{$endif}SetColorForPersistent;
  FColorPersistent.InternalDefaultValue:= Color;

  { Persistent for ColorBG }
  FColorBG:= DefaultColorBG;
  FColorBGPersistent:= TCastleColorRGBPersistent.Create(nil);
  FColorBGPersistent.SetSubComponent(true);
  FColorBGPersistent.InternalGetValue:= {$ifdef FPC}@{$endif}GetColorBGForPersistent;
  FColorBGPersistent.InternalSetValue:= {$ifdef FPC}@{$endif}SetColorBGForPersistent;
  FColorBGPersistent.InternalDefaultValue:= ColorBG;

  { Persistent for ColorBG }
  FColorMesh:= DefaultColorMesh;
  FColorMeshPersistent:= TCastleColorRGBPersistent.Create(nil);
  FColorMeshPersistent.SetSubComponent(true);
  FColorMeshPersistent.InternalGetValue:= {$ifdef FPC}@{$endif}GetColorMeshForPersistent;
  FColorMeshPersistent.InternalSetValue:= {$ifdef FPC}@{$endif}SetColorMeshForPersistent;
  FColorMeshPersistent.InternalDefaultValue:= ColorMesh;
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
  end;

  { transit color }
  if Assigned(FFog) then
  begin
    if (FColorTime > 0.0) then
    begin
      FColorTime:= FColorTime - SecondsPassed;
      factor:= 1.0 - FColorTime / FColorTransit;
      FFog.Color:= Lerp(factor, FColorBuff, FColor);
    end;
  end;
end;

destructor TSeqTunnelEffect.Destroy;
begin
  if Assigned(FDesign) then
    FreeAndNil(FDesign);

  if Assigned(FColorPersistent) then
    FreeAndNil(FColorPersistent);

  if Assigned(FColorBGPersistent) then
    FreeAndNil(FColorBGPersistent);

  if Assigned(FColorMeshPersistent) then
    FreeAndNil(FColorMeshPersistent);

  inherited;
end;

procedure TSeqTunnelEffect.SetUrl(const value: String);
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
  FFlyingObjects:= FDesign.DesignedComponent('FlyingObjects', False) as TSeqFlyingObjects;

  ApplySpeed;
  ApplyColor;
  ApplyColorBG;
  ApplyColorMesh;
end;

procedure TSeqTunnelEffect.SetSpeed(AValue: Single);
begin
  if (FSpeed = AValue) then Exit;
  FSpeed:= AValue;
  ApplySpeed;
end;

procedure TSeqTunnelEffect.SetColor(const AValue: TCastleColorRGB);
begin
  FColor:= AValue;
  ApplyColor;
end;

procedure TSeqTunnelEffect.SetColorBG(const AValue: TCastleColorRGB);
begin
  FColorBG:= AValue;
  ApplyColorBG;
end;

procedure TSeqTunnelEffect.SetColorMesh(const AValue: TCastleColorRGB);
begin
  FColorMesh:= AValue;
  ApplyColorMesh;
end;

procedure TSeqTunnelEffect.ApplySpeed;
begin
  if Assigned(FFlyingObjects) then
  begin
    FFlyingObjects.Speed:= FSpeed;
    FFlyingObjects.SpeedRandom:= FSpeed * 0.2;
  end;
end;

procedure TSeqTunnelEffect.ApplyColor;
begin
  if Assigned(FFog) then
  begin
    FColorTime:= FColorTransit;
    FColorBuff:= FFog.Color;
  end;
end;

procedure TSeqTunnelEffect.ApplyColorBG;
begin
  if Assigned(FBoxBG) then
    FBoxBG.Color:= Vector4(FColorBG, 1.0);
end;

procedure TSeqTunnelEffect.ApplyColorMesh;
var
  Node: TX3DRootNode;
begin
  if NOT Assigned(FTunnel) then Exit;

  Node:= FTunnel.RootNode;
  if NOT Assigned(Node) then Exit;

  Node.EnumerateNodes(TPhysicalMaterialNode,
    {$ifdef FPC}@{$endif}HandleNodeColorMesh, false);
end;

function TSeqTunnelEffect.GetColorForPersistent: TCastleColorRGB;
begin
  Result:= Color;
end;

procedure TSeqTunnelEffect.SetColorForPersistent(const AValue: TCastleColorRGB);
begin
  Color:= AValue;
end;

function TSeqTunnelEffect.GetColorBGForPersistent: TCastleColorRGB;
begin
  Result:= ColorBG;
end;

procedure TSeqTunnelEffect.SetColorBGForPersistent(const AValue: TCastleColorRGB);
begin
  ColorBG:= AValue;
end;

function TSeqTunnelEffect.GetColorMeshForPersistent: TCastleColorRGB;
begin
  Result:= ColorMesh;
end;

procedure TSeqTunnelEffect.SetColorMeshForPersistent(const AValue: TCastleColorRGB);
begin
  ColorMesh:= AValue;
end;

procedure TSeqTunnelEffect.HandleNodeColorMesh(ANode: TX3DNode);
var
  Material: TPhysicalMaterialNode;
begin
  Material:= ANode as TPhysicalMaterialNode;
  Material.BaseColor:= FColorMesh;
  Material.EmissiveColor:= FColorMesh;
end;

function TSeqTunnelEffect.PropertySections(const PropertyName: String): TPropertySections;
begin
  if ArrayContainsString(PropertyName, [
       'Url', 'Speed', 'ColorTransition',
       'ColorPersistent', 'ColorBGPersistent', 'ColorMeshPersistent'
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

