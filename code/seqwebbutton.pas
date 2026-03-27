unit SeqWebButton;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, CastleControls, CastleClassUtils;

type
  TSeqWebButton = class(TCastleButton)
  protected
    FWebUrl: String;
  public
    procedure DoClick; override;
    function PropertySections(const PropertyName: String): TPropertySections; override;
  published
    property WebUrl: String read FWebUrl write FWebUrl;
  end;

implementation

uses
  CastleComponentSerialize, CastleUtils, CastleOpenDocument;

procedure TSeqWebButton.DoClick;
begin
  OpenURL(FWebUrl);
  inherited;
end;

function TSeqWebButton.PropertySections(
  const PropertyName: String): TPropertySections;
begin
  if ArrayContainsString(PropertyName, [
       'WebUrl'
     ]) then
    Result:= [psBasic]
  else
    Result:= inherited PropertySections(PropertyName);
end;

initialization
  RegisterSerializableComponent(TSeqWebButton, ['Seq', 'Web Button']);
end.

