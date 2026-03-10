unit SeqLoadingBar;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, CastleUIControls, CastleRectangles, CastleVectors,
  CastleColors, CastleClassUtils;

type
  TBarDir = (LeftToRight, RightToLeft, BottomToTop, TopToBottom);

  TSeqLoadingBar = class(TCastleUserInterface)
  protected
    FRectangles: array of TFloatRectangle;
    procedure CalcRectangles;
  protected
    FValue, FCycle: Single;
    FColor: TCastleColor;
    FColorPersistent: TCastleColorPersistent;
    function GetColorForPersistent: TCastleColor;
    procedure SetColorForPersistent(const AValue: TCastleColor);
    procedure SetValue(AValue: Single);
    procedure SetCycle(AValue: Single);
    function GetBars: Integer;
    procedure SetBars(AValue: Integer);
  public
    const
      DefaultValue = 0.5;
      DefaultCycle = 0.5;
      DefaultBars = 10;
      DefaultColor: TCastleColor = (X: 1.0; Y: 1.0; Z: 1.0; W: 1.0);

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Update(const SecondsPassed: Single;
                     var HandleInput: boolean); override;
    procedure Render; override;
    function PropertySections(const PropertyName: String): TPropertySections; override;
    property Color: TCastleColor read FColor write FColor;
  published
    property Value: Single read FValue write SetValue
           {$ifdef FPC}default DefaultValue{$endif};
    property Cycle: Single read FCycle write SetCycle
           {$ifdef FPC}default DefaultCycle{$endif};
    property Bars: Integer read GetBars write SetBars
           {$ifdef FPC}default DefaultBars{$endif};
    property ColorPersistent: TCastleColorPersistent read FColorPersistent;
  end;

implementation

uses
  CastleUtils, CastleComponentSerialize, CastleGLUtils;

constructor TSeqLoadingBar.Create(AOwner: TComponent);
begin
  inherited;

  FValue:= DefaultValue;
  FCycle:= DefaultCycle;
  SetLength(FRectangles, DefaultBars);

  { Persistent for ColorBGLow }
  FColorPersistent:= TCastleColorPersistent.Create(nil);
  FColorPersistent.SetSubComponent(true);
  FColorPersistent.InternalGetValue:= {$ifdef FPC}@{$endif}GetColorForPersistent;
  FColorPersistent.InternalSetValue:= {$ifdef FPC}@{$endif}SetColorForPersistent;
  FColorPersistent.InternalDefaultValue:= Color;
  Color:= DefaultColor;
end;

destructor TSeqLoadingBar.Destroy;
begin
  if Assigned(FColorPersistent) then
    FreeAndNil(FColorPersistent);

  inherited;
end;

procedure TSeqLoadingBar.Update(const SecondsPassed: Single;
                                var HandleInput: boolean);
begin
  inherited;
  CalcRectangles;
end;

procedure TSeqLoadingBar.CalcRectangles;
var
  i: Integer;
  BarStep, BarWidth, Shift, HeightStep: Single;
begin
  HeightStep:= RenderRect.Height / Bars;
  BarStep:= RenderRect.Width / Bars;
  BarWidth:= BarStep * FCycle;
  Shift:= (BarStep - BarWidth) / 2.0;

  for i:= 0 to High(FRectangles) do
  begin
    FRectangles[i].Left:=  RenderRect.Left + BarStep * i + Shift;
    FRectangles[i].Width:= BarWidth;
    FRectangles[i].Bottom:= RenderRect.Bottom;
    FRectangles[i].Height:= HeightStep * (i + 1);
  end;
end;

procedure TSeqLoadingBar.Render;
var
  Rect: TFloatRectangle;
begin
  inherited;

  for Rect in FRectangles do
    DrawRectangle(Rect, FColor);
end;

function TSeqLoadingBar.PropertySections(const PropertyName: String): TPropertySections;
begin
  if ArrayContainsString(PropertyName, [
       'Value', 'Cycle', 'Bars', 'ColorPersistent'
     ]) then
    Result:= [psBasic]
  else
    Result:= inherited PropertySections(PropertyName);
end;

procedure TSeqLoadingBar.SetValue(AValue: Single);
begin
  if (FValue = AValue) then exit;
  FValue:= Clamped(AValue, 0.0, 1.0);

end;

procedure TSeqLoadingBar.SetCycle(AValue: Single);
begin
  if (FCycle = AValue) then exit;
  FCycle:= Clamped(AValue, 0.0, 1.0);
end;

function TSeqLoadingBar.GetBars: Integer;
begin
  Result:= Length(FRectangles);
end;

procedure TSeqLoadingBar.SetBars(AValue: Integer);
var
  Num: Integer;
begin

  if (AValue < 2) then
    Num:= 2
  else
    Num:= AValue;

  if (Length(FRectangles) <> Num) then
    SetLength(FRectangles, Num);
end;

function TSeqLoadingBar.GetColorForPersistent: TCastleColor;
begin
  Result:= Color;
end;

procedure TSeqLoadingBar.SetColorForPersistent(const AValue: TCastleColor);
begin
  Color:= AValue;
end;

initialization
  RegisterSerializableComponent(TSeqLoadingBar, ['Seq', 'Loading Bar']);
end.

