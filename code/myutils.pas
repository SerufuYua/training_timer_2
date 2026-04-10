unit MyUtils;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils, TypInfo;

{ usage: ListOfSet(TypeInfo(TMySetType) }
function ListOfSet(AType: PTypeInfo): TStringArray;

implementation

function ListOfSet(AType: PTypeInfo): TStringArray;
var
  i, len: Integer;
begin
  len:= GetEnumNameCount(AType);
  SetLength(Result, len);

  for i:= 0 to (len - 1) do
    Result[i]:= GetEnumName(AType, i);
end;

end.

