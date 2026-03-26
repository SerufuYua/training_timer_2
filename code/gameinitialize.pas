{ Game initialization.
  This unit is cross-platform.
  It will be used by the platform-specific program or library file.

  Feel free to use this code as a starting point for your own projects.
  This template code is in public domain, unlike most other CGE code which
  is covered by BSD or LGPL (see https://castle-engine.io/license). }
unit GameInitialize;

interface

implementation

uses SysUtils,
  CastleWindow, CastleLog, CastleUIControls, CastleConfig, GameSound
  {$region 'Castle Initialization Uses'}
  // The content here may be automatically updated by CGE editor.
  , GameViewSettingsSimple
  , GameViewSequenceTimer
  , GameViewBanner
  {$endregion 'Castle Initialization Uses'};

var
  Window: TCastleWindow;

{ One-time initialization of resources. }
procedure ApplicationInitialize;
begin
  { Load settings }
  {$ifdef MSWINDOWS}
  UserConfig.Load(ApplicationName + '.conf');
  {$else}
  UserConfig.Load;
  {$endif}

  { Adjust container settings for a scalable UI (adjusts to any window size in a smart way). }
  Window.Container.LoadSettings('castle-data:/CastleSettings.xml');

  { Sounds initialization }
  InitializeSounds;

  { Create views (see https://castle-engine.io/views ). }
  {$region 'Castle View Creation'}
  // The content here may be automatically updated by CGE editor.
  ViewSettingsSimple := TViewSettingsSimple.Create(Application);
  ViewSequenceTimer := TViewSequenceTimer.Create(Application);
  ViewBanner := TViewBanner.Create(Application);
  {$endregion 'Castle View Creation'}

  Window.Container.View:= ViewBanner;
end;

initialization
  { This initialization section configures:
    - Application.OnInitialize
    - Application.MainWindow
    - determines initial window size

    You should not need to do anything more in this initialization section.
    Most of your actual application initialization (in particular, any file reading)
    should happen inside ApplicationInitialize. }

  Application.OnInitialize := @ApplicationInitialize;

  Window := TCastleWindow.Create(Application);
  Window.Width:= 400;
  Window.Height:= 900;
  Window.AntiAliasing:= aa4SamplesNicer;
  Application.MainWindow := Window;

  { Optionally, adjust window fullscreen state and size at this point.
    See https://castle-engine.io/window_size . }

  { Handle command-line parameters like --fullscreen and --window.
    By doing this last, you let user to override your fullscreen / mode setup. }
  Window.ParseParameters;
end.
