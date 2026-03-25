{ Mobile Operating system Screen Keeping integration }
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
