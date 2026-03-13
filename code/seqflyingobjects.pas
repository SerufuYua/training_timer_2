unit SeqFlyingObjects;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, CastleClassUtils, CastleTransform, CastleVectors;

type
  TRefObject = class(TCastleTransformReference)
  protected
    FSpeed: Single;
  public
    property Speed: Single read FSpeed write FSpeed;
  end;

  TSeqFlyingObjects = class(TCastleTransform)
  protected
    FPositionMin, FPositionMax: TVector3;
    FSpeed, FSpeedRandom: Single;
    FSize, FSizeRandom: Single;
    FInstances: Integer;
    FReference: TCastleTransform;
    FPositionMinPersistent: TCastleVector3Persistent;
    FPositionMaxPersistent: TCastleVector3Persistent;
    function GetPositionMinPersistent: TVector3;
    procedure SetPositionMinPersistent(const AValue: TVector3);
    function GetPositionMaxPersistent: TVector3;
    procedure SetPositionMaxPersistent(const AValue: TVector3);
    procedure SetReference(AValue: TCastleTransform);
    procedure SetInstances(AValue: Integer);
    procedure SetSpeed(AValue: Single);
    procedure SetSpeedRandom(AValue: Single);
    procedure SetSize(AValue: Single);
    procedure SetSizeRandom(AValue: Single);
  public
    const
      DefaultSpeed = 1.0;
      DefaultSpeedRandom = 0.1;
      DefaultSize = 1.0;
      DefaultSizeRandom = 0.1;
      DefaultInstances = 10;
      DefaultPositionMin: TVector3 = (X: -0.5; Y: -0.5; Z: -0.5);
      DefaultPositionMax: TVector3 = (X: 0.5; Y: 0.5; Z: 0.5);

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Update(const SecondsPassed: Single; var RemoveMe: TRemoveType); override;
    function PropertySections(const PropertyName: String): TPropertySections; override;

    property PositionMin: TVector3 read FPositionMin write FPositionMin;
    property PositionMax: TVector3 read FPositionMax write FPositionMax;
  published
    property Speed: Single read FSpeed write SetSpeed
             {$ifdef FPC}default DefaultSpeed{$endif};
    property SpeedRandom: Single read FSpeedRandom write SetSpeedRandom
             {$ifdef FPC}default DefaultSpeedRandom{$endif};
    property Size: Single read FSize write SetSize
             {$ifdef FPC}default DefaultSize{$endif};
    property SizeRandom: Single read FSizeRandom write SetSizeRandom
             {$ifdef FPC}default DefaultSizeRandom{$endif};
    property Instances: Integer read FInstances write SetInstances
             {$ifdef FPC}default DefaultInstances{$endif};
    property Reference: TCastleTransform read FReference write SetReference;
    property PositionMinPersistent: TCastleVector3Persistent read FPositionMinPersistent;
    property PositionMaxPersistent: TCastleVector3Persistent read FPositionMaxPersistent;
  end;

implementation

uses
  CastleComponentSerialize, CastleUtils;

constructor TSeqFlyingObjects.Create(AOwner: TComponent);
begin
  inherited;
  FSpeed:= DefaultSpeed;
  FSpeedRandom:= DefaultSpeedRandom;
  FSize:= DefaultSize;
  FSizeRandom:= DefaultSizeRandom;
  FInstances:= DefaultInstances;

  { Persistent for PositionMin }
  FPositionMin:= DefaultPositionMin;
  FPositionMinPersistent:= TCastleVector3Persistent.Create(nil);
  FPositionMinPersistent.SetSubComponent(true);
  FPositionMinPersistent.InternalGetValue:= {$ifdef FPC}@{$endif}GetPositionMinPersistent;
  FPositionMinPersistent.InternalSetValue:= {$ifdef FPC}@{$endif}SetPositionMinPersistent;
  FPositionMinPersistent.InternalDefaultValue:= FPositionMin;

  { Persistent for PositionMax }
  FPositionMax:= DefaultPositionMax;
  FPositionMaxPersistent:= TCastleVector3Persistent.Create(nil);
  FPositionMaxPersistent.SetSubComponent(true);
  FPositionMaxPersistent.InternalGetValue:= {$ifdef FPC}@{$endif}GetPositionMaxPersistent;
  FPositionMaxPersistent.InternalSetValue:= {$ifdef FPC}@{$endif}SetPositionMaxPersistent;
  FPositionMaxPersistent.InternalDefaultValue:= FPositionMax;
end;

destructor TSeqFlyingObjects.Destroy;
begin
  inherited;
end;

procedure TSeqFlyingObjects.Update(const SecondsPassed: Single;
                           var RemoveMe: TRemoveType);
