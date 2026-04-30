unit SeqRandomShow;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, CastleUIControls, CastleClassUtils;

type
  TSeqRandomShow = class(TCastleUserInterface)
  private
    FPlane: TCastleUserInterface;
  protected
    function GetShakeIt: String;
    procedure SetShakeIt(AValie: String);
  public
    const
      DefaultShakeIt = 'change me for Shake';

    constructor Create(AOwner: TComponent); override;
    function PropertySections(const PropertyName: String): TPropertySections; override;
    procedure Shake; virtual;

    property ExistsPlane: TCastleUserInterface read FPlane;
  published
    property ShakeIt: String read GetShakeIt write SetShakeIt;
  end;

implementation

uses
  CastleComponentSerialize, CastleUtils;

constructor TSeqRandomShow.Create(AOwner: TComponent);
begin
  inherited;
  FPlane:= nil;
end;

procedure TSeqRandomShow.Shake;
var
  i, l: Integer;
  Plane: TCastleUserInterface;
  Planes: Array of TCastleUserInterface;
begin
  Planes:= [];
  for Plane in self do
  begin
    Plane.Exists:= False;
    System.Insert(Plane, Planes, Length(Planes));
  end;

  l:= Length(Planes);
  if (l > 0 ) then
  begin
    i:= Random(l);
    FPlane:= Planes[i];
    FPlane.Exists:= True;
  end;
end;

function TSeqRandomShow.GetShakeIt: String;
begin
  Result:= DefaultShakeIt;
end;

procedure TSeqRandomShow.SetShakeIt(AValie: String);
begin
  Shake;
end;

function TSeqRandomShow.PropertySections(const PropertyName: String): TPropertySections;
begin
  if ArrayContainsString(PropertyName, [
       'ShakeIt'
     ]) then
    Result:= [psBasic]
  else
    Result:= inherited PropertySections(PropertyName);
end;

initialization
  Randomize;
  RegisterSerializableComponent(TSeqRandomShow, ['Seq', 'Random Show']);
end.
