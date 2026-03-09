unit SeqTunnelEffect;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, CastleUIControls, CastleControls, CastleClassUtils,
  CastleScene, CastleColors, X3DNodes;

type
  TSeqTunnelEffect = class(TCastleUserInterface)
  protected
    FUrl: String;
    FDesign: TCastleDesign;
    FBoxBG: TCastleBox;
    FTunnel: TCastleScene;
    FFog: TCastleFog;
    FSpeed: Single;
    FColor, FColorBG, FColorMesh: TCastleColor;
    FColorPersistent, FColorBGPersistent, FColorMeshPersistent: TCastleColorPersistent;
    procedure SetUrl(const Value: String); virtual;
    procedure SetSpeed(AValue: Single);
    procedure SetColor(const AValue: TCastleColor);
    procedure SetColorBG(const AValue: TCastleColor);
    procedure SetColorMesh(const AValue: TCastleColor);
    procedure ApplyColor;
    procedure ApplyColorBG;
    procedure ApplyColorMesh;
    function GetColorForPersistent: TCastleColor;
    procedure SetColorForPersistent(const AValue: TCastleColor);
    function GetColorBGForPersistent: TCastleColor;
    procedure SetColorBGForPersistent(const AValue: TCastleColor);
    function GetColorMeshForPersistent: TCastleColor;
    procedure SetColorMeshForPersistent(const AValue: TCastleColor);
    procedure HandleNodeColorMesh(ANode: TX3DNode);
  public
    const
      DefaultSpeed = 1.0;
      DefaultColor: TCastleColor = (X: 0.6; Y: 0.0; Z: 0.5; W: 1.0);
      DefaultColorBG: TCastleColor = (X: 0.0; Y: 0.0; Z: 0.0; W: 1.0);
      DefaultColorMesh: TCastleColor = (X: 1.0; Y: 1.0; Z: 1.0; W: 1.0);

      constructor Create(AOwner: TComponent); override;
      destructor Destroy; override;
      procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
      function PropertySections(const PropertyName: String): TPropertySections; override;
      property Color: TCastleColor read FColor write SetColor;
      property ColorBG: TCastleColor read FColorBG write SetColorBG;
      property ColorMesh: TCastleColor read FColorMesh write SetColorMesh;
  published
    property Url: String read FUrl write SetUrl;
    property Speed: Single read FSpeed write SetSpeed
             {$ifdef FPC}default DefaultSpeed{$endif};
    property ColorPersistent: TCastleColorPersistent read FColorPersistent;
    property ColorBGPersistent: TCastleColorPersistent read FColorBGPersistent;
    property ColorMeshPersistent: TCastleColorPersistent read FColorMeshPersistent;
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
  FSpeed:= DefaultSpeed;

  { Persistent for Color }
  FColorPersistent:= TCastleColorPersistent.Create(nil);
  FColorPersistent.SetSubComponent(true);
  FColorPersistent.InternalGetValue:= {$ifdef FPC}@{$endif}GetColorForPersistent;
  FColorPersistent.InternalSetValue:= {$ifdef FPC}@{$endif}SetColorForPersistent;
  FColorPersistent.InternalDefaultValue:= Color;
  Color:= DefaultColor;

  { Persistent for ColorBG }
  FColorBGPersistent:= TCastleColorPersistent.Create(nil);
  FColorBGPersistent.SetSubComponent(true);
  FColorBGPersistent.InternalGetValue:= {$ifdef FPC}@{$endif}GetColorBGForPersistent;
  FColorBGPersistent.InternalSetValue:= {$ifdef FPC}@{$endif}SetColorBGForPersistent;
  FColorBGPersistent.InternalDefaultValue:= ColorBG;
  ColorBG:= DefaultColorBG;

  { Persistent for ColorBG }
  FColorMeshPersistent:= TCastleColorPersistent.Create(nil);
  FColorMeshPersistent.SetSubComponent(true);
  FColorMeshPersistent.InternalGetValue:= {$ifdef FPC}@{$endif}GetColorMeshForPersistent;
  FColorMeshPersistent.InternalSetValue:= {$ifdef FPC}@{$endif}SetColorMeshForPersistent;
  FColorMeshPersistent.InternalDefaultValue:= ColorMesh;
  ColorMesh:= DefaultColorMesh;
end;

procedure TSeqTunnelEffect.Update(const SecondsPassed: Single; var HandleInput: boolean);
var
  pos: Single;
begin
  inherited;

  { animate tunnel }
  if Assigned(FTunnel) then
  begin
    pos:= FTunnel.Translation.Z;
    pos:= pos + SecondsPassed * FSpeed;

    if (pos > 1.0) then
      pos:= 0.0;

    FTunnel.Translation:= Vector3(0.0, 0.0, pos);
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

  ApplyColor;
  ApplyColorBG;
  ApplyColorMesh;
end;

procedure TSeqTunnelEffect.SetSpeed(AValue: Single);
begin
  if (FSpeed = AValue) then Exit;
  FSpeed:= AValue;
end;

procedure TSeqTunnelEffect.SetColor(const AValue: TCastleColor);
begin
  FColor:= AValue;
  ApplyColor;
end;

procedure TSeqTunnelEffect.SetColorBG(const AValue: TCastleColor);
begin
  FColorBG:= AValue;
  ApplyColorBG;
end;

procedure TSeqTunnelEffect.SetColorMesh(const AValue: TCastleColor);
begin
  FColorMesh:= AValue;
  ApplyColorMesh;
end;

procedure TSeqTunnelEffect.ApplyColor;
begin
  if Assigned(FFog) then
    FFog.Color:= FColor.RGB;
end;

procedure TSeqTunnelEffect.ApplyColorBG;
begin
  if Assigned(FBoxBG) then
    FBoxBG.Color:= FColorBG;
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

function TSeqTunnelEffect.GetColorForPersistent: TCastleColor;
begin
  Result:= Color;
end;

procedure TSeqTunnelEffect.SetColorForPersistent(const AValue: TCastleColor);
begin
  Color:= AValue;
end;

function TSeqTunnelEffect.GetColorBGForPersistent: TCastleColor;
begin
  Result:= ColorBG;
end;

procedure TSeqTunnelEffect.SetColorBGForPersistent(const AValue: TCastleColor);
begin
  ColorBG:= AValue;
end;

function TSeqTunnelEffect.GetColorMeshForPersistent: TCastleColor;
begin
  Result:= ColorMesh;
end;

procedure TSeqTunnelEffect.SetColorMeshForPersistent(const AValue: TCastleColor);
begin
  ColorMesh:= AValue;
end;

procedure TSeqTunnelEffect.HandleNodeColorMesh(ANode: TX3DNode);
var
  Material: TPhysicalMaterialNode;
begin
  Material:= ANode as TPhysicalMaterialNode;
  Material.BaseColor:= FColorMesh.RGB;
  Material.EmissiveColor:= FColorMesh.RGB;
end;

function TSeqTunnelEffect.PropertySections(const PropertyName: String): TPropertySections;
begin
  if ArrayContainsString(PropertyName, [
       'Url', 'Speed', 'ColorPersistent', 'ColorBGPersistent',
       'ColorMeshPersistent'
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