var
  AnyObj: TCastleTransform;
  MyObj: TRefObject;
  Pos: TVector3;
  s: Single;
  i, CountObj: Integer;
begin
  inherited;

  { count current objects }
  CountObj:= 0;
  for AnyObj in self do
  begin
    if (AnyObj is TRefObject) then
    begin
      CountObj:= CountObj + 1;
    end;
  end;

  if (FInstances > CountObj) then
  begin
    { add new Objects }
    for i:= 1 to (FInstances - CountObj) do
    begin
      MyObj:= TRefObject.Create(self);
      MyObj.Reference:= FReference;
      MyObj.Translation:= Vector3(
        RandomFloatRange(FPositionMin.X, FPositionMax.X),
        RandomFloatRange(FPositionMin.Y, FPositionMax.Y),
        RandomFloatRange(FPositionMin.Z, FPositionMax.Z));
      s:= FSize + RandomFloatRange(-FSizeRandom, FSizeRandom);
      MyObj.Scale:= Vector3(s, s, s);
      MyObj.Speed:= FSpeed + RandomFloatRange(-FSpeedRandom, FSpeedRandom);
      MyObj.SetTransient;
      Add(MyObj);
    end;
  end;

  { animate Objects }
  for AnyObj in self do
  begin
    if (AnyObj is TRefObject) then
    begin
      MyObj:= AnyObj as TRefObject;
      Pos:= MyObj.Translation;
      Pos.Z:= Pos.Z + MyObj.Speed * SecondsPassed;

      if (Pos.Z > FPositionMax.Z) then
      begin
        if (FInstances < CountObj) then
        begin
          { remove odd Objects }
          RemoveDelayed(AnyObj, True);
        end
        else
        begin
          { renew position }
          Pos.X:= RandomFloatRange(FPositionMin.X, FPositionMax.X);
          Pos.Y:= RandomFloatRange(FPositionMin.X, FPositionMax.Y);
          Pos.Z:= FPositionMin.Z;
          s:= FSize + RandomFloatRange(-FSizeRandom, FSizeRandom);
          MyObj.Scale:= Vector3(s, s, s);
          MyObj.Speed:= FSpeed + RandomFloatRange(-FSpeedRandom, FSpeedRandom);
          if (MyObj.Reference <> FReference) then
            MyObj.Reference:= FReference;
        end;
      end;

      MyObj.Translation:= Pos;
    end;
  end;
end;

procedure TSeqFlyingObjects.SetReference(AValue: TCastleTransform);
begin
  if ((FReference = AValue) OR (self = AValue)) then Exit;

  FReference:= AValue;
end;

procedure TSeqFlyingObjects.SetInstances(AValue: Integer);
begin
  if (AValue < 1) then
    AValue:= 1;

  if (FInstances = AValue) then Exit;

  FInstances:= AValue;
end;

procedure TSeqFlyingObjects.SetSpeed(AValue: Single);
begin
  if (FSpeed = AValue) then Exit;
  FSpeed:= AValue;
end;

procedure TSeqFlyingObjects.SetSpeedRandom(AValue: Single);
begin
  if (FSpeedRandom = AValue) then Exit;
  FSpeedRandom:= AValue;
end;

procedure TSeqFlyingObjects.SetSize(AValue: Single);
begin
  if (FSize = AValue) then Exit;
  FSize:= AValue;
end;

procedure TSeqFlyingObjects.SetSizeRandom(AValue: Single);
begin
  if (FSizeRandom = AValue) then Exit;
  FSizeRandom:= AValue;
end;

function TSeqFlyingObjects.PropertySections(const PropertyName: String): TPropertySections;
begin
  if ArrayContainsString(PropertyName, [
       'Reference', 'Speed', 'SpeedRandom', 'Size', 'SizeRandom', 'Instances',
       'PositionMinPersistent', 'PositionMaxPersistent'
     ]) then
    Result:= [psBasic]
  else
    Result:= inherited PropertySections(PropertyName);
end;

function TSeqFlyingObjects.GetPositionMinPersistent: TVector3;
begin
  Result:= PositionMin;
end;

procedure TSeqFlyingObjects.SetPositionMinPersistent(const AValue: TVector3);
begin
  PositionMin:= AValue;
end;

function TSeqFlyingObjects.GetPositionMaxPersistent: TVector3;
begin
  Result:= PositionMax;
end;

procedure TSeqFlyingObjects.SetPositionMaxPersistent(const AValue: TVector3);
begin
  PositionMax:= AValue;
end;

initialization
  Randomize;
  RegisterSerializableComponent(TSeqFlyingObjects, ['Seq', 'Flying Objects']);
end.

