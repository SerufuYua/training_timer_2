unit SeqExhibiter;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, CastleUIControls, CastleClassUtils, CastleVectors;

type
  TExhibitDirection = (Vertical, Horizontal, Both);
  TMoveType = (Linear, Quadric, Cubic);
  TShowType = (Appear, Disappear);

  TSeqExhibiter = class(TCastleUserInterface)
  protected
    FTimeCounter, FExhibitTime: Single;
    FParentSize: TVector2;
    FExecuteOnce, FAutoSizeState: Boolean;
    FDirection: TExhibitDirection;
    FMoveType: TMoveType;
    FShowType: TShowType;
    FChainNext: TSeqExhibiter;
    FOnStart, FOnFinish: TNotifyEvent;
    procedure SetExecuteOnce(AValue: Boolean);
    procedure SetChain(AValue: TSeqExhibiter);
  public
    const
      DefaultExecuteOnce = False;
      DefaultExhibitTime = 0.6;
      DefaultDirection = Horizontal;
      DefaultShowType = Appear;
      DefaultMoveType = Linear;

    constructor Create(AOwner: TComponent); override;
    procedure Update(const SecondsPassed: Single;
                     var HandleInput: Boolean); override;
    function PropertySections(const PropertyName: String): TPropertySections; override;
  published
    property ExhibitTime: Single read FExhibitTime write FExhibitTime
             {$ifdef FPC}default DefaultExhibitTime{$endif};
    property ExecuteOnce: Boolean read FExecuteOnce write SetExecuteOnce
             {$ifdef FPC}default DefaultExecuteOnce{$endif};
    property Direction: TExhibitDirection read FDirection write FDirection
             {$ifdef FPC}default DefaultDirection{$endif};
    property MoveType: TMoveType read FMoveType write FMoveType
             {$ifdef FPC}default DefaultMoveType{$endif};
    property ShowType: TShowType read FShowType write FShowType
             {$ifdef FPC}default DefaultShowType{$endif};
    property ChainNext: TSeqExhibiter read FChainNext write SetChain;

    property OnStart: TNotifyEvent read FOnStart write FOnStart;
    property OnFinish: TNotifyEvent read FOnFinish write FOnFinish;
  end;

implementation

uses
  CastleComponentSerialize, CastleUtils
  {$ifdef CASTLE_DESIGN_MODE}
  , PropEdits, CastlePropEdits, TypInfo
  {$endif};

constructor TSeqExhibiter.Create(AOwner: TComponent);
begin
  inherited;

  FChainNext:= nil;
  FOnStart:= nil;
  FOnFinish:= nil;
  FAutoSizeState:= False;
  FTimeCounter:= 0.0;
  FExecuteOnce:= DefaultExecuteOnce;
  FExhibitTime:= DefaultExhibitTime;
  FDirection:= DefaultDirection;
  FMoveType:= DefaultMoveType;
  FShowType:= DefaultShowType;
end;

procedure TSeqExhibiter.Update(const SecondsPassed: Single;
                                    var HandleInput: Boolean);
var
  factor, size: single;
begin
  inherited;
  if ((NOT Assigned(Parent)) OR (NOT FExecuteOnce)) then Exit;
  FTimeCounter:= FTimeCounter + SecondsPassed;

  if (FTimeCounter <= FExhibitTime) then
  begin
    if Assigned(Parent) then
    begin
      factor:= FTimeCounter / FExhibitTime;

      case FMoveType of
        Quadric: factor:= factor * factor;
        Cubic:   factor:= factor * factor * factor;
      end;

      case FShowType of
        Appear:
        begin
          case FDirection of
            Vertical:
            begin
              size:= Lerp(factor, 0.0, FParentSize.Y);
              Parent.Height:= size;
            end;
            Horizontal:
            begin
              size:= Lerp(factor, 0.0, FParentSize.X);
              Parent.Width:= size;
            end;
            Both:
            begin
              size:= Lerp(factor, 0.0, FParentSize.Y);
              Parent.Height:= size;
              size:= Lerp(factor, 0.0, FParentSize.X);
              Parent.Width:= size;
            end;
          end;
        end;
        Disappear:
        begin
          case FDirection of
            Vertical:
            begin
              size:= Lerp(factor, FParentSize.Y, 0.0);
              Parent.Height:= size;
            end;
            Horizontal:
            begin
              size:= Lerp(factor, FParentSize.X, 0.0);
              Parent.Width:= size;
            end;
            Both:
            begin
              size:= Lerp(factor, FParentSize.Y, 0.0);
              Parent.Height:= size;
              size:= Lerp(factor, FParentSize.X, 0.0);
              Parent.Width:= size;
            end;
          end;
        end;
      end;
    end
  end
  else
  begin
    ExecuteOnce:= False;
  end;
end;

