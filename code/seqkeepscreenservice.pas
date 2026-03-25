{ Mobile Operating system Screen Keeping integration }
unit SeqKeepScreenService;

interface

uses Classes;

procedure KeepScreen(AEnable: Boolean);

implementation

uses CastleMessaging, CastleLog;

procedure KeepScreen(AEnable: Boolean);
begin
  {$ifdef DEBUG}
  if AEnable then
    WritelnLog('keep-screen is ON')
  else
    WritelnLog('keep-screen is OFF');
  {$endif}

  {$if defined(ANDROID)}
  if AEnable then
    Messaging.Send(['keep-screen', 'ON'])
  else
    Messaging.Send(['keep-screen', 'OFF']);
  {$endif}
end;

end.
