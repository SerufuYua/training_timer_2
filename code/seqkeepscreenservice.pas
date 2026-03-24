{
  Copyright 2017-2024 Michalis Kamburelis and Jan Adamec.

  This file is part of "Castle Game Engine".

  "Castle Game Engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Castle Game Engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Operating system Photo library integration (TPhotoService). }
unit SeqKeepScreenService;

interface

uses Classes;

procedure KeepScreen(enable: Boolean);

implementation

uses CastleMessaging, CastleLog;

procedure KeepScreen(enable: Boolean);
begin
  if enable then
    WritelnLog('keep-screen is ON')
  else
    WritelnLog('keep-screen is OFF');

  {$if defined(ANDROID)}
  if enable then
    Messaging.Send(['keep-screen', 'ON'])
  else
    Messaging.Send(['keep-screen', 'OFF']);
  {$endif}
end;

end.