procedure TSeqExhibiter.SetExecuteOnce(AValue: Boolean);
begin
  if (FExecuteOnce = AValue) then Exit;

  if AValue then
  begin
    if Assigned(Parent) then
    begin
      Parent.Exists:= True;
      FParentSize.X:= Parent.EffectiveWidth;
      FParentSize.Y:= Parent.EffectiveHeight;
      FAutoSizeState:= Parent.AutoSizeToChildren;
      Parent.AutoSizeToChildren:= False;

      case FShowType of
        Appear:
        begin
          case FDirection of
            Vertical:
            begin
              Parent.Width:= FParentSize.X;
              Parent.Height:= 0.0;
            end;
            Horizontal:
            begin
              Parent.Width:= 0.0;
              Parent.Height:= FParentSize.Y;
            end;
            Both:
            begin
              Parent.Width:= 0.0;
              Parent.Height:= 0.0;
            end;
          end;
        end;
        Disappear:
        begin
          Parent.Width:= FParentSize.X;
          Parent.Height:= FParentSize.Y;
        end;
      end;

      FTimeCounter:= 0.0;

      if Assigned(FOnStart) then
        FOnStart(self);
    end
  end
  else
  begin
    if Assigned(Parent) then
    begin
      Parent.Width:= FParentSize.X;
      Parent.Height:= FParentSize.Y;
      Parent.AutoSizeToChildren:= FAutoSizeState;
    end;

    if Assigned(FOnFinish) then
      FOnFinish(self);

    if Assigned(FChainNext) then
      FChainNext.ExecuteOnce:= True;
  end;

  FExecuteOnce:= AValue;
end;

procedure TSeqExhibiter.SetChain(AValue: TSeqExhibiter);
begin
  if (FChainNext <> AValue) then
    FChainNext:= AValue;
end;

function TSeqExhibiter.PropertySections(const PropertyName: String): TPropertySections;
begin
  if ArrayContainsString(PropertyName, [
       'ExecuteOnce', 'ExhibitTime', 'Direction', 'ChainNext', 'MoveType',
       'ShowType'
     ]) then
    Result:= [psBasic]
  else
    Result:= inherited PropertySections(PropertyName);
end;

{$ifdef CASTLE_DESIGN_MODE}
type
  { Property editor to select an ditection }
  TSeqExhibiterDirectionEditor = class(TStringPropertyEditor)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

  { Property editor to select an Show Type }
  TSeqExhibiterShowTypeEditor = class(TStringPropertyEditor)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

  { Property editor to select an Move Type }
  TSeqExhibiterMoveTypeEditor = class(TStringPropertyEditor)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

{ TSeqExhibiterDirectionEditor }
function TSeqExhibiterDirectionEditor.GetAttributes: TPropertyAttributes;
begin
  Result:= [paMultiSelect, paValueList, paSortList, paRevertable];
end;

procedure TSeqExhibiterDirectionEditor.GetValues(Proc: TGetStrProc);
var
  dir: TExhibitDirection;
begin
  Proc('');
  for dir in TExhibitDirection do
    Proc(GetEnumName(TypeInfo(TExhibitDirection), Ord(dir)));
end;

{ TSeqExhibiterShowTypeEditor }
function TSeqExhibiterShowTypeEditor.GetAttributes: TPropertyAttributes;
begin
  Result:= [paMultiSelect, paValueList, paSortList, paRevertable];
end;

procedure TSeqExhibiterShowTypeEditor.GetValues(Proc: TGetStrProc);
var
  sType: TShowType;
begin
  Proc('');
  for sType in TShowType do
    Proc(GetEnumName(TypeInfo(TShowType), Ord(sType)));
end;

{ TSeqExhibiterMoveTypeEditor }
function TSeqExhibiterMoveTypeEditor.GetAttributes: TPropertyAttributes;
begin
  Result:= [paMultiSelect, paValueList, paSortList, paRevertable];
end;

procedure TSeqExhibiterMoveTypeEditor.GetValues(Proc: TGetStrProc);
var
  mType: TMoveType;
begin
  Proc('');
  for mType in TMoveType do
    Proc(GetEnumName(TypeInfo(TMoveType), Ord(mType)));
end;
{$endif}

initialization
  RegisterSerializableComponent(TSeqExhibiter, ['Seq', 'UI Exhibiter']);

  {$ifdef CASTLE_DESIGN_MODE}
  RegisterPropertyEditor(TypeInfo(AnsiString), TSeqExhibiter, 'Direction',
                         TSeqExhibiterDirectionEditor);
  RegisterPropertyEditor(TypeInfo(AnsiString), TSeqExhibiter, 'ShowType',
                         TSeqExhibiterShowTypeEditor);
  RegisterPropertyEditor(TypeInfo(AnsiString), TSeqExhibiter, 'MoveType',
                         TSeqExhibiterMoveTypeEditor);
  {$endif}
end.

