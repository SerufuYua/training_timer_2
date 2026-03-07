unit MyTimes;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

type
  TMyStrs = Array of String;

procedure SecondsToMinSec(const ASeconds: Integer; var VMin, VSec: Integer); inline;
function MinSecToSeconds(AMin, ASec: Integer): Integer; inline;
function TimeToShortStr(ASeconds: Integer): String;
function TimeToFullStr(ASeconds: Integer): String;

implementation

procedure SecondsToMinSec(const ASeconds: Integer; var VMin, VSec: Integer);
begin
  VSec:= ASeconds;
  VMin:= VSec div 60;
  VSec:= VSec - (VMin * 60);
end;

function MinSecToSeconds(AMin, ASec: Integer): Integer;
begin
  Result:= (AMin * 60) + ASec;
end;

function TimeToShortStr(ASeconds: Integer): String;
var
  min, sec: Integer;
begin
  SecondsToMinSec(ASeconds, min, sec);
  Result:= Format('%.2d:%.2d', [min, sec]);
end;

function TimeToFullStr(ASeconds: Integer): String;
var
  min, sec: Integer;
begin
  SecondsToMinSec(ASeconds, min, sec);
  Result:= Format('%dm %ds', [min, sec]);
end;

end.

