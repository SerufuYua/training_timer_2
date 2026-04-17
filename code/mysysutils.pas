unit MySysUtils;

interface

{ Screen Keeping integration for Windows }
procedure KeepScreen; inline;

{ Screen Keeping integration for Android }
procedure KeepScreen(AEnable: Boolean); inline;

implementation

uses
  CastleMessaging, CastleLog
  {$if defined(WINDOWS)}
  , JwaWinBase
  , JwaWinNT
  {$endif};

procedure KeepScreen;
begin
  {$ifdef DEBUG}
  WritelnLog('keep-screen');
  {$endif}

  {$if defined(WINDOWS)}
  { Prevent Screensaver }
  SetThreadExecutionState(ES_DISPLAY_REQUIRED);
  { Prevent Standby or Hibernate }
  SetThreadExecutionState(ES_SYSTEM_REQUIRED);
  {$endif}
end;

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
