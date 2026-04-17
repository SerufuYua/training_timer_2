unit MyUtils;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils, TypInfo;

procedure SecondsToHrMinSec(const ASeconds: Integer; var VHour, VMin, VSec: Integer); inline;
function HrMinSecToSeconds(const AHr, AMin, ASec: Integer): Integer; inline;
function TimeToShortStr(ASeconds: Integer): String;
function TimeToFullStr(ASeconds: Integer): String;

{ usage: ListOfSet(TypeInfo(TMySetType) }
function ListOfSet(AType: PTypeInfo): TStringArray;

implementation

procedure SecondsToHrMinSec(const ASeconds: Integer; var VHour, VMin, VSec: Integer);
begin
  VSec:= ASeconds;
  VMin:= VSec div 60;
  VSec:= VSec - (VMin * 60);
  VHour:= VMin div 60;
  VMin:= VMin - (VHour * 60);
end;

function HrMinSecToSeconds(const AHr, AMin, ASec: Integer): Integer;
begin
  Result:= (AHr * 60 * 60) + (AMin * 60) + ASec;
end;

function TimeToShortStr(ASeconds: Integer): String;
var
  hr, min, sec: Integer;
begin
  SecondsToHrMinSec(ASeconds, hr, min, sec);
  Result:= Format('%.2d:%.2d:%.2d', [hr, min, sec]);
end;

function TimeToFullStr(ASeconds: Integer): String;
var
  hr, min, sec: Integer;
begin
  SecondsToHrMinSec(ASeconds, hr, min, sec);
  Result:= Format('%dh %dm %ds', [hr, min, sec]);
end;

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

